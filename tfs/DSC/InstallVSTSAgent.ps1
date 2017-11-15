configuration VSTSAgentInstallDsc
{
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	
    Node localhost
    {                
        Script DownloadAgent
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }
            SetScript = {
				#This is TFS 2017 Update 3
                $agentUrl = "https://go.microsoft.com/fwlink/?linkid=858950"
                $agentZip = "$env:TEMP" + "\vsts_agent.zip"
                Write-Host "Downloading TFS: $agentUrl"
                Invoke-WebRequest -Uri $agentUrl -OutFile $agentZip
            }
            TestScript = {
                $agentZip = "$env:TEMP" + "\vsts_agent.zip"
                Test-Path $agentZip
            }
        }


        Script UnzipAgent
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }
            SetScript = {
                $agentZip = "$env:TEMP" + "\vsts_agent.zip"
                $agentPath = "C:\agent"
                If(!(Test-Path $agentPath))
                {
                    New-Item -ItemType Directory -Force -Path $agentPath
                }

                $shell = New-Object -com shell.application
                $zip = $shell.NameSpace($agentZip)
                Foreach($item in $zip.items())
                {
                    $shell.Namespace($agentPath).copyhere($item)
                }
            }
            TestScript = {
                Test-Path "C:\agent\config.cmd"
            }
            DependsOn = "[Script]DownloadAgent"
        }


        Script ConfigAgent
        {
            GetScript = { return @{ 'Result' = $true }}
            SetScript = {
                Set-Location "C:\agent"
                $tfsurl = "http://tfs:8080/tfs"
                $cmd = ".\config.cmd --unattended --runAsService --work _work --url $tfsurl --auth integrated --pool default --agent $env:COMPUTERNAME"
                Invoke-Expression $cmd | Write-Verbose
            }
            TestScript = {
                Test-Path "C:\agent\.credentials"
            }
            DependsOn = "[Script]UnzipAgent"
            PsDscRunAsCredential = $DomainCreds
        }
    }
}
