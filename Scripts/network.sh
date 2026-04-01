#!/bin/bash

#############################################################################
# Script : setup_network.sh
# Description : Configurer l'IP statique et /etc/hosts pour le cluster Swarm
# Utilisation : sudo bash setup_network.sh <ROLE>
# Exemple : sudo bash setup_network.sh manager1
#           sudo bash setup_network.sh worker1


#    commande:
#    sudo bash net.sh nom_du_role



#############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    print_error "Rôle non fourni"
    echo "Usage: sudo bash setup_network.sh <ROLE>"
    echo ""
    echo "Rôles disponibles:"
    echo "  - manager1"
    echo "  - worker1"
    echo "  - worker2"
    echo "  - worker3"
    echo "  - serveurnfs"
    echo "  - backupnfs"
    exit 1
fi

ROLE=$1

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then 
    print_error "Ce script doit être exécuté avec sudo"
    exit 1
fi

# Définir la topologie du cluster
declare -A HOSTS=(
    [manager1]="192.168.136.100"
    [worker1]="192.168.136.101"
    [worker2]="192.168.136.102"
    [worker3]="192.168.136.103"
    [serveurnfs]="192.168.136.104"
    [backupnfs]="192.168.136.105"
)

# Vérifier que le rôle existe
if [ -z "${HOSTS[$ROLE]}" ]; then
    print_error "Rôle '$ROLE' inconnu"
    echo "Rôles valides: ${!HOSTS[@]}"
    exit 1
fi

IP=${HOSTS[$ROLE]}
GATEWAY="192.168.136.1"
NETMASK="255.255.255.0"
INTERFACE="ens33"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   Configuration Réseau - Cluster Docker Swarm               ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   Rôle: ${ROLE}                                              ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   IP: ${IP}                                         ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Étape 1 : Configurer /etc/network/interfaces
# ============================================================================

print_step "Configuration de /etc/network/interfaces..."

cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto $INTERFACE
iface $INTERFACE inet static
    address $IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers 8.8.8.8 8.8.4.4
EOF

print_success "Fichier /etc/network/interfaces créé"

# ============================================================================
# Étape 2 : Configurer /etc/hosts
# ============================================================================

print_step "Configuration de /etc/hosts..."

cat > /etc/hosts << EOF
127.0.0.1       localhost
::1             localhost

# Cluster Docker Swarm
192.168.136.100 manager1
192.168.136.101 worker1
192.168.136.102 worker2
192.168.136.103 worker3
192.168.136.104 serveurnfs
192.168.136.105 backupnfs
EOF

print_success "Fichier /etc/hosts créé"

# ============================================================================
# Étape 3 : Appliquer la configuration réseau
# ============================================================================

print_step "Application de la configuration réseau..."

# Nettoyer l'ancienne IP
ip addr flush dev $INTERFACE 2>/dev/null || true

# Redémarrer le service réseau
systemctl restart networking

# Attendre un peu que l'IP soit assignée
sleep 2

print_success "Réseau redémarré"

# ============================================================================
# Étape 4 : Vérification
# ============================================================================

print_step "Vérification de la configuration..."
echo ""

# Afficher l'IP assignée
echo -e "${YELLOW}IP assignée:${NC}"
ip addr show $INTERFACE | grep "inet " | awk '{print $2}'
echo ""

# Vérifier la gateway
echo -e "${YELLOW}Routage par défaut:${NC}"
ip route show default | head -1
echo ""

# Vérifier les DNS
echo -e "${YELLOW}Résolveurs DNS:${NC}"
grep -E "nameserver|dns-nameservers" /etc/network/interfaces | grep -v "^#"
echo ""

# Vérifier la connectivité
echo -e "${YELLOW}Vérification de la connectivité:${NC}"

# Test ping vers la gateway
if ping -c 1 -W 2 $GATEWAY &>/dev/null; then
    print_success "Gateway accessible ($GATEWAY)"
else
    print_warning "Gateway non accessible ($GATEWAY)"
fi

# Test ping vers 8.8.8.8
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    print_success "Internet accessible"
else
    print_warning "Internet non accessible (vérifier la gateway)"
fi

echo ""

# ============================================================================
# Résumé final
# ============================================================================

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Configuration réseau terminée !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Rôle: $ROLE"
echo "IP: $IP"
echo "Interface: $INTERFACE"
echo "Gateway: $GATEWAY"
echo "Fichiers modifiés: /etc/network/interfaces, /etc/hosts"
echo ""
echo "Prochaines étapes:"
echo "1. Vérifier la connectivité : ping manager1"
echo "2. Lancer le script init_manager.sh ou init_worker.sh"
echo ""