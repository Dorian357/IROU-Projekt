# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack VM
# Opis: Kreira Nova instancu s Rocky Linuxom i Cinder volumenom
# =============================================================================

data "openstack_images_image_v2" "dorian_image" {
  name        = var.image_naziv
  most_recent = true
}

data "openstack_compute_flavor_v2" "dorian_flavor" {
  name = var.flavor_naziv
}

# Cinder data volumen (ne koristi bastion)
resource "openstack_blockstorage_volume_v3" "dorian_data_vol" {
  count       = var.data_volumen ? 1 : 0
  name        = "${var.ime_vm}-data-vol-1612"
  size        = var.volumen_gb
  description = "TechSprint Dorian — data volumen za ${var.ime_vm}"
}

# Nova instanca s Rocky Linuxom
resource "openstack_compute_instance_v2" "dorian_instance" {
  name            = var.ime_vm
  image_id        = data.openstack_images_image_v2.dorian_image.id
  flavor_id       = data.openstack_compute_flavor_v2.dorian_flavor.id
  key_pair        = var.key_pair
  security_groups = var.security_groups

  metadata = var.oznake

  network {
    uuid = var.network_id
  }

  # cloud-init za automatsku inicijalizaciju
  user_data = templatefile("${path.module}/cloud-init.yaml.tpl", {
    tip_instance     = var.tip_instance
    lokalni_korisnik = var.lokalni_korisnik
  })
}

# Spajanje data volumena na instancu
resource "openstack_compute_volume_attach_v2" "dorian_vol_attach" {
  count       = var.data_volumen ? 1 : 0
  instance_id = openstack_compute_instance_v2.dorian_instance.id
  volume_id   = openstack_blockstorage_volume_v3.dorian_data_vol[0].id
}

# Floating IP — iskljucivo za bastion VM
resource "openstack_networking_floatingip_v2" "dorian_fip" {
  count = var.floating_ip ? 1 : 0
  pool  = var.ext_network_id
}

resource "openstack_compute_floatingip_associate_v2" "dorian_fip_attach" {
  count       = var.floating_ip ? 1 : 0
  floating_ip = openstack_networking_floatingip_v2.dorian_fip[0].address
  instance_id = openstack_compute_instance_v2.dorian_instance.id
}
