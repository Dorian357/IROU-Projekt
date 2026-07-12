variable "naziv_prefix" { type = string }
variable "regija" { type = string }
variable "oznake" { type = map(string) }
variable "rg_upravljanje" { type = string }
variable "dev_rg_mapa" { type = map(string) }
variable "dev_tim" { type = list(string) }
variable "voditelj" { type = string }
