VSTS Build Agent in Private Virtual Network for ASE
---------------------------------------------------

The Azure [App Service Environment (ASE)](https://docs.microsoft.com/en-us/azure/app-service/environment/intro) allows you to deploy Azure Web Apps into a private environment for enhanced security and access control. One challenge with this configuration is how to orchestrate Continuous Integration and Continuous Deployment (CI/CD) with [Visual Studio Team Services](https://www.visualstudio.com/team-services/) or [Team Foundation Server](https://www.visualstudio.com/tfs/) into such environments. 

This template deploys a VSTS/TFS build agent into the Virtual Network where the ASE is deployed and connects this agent to a VSTS or TFS instance. It also adds appropriate `hosts` file entries to the agent to allow it to deploy to a specific Web App in an ASE. 

To ensure that the configuration of the agen is correct, you need to supply:

* `TSServerUrl`: Url of your VSTS/TFS instance 
* `AgentPool`: Name of the agent pool in the VSTS/TFS instance (needs to be created in advance)
* `PAToken`: Personal Access Token for agent to register with the VSTS/TFS instance
* `AseIp`: The IP address of the ASE environment. 
* `AppDns`: The DNS name of the app, e.g. myapp.contoso-internal.us


ASE is currently not available in Azure Government, hence no Deploy to Azure Government button.

<a href="https://transmogrify.azurewebsites.net/ase-agent/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<!--
<a href="https://transmogrify.azurewebsites.net/ase-agent/azuredeploy.json?environment=gov" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
-->
 