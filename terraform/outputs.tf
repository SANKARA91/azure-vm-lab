# Affiche l'IP publique de la VM après terraform apply
output "public_ip" {
  description = "IP publique de la VM"
  value       = azurerm_public_ip.pip.ip_address
}

# Affiche directement la commande SSH prête à copier-coller
# Ex : ssh adminuser@20.X.X.X
output "ssh_command" {
  description = "Commande SSH pour se connecter"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

# Affiche le nom du resource group pour les commandes az cli
output "resource_group" {
  value = azurerm_resource_group.rg.name
}