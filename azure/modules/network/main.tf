# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Mrezna infrastruktura
# Opis: VNet-ovi, subneti, NSG-ovi, NAT Gateway, VNet Peering
# IP shema bazirana na datumu rodendana: 16.12.
# =============================================================================

# --------------------------------------------------------------------------
# Upravljacka VNet (Bastion + Voditelj)
# --------------------------------------------------------------------------

resource "azurerm_virtual_network" "upravljanje" {
  name                = "${var.naziv_prefix}-vnet-upravljanje"
  location            = var.regija
  resource_group_name = var.rg_upravljanje
  address_space       = ["10.16.0.0/16"]
  tags                = var.oznake
}

resource "azurerm_subnet" "bastion" {
  name                 = "${var.naziv_prefix}-subnet-bastion"
  resource_group_name  = var.rg_upravljanje
  virtual_network_name = azurerm_virtual_network.upravljanje.name
  address_prefixes     = ["10.16.1.0/24"]
}

resource "azurerm_subnet" "voditelj" {
  name                 = "${var.naziv_prefix}-subnet-voditelj"
  resource_group_name  = var.rg_upravljanje
  virtual_network_name = azurerm_virtual_network.upravljanje.name
  address_prefixes     = ["10.16.2.0/24"]
}

# NAT Gateway za upravljacku mrezu
resource "azurerm_public_ip" "nat_upravljanje" {
  name                = "${var.naziv_prefix}-pip-nat-upravljanje"
  location            = var.regija
  resource_group_name = var.rg_upravljanje
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.oznake
}

resource "azurerm_nat_gateway" "upravljanje" {
  name                = "${var.naziv_prefix}-nat-upravljanje"
  location            = var.regija
  resource_group_name = var.rg_upravljanje
  sku_name            = "Standard"
  tags                = var.oznake
}

resource "azurerm_nat_gateway_public_ip_association" "upravljanje" {
  nat_gateway_id       = azurerm_nat_gateway.upravljanje.id
  public_ip_address_id = azurerm_public_ip.nat_upravljanje.id
}

resource "azurerm_subnet_nat_gateway_association" "voditelj" {
  subnet_id      = azurerm_subnet.voditelj.id
  nat_gateway_id = azurerm_nat_gateway.upravljanje.id
}

# --------------------------------------------------------------------------
# NSG — Bastion (samo SSH s interneta)
# --------------------------------------------------------------------------

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.naziv_prefix}-nsg-bastion"
  location            = var.regija
  resource_group_name = var.rg_upravljanje
  tags                = var.oznake

  security_rule {
    name                       = "Dozvoli-SSH-Izvana"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Zabrani-Sve-Ostalo"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

# --------------------------------------------------------------------------
# NSG — Voditeljev VM (SSH samo s bastion subneta)
# --------------------------------------------------------------------------

resource "azurerm_network_security_group" "voditelj" {
  name                = "${var.naziv_prefix}-nsg-voditelj"
  location            = var.regija
  resource_group_name = var.rg_upravljanje
  tags                = var.oznake

  security_rule {
    name                       = "Dozvoli-SSH-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.16.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Zabrani-Sve-Ostalo"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "voditelj" {
  subnet_id                 = azurerm_subnet.voditelj.id
  network_security_group_id = azurerm_network_security_group.voditelj.id
}

# --------------------------------------------------------------------------
# Developer VNet-ovi — izolirana mreža po developeru
# Treci oktet baziran na 12 (mjesec rodendana)
# --------------------------------------------------------------------------

resource "azurerm_virtual_network" "developer" {
  for_each            = toset(var.dev_tim)
  name                = "${var.naziv_prefix}-vnet-${each.key}"
  location            = var.regija
  resource_group_name = var.dev_rg_mapa[each.key]
  address_space       = ["10.12.${index(var.dev_tim, each.key) + 1}.0/24"]
  tags                = merge(var.oznake, { vlasnik = each.key })
}

resource "azurerm_subnet" "developer" {
  for_each             = toset(var.dev_tim)
  name                 = "${var.naziv_prefix}-subnet-${each.key}"
  resource_group_name  = var.dev_rg_mapa[each.key]
  virtual_network_name = azurerm_virtual_network.developer[each.key].name
  address_prefixes     = ["10.12.${index(var.dev_tim, each.key) + 1}.0/24"]
}

# NAT Gateway po developeru
resource "azurerm_public_ip" "nat_developer" {
  for_each            = toset(var.dev_tim)
  name                = "${var.naziv_prefix}-pip-nat-${each.key}"
  location            = var.regija
  resource_group_name = var.dev_rg_mapa[each.key]
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.oznake, { vlasnik = each.key })
}

resource "azurerm_nat_gateway" "developer" {
  for_each            = toset(var.dev_tim)
  name                = "${var.naziv_prefix}-nat-${each.key}"
  location            = var.regija
  resource_group_name = var.dev_rg_mapa[each.key]
  sku_name            = "Standard"
  tags                = merge(var.oznake, { vlasnik = each.key })
}

resource "azurerm_nat_gateway_public_ip_association" "developer" {
  for_each             = toset(var.dev_tim)
  nat_gateway_id       = azurerm_nat_gateway.developer[each.key].id
  public_ip_address_id = azurerm_public_ip.nat_developer[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "developer" {
  for_each       = toset(var.dev_tim)
  subnet_id      = azurerm_subnet.developer[each.key].id
  nat_gateway_id = azurerm_nat_gateway.developer[each.key].id
}

# --------------------------------------------------------------------------
# NSG — Developer VM-ovi
# --------------------------------------------------------------------------

resource "azurerm_network_security_group" "developer" {
  for_each            = toset(var.dev_tim)
  name                = "${var.naziv_prefix}-nsg-${each.key}"
  location            = var.regija
  resource_group_name = var.dev_rg_mapa[each.key]
  tags                = merge(var.oznake, { vlasnik = each.key })

  security_rule {
    name                       = "Dozvoli-SSH-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.16.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Dozvoli-SSH-Voditelj"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.16.2.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Dozvoli-HTTP-Interno"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.12.${index(var.dev_tim, each.key) + 1}.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Dozvoli-HTTPS-Interno"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.12.${index(var.dev_tim, each.key) + 1}.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Zabrani-Sve-Ostalo"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "developer" {
  for_each                  = toset(var.dev_tim)
  subnet_id                 = azurerm_subnet.developer[each.key].id
  network_security_group_id = azurerm_network_security_group.developer[each.key].id
}

# --------------------------------------------------------------------------
# VNet Peering — Upravljanje <-> Developer VNet-ovi
# --------------------------------------------------------------------------

resource "azurerm_virtual_network_peering" "upravljanje_prema_dev" {
  for_each                  = toset(var.dev_tim)
  name                      = "${var.naziv_prefix}-peering-upravljanje-${each.key}"
  resource_group_name       = var.rg_upravljanje
  virtual_network_name      = azurerm_virtual_network.upravljanje.name
  remote_virtual_network_id = azurerm_virtual_network.developer[each.key].id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "dev_prema_upravljanju" {
  for_each                  = toset(var.dev_tim)
  name                      = "${var.naziv_prefix}-peering-${each.key}-upravljanje"
  resource_group_name       = var.dev_rg_mapa[each.key]
  virtual_network_name      = azurerm_virtual_network.developer[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.upravljanje.id
  allow_forwarded_traffic   = true
}
