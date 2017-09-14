# Vault Examples Helper

This folder contains a helper script called `vault-examples-helper.sh` for working with the 
[main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md) After running `terraform apply`, if you 
run  `vault-examples-helper.sh`, it will automatically:

1. Wait for the Vault server cluster to come up.
1. Print out the IP address of the Vault load balancer.
1. Print out some example commands you can run against your Vault servers.

Please note that this helper script only works because the examples deploy with a public load balancer.
As a result, Vault is publicly accessible. This is OK for testing and learning, but for production usage, we strongly 
recommend running Vault in private subnets.
