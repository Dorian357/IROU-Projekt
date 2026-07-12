# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Storage varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "dev_kljuc" { type = string }
variable "backup_volumen_gb" { type = number; default = 50 }
variable "vm1_id" { type = string }
variable "vm2_id" { type = string }
variable "oznake" { type = map(string) }
