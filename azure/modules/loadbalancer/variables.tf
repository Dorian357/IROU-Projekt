# =============================================================================
# IRUO Projekt — Dorian
# Modul: Azure Load Balancer varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "regija" { type = string }
variable "oznake" { type = map(string) }
variable "resource_group_name" { type = string }
variable "dev_kljuc" { type = string }
variable "vm1_id" { type = string }
variable "vm2_id" { type = string }
variable "vm1_privatna_ip" { type = string }
variable "vm2_privatna_ip" { type = string }
variable "subnet_id" { type = string }
variable "vnet_id" { type = string }
