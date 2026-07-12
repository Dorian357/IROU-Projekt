# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Load Balancer outputi
# =============================================================================

output "lb_private_ip" {
  description = "Privatna IP adresa internog Load Balancera"
  value       = azurerm_lb.dorian_lb.frontend_ip_configuration[0].private_ip_address
}

output "lb_id" {
  description = "ID Load Balancera"
  value       = azurerm_lb.dorian_lb.id
}
