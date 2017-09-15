# Vault Cluster

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy a 
[Vault](https://www.vaultproject.io/) cluster in [Azure](https://azure.microsoft.com/) on top of a Scale Set. This 
module is designed to deploy an [Azure Managed Image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) 
that had Vault installed via the [install-vault](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/install-vault) module in this Module.

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "vault_cluster" {
  # TODO: update this to the final URL
  # Use version v0.0.1 of the vault-cluster module
  source = "github.com/hashicorp/terraform-azurerm-vault//modules/vault-cluster?ref=v0.0.1"

  # Specify the URI of the Vault Image. You should build this using the scripts in the install-vault module.
  image_uri = "/subscriptions/1d21e7f2-8614-4e78-bdfe-828bd654424f/resourceGroups/vault/providers/Microsoft.Compute/images/vault-consul-ubuntu-2017-09-11-222923"
  
  # This module uses an Azure Container as a storage backend
  storage_account_name="gruntworkconsul"
  storage_account_key = "RPJu0PSVOIc60WyLKZMQALQKL2ogdoRi75pXuIwDv/c2q/bDVb/vqobtZj55NCISMACsuOLE/VZWZ7DAcy33NA=="
  storage_container_name = "VaultConfig"
  
  # Configure and start Vault during boot. 
  custom_data = <<-EOF
              #!/bin/bash
              /opt/vault/bin/run-vault --azure-account-name "${azure_account_name}" --azure-account-key "${azure_account_key}" --azure-container "${azure_container}" --tls-cert-file /opt/vault/tls/vault.crt.pem --tls-key-file /opt/vault/tls/vault.key.pem
              EOF
  
  # ... See vars.tf for the other parameters you must define for the vault-cluster module
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of the vault-cluster module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `image_uri`: Use this parameter to specify the URI of a Vault [Azure Managed Image]
(https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) to deploy on each server in the 
cluster. You should install Vault in this image using the scripts in the [install-vault](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/install-vault) module.
  
* `storage_account_name, storage_account_key and storage_container_name`: This module creates an 
[Azure Storage Container](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-dotnet-how-to-use-blobs) to use 
as a storage backend for Vault.
 
* `custom_data`: Use this parameter to specify a [Custom 
  Data](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/classic/inject-custom-data) script that each
  server will run during boot. This is where you can use the [run-vault script](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/run-vault) to configure and 
  run Vault. The `run-vault` script is one of the scripts installed by the [install-vault](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/install-vault) 
  module. 

You can find the other parameters in [vars.tf](vars.tf).

Check out the [main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md) example for working sample code.

## How do you use the Vault cluster?

To use the Vault cluster, you will typically need to SSH to each of the Vault servers. If you deployed the
[main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md) example, the [vault-examples-helper.sh script](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/examples/vault-examples-helper/vault-examples-helper.sh) 
will do the lookup for you automatically (note, you must have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
and [jq](https://stedolan.github.io/jq/) installed locally):

```
> ../vault-examples-helper/vault-examples-helper.sh

Your Vault servers are running at the following IP addresses:

11.22.33.44
11.22.33.55
11.22.33.66
```

### Initializing the Vault cluster

The very first time you deploy a new Vault cluster, you need to [initialize the 
Vault](https://www.vaultproject.io/intro/getting-started/deploy.html#initializing-the-vault). The easiest way to do 
this is to SSH to one of the servers that has Vault installed and run:

```
vault init

Key 1: 427cd2c310be3b84fe69372e683a790e01
Key 2: 0e2b8f3555b42a232f7ace6fe0e68eaf02
Key 3: 37837e5559b322d0585a6e411614695403
Key 4: 8dd72fd7d1af254de5f82d1270fd87ab04
Key 5: b47fdeb7dda82dbe92d88d3c860f605005
Initial Root Token: eaf5cc32-b48f-7785-5c94-90b5ce300e9b

Vault initialized with 5 keys and a key threshold of 3!
```

Vault will print out the [unseal keys](https://www.vaultproject.io/docs/concepts/seal.html) and a [root 
token](https://www.vaultproject.io/docs/concepts/tokens.html#root-tokens). This is the **only time ever** that all of 
this data is known by Vault, so you **MUST** save it in a secure place immediately! Also, this is the only time that 
the unseal keys should ever be so close together. You should distribute each one to a different, trusted administrator
for safe keeping in completely separate secret stores and NEVER store them all in the same place. 

In fact, a better option is to initial Vault with [PGP, GPG, or 
Keybase](https://www.vaultproject.io/docs/concepts/pgp-gpg-keybase.html) so that each unseal key is encrypted with a
different user's public key. That way, no one, not even the operator running the `init` command can see all the keys
in one place:

```
vault init -pgp-keys="keybase:jefferai,keybase:vishalnayak,keybase:sethvargo"

Key 1: wcBMA37rwGt6FS1VAQgAk1q8XQh6yc...
Key 2: wcBMA0wwnMXgRzYYAQgAavqbTCxZGD...
Key 3: wcFMA2DjqDb4YhTAARAAeTFyYxPmUd...
...
```

See [Using PGP, GPG, and Keybase](https://www.vaultproject.io/docs/concepts/pgp-gpg-keybase.html) for more info.


### Unsealing the Vault cluster

Now that you have the unseal keys, you can [unseal Vault](https://www.vaultproject.io/docs/concepts/seal.html) by 
having 3 out of the 5 administrators (or whatever your key shard threshold is) do the following:

1. SSH to a Vault server.
1. Run `vault unseal`.
1. Enter the unseal key when prompted.
1. Repeat for each of the other Vault servers.

Once this process is complete, all the Vault servers will be unsealed and you will be able to start reading and writing
secrets.


### Connecting to the Vault cluster to read and write secrets

There are three ways to connect to Vault:

1. [Access Vault from a Vault server](#access-vault-from-a-vault-server)
1. [Access Vault from other servers in the same Azure account](#access-vault-from-other-servers-in-the-same-azure-account)
1. [Access Vault from the public Internet](#access-vault-from-the-public-internet)


#### Access Vault from a Vault server

When you SSH to a Vault server, the Vault client is already configured to talk to the Vault server on localhost, so 
you can directly run Vault commands:

```
vault read secret/foo

Key                 Value
---                 -----
refresh_interval    768h0m0s
value               bar
```


#### Access Vault from other servers in the same Azure account

To access Vault from a different server in the same account, you need to specify the URL of the Vault cluster. You 
could manually look up the Vault cluster's IP address, but since this module uses Consul not only as a [storage 
backend](https://www.vaultproject.io/docs/configuration/storage/consul.html) but also as a way to register [DNS 
entries](https://www.consul.io/docs/guides/forwarding.html), you can access Vault 
using a nice domain name instead, such as `vault.service.consul`.

To set this up, use the [install-dnsmasq 
module](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/install-dnsmasq) on each server that 
needs to access Vault. This allows you to access Vault from your Azure Instances as follows:

```
vault -address=https://vault.service.consul:8200 read secret/foo

Key                 Value
---                 -----
refresh_interval    768h0m0s
value               bar
```

You can configure the Vault address as an environment variable:

```
export VAULT_ADDR=https://vault.service.consul:8200
```

That way, you don't have to remember to pass the Vault address every time:

```
vault read secret/foo

Key                 Value
---                 -----
refresh_interval    768h0m0s
value               bar
```

Note that if you're using a self-signed TLS cert (e.g. generated from the [private-tls-cert 
module](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/private-tls-cert)), you'll need to have the public key of the CA that signed that cert or you'll get 
an "x509: certificate signed by unknown authority" error. You could pass the certificate manually:
 
```
vault read -ca-cert=/opt/vault/tls/ca.crt.pem secret/foo

Key                 Value
---                 -----
refresh_interval    768h0m0s
value               bar
```

However, to avoid having to add the `-ca-cert` argument to every single call, you can use the [update-certificate-store 
module](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/update-certificate-store) to configure the server to trust the CA.

Check out the [main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md) for working sample code.


#### Access Vault from the public Internet

We **strongly** recommend only running Vault in private subnets. That means it is not directly accessible from the 
public Internet, which reduces your surface area to attackers. If you need users to be able to access Vault from 
outside of Azure, we recommend using VPN to connect to Azure. 
 
```
vault -address=https://<LOAD_BALANCER_DNS_NAME> read secret/foo
```

Where `ELB_DNS_NAME` is the DNS name for your ELB, such as `vault.example.com`. You can configure the Vault address as 
an environment variable:

```
export VAULT_ADDR=https://vault.example.com
```

That way, you don't have to remember to pass the Vault address every time:

```
vault read secret/foo
```



## What's included in this module?

This module creates the following architecture:

![Vault architecture](https://raw.githubusercontent.com/hashicorp/terraform-azurerm-vault/master/_docs/architecture.png)


## How do you roll out updates?

Please note that Vault does not support true zero-downtime upgrades, but with proper upgrade procedure the downtime 
should be very short (a few hundred milliseconds to a second depending on how the speed of access to the storage 
backend). See the [Vault upgrade guide instructions](https://www.vaultproject.io/docs/guides/upgrading/index.html) for
details.

If you want to deploy a new version of Vault across a cluster deployed with this module, the best way to do that is to:

1. Build a new Azure Image.
1. Set the `image_uri` parameter to the URL of the new Azure Image.
1. Run `terraform apply`.

This updates the Launch Configuration of the Scale Set, so any new Instances in the Scale Set will have your new Image, 
but it does NOT actually deploy those new instances. To make that happen, you need to:

1. [Replace the standby nodes](#replace-the-standby-nodes)
1. [Replace the primary node](#replace-the-primary-node)


### Replace the standby nodes

For each of the standby nodes:

1. SSH to the Azure Instance where the Vault standby is running.
1. Execute `sudo supervisorctl stop vault` to have Vault shut down gracefully.
1. Terminate the Azure Instance.
1. After a minute or two, the Scale Set should automatically launch a new Instance, with the new Azure Image, to replace the old one.
1. Have each Vault admin SSH to the new Azure Instance and unseal it.


### Replace the primary node

The procedure for the primary node is the same, but should be done LAST, after all the standbys have already been
upgraded:

1. SSH to the Azure Instance where the Vault primary is running. This should be the last server that has the old version
   of your Azure Image.
1. Execute `sudo supervisorctl stop vault` to have Vault shut down gracefully.
1. Terminate the Azure Instance.
1. After a minute or two, the Scale Set should automatically launch a new Instance, with the new Azure Image, to replace the old one.
1. Have each Vault admin SSH to the new Azure Instance and unseal it.

## What happens if a node crashes?

There are two ways a Vault node may go down:
 
1. The Vault process may crash. In that case, `supervisor` should restart it automatically. At this point, you will
   need to have each Vault admin SSH to the Instance to unseal it again.
1. The Azure Instance running Vault dies. In that case, the Auto Scaling Group should launch a replacement automatically. 
   Once again, the Vault admins will have to SSH to the replacement Instance and unseal it.

Given the need for manual intervention, you will want to have alarms set up that go off any time a Vault node gets
restarted.


## Security

Here are some of the main security considerations to keep in mind when using this module:

1. [Encryption in transit](#encryption-in-transit)
1. [Encryption at rest](#encryption-at-rest)
1. [Dedicated instances](#dedicated-instances)
1. [Security groups](#security-groups)
1. [SSH access](#ssh-access)


### Encryption in transit

Vault uses TLS to encrypt its network traffic. For instructions on configuring TLS, have a look at the
[How do you handle encryption documentation](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/modules/run-vault#how-do-you-handle-encryption).


### Encryption at rest

Vault servers keep everything in memory and does not write any data to the local hard disk. To persist data, Vault
encrypts it, and sends it off to its storage backends, so no matter how the backend stores that data, it is already
encrypted. By default, this Blueprint uses Consul as a storage backend, so if you want an additional layer of 
protection, you can check out the [official Consul encryption docs](https://www.consul.io/docs/agent/encryption.html) 
and the Consul Azure Module [How do you handle encryption 
docs](https://github.com/hashicorp/terraform-azurerm-consul/tree/master/modules/run-consul#how-do-you-handle-encryption)
for more info.

### Consul

This module configures Vault to use Consul as a high availability storage backend. This module assumes you already 
have Consul servers deployed in a separate cluster. We do not recommend co-locating Vault and Consul servers in the 
same cluster because:

1. Vault is a tool built specifically for security, and running any other software on the same server increases its
   surface area to attackers.
1. This Vault Module uses Consul as a high availability storage backend and both Vault and Consul keep their working 
   set in memory. That means for every 1 byte of data in Vault, you'd also have 1 byte of data in Consul, doubling 
   your memory consumption on each server.

Check out the [Consul Azure Module](https://github.com/hashicorp/terraform-azurerm-consul) for how to deploy a Consul 
server cluster in Azure. See the [main example](https://github.com/hashicorp/terraform-azurerm-vault/tree/master/MAIN.md) for 
sample code that shows how to run both a Vault server cluster and Consul server cluster.


### Monitoring, alerting, log aggregation

This module does not include anything for monitoring, alerting, or log aggregation. We especially recommend looking into Vault's [Audit 
backends](https://www.vaultproject.io/docs/audit/index.html) for how you can capture detailed logging and audit 
information.

Given that any time Vault crashes, reboots, or restarts, you have to have the Vault admins manually unseal it (see
[What happens if a node crashes?](#what-happens-if-a_node-crashes)), we **strongly** recommend configuring alerts that
notify these admins whenever they need to take action!
