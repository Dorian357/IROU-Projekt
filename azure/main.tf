# =============================================================================
# IRUO Projekt — Dorian
# Platforma: Microsoft Azure
# Opis: Glavni Terraform modul za TechSprint multi-cloud okolinu
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}

provider "azuread" {}

data "azurerm_subscription" "tekuca" {}

locals {
  naziv_prefix = "techsprint"
  oznake       = var.resource_tags
}

# --------------------------------------------------------------------------
# Resource grupe — upravljacka i po developeru
# --------------------------------------------------------------------------

resource "azurerm_resource_group" "upravljanje" {
  name     = "${local.naziv_prefix}-rg-upravljanje"
  location = var.azure_region
  tags     = local.oznake
}

resource "azurerm_resource_group" "dev_grupe" {
  for_each = toset(var.dev_team)
  name     = "${local.naziv_prefix}-rg-${each.key}"
  location = var.azure_region
  tags     = merge(local.oznake, { vlasnik = each.key })
}

# --------------------------------------------------------------------------
# Mrezna infrastruktura
# --------------------------------------------------------------------------

module "mrezna_infrastruktura" {
  source         = "./modules/network"
  naziv_prefix   = local.naziv_prefix
  regija         = var.azure_region
  oznake         = local.oznake
  rg_upravljanje = azurerm_resource_group.upravljanje.name
  dev_rg_mapa    = { for k, v in azurerm_resource_group.dev_grupe : k => v.name }
  dev_tim        = var.dev_team
  voditelj       = var.team_lead
}

# --------------------------------------------------------------------------
# Bastion (Jump Host) — jedina VM s javnom IP adresom
# --------------------------------------------------------------------------

module "bastion" {
  source              = "./modules/vm"
  naziv_prefix        = local.naziv_prefix
  regija              = var.azure_region
  oznake              = local.oznake
  resource_group_name = azurerm_resource_group.upravljanje.name
  ime_vm              = "${local.naziv_prefix}-vm-bastion"
  velicina_vm         = var.bastion_vm_size
  subnet_id           = module.mrezna_infrastruktura.bastion_subnet_id
  admin_korisnik      = "azureuser"
  ssh_kljuc           = var.ssh_key
  javna_ip            = true
  data_disk           = false
  os_disk_gb          = 30
  tip_instance        = "bastion"
  lokalni_korisnik    = ""
}

# --------------------------------------------------------------------------
# Voditeljev VM — nema javnu IP, pristup kroz bastion
# --------------------------------------------------------------------------

module "lead_vm" {
  source              = "./modules/vm"
  naziv_prefix        = local.naziv_prefix
  regija              = var.azure_region
  oznake              = merge(local.oznake, { uloga = "voditelj" })
  resource_group_name = azurerm_resource_group.upravljanje.name
  ime_vm              = "${local.naziv_prefix}-vm-voditelj-${var.team_lead}"
  velicina_vm         = var.lead_vm_size
  subnet_id           = module.mrezna_infrastruktura.lead_subnet_id
  admin_korisnik      = "azureuser"
  ssh_kljuc           = var.ssh_key
  javna_ip            = false
  data_disk           = true
  data_disk_gb        = var.data_disk_gb
  os_disk_gb          = var.os_disk_gb
  tip_instance        = "voditelj"
  lokalni_korisnik    = replace(var.team_lead, ".", "_")
}

# --------------------------------------------------------------------------
# Aplikacijski VM-ovi — Moodle instanca 1 po developeru
# --------------------------------------------------------------------------

module "app_vm1" {
  source              = "./modules/vm"
  for_each            = toset(var.dev_team)
  naziv_prefix        = local.naziv_prefix
  regija              = var.azure_region
  oznake              = merge(local.oznake, { vlasnik = each.key, instanca = "1" })
  resource_group_name = azurerm_resource_group.dev_grupe[each.key].name
  ime_vm              = "${local.naziv_prefix}-vm-${each.key}-app-1"
  velicina_vm         = var.app_vm_size
  subnet_id           = module.mrezna_infrastruktura.dev_subnet_ids[each.key]
  admin_korisnik      = "azureuser"
  ssh_kljuc           = var.ssh_key
  javna_ip            = false
  data_disk           = true
  data_disk_gb        = var.data_disk_gb
  os_disk_gb          = var.os_disk_gb
  tip_instance        = "moodle"
  lokalni_korisnik    = replace(each.key, ".", "_")
}

# --------------------------------------------------------------------------
# Aplikacijski VM-ovi — Moodle instanca 2 (visoka dostupnost)
# --------------------------------------------------------------------------

module "app_vm2" {
  source              = "./modules/vm"
  for_each            = toset(var.dev_team)
  naziv_prefix        = local.naziv_prefix
  regija              = var.azure_region
  oznake              = merge(local.oznake, { vlasnik = each.key, instanca = "2" })
  resource_group_name = azurerm_resource_group.dev_grupe[each.key].name
  ime_vm              = "${local.naziv_prefix}-vm-${each.key}-app-2"
  velicina_vm         = var.app_vm_size
  subnet_id           = module.mrezna_infrastruktura.dev_subnet_ids[each.key]
  admin_korisnik      = "azureuser"
  ssh_kljuc           = var.ssh_key
  javna_ip            = false
  data_disk           = true
  data_disk_gb        = var.data_disk_gb
  os_disk_gb          = var.os_disk_gb
  tip_instance        = "moodle"
  lokalni_korisnik    = replace(each.key, ".", "_")
}

# --------------------------------------------------------------------------
# Load Balancer — rasporeduje promet na 2 Moodle instance
# --------------------------------------------------------------------------

module "lb" {
  source              = "./modules/loadbalancer"
  for_each            = toset(var.dev_team)
  naziv_prefix        = local.naziv_prefix
  regija              = var.azure_region
  oznake              = merge(local.oznake, { vlasnik = each.key })
  resource_group_name = azurerm_resource_group.dev_grupe[each.key].name
  dev_kljuc           = each.key
  vm1_id              = module.app_vm1[each.key].vm_id
  vm2_id              = module.app_vm2[each.key].vm_id
  vm1_privatna_ip     = module.app_vm1[each.key].private_ip
  vm2_privatna_ip     = module.app_vm2[each.key].private_ip
  subnet_id           = module.mrezna_infrastruktura.dev_subnet_ids[each.key]
  vnet_id             = module.mrezna_infrastruktura.dev_vnet_ids[each.key]
}

# --------------------------------------------------------------------------
# Pohrana — Blob (Moodle datoteke) + Files (backup) po developeru
# --------------------------------------------------------------------------

module "storage" {
  source              = "./modules/storage"
  for_each            = toset(var.dev_team)
  naziv_prefix        = local.naziv_prefix
  regija              = var.azure_region
  oznake              = merge(local.oznake, { vlasnik = each.key })
  resource_group_name = azurerm_resource_group.dev_grupe[each.key].name
  dev_kljuc           = each.key
  vm1_id              = module.app_vm1[each.key].vm_id
  vm2_id              = module.app_vm2[each.key].vm_id
  vm1_principal_id    = module.app_vm1[each.key].identity_principal_id
  vm2_principal_id    = module.app_vm2[each.key].identity_principal_id
  files_kapacitet_gb  = var.file_storage_gb
}

# --------------------------------------------------------------------------
# IAM — RBAC rola i dodjela prava korisnicima
# --------------------------------------------------------------------------

module "upravljanje_pristupom" {
  source                   = "./modules/iam"
  naziv_prefix             = local.naziv_prefix
  pretplata_id             = data.azurerm_subscription.tekuca.id
  dev_tim                  = var.dev_team
  dev_rg_ids               = { for k, v in azurerm_resource_group.dev_grupe : k => v.id }
  voditelj_principal_id    = module.lead_vm.identity_principal_id
  dev_vm1_principals       = { for k in var.dev_team : k => module.app_vm1[k].identity_principal_id }
  dev_vm2_principals       = { for k in var.dev_team : k => module.app_vm2[k].identity_principal_id }
}
