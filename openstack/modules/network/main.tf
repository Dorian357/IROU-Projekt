# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Mrezna infrastruktura
# Opis: Neutron mreze, subneti, routeri, security grupe
# IP shema bazirana na datumu rodjendana: 16.12.
# =============================================================================

# Vanjska (provider) mreza za Floating IP
data "openstack_networking_network_v2" "vanjska" {
  name = var.vanjska_mreza
}

# --------------------------------------------------------------------------
# Upravljacka mreza (Bastion + Voditelj)
# --------------------------------------------------------------------------

resource "openstack_networking_network_v2" "upravljanje" {
  name           = "${var.naziv_prefix}-net-upravljanje-dorian"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "upravljanje" {
  name            = "${var.naziv_prefix}-subnet-upravljanje-1612"
  network_id      = openstack_networking_network_v2.upravljanje.id
  cidr            = "172.16.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_router_v2" "upravljanje" {
  name                = "${var.naziv_prefix}-router-upravljanje-dorian"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.vanjska.id
}

resource "openstack_networking_router_interface_v2" "upravljanje" {
  router_id = openstack_networking_router_v2.upravljanje.id
  subnet_id = openstack_networking_subnet_v2.upravljanje.id
}

# --------------------------------------------------------------------------
# Security grupe
# --------------------------------------------------------------------------

# Bastion — SSH s interneta
resource "openstack_networking_secgroup_v2" "bastion" {
  name        = "${var.naziv_prefix}-sg-bastion-dorian"
  description = "TechSprint Dorian 16.12. — Bastion SSH pristup"
}

resource "openstack_networking_secgroup_rule_v2" "bastion_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion.id
}

# Voditelj — SSH samo s upravljacke mreze
resource "openstack_networking_secgroup_v2" "voditelj" {
  name        = "${var.naziv_prefix}-sg-voditelj-dorian"
  description = "TechSprint Dorian 16.12. — Voditeljev VM"
}

resource "openstack_networking_secgroup_rule_v2" "voditelj_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "172.16.0.0/24"
  security_group_id = openstack_networking_secgroup_v2.voditelj.id
}

# --------------------------------------------------------------------------
# Developer mreze — izolirana mreza po developeru
# IP shema: 172.12.N.0/24 (12 = mjesec rodjendana Dorian)
# --------------------------------------------------------------------------

resource "openstack_networking_network_v2" "developer" {
  for_each       = toset(var.dev_tim)
  name           = "${var.naziv_prefix}-net-${each.key}-dorian"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "developer" {
  for_each        = toset(var.dev_tim)
  name            = "${var.naziv_prefix}-subnet-${each.key}-1612"
  network_id      = openstack_networking_network_v2.developer[each.key].id
  cidr            = "172.12.${index(var.dev_tim, each.key) + 1}.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Router po developeru za outbound internet pristup
resource "openstack_networking_router_v2" "developer" {
  for_each            = toset(var.dev_tim)
  name                = "${var.naziv_prefix}-router-${each.key}-dorian"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.vanjska.id
}

resource "openstack_networking_router_interface_v2" "developer" {
  for_each  = toset(var.dev_tim)
  router_id = openstack_networking_router_v2.developer[each.key].id
  subnet_id = openstack_networking_subnet_v2.developer[each.key].id
}

# Security grupe za developer Moodle VM-ove
resource "openstack_networking_secgroup_v2" "developer" {
  for_each    = toset(var.dev_tim)
  name        = "${var.naziv_prefix}-sg-${each.key}-dorian-1612"
  description = "TechSprint Dorian — Developer ${each.key} Moodle VM-ovi"
}

# SSH s upravljacke mreze (bastion i voditelj)
resource "openstack_networking_secgroup_rule_v2" "developer_ssh" {
  for_each          = toset(var.dev_tim)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "172.16.0.0/24"
  security_group_id = openstack_networking_secgroup_v2.developer[each.key].id
}

# HTTP interno
resource "openstack_networking_secgroup_rule_v2" "developer_http" {
  for_each          = toset(var.dev_tim)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "172.12.${index(var.dev_tim, each.key) + 1}.0/24"
  security_group_id = openstack_networking_secgroup_v2.developer[each.key].id
}

# HTTPS interno
resource "openstack_networking_secgroup_rule_v2" "developer_https" {
  for_each          = toset(var.dev_tim)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "172.12.${index(var.dev_tim, each.key) + 1}.0/24"
  security_group_id = openstack_networking_secgroup_v2.developer[each.key].id
}
