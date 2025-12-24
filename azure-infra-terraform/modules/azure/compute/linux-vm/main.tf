#===============================================================================
# Azure Linux VM Module
# Creates: VM, NIC, Public IP, NSG, Managed Disks, Backup
#===============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  nic_name        = "${var.name}-nic"
  pip_name        = "${var.name}-pip"
  nsg_name        = "${var.name}-nsg"
  data_disk_name  = "${var.name}-data"
  vault_name      = "${var.name}-vault"
  backup_policy   = "${var.name}-backup-policy"
}

#-------------------------------------------------------------------------------
# Data Sources
#-------------------------------------------------------------------------------
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

#-------------------------------------------------------------------------------
# Subnet for VM
#-------------------------------------------------------------------------------
resource "azurerm_subnet" "vm" {
  name                 = "${var.name}-subnet"
  resource_group_name  = var.vnet_resource_group
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_cidr]
}

#-------------------------------------------------------------------------------
# Public IP (Optional)
#-------------------------------------------------------------------------------
resource "azurerm_public_ip" "main" {
  count               = var.enable_public_ip ? 1 : 0
  name                = local.pip_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zone != null ? [var.availability_zone] : null

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Network Interface
#-------------------------------------------------------------------------------
resource "azurerm_network_interface" "main" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.main[0].id : null
    primary                       = true
  }

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Network Security Group
#-------------------------------------------------------------------------------
resource "azurerm_network_security_group" "main" {
  name                = local.nsg_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  tags = var.tags
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = length(var.allowed_ssh_cidrs) > 0 ? var.allowed_ssh_cidrs : ["*"]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "AllowHTTPS"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

#-------------------------------------------------------------------------------
# Data Disk
#-------------------------------------------------------------------------------
resource "azurerm_managed_disk" "data" {
  count                = var.data_disk_size_gb > 0 ? 1 : 0
  name                 = local.data_disk_name
  location             = var.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = var.availability_zone

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Linux Virtual Machine
#-------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  size                = var.vm_size
  zone                = var.availability_zone

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.admin_password == null

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = var.custom_data

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Data Disk Attachment
#-------------------------------------------------------------------------------
resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.data_disk_size_gb > 0 ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.main.id
  lun                = 1
  caching            = "ReadWrite"
}

#-------------------------------------------------------------------------------
# Azure AD Login Extension
#-------------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "aad_login" {
  count                = var.enable_aad_login ? 1 : 0
  name                 = "AADSSHLogin"
  virtual_machine_id   = azurerm_linux_virtual_machine.main.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Backup (Optional)
#-------------------------------------------------------------------------------
resource "azurerm_recovery_services_vault" "main" {
  count               = var.enable_backup ? 1 : 0
  name                = local.vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  soft_delete_enabled = true

  tags = var.tags
}

resource "azurerm_backup_policy_vm" "main" {
  count               = var.enable_backup ? 1 : 0
  name                = local.backup_policy
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main[0].name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = var.backup_retention_daily
  }

  retention_weekly {
    count    = var.backup_retention_weekly
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.backup_retention_monthly
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

resource "azurerm_backup_protected_vm" "main" {
  count               = var.enable_backup ? 1 : 0
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main[0].name
  source_vm_id        = azurerm_linux_virtual_machine.main.id
  backup_policy_id    = azurerm_backup_policy_vm.main[0].id
}
