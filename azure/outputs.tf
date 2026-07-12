# =============================================================================
# IRUO Projekt — Dorian
# Platforma: Microsoft Azure
# Opis: Izlazne vrijednosti nakon uspjesnog deploymenta
# =============================================================================

output "bastion_public_ip" {
  description = "Javna IP adresa Jump Host (bastion) masine"
  value       = module.bastion.public_ip
}

output "team_lead_private_ip" {
  description = "Privatna IP adresa voditeljevog VM-a"
  value       = module.lead_vm.private_ip
}

output "dev_environments" {
  description = "Pregled IP adresa i LB-a po svakom developeru"
  value = {
    for dev in var.dev_team : dev => {
      app_server_1  = module.app_vm1[dev].private_ip
      app_server_2  = module.app_vm2[dev].private_ip
      load_balancer = module.lb[dev].lb_private_ip
    }
  }
}

output "storage_endpoints" {
  description = "Endpointi pohrane po developeru"
  value = {
    for dev in var.dev_team : dev => {
      blob  = module.storage[dev].blob_endpoint
      files = module.storage[dev].files_endpoint
    }
  }
}

output "ssh_pristup" {
  description = "Gotove SSH naredbe za spajanje"
  value = {
    bastion  = "ssh azureuser@${module.bastion.public_ip}"
    lead_vm  = "ssh -J azureuser@${module.bastion.public_ip} azureuser@${module.lead_vm.private_ip}"
  }
}

output "kreirane_resource_grupe" {
  description = "Popis svih kreiranih resource grupa"
  value = {
    upravljanje  = azurerm_resource_group.upravljanje.name
    developeri   = { for k, v in azurerm_resource_group.dev_grupe : k => v.name }
  }
}
