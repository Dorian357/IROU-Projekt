# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Storage outputi
# =============================================================================

output "swift_kontejner_naziv" {
  description = "Naziv Swift kontejnera za Moodle datoteke"
  value       = openstack_objectstorage_container_v1.dorian_swift.name
}

output "backup_volumen_id" {
  description = "ID Cinder backup volumena"
  value       = openstack_blockstorage_volume_v3.dorian_backup_vol.id
}
