
SQL Server (2017) Always On Cluster
-----------------------------------

This template deploys a SQL Server (2017) Always On Cluster in an existing Virtual Network and Domain. There are several other such templates in the Azure Quickstart Templates archive, but this one has been updated with the latest PowerShell Dsc resources and uses a Cloud Witness instead of a witness VM, thus eliminating one VM from the deployment. In summary the deployment features:

* SQL Server 2017 Always On
* Cloud Witness (eliminating one VM)
* Updated DSC scripts
* Automated patching using the SQLIaaSAgent.

The deployment does not install any databases on the servers. In order to add a database to the cluster, you need to:

1. Create the database
2. Do a full backup of the database
3. Use the Wizard in SSMS as described [here](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/availability-group-add-a-database#SSMSProcedure)

The repository includes a Powershell DSC script, called [`AddDatabaseAG.ps1`](AddDatabaseAG.ps1), which illustrates the steps needed to add a database to an availability group and there is also an [example template](adddbtoag.json) that could be used to deploy it. However, it is not possible to deploy multiple DSC script extensions to a VM and since DSC extensions were used to set up the always on cluster, it is not easy to deploy this without first deleting the previous deployment. That being said, the script is useful for capturing the steps needed and you can upload the script to the SQL VM and use it to add the database to the availabilit group. 

To Do List
-----------

Some items that still need work. Feel free to contribute back:

* Create service user (domain user) for running SQL services.
* Add more than one replica. This should be a matter of making sure it is appropriately parameterized and doing some testing.  
* Parameterize settings
    * Patching schedule
    * Availability Group settings (synchronous, asynchronous, etc)


Deploy
------

<a href="https://transmogrify.azurewebsites.net/sql-alwayson/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a href="https://transmogrify.azurewebsites.net/sql-alwayson/azuredeploy.json?environment=gov" target="_blank">
	<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
