# Conteneur logique Azure qui regroupe toutes les ressources du projet
# Equivalent d'un "dossier" dans Azure
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"  # vm-lab-rg
  location = var.location
}

# Réseau virtuel privé — l'espace IP de votre infrastructure
# 10.0.0.0/16 = 65 536 adresses IP disponibles
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Sous-réseau dans le vnet — segment réseau pour la VM
# 10.0.1.0/24 = 256 adresses IP disponibles
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Adresse IP publique fixe pour accéder à la VM depuis internet
# Static = l'IP ne change pas au redémarrage
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static" # IP fixe, pas dynamique
  sku                 = "Standard" # Ajoutez cette ligne
}

# Pare-feu réseau — contrôle le trafic entrant et sortant
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Règle qui autorise la connexion SSH (port 22) depuis n'importe quelle IP
  security_rule {
    name                       = "SSH"
    priority                   = 1001       # Plus le chiffre est bas, plus la règle est prioritaire
    direction                  = "Inbound"  # Trafic entrant
    access                     = "Allow"    # Autoriser
    protocol                   = "Tcp"
    source_port_range          = "*"        # N'importe quel port source
    destination_port_range     = "22"       # Port SSH
    source_address_prefix      = "*"        # N'importe quelle IP source
    destination_address_prefix = "*"        # Vers n'importe quelle IP de destination
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Carte réseau virtuelle de la VM — relie la VM au réseau
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic" # IP privée attribuée automatiquement
    public_ip_address_id          = azurerm_public_ip.pip.id # Associe l'IP publique à la NIC
  }
}

# Associe le pare-feu NSG à la carte réseau NIC
# Sans cette association, les règles NSG ne s'appliquent pas
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# La VM Linux Ubuntu elle-même
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"        # Plus petite VM Azure — 1 CPU, 1 Go RAM
  admin_username      = var.admin_username

  # Connecte la VM à la carte réseau créée au-dessus
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  # Authentification par clé SSH — plus sécurisé qu'un mot de passe
  # Lit votre clé publique SSH sur votre machine locale
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub") # Votre clé publique locale
  }

  # Disque système de la VM
  os_disk {
    caching              = "ReadWrite"    # Cache lecture/écriture pour meilleures performances
    storage_account_type = "Standard_LRS" # Disque HDD standard — moins cher pour un lab
  }

  # Image du système d'exploitation — Ubuntu 22.04 LTS officiel
  source_image_reference {
    publisher = "Canonical"                    # Éditeur officiel Ubuntu
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 Jammy
    sku       = "22_04-lts"                    # Version LTS (Long Term Support)
    version   = "latest"                       # Dernière version disponible
  }

  # Script exécuté automatiquement au premier démarrage de la VM
  # base64encode() encode le script pour l'envoyer proprement à Azure
  user_data = base64encode(<<-EOF
    #!/bin/bash

    # Mise à jour des paquets Ubuntu
    apt-get update -y
    apt-get upgrade -y

    # Installation de Docker
    curl -fsSL https://get.docker.com | sh

    # Ajoute adminuser au groupe docker pour éviter sudo
    usermod -aG docker ${var.admin_username}

    # Crée le dossier de l'app
    mkdir -p /app
    cd /app

    # Crée le Dockerfile
    cat > Dockerfile <<'DOCKERFILE'
    FROM php:8.2-apache
    COPY index.php /var/www/html/index.php
    EXPOSE 80
    DOCKERFILE

    # Crée la page PHP
    cat > index.php <<'PHP'
    <?php
    echo "<h1>vm-lab</h1>";
    echo "<p>Hostname : " . gethostname() . "</p>";
    echo "<p>IP : " . $_SERVER['SERVER_ADDR'] . "</p>";
    echo "<p>Deployed via Terraform user_data + Docker</p>";
    PHP

    # Build et run du conteneur
    docker build -t vm-app .
    docker run -d \
      --name vm-app \
      --restart always \
      -p 80:80 \
      vm-app
  EOF
  )
}