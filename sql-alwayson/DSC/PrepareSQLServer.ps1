configuration SQLServerPrepareDsc
{
    param
    (
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement, xNetworking, xStorage

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

        File BackupFolder
        {
            DestinationPath = "F:\Backup"
            Type = "Directory"
            Ensure = "Present"
            DependsOn = "[xDisk]ADDataDisk"
        }

        File BackupReadme
        {
            DestinationPath = "F:\Backup\README.txt"
            Contents = "This folder is for SQL backups"
            Type = "File"
            Ensure = "Present"
            DependsOn = "[File]BackupFolder"
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