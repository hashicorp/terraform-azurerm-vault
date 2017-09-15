# Vault Cluster Example 

This is an example of Terraform code to deploy a [Vault](https://www.vaultproject.io/) cluster in 
[Azure](https://azure.microsoft.com/) using the [vault-cluster](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/vault-cluster) module. The Vault cluster uses 
[Consul](https://www.consul.io/) as a storage backend, so this example also deploys a separate Consul server cluster 
using the [consul-cluster module](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/consul-cluster) 
from the Consul Azure Module.

This example creates a public Vault cluster that is accessible from the public Internet via an
[Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview). 

WARNING: For production use, you should deploy the cluster without a load balancer so that it is only accessible from within
your Azure account.

![Vault architecture](https://raw.githubusercontent.com/hashicorp/terraform-azurerm-vault/master/_docs/architecture-azurelb.png)

You will need to create an [Azure Managed Image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) 
that has Vault and Consul installed, which you can do using the [vault-consul-image example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/examples/vault-consul-image).  

For more info on how the Vault cluster works, check out the [vault-cluster](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/vault-cluster) documentation.


## Quick start

To deploy a Vault Cluster:

1. `git clone` this repo to your computer.
1. Build a Vault and Consul Azure Image. See the [vault-consul-image example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/examples/vault-consul-image) documentation for 
   instructions.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI ID into the `ami_id` variable.
1. Run `terraform init`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
1. Run the [vault-examples-helper.sh script](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/examples/vault-examples-helper/vault-examples-helper.sh) to 
   print out the IP addresses of the Vault servers and some example commands you can run to interact with the cluster:
   `../vault-examples-helper/vault-examples-helper.sh`.
   
To see how to connect to the Vault cluster, initialize it, and start reading and writing secrets, head over to the 
[How do you use the Vault cluster?](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/vault-cluster#how-do-you-use-the-vault-cluster) docs.
