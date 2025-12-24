#===============================================================================
# Outputs - Development Environment
#===============================================================================

#-------------------------------------------------------------------------------
# Resource Group
#-------------------------------------------------------------------------------
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

#-------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------
output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = module.network.vnet_name
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = module.network.nsg_id
}

#-------------------------------------------------------------------------------
# Compute
#-------------------------------------------------------------------------------
output "vm_id" {
  description = "Virtual Machine ID"
  value       = var.deploy_vm ? module.linux_vm[0].vm_id : null
}

output "vm_private_ip" {
  description = "VM private IP address"
  value       = var.deploy_vm ? module.linux_vm[0].private_ip : null
}

output "vm_public_ip" {
  description = "VM public IP address"
  value       = var.deploy_vm && var.enable_public_ip ? module.linux_vm[0].public_ip : null
}

#-------------------------------------------------------------------------------
# Monitoring
#-------------------------------------------------------------------------------
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = var.enable_monitoring ? module.log_analytics[0].workspace_id : null
}

#-------------------------------------------------------------------------------
# Connection Info
#-------------------------------------------------------------------------------
output "ssh_connection" {
  description = "SSH connection command"
  value       = var.deploy_vm && var.enable_public_ip ? "ssh ${var.admin_username}@${module.linux_vm[0].public_ip}" : null
}
