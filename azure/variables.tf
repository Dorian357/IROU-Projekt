# =============================================================================
# IRUO Projekt — Dorian
# Platforma: Microsoft Azure
# Opis: Varijable za TechSprint multi-cloud okolinu
# =============================================================================

variable "azure_region" {
  description = "Azure regija u kojoj se kreiraju svi resursi"
  type        = string
  default     = "westeurope"
}

variable "team_lead" {
  description = "Korisnicko ime voditelja tima (format: ime.prezime)"
  type        = string
}

variable "dev_team" {
  description = "Popis korisnickih imena developera ucitanih iz CSV-a"
  type        = list(string)
}

variable "ssh_key" {
  description = "Javni SSH kljuc za prijavu na sve virtualne masine"
  type        = string
  sensitive   = true
}

variable "resource_tags" {
  description = "Obavezni tagovi na svim resursima"
  type        = map(string)
  default = {
    project     = "techsprint"
    environment = "testing"
    managed_by  = "terraform"
    owner       = "dorian"
  }
}

variable "app_vm_size" {
  description = "Velicina aplikacijske VM (Moodle) — minimum 2 vCPU i 4GB RAM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "lead_vm_size" {
  description = "Velicina VM za voditelja tima"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "bastion_vm_size" {
  description = "Velicina Jump Host (bastion) VM — ne treba puno resursa"
  type        = string
  default     = "Standard_B1s"
}

variable "os_disk_gb" {
  description = "Velicina sistemskog diska u GB"
  type        = number
  default     = 64
}

variable "data_disk_gb" {
  description = "Velicina podatkovnog diska u GB"
  type        = number
  default     = 64
}

variable "object_storage_gb" {
  description = "Kapacitet objektne pohrane (Blob) po developeru u GB"
  type        = number
  default     = 100
}

variable "file_storage_gb" {
  description = "Kapacitet datotecne pohrane (Files) po developeru u GB"
  type        = number
  default     = 100
}
