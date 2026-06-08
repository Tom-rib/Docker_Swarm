#!/bin/bash

#############################################################################
# Script : init_manager.sh
# Description : Initialiser un nœud en tant que Manager Swarm
# Utilisation : sudo bash init_manager.sh <MANAGER_IP>
# Exemple : sudo bash init_manager.sh 192.168.136.100
#############################################################################

set -e  # Arrêter si une erreur survient

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions d'affichage
print_step() {
    echo -e "${BLUE}[ÉTAPE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓ OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗ ERREUR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠ ATTENTION]${NC} $1"
}

# Vérifier les paramètres
if [ -z "$1" ]; then
    print_error "IP du Manager non fournie"
    echo "Usage: sudo bash init_manager.sh <MANAGER_IP>"
    echo "Exemple: sudo bash init_manager.sh 192.168.136.100"
    exit 1
fi

MANAGER_IP=$1

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then 
    print_error "Ce script doit être exécuté avec sudo"
    exit 1
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   Initialisation du Manager Swarm                            ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   Manager IP: ${MANAGER_IP}                                 ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Étape 1 : Mettre à jour le système
# ============================================================================

print_step "Mise à jour du système..."
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
print_success "Système mis à jour"

# ============================================================================
# Étape 2 : Installer les dépendances
# ============================================================================

print_step "Installation des dépendances..."
apt install -y \
    curl \
    wget \
    git \
    vim \
    ntp \
    openssh-server \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    net-tools > /dev/null 2>&1
print_success "Dépendances installées"

# ============================================================================
# Étape 3 : Vérifier la synchronisation NTP
# ============================================================================

print_step "Vérification de la synchronisation NTP..."
systemctl restart ntp > /dev/null 2>&1
sleep 2

NTP_STATUS=$(timedatectl status | grep -i "synchronized" | grep -i "yes" || echo "NOK")
if [ "$NTP_STATUS" != "NOK" ]; then
    print_success "NTP synchronisé"
else
    print_warning "NTP non synchronisé, synchronisation manuelle..."
    ntpdate -s pool.ntp.org 2>/dev/null || true
    systemctl restart ntp
    sleep 2
    print_success "NTP resynchronisé"
fi

# ============================================================================
# Étape 4 : Installer Docker Engine
# ============================================================================

print_step "Installation de Docker Engine..."

# Créer le répertoire keyrings
mkdir -p /etc/apt/keyrings

# Télécharger la clé GPG
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null

# Ajouter le dépôt Docker
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
apt update > /dev/null 2>&1
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null 2>&1

print_success "Docker Engine installé"

# Vérifier Docker
DOCKER_VERSION=$(docker --version)
print_success "Version: $DOCKER_VERSION"

# ============================================================================
# Étape 5 : Configurer Docker
# ============================================================================

print_step "Configuration de Docker..."

# Créer le groupe docker
groupadd docker 2>/dev/null || true

# Ajouter l'utilisateur debian au groupe
usermod -aG docker debian 2>/dev/null || true

# Démarrer Docker
systemctl enable docker > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1

# Attendre que Docker soit prêt
sleep 2

print_success "Docker configuré et démarré"

# ============================================================================
# Étape 6 : Ouvrir les ports Swarm
# ============================================================================

print_step "Ouverture des ports Swarm..."

ufw allow 2377/tcp > /dev/null 2>&1 || true
ufw allow 7946/tcp > /dev/null 2>&1 || true
ufw allow 7946/udp > /dev/null 2>&1 || true
ufw allow 4789/udp > /dev/null 2>&1 || true
ufw allow 22/tcp > /dev/null 2>&1 || true  # SSH

print_success "Ports ouverts (2377, 7946, 4789)"

# ============================================================================
# Étape 7 : Initialiser le Swarm
# ============================================================================

print_step "Initialisation du Swarm..."

# Vérifier si le Swarm est déjà initialisé
if docker info | grep -q "Swarm: active"; then
    print_warning "Swarm déjà initialisé sur ce nœud"
else
    docker swarm init --advertise-addr $MANAGER_IP > /dev/null 2>&1
    print_success "Swarm initialisé"
fi

# ============================================================================
# Étape 8 : Récupérer et afficher les tokens
# ============================================================================

print_step "Récupération des tokens..."

WORKER_TOKEN=$(docker swarm join-token worker -q)
MANAGER_TOKEN=$(docker swarm join-token manager -q)

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}   Configuration du Swarm Complète !                          ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_success "Manager initialisé avec succès"
echo ""

echo -e "${YELLOW}Pour joindre les WORKERS, utilisez cette commande:${NC}"
echo -e "${BLUE}docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377${NC}"
echo ""

echo -e "${YELLOW}Pour promouvoir un nœud en MANAGER, utilisez:${NC}"
echo -e "${BLUE}docker swarm join --token $MANAGER_TOKEN $MANAGER_IP:2377${NC}"
echo ""

# Afficher l'état du cluster
echo -e "${YELLOW}État actuel du Swarm:${NC}"
docker node ls
echo ""

# Créer un fichier avec les tokens pour facilité
TOKENS_FILE="/tmp/swarm-tokens.txt"
cat > $TOKENS_FILE << EOF
=== DOCKER SWARM TOKENS ===
Generated: $(date)
Manager IP: $MANAGER_IP

WORKER TOKEN:
$WORKER_TOKEN

MANAGER TOKEN:
$MANAGER_TOKEN

Command to join workers:
docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377

Command to join managers:
docker swarm join --token $MANAGER_TOKEN $MANAGER_IP:2377
EOF

print_success "Tokens sauvegardés dans: $TOKENS_FILE"
echo ""

# Résumé final
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Manager Swarm initialisé avec succès !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Prochaines étapes :"
echo "1. Initialiser les Worker avec les tokens fournis"
echo "2. Vérifier l'état : docker node ls"
echo "3. Créer les réseaux overlay"
echo "4. Déployer les services"
echo ""
