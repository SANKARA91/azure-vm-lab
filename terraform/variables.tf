# Région Azure où toutes les ressources seront créées
variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe" # Paris / Amsterdam
}

# Préfixe utilisé dans le nom de toutes les ressources
# Ex : "vm-lab" → "vm-lab-rg", "vm-lab-vm"
# Changer cette valeur renomme tout le projet
variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "vm-lab"
}

# Nom du compte administrateur sur la VM Linux
variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}