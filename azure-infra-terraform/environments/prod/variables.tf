#===============================================================================
# Variables - Development Environment
#===============================================================================

#-------------------------------------------------------------------------------
# General
#-------------------------------------------------------------------------------
variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------
variable "address_space" {
  description = "VNet address space in CIDR notation"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_private_subnets" {
  description = "Create private subnets"
  type        = bool
  default     = true
}

variable "create_database_subnets" {
  description = "Create database subnets"
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Create NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "num_public_subnets" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "num_private_subnets" {
  description = "Number of private subnets"
  type        = number
  default     = 2
}

variable "num_database_subnets" {
  description = "Number of database subnets"
  type        = number
  default     = 2
}

#-------------------------------------------------------------------------------
# Disaster Recovery
#-------------------------------------------------------------------------------
variable "enable_dr" {
  description = "Enable disaster recovery resources"
  type        = bool
  default     = false
}

variable "dr_location" {
  description = "DR region location"
  type        = string
  default     = "westus"
}

variable "dr_address_space" {
  description = "DR VNet address space"
  type        = string
  default     = "10.1.0.0/16"
}

#-------------------------------------------------------------------------------
# Compute
#-------------------------------------------------------------------------------
variable "deploy_vm" {
  description = "Deploy Linux VM"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "vm_subnet_cidr" {
  description = "Subnet CIDR for VM"
  type        = string
  default     = "10.0.10.0/24"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureadmin"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB"
  type        = number
  default     = 256
}

variable "enable_public_ip" {
  description = "Assign public IP to VM"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable VM backup"
  type        = bool
  default     = true
}

variable "enable_aad_login" {
  description = "Enable Azure AD login for VM"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

#-------------------------------------------------------------------------------
# Monitoring
#-------------------------------------------------------------------------------
variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}
