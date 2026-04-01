#!/bin/bash
# Script d'initialisation du cluster Docker Swarm
# Usage: bash init-swarm.sh MANAGER_IP

if [ -z "$1" ]; then
    echo "Usage: bash init-swarm.sh MANAGER_IP"
    echo "Exemple: bash init-swarm.sh 192.168.1.100"
    exit 1
fi

MANAGER_IP=$1

echo "========================================"
echo "Initialisation Docker Swarm"
echo "Manager IP: $MANAGER_IP"
echo "========================================"

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Installe Docker d'abord."
    exit 1
fi

# Vérifier que l'on est sur le manager
echo -e "\n[1/3] Vérification du rôle..."
docker info | grep -q "Swarm: active" && {
    echo "⚠️  Swarm est déjà initialisé sur ce nœud"
    exit 1
}

# Initialiser Swarm
echo -e "\n[2/3] Initialisation de Swarm..."
docker swarm init --advertise-addr $MANAGER_IP

if [ $? -eq 0 ]; then
    echo "✓ Swarm initialisé avec succès"
else
    echo "❌ Erreur lors de l'initialisation"
    exit 1
fi

# Afficher le token worker
echo -e "\n[3/3] Token Worker (à utiliser sur les workers):"
echo "=================================================="
docker swarm join-token worker | grep "docker swarm join"
echo "=================================================="

echo -e "\n✓ Initialisation terminée !"
echo "Sur les workers, exécute la commande ci-dessus pour les ajouter au cluster."
