# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Storage
# Opis: Swift kontejner (objektna pohrana) + Cinder volumen (backup)
# =============================================================================

# Swift kontejner za Moodle datoteke (objektna pohrana)
resource "openstack_objectstorage_container_v1" "dorian_swift" {
  name   = "${var.naziv_prefix}-swift-${var.dev_kljuc}-dorian-1612"
  region = "RegionOne"

  metadata = {
    project     = "techsprint"
    environment = "testing"
    vlasnik     = var.dev_kljuc
    autor       = "dorian"
  }

  content_type = "application/json"
}

# Cinder volumen za backup kopije (datotecna pohrana)
resource "openstack_blockstorage_volume_v3" "dorian_backup_vol" {
  name        = "${var.naziv_prefix}-vol-backup-${var.dev_kljuc}-dorian-1612"
  size        = var.backup_volumen_gb
  description = "TechSprint Dorian — backup volumen za developera ${var.dev_kljuc}"

  metadata = var.oznake
}

# Montiranje backup volumena na app VM1
resource "openstack_compute_volume_attach_v2" "dorian_backup_vm1" {
  instance_id = var.vm1_id
  volume_id   = openstack_blockstorage_volume_v3.dorian_backup_vol.id
}
