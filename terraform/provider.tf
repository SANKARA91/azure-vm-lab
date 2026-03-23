# Bloc principal de configuration Terraform
terraform {

  # Déclare les plugins nécessaires à télécharger
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # Adresse du plugin sur le registry Terraform
      version = "~> 3.0"            # Version 3.x uniquement, pas la 4
    }
  }

  required_version = ">= 1.3.0" # Terraform minimum requis sur la machine
}

# Configure la connexion à Azure
# features {} est obligatoire même vide pour le provider azurerm
provider "azurerm" {
  features {}
}