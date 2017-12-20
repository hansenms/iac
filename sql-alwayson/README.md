
SQL Server (2017) Always On Cluster
-----------------------------------

This template deploys a SQL Server (2017) Always On Cluster in an existing Virtual Network and Domain. There are several other such templates in the Azure Quickstart Templates archive, but this one has been updated with the latest PowerShell Dsc resources and uses a Cloud Witness instead of a witness VM, thus eliminating one VM from the deployment. In summary the deployment features:

* SQL Server 2017 Always On
* Cloud Witness (eliminating one VM)
* Updated DSC scripts
* Automated patching using the SQLIaaSAgent.

The deployment does not install any databases on the servers at the moment. In order to add a database to the cluster, you need to:

1. Create the database
2. Do a full backup of the database
3. Use the Wizard in SSMS as described [here](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/availability-group-add-a-database#SSMSProcedure)

To Do List
-----------

Some items that still need work:

* Create service user (domain user) for running SQL services.


Deploy
------

<a href="https://transmogrify.azurewebsites.net/sql-alwayson/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a href="https://transmogrify.azurewebsites.net/sql-alwayson/azuredeploy.json?environment=gov" target="_blank">
	<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
