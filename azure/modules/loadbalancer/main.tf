# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Load Balancer
# Opis: Interni Standard LB koji balansira 2 Moodle instance po developeru
# =============================================================================

# Interni Standard Load Balancer
resource "azurerm_lb" "dorian_lb" {
  name                = "${var.naziv_prefix}-lb-${var.dev_kljuc}-1612"
  location            = var.regija
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.oznake

  frontend_ip_configuration {
    name                          = "dorian-frontend-1612"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Backend pool — skupina Moodle VM-ova
resource "azurerm_lb_backend_address_pool" "dorian_backend" {
  name            = "${var.naziv_prefix}-backend-${var.dev_kljuc}"
  loadbalancer_id = azurerm_lb.dorian_lb.id
}

# Dodavanje Moodle instance 1 u backend pool
resource "azurerm_lb_backend_address_pool_address" "dorian_app1" {
  name                    = "dorian-app-server-1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dorian_backend.id
  virtual_network_id      = var.vnet_id
  ip_address              = var.vm1_privatna_ip
}

# Dodavanje Moodle instance 2 u backend pool
resource "azurerm_lb_backend_address_pool_address" "dorian_app2" {
  name                    = "dorian-app-server-2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dorian_backend.id
  virtual_network_id      = var.vnet_id
  ip_address              = var.vm2_privatna_ip
}

# Health probe — provjera dostupnosti Moodle aplikacije
resource "azurerm_lb_probe" "dorian_health_probe" {
  name                = "${var.naziv_prefix}-probe-moodle-${var.dev_kljuc}"
  loadbalancer_id     = azurerm_lb.dorian_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/login/index.php"
  interval_in_seconds = 16
  number_of_probes    = 2
}

# Load balancing pravilo za HTTP promet
resource "azurerm_lb_rule" "dorian_http" {
  name                           = "${var.naziv_prefix}-pravilo-http-${var.dev_kljuc}"
  loadbalancer_id                = azurerm_lb.dorian_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "dorian-frontend-1612"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dorian_backend.id]
  probe_id                       = azurerm_lb_probe.dorian_health_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 16
  load_distribution              = "Default"
}

# Load balancing pravilo za HTTPS promet
resource "azurerm_lb_rule" "dorian_https" {
  name                           = "${var.naziv_prefix}-pravilo-https-${var.dev_kljuc}"
  loadbalancer_id                = azurerm_lb.dorian_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "dorian-frontend-1612"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dorian_backend.id]
  probe_id                       = azurerm_lb_probe.dorian_health_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 12
  load_distribution              = "Default"
}
