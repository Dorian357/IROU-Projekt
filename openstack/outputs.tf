# =============================================================================
# IRUO Projekt — Dorian
# Platforma: OpenStack
# Opis: Izlazne vrijednosti nakon uspjesnog deploymenta
# =============================================================================

output "bastion_floating_ip" {
  description = "Floating IP adresa bastion VM-a (jedina javno dostupna)"
  value       = module.bastion.floating_ip
}

output "voditelj_privatna_ip" {
  description = "Privatna IP adresa voditeljevog VM-a"
  value       = module.voditelj_vm.private_ip
}

output "dev_okoline" {
  description = "Pregled IP adresa i LB-a po svakom developeru"
  value = {
    for dev in var.dev_tim : dev => {
      app_server_1  = module.app_vm1[dev].private_ip
      app_server_2  = module.app_vm2[dev].private_ip
      load_balancer = module.lb[dev].lb_vip_adresa
    }
  }
}

output "swift_kontejneri" {
  description = "Swift kontejneri za Moodle datoteke po developeru"
  value       = { for dev in var.dev_tim : dev => module.pohrana[dev].swift_kontejner_naziv }
}

output "ssh_pristup" {
  description = "SSH naredbe za pristup VM-ovima"
  value = {
    bastion  = "ssh rocky@${module.bastion.floating_ip}"
    voditelj = "ssh -J rocky@${module.bastion.floating_ip} rocky@${module.voditelj_vm.private_ip}"
  }
}
