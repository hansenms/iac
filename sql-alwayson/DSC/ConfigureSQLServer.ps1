configuration SQLServerConfigureDsc
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

		[String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement, xNetworking, xActiveDirectory, xStorage, SqlServerDsc
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        
        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        <#TODO: Add user for running SQL server.
        xADUser SvcUser
        {

        }
        #>

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Data
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Data'
            Path                    = 'F:\Data'
            RestartService          = $true
        }

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Log
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Log'
            Path                    = 'F:\Log'
            RestartService          = $true
            DependsOn = "[SqlDatabaseDefaultLocation]Set_SqlDatabaseDefaultDirectory_Data"
        }

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Backup
        {
			ServerName = "$env:COMPUTERNAME"
			InstanceName = "MSSQLSERVER"
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Backup'
            Path                    = 'F:\Backup'
            RestartService          = $true
            DependsOn = "[SqlDatabaseDefaultLocation]Set_SqlDatabaseDefaultDirectory_Log"
        }

        SqlServerLogin AddDomainAdminAccountToSqlServer
        {
            Name = $DomainCreds.UserName
            LoginType = "WindowsUser"
			ServerName = "$env:COMPUTERNAME"
            InstanceName = "MSSQLSERVER"
            DependsOn = "[SqlDatabaseDefaultLocation]Set_SqlDatabaseDefaultDirectory_Backup"
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
            DependsOn = "[SqlServerRole]AddDomainAdminAccountToSysAdmi"
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