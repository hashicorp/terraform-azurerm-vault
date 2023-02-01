# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

output "vault_cluster_size" {
  value = "${var.num_vault_servers}"
}

output "vault_admin_user_name" {
  value = "${module.vault_servers.admin_user_name}"
}

output "load_balancer_ip_address" {
  value = "${module.vault_servers.load_balancer_ip_address}"
}
