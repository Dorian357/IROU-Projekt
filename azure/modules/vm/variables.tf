# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure VM varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "regija" { type = string }
variable "oznake" { type = map(string) }
variable "resource_group_name" { type = string }
variable "ime_vm" { type = string }
variable "velicina_vm" { type = string }
variable "subnet_id" { type = string }
variable "admin_korisnik" { type = string }
variable "ssh_kljuc" { type = string; sensitive = true }
variable "javna_ip" { type = bool; default = false }
variable "data_disk" { type = bool; default = true }
variable "os_disk_gb" { type = number; default = 64 }
variable "data_disk_gb" { type = number; default = 64 }
variable "tip_instance" { type = string }
variable "lokalni_korisnik" { type = string; default = "" }
