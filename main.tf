# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VAULT CLUSTER IN AZURE
# These configurations show an example of how to use the consul-cluster module to deploy Consul in Azure. We deploy two
# Scale Sets: one with Consul server nodes and one with Consul client nodes. Note that these templates assume
# that the Custom Image you provide via the image_id input variable is built from the
# examples/consul-image/consul.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.secret_access_key}"
  tenant_id = "${var.tenant_id}"
}

terraform {
  required_version = ">= 0.10.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE NECESSARY NETWORK RESOURCES FOR THE EXAMPLE
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "consul" {
  name = "consulvn"
  address_space = ["${var.address_space}"]
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "consul" {
  name = "consulsubnet"
  resource_group_name = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.consul.name}"
  address_prefix = "${var.subnet_address}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_servers" {
  source = "git::git@github.com:hashicorp/terraform-azurerm-consul.git//modules/consul-cluster?ref=v0.0.1"

  cluster_name = "${var.consul_cluster_name}"
  cluster_size = "${var.num_consul_servers}"
  key_data = "${var.key_data}"

  resource_group_name = "${var.resource_group_name}"
  storage_account_name = "${var.storage_account_name}"

  location = "${var.location}"
  custom_data = "${data.template_file.custom_data_consul.rendered}"
  instance_size = "${var.instance_size}"
  image_id = "${var.image_uri}"
  subnet_id = "${azurerm_subnet.consul.id}"
  allowed_inbound_cidr_blocks = []
}

# ---------------------------------------------------------------------------------------------------------------------
# THE CUSTOM DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER AZURE INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "custom_data_consul" {
  template = "${file("${path.module}/custom-data-consul.sh")}"

  vars {
    scale_set_name = "${var.consul_cluster_name}"
    subscription_id = "${var.subscription_id}"
    tenant_id = "${var.tenant_id}"
    client_id = "${var.client_id}"
    secret_access_key = "${var.secret_access_key}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE STORAGE
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "vault_storage" {
  name                  = "vault"
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${var.storage_account_name}"
  container_access_type = "private"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE VAULT SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "vault_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-azurerm-vault.git//modules/vault-cluster?ref=v0.0.1"
  source = "./modules/vault-cluster"

  cluster_name = "${var.vault_cluster_name}"
  cluster_size = "${var.num_vault_servers}"
  key_data = "${var.key_data}"

  resource_group_name = "${var.resource_group_name}"
  storage_account_name = "${var.storage_account_name}"

  location = "${var.location}"
  custom_data = "${data.template_file.custom_data_vault.rendered}"
  instance_size = "${var.instance_size}"
  image_id = "${var.image_uri}"
  subnet_id = "${azurerm_subnet.consul.id}"
  storage_container_name = "vault"
  associate_public_ip_address_load_balancer = true
}

# ---------------------------------------------------------------------------------------------------------------------
# THE CUSTOM DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER AZURE INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "custom_data_vault" {
  template = "${file("${path.module}/custom-data-vault.sh")}"

  vars {
    scale_set_name = "${var.consul_cluster_name}"
    subscription_id = "${var.subscription_id}"
    tenant_id = "${var.tenant_id}"
    client_id = "${var.client_id}"
    secret_access_key = "${var.secret_access_key}"
    azure_account_name = "${var.storage_account_name}"
    azure_account_key = "${var.storage_account_key}"
    azure_container = "${azurerm_storage_container.vault_storage.name}"
  }
}
