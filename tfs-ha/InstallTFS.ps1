configuration TFSInstallDsc
{
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [String]$SqlServerInstance,

        [Parameter(Mandatory)]
        [String]$primaryInstance,

        [Parameter(Mandatory=$false)]
        [ValidateSet("TFS2018", "TFS2017Update3","TFS2017Update2")]
        [String]$TFSVersion = "TFS2018"
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Import-DscResource -ModuleName  xStorage, xPendingReboot, 'PSDesiredStateConfiguration'

    <#
        Download links for TFS:

        2017Update2: https://go.microsoft.com/fwlink/?LinkId=850949
        2017Update3: https://go.microsoft.com/fwlink/?LinkId=857134
        2018: https://go.microsoft.com/fwlink/?LinkId=856344
    #>

    $TFSDownloadLinks = @{
        "TFS2018" = "https://go.microsoft.com/fwlink/?LinkId=856344"
        "TFS2017Update2" = "https://go.microsoft.com/fwlink/?LinkId=850949"
        "TFS2017Update3" = "https://go.microsoft.com/fwlink/?LinkId=857134"
    }
  
    $currentDownloadLink = $TFSDownloadLinks[$TFSVersion]
    $installerDownload = $env:TEMP + "\tfs_installer.exe"
    $isTFS2017 = $false

    $isPrimaryInstance = $primaryInstance -eq $env:COMPUTERNAME

    if ($TFSVersion.Substring(0,7) -eq "TFS2017") {
        $isTFS2017 = $true
    }
	
    $TfsConfigExe = "C:\Program Files\Microsoft Team Foundation Server 2018\Tools\TfsConfig.exe"

    if ($isTFS2017) {
        $TfsConfigExe = "C:\Program Files\Microsoft Team Foundation Server 15.0\Tools\TfsConfig.exe"
    }
    
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

        Script DownloadTFS
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }
            SetScript = {
                Write-Host "Downloading TFS: " + $using:currentDownloadLink
                Invoke-WebRequest -Uri $using:currentDownloadLink -OutFile $using:installerDownload
            }
            TestScript = {
                Test-Path $using:installerDownload
            }
			DependsOn = "[xDisk]ADDataDisk"
        }
        
        Script InstallTFS
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }
            SetScript = {
                Write-Verbose "Install TFS..."                
                
                $cmd = $using:installerDownload + " /full /quiet /Log $env:TEMP\tfs_install_log.txt"
                Write-Verbose "Command to run: $cmd"
                Invoke-Expression $cmd | Write-Verbose


                #Sleep for 10 seconds to make sure installer is going
                Start-Sleep -s 10

                #The tfs installer will per default run in the background. We will wait for it. 
                Wait-Process -Name "tfs_installer"
            }
            TestScript = {
                Test-Path $using:TfsConfigExe
            }
            DependsOn = "[Script]DownloadTFS"
        }
 
 
        xPendingReboot PostInstallReboot {
            Name = "Check for a pending reboot before changing anything"
            DependsOn = "[Script]InstallTFS"
        }
 
        LocalConfigurationManager{
            RebootNodeIfNeeded = $True
        }
                
        Script ConfigureTFS
        {
            GetScript = {
                return @{ 'Result' = $true }                
            }
            SetScript = {
                $cmd = ""
                if ($using:isPrimaryInstance) {                
                    $cmd = "& '$using:TfsConfigExe' unattend /configure /continue /type:NewServerAdvanced  /inputs:SqlInstance=" + $using:SqlServerInstance
                } else {
                    $cmd = "& '$using:TfsConfigExe' unattend /configure /continue /type:ApplicationTierOnlyAdvanced  /inputs:SqlInstance=" + $using:SqlServerInstance
                }

                Write-Verbose "$cmd"
                Invoke-Expression $cmd | Write-Verbose
            }
            TestScript = {
                $false
            }
            DependsOn = "[xPendingReboot]PostInstallReboot"
            PsDscRunAsCredential = $DomainCreds
        }
    }
}