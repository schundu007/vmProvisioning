#===============================================================================
# Outputs - Linux VM Module
#===============================================================================

output "vm_id" {
  description = "Virtual Machine ID"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Virtual Machine name"
  value       = azurerm_linux_virtual_machine.main.name
}

output "private_ip" {
  description = "Private IP address"
  value       = azurerm_network_interface.main.private_ip_address
}

output "public_ip" {
  description = "Public IP address"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "System-assigned managed identity tenant ID"
  value       = azurerm_linux_virtual_machine.main.identity[0].tenant_id
}

output "nic_id" {
  description = "Network Interface ID"
  value       = azurerm_network_interface.main.id
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.vm.id
}

output "recovery_vault_id" {
  description = "Recovery Services Vault ID"
  value       = var.enable_backup ? azurerm_recovery_services_vault.main[0].id : null
}
