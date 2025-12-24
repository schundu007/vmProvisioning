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
    azapi = {
      source  = "azure/azapi"
      version = "=1.12.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "=3.2.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.10.0"
    }
  }
}


#-------------------------------
# Providers
#-------------------------------
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_secrets    = true
    }
  }
}
provider "azapi" {

}
locals {
  prefix       = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace    = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix       = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""
  partition    = split("-", trimspace(lower(terraform.workspace)))[0]
  base_name    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  vbase_name   = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}" : "${local.workspace}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  resource_group_name = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)
  vm_name             = "${local.base_name_21}-vm"

}

data "azurerm_client_config" "current" {}
data "terraform_remote_state" "central_resources" {
  backend = "azurerm"
  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.central_resources_workspace_name)
  }
}

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

module "ubuntu-vm" {
  source                = "../../modules/providers/azure/ubuntu-vm"
  name                  = local.vm_name
  location              = azurerm_resource_group.main.location
  vnet_name             = data.terraform_remote_state.central_resources.outputs.vnet_name
  central_rg_name       = data.terraform_remote_state.central_resources.outputs.resource_group_name
  admin_public_ssh_key  = var.ssh_public_key_file
  resource_group_name   = azurerm_resource_group.main.name
  vm_size               = "Standard_E4bs_v5"
  subscription_id       = data.azurerm_client_config.current.subscription_id
  backup_vnet_name      = data.terraform_remote_state.central_resources.outputs.backup_vnet_name
  data_disk_type        = "Premium_LRS"
  vm_backup_subnet_name = data.terraform_remote_state.central_resources.outputs.backup_public_subnets.0
}
