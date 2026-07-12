# =============================================================================
# IRUO Projekt — Dorian
# Platforma: OpenStack
# Opis: Glavni Terraform modul za TechSprint OpenStack okolinu
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "openstack" {
  auth_url = var.os_auth_url
  region   = var.os_regija
  # Credentials se citaju iz OS_* environment varijabli (keystonerc file)
}

locals {
  naziv_prefix = "techsprint"
  oznake       = var.resource_tags
}

# --------------------------------------------------------------------------
# IAM — Keystone projekti, korisnici i role
# --------------------------------------------------------------------------

module "upravljanje_identitetima" {
  source        = "./modules/iam"
  naziv_prefix  = local.naziv_prefix
  voditelj_tima = var.voditelj_tima
  dev_tim       = var.dev_tim
}

# --------------------------------------------------------------------------
# Mrezna infrastruktura
# --------------------------------------------------------------------------

module "mrezna_infrastruktura" {
  source        = "./modules/network"
  naziv_prefix  = local.naziv_prefix
  dev_tim       = var.dev_tim
  vanjska_mreza = var.vanjska_mreza
  oznake        = local.oznake

  depends_on = [module.upravljanje_identitetima]
}

# --------------------------------------------------------------------------
# SSH Key Pair — dijeli se izmedju svih VM-ova
# --------------------------------------------------------------------------

resource "openstack_compute_keypair_v2" "dorian_keypair" {
  name       = "${local.naziv_prefix}-dorian-keypair-1612"
  public_key = var.ssh_kljuc
}

# --------------------------------------------------------------------------
# Bastion VM — jedina VM s Floating IP adresom
# --------------------------------------------------------------------------

module "bastion" {
  source           = "./modules/vm"
  naziv_prefix     = local.naziv_prefix
  ime_vm           = "${local.naziv_prefix}-vm-bastion-dorian"
  flavor_naziv     = var.bastion_flavor
  image_naziv      = var.os_image
  key_pair         = openstack_compute_keypair_v2.dorian_keypair.name
  network_id       = module.mrezna_infrastruktura.upravljanje_network_id
  security_groups  = [module.mrezna_infrastruktura.sg_bastion_id]
  floating_ip      = true
  ext_network_id   = module.mrezna_infrastruktura.vanjska_network_id
  data_volumen     = false
  volumen_gb       = var.data_volumen_gb
  tip_instance     = "bastion"
  lokalni_korisnik = ""
  oznake           = local.oznake

  depends_on = [module.mrezna_infrastruktura]
}

# --------------------------------------------------------------------------
# Voditeljev VM — nema Floating IP, pristup kroz bastion
# --------------------------------------------------------------------------

module "voditelj_vm" {
  source           = "./modules/vm"
  naziv_prefix     = local.naziv_prefix
  ime_vm           = "${local.naziv_prefix}-vm-voditelj-${var.voditelj_tima}"
  flavor_naziv     = var.voditelj_flavor
  image_naziv      = var.os_image
  key_pair         = openstack_compute_keypair_v2.dorian_keypair.name
  network_id       = module.mrezna_infrastruktura.upravljanje_network_id
  security_groups  = [module.mrezna_infrastruktura.sg_voditelj_id]
  floating_ip      = false
  ext_network_id   = module.mrezna_infrastruktura.vanjska_network_id
  data_volumen     = true
  volumen_gb       = var.data_volumen_gb
  tip_instance     = "voditelj"
  lokalni_korisnik = replace(var.voditelj_tima, ".", "_")
  oznake           = local.oznake

  depends_on = [module.mrezna_infrastruktura]
}

# --------------------------------------------------------------------------
# Aplikacijski VM-ovi — Moodle instanca 1 po developeru
# --------------------------------------------------------------------------

module "app_vm1" {
  source           = "./modules/vm"
  for_each         = toset(var.dev_tim)
  naziv_prefix     = local.naziv_prefix
  ime_vm           = "${local.naziv_prefix}-vm-${each.key}-app-1-dorian"
  flavor_naziv     = var.app_flavor
  image_naziv      = var.os_image
  key_pair         = openstack_compute_keypair_v2.dorian_keypair.name
  network_id       = module.mrezna_infrastruktura.dev_network_ids[each.key]
  security_groups  = [module.mrezna_infrastruktura.dev_sg_ids[each.key]]
  floating_ip      = false
  ext_network_id   = module.mrezna_infrastruktura.vanjska_network_id
  data_volumen     = true
  volumen_gb       = var.data_volumen_gb
  tip_instance     = "moodle"
  lokalni_korisnik = replace(each.key, ".", "_")
  oznake           = merge(local.oznake, { vlasnik = each.key, instanca = "1" })

  depends_on = [module.mrezna_infrastruktura, module.upravljanje_identitetima]
}

# --------------------------------------------------------------------------
# Aplikacijski VM-ovi — Moodle instanca 2 (visoka dostupnost)
# --------------------------------------------------------------------------

module "app_vm2" {
  source           = "./modules/vm"
  for_each         = toset(var.dev_tim)
  naziv_prefix     = local.naziv_prefix
  ime_vm           = "${local.naziv_prefix}-vm-${each.key}-app-2-dorian"
  flavor_naziv     = var.app_flavor
  image_naziv      = var.os_image
  key_pair         = openstack_compute_keypair_v2.dorian_keypair.name
  network_id       = module.mrezna_infrastruktura.dev_network_ids[each.key]
  security_groups  = [module.mrezna_infrastruktura.dev_sg_ids[each.key]]
  floating_ip      = false
  ext_network_id   = module.mrezna_infrastruktura.vanjska_network_id
  data_volumen     = true
  volumen_gb       = var.data_volumen_gb
  tip_instance     = "moodle"
  lokalni_korisnik = replace(each.key, ".", "_")
  oznake           = merge(local.oznake, { vlasnik = each.key, instanca = "2" })

  depends_on = [module.mrezna_infrastruktura, module.upravljanje_identitetima]
}

# --------------------------------------------------------------------------
# Load Balancer — Octavia LBaaS po developeru
# --------------------------------------------------------------------------

module "lb" {
  source        = "./modules/loadbalancer"
  for_each      = toset(var.dev_tim)
  naziv_prefix  = local.naziv_prefix
  dev_kljuc     = each.key
  subnet_id     = module.mrezna_infrastruktura.dev_subnet_ids[each.key]
  vm1_adresa    = module.app_vm1[each.key].private_ip
  vm2_adresa    = module.app_vm2[each.key].private_ip
  oznake        = merge(local.oznake, { vlasnik = each.key })

  depends_on = [module.app_vm1, module.app_vm2]
}

# --------------------------------------------------------------------------
# Pohrana — Swift (objektna) + Cinder (backup) po developeru
# --------------------------------------------------------------------------

module "pohrana" {
  source           = "./modules/storage"
  for_each         = toset(var.dev_tim)
  naziv_prefix     = local.naziv_prefix
  dev_kljuc        = each.key
  backup_volumen_gb = var.backup_volumen_gb
  vm1_id           = module.app_vm1[each.key].vm_id
  vm2_id           = module.app_vm2[each.key].vm_id
  oznake           = merge(local.oznake, { vlasnik = each.key })

  depends_on = [module.app_vm1, module.app_vm2]
}
