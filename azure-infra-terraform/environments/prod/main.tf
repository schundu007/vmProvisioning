#===============================================================================
# Azure Infrastructure - Development Environment
# Deploys: Network, Compute, Monitoring resources
#===============================================================================

terraform {
  required_version = ">= 1.5"

  backend "azurerm" {
    key = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

#-------------------------------------------------------------------------------
# Providers
#-------------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

#-------------------------------------------------------------------------------
# Local Variables
#-------------------------------------------------------------------------------
locals {
  prefix    = lower(replace(var.prefix, "_", "-"))
  env       = lower(var.environment)
  base_name = "${local.prefix}-${local.env}"
  
  # Resource naming
  resource_group_name = "${local.base_name}-rg"
  vnet_name           = "${local.base_name}-vnet"
  
  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.prefix
  })
}

#-------------------------------------------------------------------------------
# Data Sources
#-------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

#-------------------------------------------------------------------------------
# Random String for Unique Naming
#-------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

#-------------------------------------------------------------------------------
# Resource Group
#-------------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#-------------------------------------------------------------------------------
# Network Module
#-------------------------------------------------------------------------------
module "network" {
  source = "../../modules/azure/network"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space

  create_public_subnets   = true
  create_private_subnets  = var.create_private_subnets
  create_database_subnets = var.create_database_subnets
  create_nat_gateway      = var.create_nat_gateway

  num_public_subnets   = var.num_public_subnets
  num_private_subnets  = var.num_private_subnets
  num_database_subnets = var.num_database_subnets

  tags = local.common_tags
}

#-------------------------------------------------------------------------------
# Backup Network (DR Region) - Optional
#-------------------------------------------------------------------------------
module "backup_network" {
  count  = var.enable_dr ? 1 : 0
  source = "../../modules/azure/network"

  prefix              = var.prefix
  environment         = "${var.environment}-dr"
  location            = var.dr_location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.dr_address_space

  create_public_subnets   = true
  create_private_subnets  = false
  create_database_subnets = false
  create_nat_gateway      = false

  num_public_subnets = 1

  tags = local.common_tags
}

#-------------------------------------------------------------------------------
# Linux VM - Optional
#-------------------------------------------------------------------------------
module "linux_vm" {
  count  = var.deploy_vm ? 1 : 0
  source = "../../modules/azure/compute/linux-vm"

  name                = "${local.base_name}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  vnet_name           = module.network.vnet_name
  vnet_resource_group = azurerm_resource_group.main.name
  subnet_cidr         = var.vm_subnet_cidr

  vm_size           = var.vm_size
  admin_username    = var.admin_username
  os_disk_size_gb   = var.os_disk_size_gb
  data_disk_size_gb = var.data_disk_size_gb

  enable_public_ip  = var.enable_public_ip
  enable_backup     = var.enable_backup
  enable_aad_login  = var.enable_aad_login

  allowed_ssh_cidrs = var.allowed_ssh_cidrs

  tags = local.common_tags
}

#-------------------------------------------------------------------------------
# Log Analytics Workspace - Optional
#-------------------------------------------------------------------------------
module "log_analytics" {
  count  = var.enable_monitoring ? 1 : 0
  source = "../../modules/azure/monitoring/log-analytics"

  name                = "${local.base_name}-logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}
