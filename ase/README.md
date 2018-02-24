App Service Environment with Website
------------------------------------

This template illustrates how to deploy [Azure App Service Environment](https://docs.microsoft.com/en-us/azure/app-service/environment/intro) a.k.a. ASEv2 with ILB configuration.

The template allows you to supply an existing Subnet for ASE deployment (there should be no resources in this Subnet). If you do not supply a Subnet, i.e. leave that parameter as `null`, a new Virtual Network will be created and the ASE deployed in it. 

The ASE needs a certificate, which supports the `*.domainname`, and `*.scm.domainname` DNS names. If you do not have a certificate, you can generate one with the `New-SelfSignedCertificate` command. The repository also includes a [convenience script](https://github.com/hansenms/iac/blob/master/scripts/PrepareAseDeployment.ps1), that prepares the details needed for this deployment. To use the script for this deployment:

```
iac\scripts\PrepareAseDeployment.ps1 -DomainName mydomain-internal.us -OutFile C:\temp\myase.parameters.json
```

This will generate a parameter file that you can use to either copy/paste from or with a CLI or Powershell command to deploy the template. 

Note: It would be possible (and better) to deploy the certificate using Key Vault, but this workflow is not supported in all clouds (including sovereign clouds); for compatibility reasons, the certificate is passed as a string blob in this template.

Please note that ASE is not yet available in Azure Government, hence no Azure Government deploy button. 

<a href="https://transmogrify.azurewebsites.net/ase/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<!--
<a href="https://transmogrify.azurewebsites.net/ase/azuredeploy.json?environment=gov" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
-->
