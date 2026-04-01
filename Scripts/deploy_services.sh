#!/bin/bash

#############################################################################
# Script : deploy_services.sh
# Description : Déployer tous les services sur le Swarm
# Utilisation : bash deploy_services.sh <NFS_IP>
# Exemple : bash deploy_services.sh 192.168.1.20
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

# Vérifier que on est sur le Manager
if ! docker info | grep -q "Swarm: active"; then
    print_error "Ce script doit être lancé sur un Manager Swarm"
    exit 1
fi

NFS_IP=${1:-"192.168.1.20"}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   Déploiement des Services Swarm                           ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   NFS Server: ${NFS_IP}                                    ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Étape 1 : Créer le réseau overlay
# ============================================================================

print_step "Création du réseau overlay..."

if docker network ls | grep -q "swarm-network"; then
    print_step "Réseau 'swarm-network' déjà existe, passage..."
else
    docker network create \
        --driver overlay \
        --attachable \
        swarm-network > /dev/null 2>&1
    print_success "Réseau 'swarm-network' créé"
fi

# ============================================================================
# Étape 2 : Créer les volumes NFS
# ============================================================================

print_step "Création des volumes Docker (NFS)..."

create_volume() {
    local VOLUME_NAME=$1
    local NFS_PATH=$2
    
    if docker volume ls | grep -q "^local.*$VOLUME_NAME"; then
        print_step "Volume '$VOLUME_NAME' existe déjà"
    else
        docker volume create \
            --driver local \
            --opt type=nfs \
            --opt o=addr=$NFS_IP,vers=4,soft,timeo=180 \
            --opt device=:$NFS_PATH \
            $VOLUME_NAME > /dev/null 2>&1
        print_success "Volume '$VOLUME_NAME' créé"
    fi
}

create_volume "vol-mariadb" "/export/docker/mariadb"
create_volume "vol-nginx" "/export/docker/nginx"
create_volume "vol-app" "/export/docker/app"
create_volume "vol-registry" "/export/docker/registry"

# ============================================================================
# Étape 3 : Déployer MariaDB
# ============================================================================

print_step "Déploiement de MariaDB..."

if docker service ls | grep -q "mariadb"; then
    print_step "Service 'mariadb' existe déjà, passage..."
else
    docker service create \
        --name mariadb \
        --replicas 2 \
        --network swarm-network \
        --publish 3306:3306 \
        --env MYSQL_ROOT_PASSWORD=RootPassword123! \
        --env MYSQL_DATABASE=app_db \
        --env MYSQL_USER=appuser \
        --env MYSQL_PASSWORD=AppPassword123! \
        --mount type=volume,source=vol-mariadb,target=/var/lib/mysql \
        --constraint node.role==worker \
        mariadb:latest > /dev/null 2>&1
    
    print_success "Service 'mariadb' créé"
    print_step "⏳ Attendre le démarrage de MariaDB (15-30s)..."
    sleep 20
fi

# ============================================================================
# Étape 4 : Déployer Nginx
# ============================================================================

print_step "Déploiement de Nginx..."

if docker service ls | grep -q "nginx"; then
    print_step "Service 'nginx' existe déjà, passage..."
else
    docker service create \
        --name nginx \
        --replicas 2 \
        --network swarm-network \
        --publish 80:80 \
        --publish 443:443 \
        --mount type=volume,source=vol-nginx,target=/etc/nginx/conf.d \
        --constraint node.role==worker \
        nginx:latest > /dev/null 2>&1
    
    print_success "Service 'nginx' créé"
fi

# ============================================================================
# Étape 5 : Déployer PHP-FPM
# ============================================================================

print_step "Déploiement de PHP-FPM..."

if docker service ls | grep -q "php-fpm"; then
    print_step "Service 'php-fpm' existe déjà, passage..."
else
    docker service create \
        --name php-fpm \
        --replicas 2 \
        --network swarm-network \
        --env MYSQL_HOST=mariadb \
        --env MYSQL_DATABASE=app_db \
        --env MYSQL_USER=appuser \
        --env MYSQL_PASSWORD=AppPassword123! \
        --mount type=volume,source=vol-app,target=/var/www/html \
        --constraint node.role==worker \
        php:8.2-fpm > /dev/null 2>&1
    
    print_success "Service 'php-fpm' créé"
fi

# ============================================================================
# Étape 6 : Déployer Registry
# ============================================================================

print_step "Déploiement du Registry interne..."

if docker service ls | grep -q "registry"; then
    print_step "Service 'registry' existe déjà, passage..."
else
    docker service create \
        --name registry \
        --replicas 1 \
        --network swarm-network \
        --publish 5000:5000 \
        --mount type=volume,source=vol-registry,target=/var/lib/registry \
        --constraint node.role==manager \
        registry:2 > /dev/null 2>&1
    
    print_success "Service 'registry' créé"
fi

# ============================================================================
# Résumé
# ============================================================================

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Services déployés avec succès !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Afficher l'état des services
echo -e "${YELLOW}État des services:${NC}"
docker service ls
echo ""

# Afficher les tâches
echo -e "${YELLOW}Détail des tâches par service:${NC}"
for service in mariadb nginx php-fpm registry; do
    if docker service ls | grep -q "$service"; then
        echo ""
        echo -e "${BLUE}Service: $service${NC}"
        docker service ps $service --no-trunc | head -5
    fi
done

echo ""
echo -e "${YELLOW}Tests de connectivité:${NC}"
echo "Nginx (HTTP) : curl http://localhost:80"
echo "MariaDB      : mysql -h localhost -u appuser -p"
echo "Registry     : curl http://localhost:5000/v2/"
echo ""

print_success "Déploiement terminé !"
echo "Les services vont continuer à démarrer, vérifiez leur état:"
echo "  docker service ls"
echo "  docker service ps <SERVICE>"
echo ""
