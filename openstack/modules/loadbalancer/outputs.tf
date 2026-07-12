# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Load Balancer outputi
# =============================================================================

output "lb_vip_adresa" {
  description = "VIP adresa Octavia Load Balancera"
  value       = openstack_lb_loadbalancer_v2.dorian_lb.vip_address
}

output "lb_id" {
  description = "ID Load Balancera"
  value       = openstack_lb_loadbalancer_v2.dorian_lb.id
}
