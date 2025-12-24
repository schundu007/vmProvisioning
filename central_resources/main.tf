terraform {
  required_version = ">= 1.3"

  backend "azurerm" {
    key = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.79.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.45.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "=3.2.1"
    }
    time = {
      source = "hashicorp/time"
      version = "0.10.0"
    }    
  }
}


#-------------------------------
# Providers
#-------------------------------
provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_secrets    = true
    }
  }
}

#-------------------------------
# Private Variables
#-------------------------------
locals {
  prefix                  = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace               = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix                  = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""
  base_name               = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21            = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46            = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60            = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76            = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83            = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"
  resource_group_name     = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  vnet_name               = "${local.base_name_60}-vnet"
  #backend_access_allowed_networks  = ["12.94.93.106/32"]
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "random_uuid" "oauth2_permission_scopes_id" {}
resource "random_string" "workspace_scope" {
  keepers = {
    ws_name = replace(trimspace(lower(terraform.workspace)), "-", "")
    prefix  = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = max(1, var.randomization_level)
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.resource_group_location
  tags     = var.resource_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

module "network" {
  vnet_location = var.resource_group_location
  source                  = "../modules/providers/azure/network"
  resource_group_name     = azurerm_resource_group.main.name
  resource_group_location = azurerm_resource_group.main.location
  address_space           = var.address_space
  prefix                  = var.prefix
  env                     = var.env
  create_vnet             = true
  create_resource_group   = true
  create_public_subnets   = true
  num_public_subnets      = 1
  create_private_subnets  = false
  create_database_subnets = false
  create_nat_gateway      = false
  resource_tags           = var.resource_tags
}

module "backup_network" {
  source = "../modules/providers/azure/network"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_location = azurerm_resource_group.main.location
  address_space = var.backup_address_space
  prefix = var.prefix
  env = "${var.env}-backup"
  vnet_location = "centralus"
  create_vnet = true
  create_resource_group = false
  existing_resource_group_name = azurerm_resource_group.main.name
  create_database_subnets = false
  create_private_subnets = false
  create_public_subnets = true
  num_public_subnets = 1
  create_nat_gateway = false
  resource_tags = var.resource_tags
}