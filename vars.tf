# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "tenant_id" {
  description = "The Azure tenant ID"
}

variable "client_id" {
  description = "The Azure client ID"
}

variable "secret_access_key" {
  description = "The Azure secret access key"
}

variable "resource_group_name" {
  description = "The name of the Azure resource group consul will be deployed into. This RG should already exist"
}

variable "storage_account_name" {
  description = "The name of an Azure Storage Account. This SA should already exist"
}

variable "storage_account_key" {
  description = "The key for storage_account_name."
}

variable "image_uri" {
  description = "The URI to the Azure image that should be deployed to the consul cluster."
}

variable "key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow connections to Consul"
  type        = "list"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "location" {
  description = "The Azure region the consul cluster will be deployed in"
  default = "East US"
}

variable "address_space" {
  description = "The supernet for the resources that will be created"
  default = "10.0.0.0/16"
}

variable "subnet_address" {
  description = "The subnet that consul resources will be deployed into"
  default = "10.0.10.0/24"
}

variable "consul_cluster_name" {
  description = "What to name the Consul cluster and all of its associated resources"
  default = "consul-example"
}

variable "vault_cluster_name" {
  description = "What to name the Vault cluster and all of its associated resources"
  default = "vault-example"
}

variable "instance_size" {
  description = "The instance size for the servers"
  default = "Standard_A0"
}

variable "num_consul_servers" {
  description = "The number of Consul server nodes to deploy. We strongly recommend using 3 or 5."
  default = 3
}

variable "num_vault_servers" {
  description = "The number of Vault server nodes to deploy. We strongly recommend using 3 or 5."
  default = 3
}
