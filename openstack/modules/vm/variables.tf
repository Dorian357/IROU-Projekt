# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack VM varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "ime_vm" { type = string }
variable "flavor_naziv" { type = string }
variable "image_naziv" { type = string }
variable "key_pair" { type = string }
variable "network_id" { type = string }
variable "security_groups" { type = list(string) }
variable "floating_ip" { type = bool; default = false }
variable "ext_network_id" { type = string }
variable "data_volumen" { type = bool; default = true }
variable "volumen_gb" { type = number; default = 50 }
variable "tip_instance" { type = string }
variable "lokalni_korisnik" { type = string; default = "" }
variable "oznake" { type = map(string) }
