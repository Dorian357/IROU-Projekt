# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Storage
# Opis: Blob Storage (Moodle datoteke) + Azure Files (backup)
# Pristup: Managed Identity — least-privilege princip
# =============================================================================

resource "random_string" "dorian_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Storage Account po developeru
resource "azurerm_storage_account" "dorian_storage" {
  name                     = "dorian${replace(var.dev_kljuc, ".", "")}${random_string.dorian_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.regija
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Pristup samo putem Managed Identity — bez account key-a
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  tags = var.oznake
}

# Blob kontejner za Moodle datoteke (slike, dokumenti, plugini)
resource "azurerm_storage_container" "dorian_moodle_blob" {
  name                  = "dorian-moodle-1612"
  storage_account_name  = azurerm_storage_account.dorian_storage.name
  container_access_type = "private"
}

# Azure Files dijeljenje za backup kopije
resource "azurerm_storage_share" "dorian_backup" {
  name                 = "dorian-backup-1612"
  storage_account_name = azurerm_storage_account.dorian_storage.name
  quota                = var.files_kapacitet_gb
}

# --------------------------------------------------------------------------
# RBAC dodjele — least-privilege pristup putem Managed Identity
# --------------------------------------------------------------------------

# App VM1 — Blob Data Contributor (citanje i pisanje blob podataka)
resource "azurerm_role_assignment" "dorian_vm1_blob" {
  scope                = azurerm_storage_account.dorian_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.vm1_principal_id
}

# App VM2 — Blob Data Contributor
resource "azurerm_role_assignment" "dorian_vm2_blob" {
  scope                = azurerm_storage_account.dorian_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.vm2_principal_id
}

# App VM1 — Files SMB Share Contributor (citanje i pisanje backup dijeljenja)
resource "azurerm_role_assignment" "dorian_vm1_files" {
  scope                = azurerm_storage_account.dorian_storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = var.vm1_principal_id
}

# App VM2 — Files SMB Share Contributor
resource "azurerm_role_assignment" "dorian_vm2_files" {
  scope                = azurerm_storage_account.dorian_storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = var.vm2_principal_id
}
