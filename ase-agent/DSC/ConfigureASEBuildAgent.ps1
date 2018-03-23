configuration ConfigureASEBuildAgentDsc
{
    param
    (
        [Parameter(Mandatory)]
        [String]$TSUrl,

        [Parameter(Mandatory)]
        [String]$AgentPool,

        [Parameter(Mandatory)]
        [String]$PAToken,

        [Parameter(Mandatory)]
        [String]$AseIp,

        [Parameter(Mandatory)]
        [String]$AppDns,

        [Parameter(Mandatory=$false)]
        [String]$VSTSAgentUrl = "https://vstsagentpackage.azureedge.net/agent/2.127.0/vsts-agent-win-x64-2.127.0.zip"
    )
    
    Import-DscResource -ModuleName xNetworking, 'PSDesiredStateConfiguration'

    $tmp = $AppDns.Split('.')
    $OFS='.'
    $AppScmDns = $tmp[0] + ".scm." + [String]$tmp[1..$tmp.Count]
	
    Node localhost
    {                
        Script DownloadAgent
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }
            SetScript = {
                $agentUrl = $using:VSTSAgentUrl
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
                $tsurl = $using:TSUrl
                $tok = $using:PAToken
                $pool = $using:AgentPool
                $cmd = ".\config.cmd --unattended --runAsService --work _work --url $tsurl --auth pat --token $tok --pool $pool --agent $env:COMPUTERNAME"
                Invoke-Expression $cmd | Write-Verbose
            }
            TestScript = {
                Test-Path "C:\agent\.credentials"
            }
            DependsOn = "[Script]UnzipAgent"
        }

        xHostsFile HostEntry
        {
            HostName  = $AppDns
            IPAddress = $AseIp
            Ensure    = 'Present'
        }

        xHostsFile HostScmEntry
        {
            HostName  = $AppScmDns
            IPAddress = $AseIp
            Ensure    = 'Present'
        }

        Registry StrongCrypto1
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
            ValueName   = "SchUseStrongCrypto"
            ValueType   = "Dword"
            ValueData   = "00000001"
        }

        Registry StrongCrypto2
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
            ValueName   = "SchUseStrongCrypto"
            ValueType   = "Dword"
            ValueData   = "00000001"
        }
    }
}
