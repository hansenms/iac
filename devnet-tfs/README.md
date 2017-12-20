Private TFS DevOps in Azure
---------------------------

Microsoft [Azure](https://azure.microsoft.com/en-us/) offers a hosted DevOps experience with [Vistual Studio Team Services](https://www.visualstudio.com/team-services/) (VSTS). It is great, but sometimes organizations would like to host their own [Team Foundation Server](https://www.visualstudio.com/tfs/) (TFS). A particularly relevant use case is users in the [Microsoft Government Cloud](https://azure.microsoft.com/en-us/overview/clouds/government/) where VSTS is not yet available. Deploying a TFS Server with database and build agents can be complicated. 

This template illustrates how to create a private DevOps network with TFS server and agents. The topology is illustrated below:

![Private DevOps](./private_devops.png)

This deployment is actually a nested compbination of deployment of a virtual network with two domain controllers and a JumpBox. You can deploy that without the TFS installation using [this template](https://github.com/hansenms/iac/tree/master/core-network). You can then deploy the TFS resources (e.g. in a different resource group) using [this template](https://github.com/hansenms/iac/tree/master/tfs). 


<a href="https://transmogrify.azurewebsites.net/devnet-tfs/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a href="https://transmogrify.azurewebsites.net/devnet-tfs/azuredeploy.json?environment=gov" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
