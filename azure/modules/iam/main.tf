# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure IAM (RBAC)
# Opis: Custom rola za developere i dodjela prava voditelju
# Princip: least-privilege — developer kontrolira samo svoje VM-ove
# =============================================================================

# Custom RBAC rola — Developer VM Operator
# Minimalne dozvole: samo start, stop, restart i citanje vlastitih VM-ova
resource "azurerm_role_definition" "dorian_dev_operator" {
  name        = "${var.naziv_prefix}-dorian-developer-operator-1612"
  scope       = "/subscriptions/${var.pretplata_id}"
  description = "TechSprint Developer — dozvoljava samo pokretanje, gasenje i restart vlastitih VM-ova."

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/deployments/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.pretplata_id}"
  ]
}

# Dodjela custom role developerima na njihovim resource grupama
resource "azurerm_role_assignment" "dorian_dev_vm1_operator" {
  for_each             = toset(var.dev_tim)
  scope                = var.dev_rg_ids[each.key]
  role_definition_id   = azurerm_role_definition.dorian_dev_operator.role_definition_resource_id
  principal_id         = var.dev_vm1_principals[each.key]
}

resource "azurerm_role_assignment" "dorian_dev_vm2_operator" {
  for_each             = toset(var.dev_tim)
  scope                = var.dev_rg_ids[each.key]
  role_definition_id   = azurerm_role_definition.dorian_dev_operator.role_definition_resource_id
  principal_id         = var.dev_vm2_principals[each.key]
}

# Voditelj — Reader na cijeloj pretplati
resource "azurerm_role_assignment" "dorian_voditelj_reader" {
  scope                = "/subscriptions/${var.pretplata_id}"
  role_definition_name = "Reader"
  principal_id         = var.voditelj_principal_id
}

# Voditelj — VM Contributor na svim developer resource grupama
resource "azurerm_role_assignment" "dorian_voditelj_vm_contributor" {
  for_each             = var.dev_rg_ids
  scope                = each.value
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.voditelj_principal_id
}
