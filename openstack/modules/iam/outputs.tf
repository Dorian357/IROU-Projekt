# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack IAM outputi
# =============================================================================

output "dev_projekt_ids" {
  description = "ID-evi Keystone projekata po developeru"
  value       = { for k, v in openstack_identity_project_v3.dorian_dev_projekt : k => v.id }
}

output "dev_korisnik_ids" {
  description = "ID-evi Keystone korisnika po developeru"
  value       = { for k, v in openstack_identity_user_v3.dorian_dev_korisnik : k => v.id }
  sensitive   = true
}

output "dev_lozinke" {
  description = "Generirane lozinke za developere"
  value       = { for k, v in random_password.dorian_dev_lozinka : k => v.result }
  sensitive   = true
}

output "voditelj_lozinka" {
  description = "Generirana lozinka za voditelja"
  value       = random_password.dorian_voditelj_lozinka.result
  sensitive   = true
}
