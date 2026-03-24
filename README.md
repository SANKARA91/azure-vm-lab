# azure-vm-lab

> VM Linux Ubuntu sur Azure — provisionnée en IaC, application conteneurisée déployée via CI/CD.

Projet réalisé pour démontrer le provisioning d'une infrastructure Azure avec Terraform, le déploiement automatique d'une application Docker sur une VM Linux, et un pipeline CI/CD GitHub Actions qui redéploie à chaque push.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub                               │
│  push → GitHub Actions → scp app/ → ssh docker rebuild     │
└──────────────────────────────┬──────────────────────────────┘
                               │
        ┌──────────────────────▼──────────────────────┐
        │               Azure (vm-lab-rg)              │
        │                                              │
        │   ┌──────────────────────────────────────┐  │
        │   │         vm-lab-vnet (10.0.0.0/16)    │  │
        │   │                                      │  │
        │   │   ┌──────────────────────────────┐   │  │
        │   │   │   vm-lab-subnet (10.0.1.0/24)│   │  │
        │   │   │                              │   │  │
        │   │   │   ┌──────────────────────┐   │   │  │
        │   │   │   │   vm-lab-vm          │   │   │  │
        │   │   │   │   Ubuntu 22.04 LTS   │   │   │  │
        │   │   │   │   Standard_D2s_v3    │   │   │  │
        │   │   │   │                      │   │   │  │
        │   │   │   │   Docker Container   │   │   │  │
        │   │   │   │   PHP Apache :80     │   │   │  │
        │   │   │   └──────────────────────┘   │   │  │
        │   │   └──────────────────────────────┘   │  │
        │   └──────────────────────────────────────┘  │
        │                                              │
        │   NSG : SSH (22) + HTTP (80) autorisés       │
        │   IP publique statique                       │
        └──────────────────────────────────────────────┘
```

---

## Stack technique

| Outil | Rôle |
|-------|------|
| Terraform | Provisioning IaC : VM, VNet, Subnet, NSG, IP publique |
| Azure VM | Ubuntu 22.04 LTS (Standard_D2s_v3) |
| Docker | Conteneurisation de l'application PHP Apache |
| user_data | Script d'installation automatique au démarrage de la VM |
| GitHub Actions | Pipeline CI/CD : scp app → rebuild Docker → restart conteneur |

---

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3.0
- [Azure CLI](https://learn.microsoft.com/fr-fr/cli/azure/install-azure-cli) installé et configuré
- Une clé SSH sur votre machine (`~/.ssh/id_rsa.pub`)
- Un compte Azure avec une subscription active
- Un repo GitHub avec les secrets configurés

---

## Installation

### 1. Cloner le repo

```bash
git clone https://github.com/SANKARA91/azure-vm-lab.git
cd azure-vm-lab
```

### 2. Se connecter à Azure

```bash
az login --tenant <TENANT_ID>
az account set --subscription <SUBSCRIPTION_ID>
```

### 3. Vérifier la clé SSH

```bash
ls ~/.ssh/id_rsa.pub
```

Si elle n'existe pas :

```bash
ssh-keygen -t rsa -b 4096
```

### 4. Provisionner l'infrastructure avec Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

À la fin, Terraform affiche les outputs :

```
public_ip      = "X.X.X.X"
resource_group = "vm-lab-rg"
ssh_command    = "ssh adminuser@X.X.X.X"
```

### 5. Se connecter à la VM

```bash
ssh adminuser@<public_ip>
```

### 6. Vérifier le conteneur Docker

```bash
docker ps
```

L'application est accessible dans le navigateur :

```
http://<public_ip>
```

---

## Pipeline CI/CD

Le pipeline GitHub Actions se déclenche automatiquement à chaque `push` sur `main` :

```
push → checkout → scp app/ vers VM → ssh rebuild Docker → restart conteneur
```

### Secrets GitHub à configurer

| Secret | Valeur |
|--------|--------|
| `VM_IP` | IP publique de la VM |
| `VM_USER` | `adminuser` |
| `SSH_PRIVATE_KEY` | Contenu complet de `~/.ssh/id_rsa` |

---

## Structure du projet

```
azure-vm-lab/
├── .github/
│   └── workflows/
│       └── deploy.yml        # Pipeline CI/CD GitHub Actions
├── app/
│   ├── Dockerfile            # Image PHP Apache
│   └── index.php             # Application (hostname + IP)
├── terraform/
│   ├── main.tf               # VM + VNet + Subnet + NSG + IP publique
│   ├── provider.tf           # Provider azurerm
│   ├── variables.tf          # Variables configurables
│   └── outputs.tf            # IP publique + commande SSH
└── README.md
```

---

## Commandes utiles

```bash
# Se connecter à la VM
ssh adminuser@<public_ip>

# Voir les conteneurs en cours
docker ps

# Voir les logs du conteneur
docker logs vm-app

# Redémarrer le conteneur manuellement
docker restart vm-app

# Voir les logs du script user_data
sudo cat /var/log/cloud-init-output.log

# Détruire toute l'infrastructure
cd terraform && terraform destroy
```

---

## Points techniques notables

user_data : Le script d'installation s'exécute automatiquement au premier démarrage de la VM  Docker est installé et le conteneur est lancé sans intervention manuelle. C'est l'équivalent d'un Ansible playbook simplifié pour un cas d'usage léger.

Authentification SSH par clé: Aucun mot de passe n'est utilisé pour accéder à la VM uniquement une clé SSH. Plus sécurisé et compatible avec les pipelines CI/CD automatisés.

NSG : Le Network Security Group n'autorise que les ports 22 (SSH) et 80 (HTTP)  tous les autres ports sont bloqués par défaut. Principe du moindre privilège appliqué au réseau.

IP publique statique : L'IP ne change pas au redémarrage de la VM  les secrets GitHub `VM_IP` restent valides sans mise à jour manuelle.

---

## Améliorations futures

- Ajouter HTTPSavec un certificat Let's Encrypt via Certbot
- Remplacer le `user_data` par Ansible pour plus de flexibilité
- Ajouter Watchtower pour les mises à jour automatiques des images Docker
- Configurer un backend Terraform distant (Azure Storage) pour le tfstate en équipe
- Ajouter une supervision avec Uptime Kuma

---

## Auteur

Boureima SANKARA — Ingénieur Systèmes, Réseaux & Sécurité Cloud  
[GitHub](https://github.com/SANKARA91) · [LinkedIn](https://linkedin.com/in/boureima-sankara)