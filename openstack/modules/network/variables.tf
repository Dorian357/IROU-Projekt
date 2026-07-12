# =============================================================================
# IRUO Projekt — Dorian
# Modul: OpenStack Network varijable
# =============================================================================

variable "naziv_prefix" { type = string }
variable "dev_tim" { type = list(string) }
variable "vanjska_mreza" { type = string }
variable "oznake" { type = map(string) }
