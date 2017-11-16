configuration TFSInstallDsc
{
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Import-DscResource -ModuleName  xStorage, 'PSDesiredStateConfiguration'
	    
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
				#This is TFS 2017 Update 3
                $TFSURL = "https://go.microsoft.com/fwlink/?LinkId=857134&clcid=0x409"
                $installer = "$env:TEMP" + "\tfs_installer.exe"
                Write-Host "Downloading TFS: $TFSURL"
                Invoke-WebRequest -Uri $TFSURL -OutFile $installer
            }
            TestScript = {
                $installer = "$env:TEMP" + "\tfs_installer.exe"
                Test-Path $installer
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
                $installer =  "$env:TEMP" + "\tfs_installer.exe"
                $cmd = "$installer /full /quiet /Log $env:TEMP\tfs_install_log.txt"
                Write-Verbose "Command to run: $cmd"
                Invoke-Expression $cmd | Write-Verbose

                #The tfs installer will per default run in the background. We will wait for it. 

                #Sleep for 10 seconds to make sure installer is going
                Start-Sleep -s 10
                $insprocs = Get-Process -Name "tfs_inst*"
                While ($insprocs.length -gt 0) {
                    Wait-Process -Id $insprocs[0].Id
                    $insprocs = Get-Process -Name "tfs_inst*"                    
                }
            }
            TestScript = {
                Test-Path "C:\Program Files\Microsoft Team Foundation Server 15.0\Tools\TfsConfig.exe"
            }
            DependsOn = "[Script]DownloadTFS"
        }

        Script ConfigureTFS
        {
            GetScript = {
                return @{ 'Result' = $true }                
            }
            SetScript = {
                Write-Verbose "Configuring TFS..."
                $cfgexe = "C:\\Program Files\\Microsoft Team Foundation Server 15.0\\Tools\\TfsConfig.exe"
				$iniuri = "https://raw.githubusercontent.com/hansenms/iac/master/tfs/DSC/basic.ini"
                $inifile = "C:\\Windows\\Temp\\basic.ini"
				Invoke-WebRequest -Uri $iniuri -OutFile $inifile
                $cmd = "& '$cfgexe' unattend /configure /continue /unattendfile:$inifile"
                Invoke-Expression $cmd | Write-Verbose
            }
            TestScript = {
                $false
            }
            DependsOn = "[Script]InstallTFS"
            PsDscRunAsCredential = $DomainCreds
        }
    }
}