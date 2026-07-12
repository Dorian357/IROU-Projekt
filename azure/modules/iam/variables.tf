# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure IAM varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "pretplata_id" { type = string }
variable "dev_tim" { type = list(string) }
variable "dev_rg_ids" { type = map(string) }
variable "voditelj_principal_id" { type = string }
variable "dev_vm1_principals" { type = map(string) }
variable "dev_vm2_principals" { type = map(string) }
