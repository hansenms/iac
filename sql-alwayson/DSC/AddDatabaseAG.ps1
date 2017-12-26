configuration AddDatabaseAGDsc
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

		[String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory)]
        [String]$SQLServerAG,

        [Parameter(Mandatory)]
        [String[]]$SQLDatabases,

        [Parameter(Mandatory=$false)]
        [String]$SQLInstanceName = "MSSQLSERVER",

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds

    )

    Import-DscResource -ModuleName xComputerManagement, xNetworking, xStorage, SmbShare, xSMBShare, SqlServer, SqlServerDsc, PSDesiredStateConfiguration

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

   
    Node localhost
    {
        
        File BackupDirectory
        {
            Ensure = "Present" 
            Type = "Directory" 
            DestinationPath = "F:\Backup"    
        }


        xSMBShare DBBackupShare
        {
            Name = "DBBackup"
            Path = "F:\Backup"
            Ensure = "Present"
            FullAccess = $DomainCreds.UserName
            Description = "Backup share for SQL Server"
            DependsOn = "[File]BackupDirectory"
        }

        SqlAGDatabase AddDatabaseToAG
        {
            AvailabilityGroupName   = $SQLServerAG
            BackupPath              = "\\" + $env:COMPUTERNAME + "\DBBackup"
            DatabaseName            = $SQLDatabases
            InstanceName            = $SQLInstanceName
            ServerName              = $env:COMPUTERNAME
            Ensure                  = 'Present'
            ProcessOnlyOnActiveNode = $true
            PsDscRunAsCredential    = $DomainCreds
            DependsOn               = "[xSMBShare]DBBackupShare"
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