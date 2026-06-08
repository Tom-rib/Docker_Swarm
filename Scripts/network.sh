#!/bin/bash

#############################################################################
# Script: setup_network_static.sh
# Description: Configuration réseau COMPLÈTE
#              - ens33: DHCP (internet) - priorité 100
#              - ens37: IP statique (10.0.0.x cluster) - priorité 200
#              - /etc/hosts, sysctl, nftables
# Usage: sudo bash setup_network_static.sh <ROLE>
# Exemples:
#   sudo bash setup_network_static.sh manager1
#   sudo bash setup_network_static.sh worker1
#############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

# Vérification des paramètres
if [ -z "$1" ]; then
    print_error "Rôle non fourni"
    echo "Usage: sudo bash setup_network_static.sh <ROLE>"
    echo ""
    echo "Rôles disponibles:"
    echo "  - manager1"
    echo "  - worker1, worker2, worker3"
    echo "  - serveurnfs, backupnfs"
    exit 1
fi

ROLE=$1

if [ "$EUID" -ne 0 ]; then 
    print_error "Ce script doit être exécuté avec sudo"
    exit 1
fi

# ============================================================================
# DÉFINITION DE LA TOPOLOGIE
# ============================================================================

# IPs INTERNE (10.0.0.0/24) - STATIQUE
declare -A HOSTS_INTERNE=(
    [manager1]="10.0.0.100"
    [worker1]="10.0.0.101"
    [worker2]="10.0.0.102"
    [worker3]="10.0.0.103"
    [serveurnfs]="10.0.0.104"
    [backupnfs]="10.0.0.105"
)

# Vérifier que le rôle existe
if [ -z "${HOSTS_INTERNE[$ROLE]}" ]; then
    print_error "Rôle '$ROLE' inconnu"
    echo "Rôles valides: ${!HOSTS_INTERNE[@]}"
    exit 1
fi

IP_INTERNE=${HOSTS_INTERNE[$ROLE]}
GATEWAY_INTERNE="10.0.0.1"
NETMASK_INTERNE="255.255.255.0"
IFACE_INTERNE="ens37"

# Affichage du header
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   Configuration Réseau - Docker Swarm Cluster               ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   Rôle: ${ROLE}                                             ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   ens33 (DHCP): Internet                                  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   ens37 (Static): ${IP_INTERNE}                              ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# ÉTAPE 1: /etc/network/interfaces (DHCP + STATIQUE avec métriques)
# ============================================================================

print_step "Configuration de /etc/network/interfaces (DHCP + STATIQUE avec métriques)..."

cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

# Interface DHCP (ens33) - Internet
# metric 100 = priorité haute pour le routage par défaut (internet)
auto ens33
iface ens33 inet dhcp
    dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1
    metric 100

# Interface STATIQUE (ens37) - Cluster interne 10.0.0.0/24
# metric 200 = priorité basse pour le cluster interne
auto ens37
iface ens37 inet static
    address ${IP_INTERNE}
    netmask ${NETMASK_INTERNE}
    gateway ${GATEWAY_INTERNE}
    metric 200
EOF

print_success "Fichier /etc/network/interfaces créé (DHCP + STATIC avec métriques)"

# ============================================================================
# ÉTAPE 2: /etc/hosts
# ============================================================================

print_step "Configuration de /etc/hosts..."

cat > /etc/hosts << 'EOFHOSTS'
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

# Cluster - Réseau INTERNE (10.0.0.x - statique)
10.0.0.100      manager1
10.0.0.101      worker1
10.0.0.102      worker2
10.0.0.103      worker3
10.0.0.104      serveurnfs
10.0.0.105      backupnfs

# Gateways
10.0.0.1        cluster-gateway
EOFHOSTS

print_success "Fichier /etc/hosts créé"

# ============================================================================
# ÉTAPE 3: sysctl (forwards)
# ============================================================================

print_step "Activation des forwards IPv4/IPv6..."

# Supprimer les lignes existantes pour éviter les doublons
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
sed -i '/net.ipv6.conf.all.forwarding/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.conf

# Ajouter les lignes
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.conf

sysctl -p > /dev/null 2>&1

print_success "Forwards activés"

# ============================================================================
# ÉTAPE 4: nftables
# ============================================================================

print_step "Installation et configuration de nftables..."

if ! command -v nft &> /dev/null; then
    apt-get update -qq
    apt-get install -y nftables > /dev/null 2>&1
fi

systemctl enable nftables > /dev/null 2>&1

cat > /etc/nftables.conf << 'EOFNFT'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        iif lo accept
        ct state established,related accept
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        tcp dport 22 accept
        tcp dport 2376 accept
        tcp dport 2377 accept
        tcp dport 7946 accept
        udp dport 7946 accept
        udp dport 4789 accept
        tcp dport 111 accept
        tcp dport 2049 accept
        udp dport 111 accept
        udp dport 2049 accept
        tcp dport 53 accept
        udp dport 53 accept
        tcp dport 80 accept
        tcp dport 443 accept
        counter reject with icmp type port-unreachable
    }
    
    chain forward {
        type filter hook forward priority 0; policy accept;
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}

table inet nat {
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
    }
}
EOFNFT

nft -f /etc/nftables.conf 2>/dev/null || true

print_success "nftables configuré"

# ============================================================================
# ÉTAPE 5: Redémarrage du réseau
# ============================================================================

print_step "Redémarrage du service réseau..."

ip addr flush dev ens33 2>/dev/null || true
ip addr flush dev ens37 2>/dev/null || true

systemctl restart networking

sleep 3

print_success "Service réseau redémarré"

# ============================================================================
# ÉTAPE 6: Vérifications
# ============================================================================

print_step "Vérification de la configuration..."
echo ""

echo -e "${YELLOW}📌 Interface NAT (ens33 - 192.168.136.x):${NC}"
ip addr show ens33 2>/dev/null | grep "inet " | awk '{print "   ➜ " $2}' || echo "   [Interface non trouvée]"
echo ""

echo -e "${YELLOW}📌 Interface INTERNE (ens37 - 10.0.0.x):${NC}"
ip addr show ens37 2>/dev/null | grep "inet " | awk '{print "   ➜ " $2}' || echo "   [Interface non trouvée]"
echo ""

echo -e "${YELLOW}🔗 Test connectivité INTERNE (10.0.0.1):${NC}"
if ping -c 1 -W 2 10.0.0.1 &>/dev/null; then
    print_success "Gateway interne accessible"
else
    print_warning "Gateway interne non accessible"
fi
echo ""

echo -e "${YELLOW}🌐 Test connectivité NAT (192.168.136.1):${NC}"
if ping -c 1 -W 2 192.168.136.1 &>/dev/null; then
    print_success "Gateway NAT accessible"
else
    print_warning "Gateway NAT non accessible"
fi
echo ""

echo -e "${YELLOW}🌍 Test internet (8.8.8.8):${NC}"
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    print_success "Internet accessible"
else
    print_warning "Internet non accessible"
fi
echo ""

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================

echo -e "${GREEN}═════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Configuration réseau terminée !${NC}"
echo -e "${GREEN}═════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "📋 RÉSUMÉ DE CONFIGURATION:"
echo "   Rôle: ${ROLE}"
echo ""
echo "   🌐 Interface DHCP (ens33) - Internet:"
echo "      • Mode: DHCP (IP dynamique)"
echo "      • Métrique: 100 (priorité haute)"
echo "      • DNS: 8.8.8.8, 8.8.4.4, 1.1.1.1"
echo ""
echo "   🔗 Interface STATIQUE (ens37) - Cluster interne:"
echo "      • IP: ${IP_INTERNE}/${NETMASK_INTERNE}"
echo "      • Gateway: ${GATEWAY_INTERNE}"
echo "      • Métrique: 200 (priorité basse)"
echo ""
echo "📁 Fichiers modifiés:"
echo "   • /etc/network/interfaces (DHCP + STATIC avec métriques)"
echo "   • /etc/hosts (noms du cluster)"
echo "   • /etc/sysctl.conf (forwards IPv4/IPv6)"
echo "   • /etc/nftables.conf (firewall)"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. Vérifier internet: ping 8.8.8.8"
echo "   2. Vérifier réseau interne: ping 10.0.0.1"
echo "   3. Vérifier inter-VM: ping manager1"
echo "   4. Redémarrer pour stabiliser: sudo reboot"
echo "   5. Répéter pour les autres VMs"
echo ""