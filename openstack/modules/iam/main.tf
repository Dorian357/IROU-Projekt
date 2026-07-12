# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack IAM (Keystone)
# Opis: Projekti, korisnici i role za izolaciju resursa
# Princip: least-privilege — developer pristupa samo svom projektu
# =============================================================================

# Keystone projekt po developeru — potpuna izolacija resursa
resource "openstack_identity_project_v3" "dorian_dev_projekt" {
  for_each    = toset(var.dev_tim)
  name        = "${var.naziv_prefix}-projekt-${each.key}-dorian"
  description = "TechSprint Dorian — projekt za developera ${each.key}"
  enabled     = true
}

# Generiranje sigurne lozinke po developeru
resource "random_password" "dorian_dev_lozinka" {
  for_each = toset(var.dev_tim)
  length   = 20
  special  = true
}

# Keystone korisnik po developeru
resource "openstack_identity_user_v3" "dorian_dev_korisnik" {
  for_each           = toset(var.dev_tim)
  name               = "${each.key}-dorian-1612"
  description        = "TechSprint Dorian 16.12. — developer ${each.key}"
  enabled            = true
  default_project_id = openstack_identity_project_v3.dorian_dev_projekt[each.key].id
  password           = random_password.dorian_dev_lozinka[each.key].result
}

# Dohvat member i admin rola
data "openstack_identity_role_v3" "member" {
  name = "member"
}

data "openstack_identity_role_v3" "admin" {
  name = "admin"
}

# Dodjela member role developerima — pristup samo vlastitom projektu
resource "openstack_identity_role_assignment_v3" "dorian_dev_member" {
  for_each   = toset(var.dev_tim)
  user_id    = openstack_identity_user_v3.dorian_dev_korisnik[each.key].id
  project_id = openstack_identity_project_v3.dorian_dev_projekt[each.key].id
  role_id    = data.openstack_identity_role_v3.member.id
}

# Generiranje lozinke za voditelja
resource "random_password" "dorian_voditelj_lozinka" {
  length  = 20
  special = true
}

# Keystone korisnik za voditelja tima
resource "openstack_identity_user_v3" "dorian_voditelj" {
  name        = "${var.voditelj_tima}-dorian-voditelj-1612"
  description = "TechSprint Dorian — Voditelj tima"
  enabled     = true
  password    = random_password.dorian_voditelj_lozinka.result
}

# Voditelj dobiva admin pristup na svim developer projektima
resource "openstack_identity_role_assignment_v3" "dorian_voditelj_admin" {
  for_each   = toset(var.dev_tim)
  user_id    = openstack_identity_user_v3.dorian_voditelj.id
  project_id = openstack_identity_project_v3.dorian_dev_projekt[each.key].id
  role_id    = data.openstack_identity_role_v3.admin.id
}
