# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Storage varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "regija" { type = string }
variable "oznake" { type = map(string) }
variable "resource_group_name" { type = string }
variable "dev_kljuc" { type = string }
variable "vm1_id" { type = string }
variable "vm2_id" { type = string }
variable "vm1_principal_id" { type = string }
variable "vm2_principal_id" { type = string }
variable "files_kapacitet_gb" { type = number; default = 100 }
