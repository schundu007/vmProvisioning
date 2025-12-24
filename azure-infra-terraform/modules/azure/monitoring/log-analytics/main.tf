#===============================================================================
# Azure Log Analytics Workspace Module
#===============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
variable "name" {
  description = "Workspace name"
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

variable "sku" {
  description = "SKU (PerGB2018, Free, etc.)"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention in days (30-730)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------------------------------
# Outputs
#-------------------------------------------------------------------------------
output "workspace_id" {
  description = "Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "primary_shared_key" {
  description = "Primary shared key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Secondary shared key"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}
