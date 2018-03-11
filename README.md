Infrastructure as Code (IaC)
----------------------------

This repository contains a number of templates for deploying infrastructure in Microsoft [Azure](https://azure.microsoft.com/en-us/).

* [core-network](core-network/) is a basic virtual network with two domain controllers in an availability set and a jump box for connecting to the VNET. 
* [tfs](tfs/) is a template for deploying [Team Foundation Server](https://www.visualstudio.com/tfs/) (TFS) into an existing virtual network with domain controllers already deployed. 
* [devnet-tfs](devnet-tfs) is a combination of core-network and tfs mentioned above. First the core network is deployed and then the tfs server with database and build agent.
* [sql-alwayson](sql-alwayson) is a template automation for deploying SQL Server (2016 or 2017) with "Always On", high-availability configuration configuration.
* [tfs-ha] is a template for deploying a high availability version of [Team Foundation Server](https://www.visualstudio.com/tfs/) (TFS). It is recommended to use the [SQL Always On](sql-alwayson) configuration on the backend for a true high availability configuration.  * [devnet-tfs-ha](devnet-tfs-ha) is a combination of [core-network](core-network), [sql-alwayson](sql-alwayson), and [tfs-ha](tfs-ha) mentioned above (including build agents) for a complete end-to-end high-availability DevOps environment base on TFS.
* [ase](ase/) is a template for deploy Azure App Service Environment (ASE) into an existing or new Virtual Network.
* [ase-agent](ase-agent/) is a template for deploying a VSTS/TFS build agent into a Virtual Network and let it deploy to a Web App in an App Service Environment (ASE).
* [ase-devops](ase-devops/) is a combination of [ase](ase/) and [ase-agent](ase-agent/) to demonstrate the complete ASE VSTS/TFS DevOps experience. 

