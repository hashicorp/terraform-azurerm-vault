# Vault and Consul AMI

This folder shows an example of how to use the [install-vault sub-module](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/install-vault) from this Module and 
the [install-consul](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/install-consul)
and [install-dnsmasq](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/install-dnsmasq) modules
from the Consul Azure Module with [Packer](https://www.packer.io/) to create an 
[Azure Managed Image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) that has 
Vault and Consul installed on top of Ubuntu 16.04.

You can use this Image to deploy a [Vault cluster](https://www.vaultproject.io/) by using the [vault-cluster
module](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/vault-cluster). This Vault cluster will use Consul as its HA backend, so you can also use the 
same Image to deploy a separate [Consul server cluster](https://www.consul.io/) by using the [consul-cluster 
module](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/consul-cluster). 

Check out the [main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md) for working sample code. For more info on Vault 
installation and configuration, check out the [install-vault](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/install-vault) documentation.

## Quick start

To build the Vault and Consul Azure Image:

1. `git clone` this repo to your computer.
1. Install [Packer](https://www.packer.io/).
1. Configure your Azure credentials by setting the `ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET` and 
`ARM_TENANT_ID` environment variables.

1. Use the [private-tls-cert module](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/private-tls-cert) to generate a CA cert and public and private keys for a 
   TLS cert: 
   
    1. Set the `dns_names` parameter to `vault.service.consul`. If you're using the [vault-cluster-public
       example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/examples/vault-cluster-public) and want a public domain name (e.g. `vault.example.com`), add that 
       domain name here too.
    1. Set the `ip_addresses` to `127.0.0.1`. 
    1. For production usage, you should take care to protect the private key by encrypting it (see [Using TLS 
       certs](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/private-tls-cert#using-tls-certs) for more info). 

1. Update the `variables` section of the `vault-consul.json` Packer template to specify the Azure region, Vault 
   version, Consul version, and the paths to the TLS cert files you just generated. 

1. Run `packer build vault-consul.json`.

To see how to deploy this image, check out the [main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md).


## Creating your own Packer template for production usage

When creating your own Packer template for production usage, you can copy the example in this folder more or less 
exactly, except for one change: we recommend replacing the `file` provisioner with a call to `git clone` in the `shell` 
provisioner. Instead of:

```json
{
  "provisioners": [{
    "type": "file",
    "source": "{{template_dir}}/../../../terraform-vault-azure",
    "destination": "/tmp"
  },{
    "type": "shell",
    "inline": [
      "/tmp/terraform-vault-azure/tree/master/modules/install-vault/install-vault --version {{user `vault_version`}}"
    ],
    "pause_before": "30s"
  }]
}
```

Your code should look more like this:

```json
{
  "provisioners": [{
    "type": "shell",
    "inline": [
      "git clone --branch <MODULE_VERSION> https://github.com/hashicorp/terraform-azurerm-vault.git /tmp/terraform-vault-azure",
      "/tmp/terraform-vault-azure/tree/master/modules/install-vault/install-vault --version {{user `vault_version`}}"
    ],
    "pause_before": "30s"
  }]
}
```

You should replace `<MODULE_VERSION>` in the code above with the version of this module that you want to use (see
the [Releases Page](../../releases) for all available versions). That's because for production usage, you should always
use a fixed, known version of this Module, downloaded from the official Git repo. On the other hand, when you're 
just experimenting with the module, it's OK to use a local checkout of the Module, uploaded from your own 
computer.