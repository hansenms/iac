Infrastructure as Code (IaC)
----------------------------

This repository contains a number of templates for deploying infrastructure in Microsoft [Azure](https://azure.microsoft.com/en-us/).

* [core-network](core-network/) is a basic virtual network with two domain controllers in an availability set and a jump box for connecting to the VNET. 
* [tfs](tfs/) is a template for deploying [Team Foundation Server](https://www.visualstudio.com/tfs/) (TFS) into an existing virtual network with domain controllers already deployed. 
* [devnet-tfs](devnet-tfs) is a combination of core-network and tfs mentioned above. First the core network is deployed and then the tfs server with database and build agent.
* [sql-alwayson](sql-alwayson) is a template automation for deploying SQL Server (2016 or 2017) with "Always On", high-availability configuration configuration.
* [tfs-ha] is a template for deploying a high availability version of [Team Foundation Server](https://www.visualstudio.com/tfs/) (TFS). It is recommended to use the [SQL Always On](sql-alwayson) configuration on the backend for a true high availability configuration.  * [devnet-tfs-ha](devnet-tfs-ha) is a combination of [core-network](core-network), [sql-alwayson](sql-alwayson), and [tfs-ha](tfs-ha) mentioned above (including build agents) for a complete end-to-end high-availability DevOps environment base on TFS.   
