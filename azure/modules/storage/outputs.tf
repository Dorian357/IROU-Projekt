# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Storage outputi
# =============================================================================

output "blob_endpoint" {
  description = "Endpoint za Azure Blob Storage (objektna pohrana)"
  value       = azurerm_storage_account.dorian_storage.primary_blob_endpoint
}

output "files_endpoint" {
  description = "Endpoint za Azure Files (datotecna pohrana)"
  value       = azurerm_storage_account.dorian_storage.primary_file_endpoint
}

output "storage_account_naziv" {
  description = "Naziv Storage Accounta"
  value       = azurerm_storage_account.dorian_storage.name
}
