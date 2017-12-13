Infrastructure as Code (IaC)
----------------------------

This repository contains a number of templates for deploying infrastructure in Microsoft [Azure](https://azure.microsoft.com/en-us/).

* [core-network](core-network/) is a basic virtual network with two domain controllers in an availability set and a jump box for connecting to the VNET. 
* [tfs](tfs/) is a template for deploying [Team Foundation Server](https://www.visualstudio.com/tfs/) (TFS) into an existing virtual network with domain controllers already deployed. 
* [devnet-tfs](devnet-tfs) is a combination of core-network and tfs mentioned above. First the core network is deployed and then the tfs server with database and build agent. 

Adding a [link](https://transmogrif.azurewebsites.net/tfs/core-network/azuredeploy.json)