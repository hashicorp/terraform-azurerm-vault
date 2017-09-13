# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "location" {
  description = "The location that the resources will run in (e.g. East US)"
}

variable "resource_group_name" {
  description = "The name of the resource group that the resources for consul will run in"
}

variable "storage_account_name" {
  description = "The name of the storage account that will be used for images"
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the cluster into"
}

variable "cluster_name" {
  description = "The name of the Consul cluster (e.g. consul-stage). This variable is used to namespace all resources created by this module."
}

variable "storage_container_name" {
  description = "The name of the Azure Storage Container where secrets will be kept."
}

variable "image_id" {
  description = "The URL of the Image to run in this cluster. Should be an image that had Consul installed and configured by the install-consul module."
}

variable "instance_size" {
  description = "The size of Azure Instances to run for each node in the cluster (e.g. Standard_A0)."
}

variable "key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
}

variable "custom_data" {
  description = "A Custom Data script to execute while the server is booting. We remmend passing in a bash script that executes the run-consul script, which should have been installed in the Consul Image by the install-consul module."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_tier" {
  description = "Specifies the tier of virtual machines in a scale set. Possible values, standard or basic."
  default = "standard"
}

variable "consul_computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default = "consul"
}

variable "vault_computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default = "vault"
}

variable "consul_admin_user_name" {
  description = "The name of the administrator user for each instance in the cluster"
  default = "consuladmin"
}

variable "vault_admin_user_name" {
  description = "The name of the administrator user for each instance in the cluster"
  default = "vaultadmin"
}

variable "instance_root_volume_size" {
  description = "Specifies the size of the instance root volume in GB. Default 40GB"
  default     = 40
}

variable "cluster_size" {
  description = "The number of nodes to have in the Consul cluster. We strongly recommended that you use either 3 or 5."
  default     = 3
}

variable "cluster_tag_key" {
  description = "Add a tag with this key and the value var.cluster_tag_value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "consul-servers"
}

variable "cluster_tag_value" {
  description = "Add a tag with key var.clsuter_tag_key and this value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "auto-join"
}

variable "subnet_ids" {
  description = "The subnet IDs into which the Azure Instances should be deployed. We recommend one subnet ID per node in the cluster_size variable. At least one of var.subnet_ids or var.availability_zones must be non-empty."
  type        = "list"
  default     = []
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow SSH connections"
  type        = "list"
  default     = []
}

variable "associate_public_ip_address_load_balancer" {
  description = "If set to true, create a public IP address with back end pool to allow SSH publically to the instances."
  default     = false
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "standard"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 50
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "api_port" {
  description = "The port to use for Vault API calls"
  default     = 8200
}