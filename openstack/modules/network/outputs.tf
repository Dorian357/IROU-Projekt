# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Network outputi
# =============================================================================

output "upravljanje_network_id" {
  value = openstack_networking_network_v2.upravljanje.id
}

output "vanjska_network_id" {
  value = data.openstack_networking_network_v2.vanjska.id
}

output "sg_bastion_id" {
  value = openstack_networking_secgroup_v2.bastion.id
}

output "sg_voditelj_id" {
  value = openstack_networking_secgroup_v2.voditelj.id
}

output "dev_network_ids" {
  value = { for k, v in openstack_networking_network_v2.developer : k => v.id }
}

output "dev_subnet_ids" {
  value = { for k, v in openstack_networking_subnet_v2.developer : k => v.id }
}

output "dev_sg_ids" {
  value = { for k, v in openstack_networking_secgroup_v2.developer : k => v.id }
}
