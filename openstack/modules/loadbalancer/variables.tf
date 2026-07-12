# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Load Balancer varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "dev_kljuc" { type = string }
variable "subnet_id" { type = string }
variable "vm1_adresa" { type = string }
variable "vm2_adresa" { type = string }
variable "oznake" { type = map(string) }
