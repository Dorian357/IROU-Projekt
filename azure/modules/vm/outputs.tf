# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure VM outputi
# =============================================================================

output "vm_id" {
  description = "ID kreirane virtualne masine"
  value       = azurerm_linux_virtual_machine.dorian_vm.id
}

output "private_ip" {
  description = "Privatna IP adresa VM-a"
  value       = azurerm_network_interface.dorian_nic.private_ip_address
}

output "public_ip" {
  description = "Javna IP adresa (samo za bastion)"
  value       = var.javna_ip ? azurerm_public_ip.dorian_pip[0].ip_address : null
}

output "identity_principal_id" {
  description = "System-assigned Managed Identity ID za pristup Azure resursima"
  value       = azurerm_linux_virtual_machine.dorian_vm.identity[0].principal_id
}
