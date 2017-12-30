High Availability Team Foundation Server
----------------------------------------

This folder contains two templates, [`azuredeploy.json`](azuredeploy.json) will deploy a high-availability version of the Team Foundation Server and [`deployagents.json`](deployagents.json) can be used to deploy build agents. The templates assume that you already have established some network infrastructure with domain controller(s). You can use the [core-network](../core-network) template to deploy that. You also need a SQL Server, for the high-availability deployment, you can use the [sql-alwayson](../sql-alwayson) template. 



Deploy
------

Deploy this solution to either Azure Commercial or Azure Government:

<a href="https://transmogrify.azurewebsites.net/tfs-ha/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a href="https://transmogrify.azurewebsites.net/tfs-ha/azuredeploy.json?environment=gov" target="_blank">
	<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>

Post Deployment Steps
----------------------

* Add databases to availability group
    * Log into the first database node in the SQL cluster.
    * Start SQL Server Management Studio (SSMS). 
    * Backup the databases "Tfs_Configuration" and "Tfs_DefaultCollection"
    * Make a share that is accessible from all database nodes in the cluster, e.g. `F:\Backup`
    * In SSMS find "Availability Databases" by expanded a few levels under "Always On High Availability", right-click and choose "Add Databases"
    * Add the two TFS databases and follow the wizard. Choose "Full Database and Log Backup" option and point to the share you created. 
    * Run the Wizard. 
* Install build agents. 
    *Agents are not included in the base template, but you can use the template below if you would just like generic Windows agents.

Deploy Build Agents
-------------------

Deploying build agents is not part of the high availability template itself, since they are likely to require specific configuration related to the workloads they are to support. However, you can use the `deployagents.json` template as inspiration or if you simply want some Windows build agents with Visual Studio installed, deploy build agents:

<a href="https://transmogrify.azurewebsites.net/tfs-ha/deployagents.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a href="https://transmogrify.azurewebsites.net/tfs-ha/deployagents.json?environment=gov" target="_blank">
	<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>

_Note_ : If you are experiencing problems with registering build agents. Specifically, an error message like `TF400813: Resource not available for anonymous access. Client authentication required.`, reboot the TFS nodes and try again. 