configuration SQLWitnessPrepareDsc
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [String]$DomainNetbiosName = (Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName xComputerManagement, xSmbShare, xActiveDirectory, xStorage
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    xWaitforDisk Disk2 {
        DiskId           = 2
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }

    xDisk AddDataDisk {
        DiskId      = 2
        DriveLetter = "F"
        DependsOn   = "[xWaitForDisk]Disk2"
    }

    File FSWFolder {
        DestinationPath = "F:\SQLFILEWITNESS"
        Type            = "Directory"
        Ensure          = "Present"
        DependsOn       = "[xDisk]AddDataDisk"  
    }

    xSmbShare FSWShare
    {
        Name       = "SQLFILEWITNESS"
        Path       = "F:\SQLFILEWITNESS"
        FullAccess = "BUILTIN\Administrators"
        Ensure     = "Present"
        DependsOn  = "[File]FSWFolder"
    }

}