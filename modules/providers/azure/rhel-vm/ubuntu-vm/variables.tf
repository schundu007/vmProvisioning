variable "name" {
  description = "The name of the VM"
  type        = string
}

variable "location" {
  description = "Location of the existing resource group."
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
}

variable "resource_group_name" {
  description = "The name of an existing resource group that VM bus will be provisioned"
  type        = string
}

variable "central_rg_name" {
  description = "The name of an existing resource group that VM bus will be provisioned"
  type        = string
}

variable "resource_tags" {
  description = " A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "admin_public_ssh_key" {
  description = "Path to public ssh key"
  type        = string
}

variable "vm_size" {
  description = "Size of the VM. For example: Standard_F2"
  type        = string
}

variable "storage_account_type" {
  description = "Storage Account Type for OS disk. For example: Standard_LRS"
  type        = string
  default     = "Standard_LRS"
}

variable "data_disk_type" {
  description = "Storage Account Type for Data disk. For example: Standard_LRS"
  type        = string
  default     = "Standard_LRS"
}

variable "pip_sku" {
  description = "SKU of Public IP Address"
  type = object({
    sku      = string
    sku_tier = string
  })
  default = {
    sku      = "Standard"
    sku_tier = "Regional"
  }
}

variable "subscription_id" {
  type        = string
  description = "ID of the Subscription."
}

variable "disk_size_gb" {
  type        = string
  description = "Number of GB for data disk"
  default     = "128"
}

variable "secondary_location" {
  type = string
  description = "Secondary location for replication"
  default = "centralus"
}

variable "backup_vnet_name" {
  description = "Name of the backup virtual network"
}

variable "vm_backup_subnet_name" {
  description = "Subnet Id of the VM for backup"
  type        = string
}
