#===============================================================================
# Variables - Linux VM Module
#===============================================================================

variable "name" {
  description = "VM name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "vnet_resource_group" {
  description = "VNet resource group name"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR for VM"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------------------------------
# VM Configuration
#-------------------------------------------------------------------------------
variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "availability_zone" {
  description = "Availability zone (1, 2, or 3)"
  type        = string
  default     = "2"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password (null for SSH key only)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = null
}

variable "custom_data" {
  description = "Cloud-init script (base64 encoded)"
  type        = string
  default     = null
}

#-------------------------------------------------------------------------------
# OS Image
#-------------------------------------------------------------------------------
variable "image_publisher" {
  description = "Image publisher"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Image offer"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "image_sku" {
  description = "Image SKU"
  type        = string
  default     = "server"
}

variable "image_version" {
  description = "Image version"
  type        = string
  default     = "latest"
}

#-------------------------------------------------------------------------------
# Disks
#-------------------------------------------------------------------------------
variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "os_disk_type" {
  description = "OS disk type"
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB (0 to skip)"
  type        = number
  default     = 256
}

variable "data_disk_type" {
  description = "Data disk type"
  type        = string
  default     = "Premium_LRS"
}

#-------------------------------------------------------------------------------
# Networking
#-------------------------------------------------------------------------------
variable "enable_public_ip" {
  description = "Create public IP"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = []
}

#-------------------------------------------------------------------------------
# Features
#-------------------------------------------------------------------------------
variable "enable_aad_login" {
  description = "Enable Azure AD SSH login"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable VM backup"
  type        = bool
  default     = true
}

variable "backup_retention_daily" {
  description = "Daily backup retention count"
  type        = number
  default     = 7
}

variable "backup_retention_weekly" {
  description = "Weekly backup retention count"
  type        = number
  default     = 4
}

variable "backup_retention_monthly" {
  description = "Monthly backup retention count"
  type        = number
  default     = 6
}
