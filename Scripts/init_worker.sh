#!/bin/bash

#############################################################################
# Script : init_worker.sh
# Description : Initialiser un nœud en tant que Worker Swarm
# Utilisation : sudo bash init_worker.sh <TOKEN> <MANAGER_IP>
# Exemple : sudo bash init_worker.sh "SWMTKN-1-..." 192.168.1.10
#############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonctions
print_step() {
    echo -e "${BLUE}[ÉTAPE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓ OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗ ERREUR]${NC} $1"
}

# Vérifier les paramètres
if [ -z "$1" ] || [ -z "$2" ]; then
    print_error "Paramètres manquants"
    echo "Usage: sudo bash init_worker.sh <TOKEN> <MANAGER_IP>"
    echo "Exemple: sudo bash init_worker.sh 'SWMTKN-1-...' 192.168.1.10"
    exit 1
fi

TOKEN=$1
MANAGER_IP=$2

# Vérifier root
if [ "$EUID" -ne 0 ]; then 
    print_error "Ce script doit être exécuté avec sudo"
    exit 1
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   Initialisation d'un Worker Swarm                          ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   Manager: ${MANAGER_IP}                                   ${BLUE}║${NC}"
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
    net-tools \
    nfs-common > /dev/null 2>&1
print_success "Dépendances installées"

# ============================================================================
# Étape 3 : Synchroniser NTP
# ============================================================================

print_step "Synchronisation de l'horloge NTP..."
systemctl restart ntp > /dev/null 2>&1
sleep 2
print_success "NTP synchronisé"

# ============================================================================
# Étape 4 : Installer Docker Engine
# ============================================================================

print_step "Installation de Docker Engine..."

mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update > /dev/null 2>&1
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null 2>&1

print_success "Docker Engine installé"

DOCKER_VERSION=$(docker --version)
print_success "Version: $DOCKER_VERSION"

# ============================================================================
# Étape 5 : Configurer Docker
# ============================================================================

print_step "Configuration de Docker..."

groupadd docker 2>/dev/null || true
usermod -aG docker debian 2>/dev/null || true

systemctl enable docker > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1

sleep 2
print_success "Docker configuré"

# ============================================================================
# Étape 6 : Ouvrir les ports Swarm
# ============================================================================

print_step "Ouverture des ports Swarm..."

ufw allow 2377/tcp > /dev/null 2>&1 || true
ufw allow 7946/tcp > /dev/null 2>&1 || true
ufw allow 7946/udp > /dev/null 2>&1 || true
ufw allow 4789/udp > /dev/null 2>&1 || true
ufw allow 22/tcp > /dev/null 2>&1 || true

print_success "Ports ouverts"

# ============================================================================
# Étape 7 : Joindre le Swarm
# ============================================================================

print_step "Jonction au cluster Swarm..."

# Attendre que le Manager soit accessible
RETRIES=0
MAX_RETRIES=10

while [ $RETRIES -lt $MAX_RETRIES ]; do
    if ping -c 1 $MANAGER_IP > /dev/null 2>&1; then
        break
    fi
    print_step "Attente du Manager ($RETRIES/$MAX_RETRIES)..."
    sleep 2
    RETRIES=$((RETRIES + 1))
done

if [ $RETRIES -ge $MAX_RETRIES ]; then
    print_error "Manager $MANAGER_IP non accessible"
    exit 1
fi

# Joindre le Swarm
if docker swarm join --token $TOKEN $MANAGER_IP:2377 > /dev/null 2>&1; then
    print_success "Worker joint au Swarm"
else
    print_error "Impossible de joindre le Swarm"
    print_error "Vérifier le token et l'IP du Manager"
    exit 1
fi

# ============================================================================
# Résumé
# ============================================================================

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Worker initialisé avec succès !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Obtenir le nom du nœud
NODE_NAME=$(docker info --format '{{.Swarm.NodeID}}' | cut -c1-12)

echo "Node ID: $NODE_NAME"
echo "Manager: $MANAGER_IP"
echo ""
echo "Pour vérifier depuis le Manager :"
echo "  docker node ls"
echo "  docker service ps"
echo ""
