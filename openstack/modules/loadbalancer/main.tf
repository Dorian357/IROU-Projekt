# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Load Balancer (Octavia LBaaS v2)
# Opis: Round Robin balansiranje izmedju 2 Moodle instance po developeru
# =============================================================================

resource "openstack_lb_loadbalancer_v2" "dorian_lb" {
  name          = "${var.naziv_prefix}-lb-${var.dev_kljuc}-dorian-1612"
  vip_subnet_id = var.subnet_id
}

# Listener za HTTP promet
resource "openstack_lb_listener_v2" "dorian_http" {
  name            = "${var.naziv_prefix}-listener-http-${var.dev_kljuc}-1612"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.dorian_lb.id
}

# Listener za HTTPS promet
resource "openstack_lb_listener_v2" "dorian_https" {
  name            = "${var.naziv_prefix}-listener-https-${var.dev_kljuc}-1612"
  protocol        = "TCP"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.dorian_lb.id
}

# Backend pool za HTTP — Round Robin
resource "openstack_lb_pool_v2" "dorian_http_pool" {
  name        = "${var.naziv_prefix}-pool-http-${var.dev_kljuc}-dorian"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.dorian_http.id
}

# Backend pool za HTTPS — Round Robin
resource "openstack_lb_pool_v2" "dorian_https_pool" {
  name        = "${var.naziv_prefix}-pool-https-${var.dev_kljuc}-dorian"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.dorian_https.id
}

# Health monitor — provjera Moodle login stranice
resource "openstack_lb_monitor_v2" "dorian_monitor" {
  name           = "${var.naziv_prefix}-monitor-${var.dev_kljuc}-1612"
  pool_id        = openstack_lb_pool_v2.dorian_http_pool.id
  type           = "HTTP"
  delay          = 16
  timeout        = 12
  max_retries    = 3
  url_path       = "/login/index.php"
  http_method    = "GET"
  expected_codes = "200"
}

# Moodle app server 1 u HTTP pool
resource "openstack_lb_member_v2" "dorian_app1_http" {
  name          = "dorian-app-1-http"
  pool_id       = openstack_lb_pool_v2.dorian_http_pool.id
  address       = var.vm1_adresa
  protocol_port = 80
}

# Moodle app server 2 u HTTP pool
resource "openstack_lb_member_v2" "dorian_app2_http" {
  name          = "dorian-app-2-http"
  pool_id       = openstack_lb_pool_v2.dorian_http_pool.id
  address       = var.vm2_adresa
  protocol_port = 80
}

# Moodle app server 1 u HTTPS pool
resource "openstack_lb_member_v2" "dorian_app1_https" {
  name          = "dorian-app-1-https"
  pool_id       = openstack_lb_pool_v2.dorian_https_pool.id
  address       = var.vm1_adresa
  protocol_port = 443
}

# Moodle app server 2 u HTTPS pool
resource "openstack_lb_member_v2" "dorian_app2_https" {
  name          = "dorian-app-2-https"
  pool_id       = openstack_lb_pool_v2.dorian_https_pool.id
  address       = var.vm2_adresa
  protocol_port = 443
}
