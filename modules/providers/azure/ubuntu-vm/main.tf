terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "=1.12.1"
    }
  }
}

locals {
  nic_name        = "${var.name}-nic"
  public_ip_name  = "${var.name}-pip"
  jit_policy_name = "${var.name}-just-in-time-policy"
  data_disk_name  = "${var.name}-data"
  replication_name = "${var.name}-vault"
  primary_fabric_name = "${var.name}-primary-fabric"
  secondary_fabric_name = "${var.name}-secondary-fabric"
  primary_protection_container = replace(trimspace(lower("${var.name}-ppc")), "-", "")
  secondary_protection_container = replace(trimspace(lower("${var.name}-spc")), "-", "")
  vm_backup_policy_name = replace(trimspace(lower("${var.name}-bpn")), "-", "")
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.name}-snet"
  resource_group_name  = var.central_rg_name
  virtual_network_name = var.vnet_name 
  address_prefixes     = ["16.0.9.0/27"]
}

resource "azurerm_public_ip" "vm-ip" {
  name                = local.public_ip_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags                = var.resource_tags
  sku                 = var.pip_sku.sku
  sku_tier            = var.pip_sku.sku_tier
  zones = ["2"]
}

resource "azurerm_network_interface" "main-nic" {
  name                = local.nic_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-ip.id
    primary                       = true
  }
  tags = var.resource_tags
}

resource "azurerm_managed_disk" "main-data-disk" {
  name                 = local.data_disk_name
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb
  zone = "2"
  tags                 = var.resource_tags
}

resource "azurerm_linux_virtual_machine" "main-vm" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  size                = var.vm_size

  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [azurerm_network_interface.main-nic.id,]
  os_disk {
    disk_size_gb         = "128"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" #var.storage_account_type
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"    
  }
  zone = "2"
  computer_name  = "${var.name}-vm"
  admin_username = "devopsadmin"
  admin_password = "trkadmin#king3"
  #custom_data    = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  disable_password_authentication = false
  tags = var.resource_tags
}

#data "template_file" "linux-vm-cloud-init" {
#  template = file("azure-user-data.sh")
#}

resource "azurerm_virtual_machine_data_disk_attachment" "main-vm-disk-attachment" {
  managed_disk_id = azurerm_managed_disk.main-data-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.main-vm.id
  lun = "1"
  caching = "ReadWrite"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  security_rule {
    name                       = "AllowHTTP"
    description                = "Allow HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main-nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine_extension" "ad-login" {
  name                 = "AADSSHLogin"
  virtual_machine_id   = azurerm_linux_virtual_machine.main-vm.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"

  tags = var.resource_tags
}

# resource "azurerm_data_protection_backup_vault" "main" {
#   name                = "${var.name}-bv"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   datastore_type      = "VaultStore"
#   redundancy          = "ZoneRedundant"
#   tags = var.resource_tags
# }

resource "azurerm_recovery_services_vault" "main-vault" {
  name                = local.replication_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "vm_backup_policy" {
  name                = local.vm_backup_policy_name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main-vault.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 42
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 7
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 77
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}

resource "azurerm_backup_protected_vm" "vm" {
    resource_group_name             = var.resource_group_name
    recovery_vault_name             = azurerm_recovery_services_vault.main-vault.name
    source_vm_id                    = azurerm_linux_virtual_machine.main-vm.id
    backup_policy_id                = azurerm_backup_policy_vm.vm_backup_policy.id
}

# resource "azurerm_site_recovery_fabric" "primary" {
#   name = local.primary_fabric_name
#   resource_group_name = data.azurerm_resource_group.main.name
#   location = data.azurerm_resource_group.main.location
#   recovery_vault_name = azurerm_recovery_services_vault.main-vault.name
# }

# resource "azurerm_site_recovery_fabric" "secondary" {
#   name = local.secondary_fabric_name
#   resource_group_name = data.azurerm_resource_group.main.name
#   location = var.secondary_location
#   recovery_vault_name = azurerm_recovery_services_vault.main-vault.name
# }

# resource "azurerm_site_recovery_protection_container" "primary" {
#   name                 = local.primary_protection_container
#   resource_group_name  = data.azurerm_resource_group.main.name
#   recovery_vault_name  = azurerm_recovery_services_vault.main-vault.name
#   recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
# }

# resource "azurerm_site_recovery_protection_container" "secondary" {
#   name                 = local.primary_protection_container
#   resource_group_name  = data.azurerm_resource_group.main.name
#   recovery_vault_name  = azurerm_recovery_services_vault.main-vault.name
#   recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
# }

# resource "azurerm_public_ip" "recovery-ip" {
#   name                = "${local.public_ip_name}-recovery"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = var.secondary_location
#   allocation_method   = "Static"
#   tags                = var.resource_tags
#   sku                 = var.pip_sku.sku
#   sku_tier            = var.pip_sku.sku_tier
# }

# resource "azurerm_site_recovery_replication_policy" "policy" {
#   name                                                 = "policy"
#   resource_group_name                                  = data.azurerm_resource_group.main.name
#   recovery_vault_name                                  = azurerm_recovery_services_vault.main-vault.name
#   recovery_point_retention_in_minutes                  = 24 * 60
#   application_consistent_snapshot_frequency_in_minutes = 4 * 60
# }

#resource "azurerm_storage_account" "primary-recovery-cache" {
#  name                     = "primaryrecoverycache"
#  location                 = data.azurerm_resource_group.main.location
#  resource_group_name      = data.azurerm_resource_group.main.name
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#}

# resource "azurerm_site_recovery_replicated_vm" "main-vm-replication" {
#   name = "${var.name}-replication"
#   resource_group_name = data.azurerm_resource_group.main.name
#   recovery_vault_name = azurerm_recovery_services_vault.main-vault.name
#   source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
#   source_vm_id = azurerm_linux_virtual_machine.main-vm.id
#   recovery_replication_policy_id = azurerm_site_recovery_replication_policy.policy.id
#   source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name

#   target_resource_group_id = data.azurerm_resource_group.main.id
#   target_recovery_fabric_id = azurerm_site_recovery_fabric.secondary.id
#   target_recovery_protection_container_id = azurerm_site_recovery_protection_container.secondary.id

#   managed_disk {
#     disk_id = azurerm_managed_disk.main-data-disk.id
#     staging_storage_account_id = azurerm_storage_account.primary-recovery-cache.id
#     target_resource_group_id = data.azurerm_resource_group.main.id
#     target_disk_type = var.data_disk_type
#     target_replica_disk_type = var.data_disk_type
#   }

#   network_interface {
#     source_network_interface_id = azurerm_network_interface.main-nic.id
#     recovery_public_ip_address_id = azurerm_public_ip.recovery-ip.id
#     target_subnet_name = var.vm_backup_subnet_name
#   }
# }
