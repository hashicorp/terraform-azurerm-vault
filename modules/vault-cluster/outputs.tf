output "scale_set_name" {
  value = "${var.cluster_name}"
}

output "admin_user_name" {
  value = "${var.vault_admin_user_name}"
}

output "cluster_size" {
  value = "${var.cluster_size}"
}

output "storage_containter_id" {
  value = "${azurerm_storage_container.vault.id}"
}

output "load_balancer_ip_address" {
  value = "${azurerm_public_ip.vault_access.*.ip_address}"
}
