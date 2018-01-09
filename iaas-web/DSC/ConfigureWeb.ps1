configuration ConfigureWebDsc
{
    param
    (
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    Node localhost
    {
        WindowsFeature IIS
        {
            Ensure          = 'Present'
            Name            = 'Web-Server'
        }

        WindowsFeature aspnet45
        {
            Ensure          = 'Present'
            Name            = 'Web-Asp-Net45'
            DependsOn       = '[WindowsFeature]IIS'
        }
        
        WindowsFeature NetFrameworkFeature
        {
            Ensure          = 'Present'
            Name            = 'NET-Framework-Features'
            DependsOn       = '[WindowsFeature]aspnet45'
        }

        xWebsite DefaultSite 
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot'
            DependsOn       = '[WindowsFeature]NetFrameworkFeature'
        }

        Script InstallDotNetStuff
        {
            GetScript = { 
                return @{ 'Result' = $true }
            }

            TestScript = { 
                Test-Path $env:temp\dotnet-dev-win-x64.1.0.4.exe
            }
            SetScript = {
                # Install the .NET Core SDK
                Invoke-WebRequest https://go.microsoft.com/fwlink/?linkid=848827 -outfile $env:temp\dotnet-dev-win-x64.1.0.4.exe
                Start-Process $env:temp\dotnet-dev-win-x64.1.0.4.exe -ArgumentList '/quiet' -Wait

                # Install the .NET Core Windows Server Hosting bundle
                Invoke-WebRequest https://go.microsoft.com/fwlink/?LinkId=817246 -outfile $env:temp\DotNetCore.WindowsHosting.exe
                Start-Process $env:temp\DotNetCore.WindowsHosting.exe -ArgumentList '/quiet' -Wait

                # Restart the web server so that system PATH updates take effect
                net stop was /y
                net start w3svc
            }
            DependsOn = "[xWebsite]DefaultSite"
        }

        File WebContent
        {
            Ensure          = 'Present'
            DestinationPath = 'C:\inetpub\wwwroot\index.html'
            Recurse         = $true
            Type            = 'File'
            Contents        = '<html><body><h1>This is the default website</h1></body></html>' 
            DependsOn       = '[xWebsite]DefaultSite'
        }       
    }
}
