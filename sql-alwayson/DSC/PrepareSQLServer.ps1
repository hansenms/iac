configuration SQLServerPrepareDsc
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

		[String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory=$true)]
        [String]$ClusterName,

        [Parameter(Mandatory=$true)]
        [String]$ClusterOwnerNode,

        [Parameter(Mandatory=$true)]
        [String]$ClusterIP,

        [Parameter(Mandatory=$false)]
        [ValidateSet('primary','secondary')]
        [String]$Role = "primary",

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement, xNetworking, xActiveDirectory, xStorage, xFailoverCluster, SqlServerDsc
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        xWaitforDisk Disk2
        {
                DiskId = 2
                RetryIntervalSec =$RetryIntervalSec
                RetryCount = $RetryCount
        }

        xDisk ADDataDisk
        {
            DiskId = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }
        
		xFirewall DatabaseEngineFirewallRule
        {
            Direction = "Inbound"
            Name = "SQL-Server-Database-Engine-TCP-In"
            DisplayName = "SQL Server Database Engine (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Database Engine."
            Group = "SQL Server"
            Enabled = "True"
            Protocol = "TCP"
            LocalPort = "1433"
            Ensure = "Present"
        }

        xFirewall DatabaseMirroringFirewallRule
        {
            Direction = "Inbound"
            Name = "SQL-Server-Database-Mirroring-TCP-In"
            DisplayName = "SQL Server Database Mirroring (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Database Mirroring."
            Group = "SQL Server"
            Enabled = "True"
            Protocol = "TCP"
            LocalPort = "5022"
            Ensure = "Present"
        }

        xFirewall ListenerFirewallRule
        {
            Direction = "Inbound"
            Name = "SQL-Server-Availability-Group-Listener-TCP-In"
            DisplayName = "SQL Server Availability Group Listener (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Availability Group listener."
            Group = "SQL Server"
            Enabled = "True"
            Protocol = "TCP"
            LocalPort = "59999"
            Ensure = "Present"
        }

        WindowsFeature FC
        {
            Name = "Failover-Clustering"
            Ensure = "Present"
        }

        WindowsFeature FailoverClusterTools 
        { 
            Ensure = "Present" 
            Name = "RSAT-Clustering-Mgmt"
            DependsOn = "[WindowsFeature]FC"
        } 

        WindowsFeature FCPS
        {
            Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]FailoverClusterTools"
        }

        WindowsFeature FCPSCMD
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]FCPS'
        }

        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }


        if ($Role -eq "primary") {
            xCluster CreateCluster
            {
                Name                          = $ClusterName
                StaticIPAddress               = $ClusterIP
                DomainAdministratorCredential = $DomainCreds
                DependsOn                     = "[WindowsFeature]FCPSCMD"
            }

            SqlAlwaysOnService EnableAlwaysOn
            {
                Ensure               = 'Present'
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                RestartTimeout       = 120
                DependsOn = "[xCluster]CreateCluster"
            }

            # Create a DatabaseMirroring endpoint
            SqlServerEndpoint HADREndpoint
            {
                EndPointName         = 'HADR'
                Ensure               = 'Present'
                Port                 = 5022
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                DependsOn            = "[SqlAlwaysOnService]EnableAlwaysOn"
            }

            # Create the availability group on the instance tagged as the primary replica
            SqlAG AddTestAG
            {
                Ensure               = "Present"
                Name                 = "AGDefault"
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                DependsOn            = "[SqlServerEndpoint]HADREndpoint"
            }

        } else {
            xWaitForCluster WaitForCluster
            {
                Name             = $ClusterName
                RetryIntervalSec = 10
                RetryCount       = 60
                DependsOn        = "[WindowsFeature]FCPSCMD"
            }

            #We have to do this manually due to a problem with xCluster:
            #  see: https://github.com/PowerShell/xFailOverCluster/issues/7
            #      - Cluster is added with an IP and the xCluster module tries to access this IP. 
            #      - Cluster is not not yet responding on that addreess
            Script JoinExistingCluster
            {
                GetScript = { 
                    return @{ 'Result' = $true }
                }
                SetScript = {
                    $targetNodeName = $env:COMPUTERNAME
                    Add-ClusterNode -Name $targetNodeName -Cluster $using:ClusterOwnerNode
                }
                TestScript = {
                    $targetNodeName = $env:COMPUTERNAME
                    $(Get-ClusterNode -Cluster $using:ClusterOwnerNode).Name -contains $targetNodeName
                }
                DependsOn = "[xWaitForCluster]WaitForCluster"
                PsDscRunAsCredential = $DomainCreds
            }

            SqlAlwaysOnService EnableAlwaysOn
            {
                Ensure               = 'Present'
                ServerName           = $env:COMPUTERNAME
                InstanceName         = 'MSSQLSERVER'
                RestartTimeout       = 120
                DependsOn = "[Script]JoinExistingCluster"
            }

              # Create a DatabaseMirroring endpoint
              SqlServerEndpoint HADREndpoint
              {
                  EndPointName         = 'HADR'
                  Ensure               = 'Present'
                  Port                 = 5022
                  ServerName           = $env:COMPUTERNAME
                  InstanceName         = 'MSSQLSERVER'
                  DependsOn            = "[SqlAlwaysOnService]EnableAlwaysOn"
              }
    
               # Add the availability group replica to the availability group
                SqlAGReplica AddReplica
                {
                    Ensure                     = 'Present'
                    Name                       = $env:COMPUTERNAME
                    AvailabilityGroupName      = "AGDefault"
                    ServerName                 = $env:COMPUTERNAME
                    InstanceName               = 'MSSQLSERVER'
                    PrimaryReplicaServerName   = $ClusterOwnerNode
                    PrimaryReplicaInstanceName = 'MSSQLSERVER'
                }
        }

        <#TODO: Add user for running SQL server.
        xADUser SvcUser
        {

        }
        #>

        File DataFolder
        {
            DestinationPath = "F:\Data"
            Type = "Directory"
            Ensure = "Present"
            DependsOn = "[xDisk]ADDataDisk"
        }

        File DataReadme
        {
            DestinationPath = "F:\Data\README.txt"
            Contents = "This folder is for SQL Databases"
            Type = "File"
            Ensure = "Present"
            DependsOn = "[File]DataFolder"
        }

        File LogFolder
        {
            DestinationPath = "F:\Log"
            Type = "Directory"
            Ensure = "Present"
            DependsOn = "[xDisk]ADDataDisk"
        }

        File LogReadme
        {
            DestinationPath = "F:\Log\README.txt"
            Contents = "This folder is for SQL logs"
            Type = "File"
            Ensure = "Present"
            DependsOn = "[File]LogFolder"
        }

        File BackupReadme
        {
            DestinationPath = "F:\Backup\README.txt"
            Contents = "This folder is for SQL backups"
            Type = "File"
            Ensure = "Present"
            DependsOn = "[File]BackupFolder"
        }

        File BackupFolder
        {
            DestinationPath = "F:\Backup"
            Type = "Directory"
            Ensure = "Present"
            DependsOn = "[xDisk]ADDataDisk"
        }

        <#
        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Data
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Data'
            Path                    = 'F:\Data'
            RestartService          = $true
            DependsOn = "[File]DataReadme"
        }

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Log
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Log'
            Path                    = 'F:\Log'
            RestartService          = $true
            DependsOn = "[File]LogReadme"
        }

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Backup
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Backup'
            Path                    = 'F:\Backup'
            RestartService          = $true
            DependsOn = "[File]BackupReadme"
        }
        #>

        SqlServerLogin AddDomainAdminAccountToSqlServer
        {
            Name = $DomainCreds.UserName
            LoginType = "WindowsUser"
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
        }

		SqlServerRole AddDomainAdminAccountToSysAdmin
        {
			Ensure = "Present"
            MembersToInclude = $DomainCreds.UserName
            ServerRoleName = "sysadmin"
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
			DependsOn = "[SqlServerLogin]AddDomainAdminAccountToSqlServer"
        }

        #TODO: We should create a dedicated user for this.
        SqlServiceAccount SetServiceAcccount_User
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ServiceType    = 'DatabaseEngine'
            ServiceAccount = $DomainCreds
            RestartService = $true
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }
    }
}

function Get-NetBIOSName
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}