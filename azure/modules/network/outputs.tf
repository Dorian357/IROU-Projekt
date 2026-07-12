output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "lead_subnet_id" {
  value = azurerm_subnet.voditelj.id
}

output "dev_subnet_ids" {
  value = { for k, v in azurerm_subnet.developer : k => v.id }
}

output "dev_vnet_ids" {
  value = { for k, v in azurerm_virtual_network.developer : k => v.id }
}
