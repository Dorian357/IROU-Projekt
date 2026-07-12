# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack VM outputi
# =============================================================================

output "vm_id" {
  description = "ID kreirane OpenStack instance"
  value       = openstack_compute_instance_v2.dorian_instance.id
}

output "private_ip" {
  description = "Privatna IP adresa instance"
  value       = openstack_compute_instance_v2.dorian_instance.access_ip_v4
}

output "floating_ip" {
  description = "Floating IP adresa (samo za bastion)"
  value       = var.floating_ip ? openstack_networking_floatingip_v2.dorian_fip[0].address : null
}
