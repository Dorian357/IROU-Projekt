# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure IAM outputi
# =============================================================================

output "dorian_developer_role_id" {
  description = "ID custom RBAC role za developere"
  value       = azurerm_role_definition.dorian_dev_operator.role_definition_resource_id
}
