#===============================================================================
# Outputs - Network Module
#===============================================================================

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "VNet address space"
  value       = azurerm_virtual_network.main.address_space
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "public_subnet_names" {
  description = "Public subnet names"
  value       = azurerm_subnet.public[*].name
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = azurerm_subnet.private[*].id
}

output "private_subnet_names" {
  description = "Private subnet names"
  value       = azurerm_subnet.private[*].name
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = azurerm_subnet.database[*].id
}

output "database_subnet_names" {
  description = "Database subnet names"
  value       = azurerm_subnet.database[*].name
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.main.id
}

output "nsg_name" {
  description = "Network Security Group name"
  value       = azurerm_network_security_group.main.name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.create_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = var.create_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}
