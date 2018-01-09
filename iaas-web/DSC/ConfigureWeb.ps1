configuration Sample_xWebsite_NewWebsite
{
    param
    (
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    Node $NodeName
    {
        WindowsFeature IIS
        {
            Ensure          = 'Present'
            Name            = 'Web-Server'
        }

        xWebsite DefaultSite 
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot'
            DependsOn       = '[WindowsFeature]IIS'
        }

        File WebContent
        {
            Ensure          = 'Present'
            DestinationPath = 'C:\inetpub\wwwroot\index.html'
            Recurse         = $true
            Type            = 'File'
            Contents        = '<html><body><h1>This is the default website</h1></body></html>' 
            DependsOn       = '[WindowsFeature]IIS'
        }       
    }
}
