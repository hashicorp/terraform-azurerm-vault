terraform {
  required_version = ">= 0.10.0"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE STORAGE BUCKET
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "vault" {
  name                  = "${var.storage_container_name}"
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${var.storage_account_name}"
  container_access_type = "private"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A LOAD BALANCER
#---------------------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "vault_access" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}_access"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label = "${var.cluster_name}"
}

resource "azurerm_lb" "vault_access" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}_access"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.vault_access.id}"
  }
}

resource "azurerm_lb_nat_pool" "vault_lbnatpool" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "ssh"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  protocol = "Tcp"
  frontend_port_start = 2200
  frontend_port_end = 2299
  backend_port = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "vault_probe" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  name                = "vault-running-probe"
  port                = "${var.api_port}"
}

resource "azurerm_lb_backend_address_pool" "vault_bepool" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  name = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "vault_api_port" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "vault-api"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  protocol = "Tcp"
  frontend_port = "${var.api_port}"
  backend_port = "${var.api_port}"
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.vault_bepool.id}"
  probe_id = "${azurerm_lb_probe.vault_probe.id}"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN VAULT (WITHOUT LOAD BALANCER)
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "vault" {
  count = "${var.associate_public_ip_address_load_balancer ? 0 : 1}"
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.instance_size}"
    tier = "${var.instance_tier}"
    capacity = "${var.cluster_size}"
  }

  os_profile {
    computer_name_prefix = "${var.vault_computer_name_prefix}"
    admin_username = "${var.vault_admin_user_name}"

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.vault_admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  network_profile {
    name = "VaultNetworkProfile"
    primary = true

    ip_configuration {
      name = "VaultIPConfiguration"
      subnet_id = "${var.subnet_id}"
    }
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN VAULT (WITH LOAD BALANCER)
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "vault_with_load_balancer" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.instance_size}"
    tier = "${var.instance_tier}"
    capacity = "${var.cluster_size}"
  }

  os_profile {
    computer_name_prefix = "${var.vault_computer_name_prefix}"
    admin_username = "${var.vault_admin_user_name}"

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.vault_admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  network_profile {
    name = "VaultNetworkProfile"
    primary = true

    ip_configuration {
      name = "VaultIPConfiguration"
      subnet_id = "${var.subnet_id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.vault_bepool.id}"]
      load_balancer_inbound_nat_rules_ids = ["${element(azurerm_lb_nat_pool.vault_lbnatpool.*.id, count.index)}"]
    }
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "vault" {
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "ssh" {
  count = "${length(var.allowed_ssh_cidr_blocks)}"

  access = "Allow"
  destination_address_prefix = "*"
  destination_port_range = "22"
  direction = "Inbound"
  name = "SSH${count.index}"
  network_security_group_name = "${azurerm_network_security_group.vault.name}"
  priority = "${100 + count.index}"
  protocol = "Tcp"
  resource_group_name = "${var.resource_group_name}"
  source_address_prefix = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
  source_port_range = "1024-65535"
}

