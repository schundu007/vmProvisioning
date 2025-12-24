#===============================================================================
# Variables - Network Module
#===============================================================================

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "address_space" {
  description = "VNet address space CIDR"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------------------------------
# Subnet Configuration
#-------------------------------------------------------------------------------
variable "create_public_subnets" {
  description = "Create public subnets"
  type        = bool
  default     = true
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

variable "public_subnet_cidrs" {
  description = "Custom public subnet CIDRs"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Custom private subnet CIDRs"
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "Custom database subnet CIDRs"
  type        = list(string)
  default     = []
}

#-------------------------------------------------------------------------------
# NAT Gateway
#-------------------------------------------------------------------------------
variable "create_nat_gateway" {
  description = "Create NAT Gateway for private subnets"
  type        = bool
  default     = false
}

#-------------------------------------------------------------------------------
# NSG Rules
#-------------------------------------------------------------------------------
variable "custom_nsg_rules" {
  description = "Custom NSG rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}
