output "resource_group_name" {
  description = "The Resource Group name."
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The Resource Group name."
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "The resource id for the provisioned resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "vnet_name" {
  description = "The Name of the newly created vNet"
  value       = module.network.vnet_name
}

output "vnet_subnets_name_id" {
  description = "Can be queried subnet-id by subnet name by using lookup(module.network.vnet_subnets_name_id, subnet1)"
  value       = module.network.vnet_subnets_name_id
}

output "database_subnets" {
  value = module.network.database_subnets
}

output "private_subnets" {
  value = module.network.private_subnets
}
output "public_subnets" {
  value = module.network.public_subnets
}

output "backup_vnet_name" {
  value = module.backup_network.vnet_name
}

output "backup_public_subnets" {
  value = module.backup_network.public_subnets
}
