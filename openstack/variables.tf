# =============================================================================
# IRUO Projekt — Dorian
# Platforma: OpenStack
# Opis: Varijable za TechSprint multi-cloud okolinu
# =============================================================================

variable "os_auth_url" {
  description = "OpenStack Keystone autentikacijski URL"
  type        = string
}

variable "os_regija" {
  description = "OpenStack regija"
  type        = string
  default     = "RegionOne"
}

variable "voditelj_tima" {
  description = "Korisnicko ime voditelja tima (format: ime.prezime)"
  type        = string
}

variable "dev_tim" {
  description = "Popis korisnickih imena developera ucitanih iz CSV-a"
  type        = list(string)
}

variable "ssh_kljuc" {
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
    autor       = "dorian"
  }
}

variable "app_flavor" {
  description = "OpenStack flavor za Moodle VM-ove (min 2 vCPU, 4GB RAM)"
  type        = string
  default     = "m1.medium"
}

variable "voditelj_flavor" {
  description = "OpenStack flavor za voditeljev VM"
  type        = string
  default     = "m1.medium"
}

variable "bastion_flavor" {
  description = "OpenStack flavor za bastion VM"
  type        = string
  default     = "m1.small"
}

variable "os_image" {
  description = "Naziv Rocky Linux cloud image-a u OpenStack Glance"
  type        = string
  default     = "Rocky-Linux-9"
}

variable "vanjska_mreza" {
  description = "Naziv vanjske mreze za Floating IP"
  type        = string
  default     = "external"
}

variable "data_volumen_gb" {
  description = "Velicina Cinder data volumena u GB"
  type        = number
  default     = 50
}

variable "backup_volumen_gb" {
  description = "Velicina Cinder backup volumena u GB"
  type        = number
  default     = 50
}

variable "swift_kapacitet_gb" {
  description = "Velicina Swift objektnog kontejnera u GB"
  type        = number
  default     = 100
}
