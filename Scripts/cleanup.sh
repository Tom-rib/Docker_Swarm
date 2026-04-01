#!/bin/bash

#############################################################################
# Script : cleanup.sh
# Description : Nettoyer et supprimer tous les services du Swarm
# Utilisation : bash cleanup.sh [option]
# Options : --full (supprime aussi les volumes et réseaux)
#############################################################################

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

print_warning() {
    echo -e "${YELLOW}[⚠ ATTENTION]${NC} $1"
}

# Vérifier Manager
if ! docker info | grep -q "Swarm: active"; then
    echo -e "${RED}[✗ ERREUR]${NC} Ce script doit être lancé sur un Manager Swarm"
    exit 1
fi

# Affichage de confirmation
echo ""
echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}   ATTENTION : Nettoyage du Cluster Swarm                    ${RED}║${NC}"
echo -e "${RED}║${NC}   Tous les services et conteneurs vont être supprimés !     ${RED}║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Demander confirmation
read -p "Êtes-vous sûr ? (oui/non) : " CONFIRM

if [ "$CONFIRM" != "oui" ] && [ "$CONFIRM" != "yes" ]; then
    echo "Opération annulée"
    exit 0
fi

echo ""
print_step "Démarrage du nettoyage..."
echo ""

# ============================================================================
# Étape 1 : Supprimer tous les services
# ============================================================================

print_step "Suppression des services..."

SERVICES=$(docker service ls -q)
if [ -z "$SERVICES" ]; then
    print_warning "Aucun service trouvé"
else
    for service in $SERVICES; do
        SERVICE_NAME=$(docker service inspect $service --format '{{.Spec.Name}}')
        docker service rm $service > /dev/null 2>&1
        print_success "Service '$SERVICE_NAME' supprimé"
    done
fi

sleep 2

# ============================================================================
# Étape 2 : Supprimer les conteneurs arrêtés
# ============================================================================

print_step "Nettoyage des conteneurs..."

docker container prune -f > /dev/null 2>&1
print_success "Conteneurs arrêtés nettoyés"

# ============================================================================
# Étape 3 : Options de nettoyage complet
# ============================================================================

if [ "$1" == "--full" ] || [ "$1" == "-f" ]; then
    
    print_warning "Mode nettoyage COMPLET activé"
    echo ""
    
    # Supprimer les réseaux overlay
    print_step "Suppression des réseaux overlay..."
    
    NETWORKS=$(docker network ls -f driver=overlay -q | grep -v "^ingress$")
    if [ -z "$NETWORKS" ]; then
        print_warning "Aucun réseau overlay à supprimer"
    else
        for network in $NETWORKS; do
            NETWORK_NAME=$(docker network inspect $network --format '{{.Name}}')
            docker network rm $network > /dev/null 2>&1
            print_success "Réseau '$NETWORK_NAME' supprimé"
        done
    fi
    
    # Supprimer les volumes
    print_step "Suppression des volumes..."
    
    docker volume prune -f > /dev/null 2>&1
    print_success "Volumes inutilisés supprimés"
    
    # Nettoyer les images (optionnel)
    read -p "Supprimer aussi les images Docker non utilisées ? (oui/non) : " IMAGES_CONFIRM
    
    if [ "$IMAGES_CONFIRM" = "oui" ] || [ "$IMAGES_CONFIRM" = "yes" ]; then
        print_step "Suppression des images..."
        docker image prune -a -f > /dev/null 2>&1
        print_success "Images inutilisées supprimées"
    fi
    
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
print_success "Nettoyage terminé !"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Afficher l'état final
echo "État final du cluster :"
echo ""
print_step "Services restants :"
docker service ls | head -5

echo ""
print_step "Volumes restants :"
docker volume ls | head -5

echo ""
print_step "Réseaux restants :"
docker network ls | head -5

echo ""
echo "Le cluster Swarm est prêt pour un redéploiement."
echo ""
