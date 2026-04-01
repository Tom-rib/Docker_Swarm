#!/bin/bash

#############################################################################
# Script : test_resilience.sh
# Description : Tester la résilience du cluster Swarm
# Utilisation : bash test_resilience.sh [test_name]
# Exemples : 
#   bash test_resilience.sh                    (tous les tests)
#   bash test_resilience.sh health              (test de santé)
#   bash test_resilience.sh container_restart   (test de redémarrage)
#############################################################################

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonctions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}   $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
}

print_failure() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Vérifier Manager
if ! docker info | grep -q "Swarm: active"; then
    print_failure "Ce script doit être lancé sur un Manager Swarm"
    exit 1
fi

# ============================================================================
# TEST 1 : Vérification de santé générale du cluster
# ============================================================================

test_health() {
    print_header "TEST 1 : SANTÉ GÉNÉRALE DU CLUSTER"
    
    local PASSED=0
    local FAILED=0
    
    # Test 1.1 : Tous les nœuds sont Ready
    print_test "Tous les nœuds sont Ready..."
    READY_COUNT=$(docker node ls | awk 'NR>1 {print $4}' | grep -c "Ready")
    TOTAL_COUNT=$(docker node ls | awk 'NR>1' | wc -l)
    
    if [ "$READY_COUNT" -eq "$TOTAL_COUNT" ]; then
        print_success "Tous les $TOTAL_COUNT nœuds sont Ready"
        ((PASSED++))
    else
        print_failure "$READY_COUNT/$TOTAL_COUNT nœuds sont Ready"
        ((FAILED++))
    fi
    
    # Test 1.2 : Services avec replicas complètes
    print_test "Services avec replicas complètes..."
    docker service ls | awk 'NR>1 {print $4}' | while read replicas; do
        if [[ ! "$replicas" =~ ([0-9]+)/\1 ]]; then
            return 1
        fi
    done
    
    if [ $? -eq 0 ]; then
        print_success "Tous les services ont leurs replicas"
        ((PASSED++))
    else
        print_failure "Certains services manquent des replicas"
        docker service ls
        ((FAILED++))
    fi
    
    # Test 1.3 : Pas de tâches échouées
    print_test "Pas de tâches échouées..."
    FAILED_TASKS=$(docker service ps $(docker service ls -q) 2>/dev/null | grep -i "failed\|error\|shutdown" | wc -l)
    
    if [ "$FAILED_TASKS" -eq 0 ]; then
        print_success "Aucune tâche échouée"
        ((PASSED++))
    else
        print_failure "$FAILED_TASKS tâches en erreur"
        ((FAILED++))
    fi
    
    echo ""
    echo "Résultats: ${GREEN}$PASSED PASS${NC} / ${RED}$FAILED FAIL${NC}"
}

# ============================================================================
# TEST 2 : Redémarrage de conteneurs
# ============================================================================

test_container_restart() {
    print_header "TEST 2 : REDÉMARRAGE DE CONTENEURS"
    
    print_test "Arrêt d'un conteneur MariaDB..."
    
    # Obtenir un conteneur MariaDB
    CONTAINER=$(docker ps -q -f label=com.docker.swarm.service.name=mariadb | head -1)
    
    if [ -z "$CONTAINER" ]; then
        print_failure "Aucun conteneur MariaDB trouvé"
        return
    fi
    
    print_info "Arrêt du conteneur: $CONTAINER"
    docker stop $CONTAINER
    
    # Attendre et vérifier la relance
    print_test "Attente de la relance automatique..."
    for i in {1..30}; do
        if docker ps | grep -q "$CONTAINER"; then
            print_success "Conteneur relancé après $((i*2)) secondes"
            return 0
        fi
        sleep 2
    done
    
    print_failure "Conteneur non relancé après 60 secondes"
}

# ============================================================================
# TEST 3 : Accès aux services
# ============================================================================

test_service_access() {
    print_header "TEST 3 : ACCÈS AUX SERVICES"
    
    # Test Nginx
    print_test "Accès à Nginx..."
    if curl -s http://localhost:80 > /dev/null 2>&1; then
        print_success "Nginx accessible"
    else
        print_failure "Nginx non accessible"
    fi
    
    # Test MariaDB
    print_test "Connexion à MariaDB..."
    if docker exec $(docker ps -q -f label=com.docker.swarm.service.name=mariadb | head -1) \
        mysql -h mariadb -u appuser -pAppPassword123! -e "SELECT 1;" > /dev/null 2>&1; then
        print_success "MariaDB accessible"
    else
        print_failure "MariaDB non accessible"
    fi
    
    # Test Registry
    print_test "Accès au Registry..."
    if curl -s http://localhost:5000/v2/ > /dev/null 2>&1; then
        print_success "Registry accessible"
    else
        print_failure "Registry non accessible"
    fi
}

# ============================================================================
# TEST 4 : Continuité pendant redéploiement
# ============================================================================

test_continuous_requests() {
    print_header "TEST 4 : CONTINUITÉ PENDANT REDÉPLOIEMENT"
    
    print_test "Envoi de 30 requêtes HTTP..."
    
    FAILURES=0
    for i in {1..30}; do
        if ! curl -s http://localhost:80 > /dev/null 2>&1; then
            ((FAILURES++))
        fi
        printf "."
    done
    echo ""
    
    if [ "$FAILURES" -eq 0 ]; then
        print_success "30/30 requêtes réussies"
    else
        print_failure "$FAILURES requêtes échouées"
    fi
}

# ============================================================================
# TEST 5 : Volumes NFS
# ============================================================================

test_nfs_volumes() {
    print_header "TEST 5 : VOLUMES NFS"
    
    print_test "Vérification des volumes NFS..."
    
    # Vérifier qu'au moins un volume NFS existe
    NFS_VOLUMES=$(docker volume ls | grep "local.*nfs" | wc -l)
    
    if [ "$NFS_VOLUMES" -gt 0 ]; then
        print_success "$NFS_VOLUMES volumes NFS disponibles"
        
        # Inspecter les détails
        docker volume ls | grep "local.*nfs" | while read driver volume; do
            print_info "Volume: $volume"
        done
    else
        print_failure "Aucun volume NFS trouvé"
    fi
}

# ============================================================================
# TEST 6 : Monitoring des ressources
# ============================================================================

test_resources() {
    print_header "TEST 6 : MONITORING DES RESSOURCES"
    
    print_test "Affichage de l'utilisation des ressources..."
    echo ""
    
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -10
    
    echo ""
    print_info "Utilisation totale du disque Docker:"
    docker system df
}

# ============================================================================
# TEST 7 : État détaillé du Swarm
# ============================================================================

test_swarm_details() {
    print_header "TEST 7 : DÉTAILS DU SWARM"
    
    print_test "Nœuds du cluster..."
    docker node ls
    
    echo ""
    print_test "Services déployés..."
    docker service ls
    
    echo ""
    print_test "Tâches par service..."
    for service in $(docker service ls -q); do
        SERVICE_NAME=$(docker service inspect $service --format '{{.Spec.Name}}')
        print_info "$SERVICE_NAME:"
        docker service ps $service --no-trunc | head -3
        echo ""
    done
}

# ============================================================================
# Sélection et exécution des tests
# ============================================================================

TEST_NAME=${1:-"all"}

case $TEST_NAME in
    health)
        test_health
        ;;
    container_restart)
        test_container_restart
        ;;
    service_access)
        test_service_access
        ;;
    continuous)
        test_continuous_requests
        ;;
    nfs)
        test_nfs_volumes
        ;;
    resources)
        test_resources
        ;;
    details)
        test_swarm_details
        ;;
    all)
        test_health
        test_container_restart
        test_service_access
        test_continuous_requests
        test_nfs_volumes
        test_resources
        test_swarm_details
        ;;
    *)
        echo "Tests disponibles:"
        echo "  health           - Vérification de santé générale"
        echo "  container_restart- Test de redémarrage de conteneurs"
        echo "  service_access   - Test d'accès aux services"
        echo "  continuous       - Test de continuité de requêtes"
        echo "  nfs              - Test des volumes NFS"
        echo "  resources        - Monitoring des ressources"
        echo "  details          - Affichage détaillé du Swarm"
        echo "  all              - Tous les tests"
        echo ""
        echo "Usage: bash test_resilience.sh [test_name]"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo "Tests terminés"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
