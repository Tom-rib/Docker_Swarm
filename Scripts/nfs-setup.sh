#!/bin/bash
# Script de configuration NFS
# Usage sur NFS server: bash nfs-setup.sh server
# Usage sur NFS client: bash nfs-setup.sh client NFS_IP

if [ -z "$1" ]; then
    echo "Usage:"
    echo "  Sur NFS server: bash nfs-setup.sh server"
    echo "  Sur NFS client : bash nfs-setup.sh client NFS_IP"
    echo ""
    echo "Exemple NFS server:"
    echo "  bash nfs-setup.sh server"
    echo ""
    echo "Exemple NFS client:"
    echo "  bash nfs-setup.sh client 192.168.1.103"
    exit 1
fi

MODE=$1
NFS_IP=$2

if [ "$MODE" = "server" ]; then
    echo "========================================"
    echo "Configuration NFS Server"
    echo "========================================"

    # Vérifier que l'on est root
    if [ "$EUID" -ne 0 ]; then 
        echo "❌ Ce script doit être exécuté en root (sudo)"
        exit 1
    fi

    # Installer NFS server
    echo -e "\n[1/3] Installation NFS server..."
    apt update -qq
    apt install -y nfs-kernel-server > /dev/null 2>&1

    # Créer les répertoires
    echo -e "\n[2/3] Création des répertoires..."
    mkdir -p /swarm-data
    chown nobody:nogroup /swarm-data
    chmod 777 /swarm-data

    # Configurer les exports
    echo -e "\n[3/3] Configuration des exports..."
    cat > /tmp/exports_append << 'EOF'
/swarm-data 192.168.1.101(rw,sync,no_subtree_check,no_root_squash)
/swarm-data 192.168.1.102(rw,sync,no_subtree_check,no_root_squash)
EOF

    # Ajouter les exports si pas déjà présents
    if ! grep -q "swarm-data" /etc/exports; then
        cat /tmp/exports_append >> /etc/exports
        echo "✓ Exports ajoutés"
    else
        echo "⚠️  Exports déjà présents"
    fi

    # Appliquer la config
    exportfs -ra
    systemctl restart nfs-kernel-server

    # Vérifier
    echo -e "\n✓ Configuration NFS Server terminée !"
    echo "Exports disponibles:"
    showmount -e localhost

elif [ "$MODE" = "client" ]; then
    if [ -z "$NFS_IP" ]; then
        echo "❌ Manque NFS_IP pour le mode client"
        exit 1
    fi

    echo "========================================"
    echo "Configuration NFS Client"
    echo "NFS Server: $NFS_IP"
    echo "========================================"

    # Vérifier que l'on est root
    if [ "$EUID" -ne 0 ]; then 
        echo "❌ Ce script doit être exécuté en root (sudo)"
        exit 1
    fi

    # Installer client NFS
    echo -e "\n[1/3] Installation NFS client..."
    apt update -qq
    apt install -y nfs-common > /dev/null 2>&1

    # Créer le point de montage
    echo -e "\n[2/3] Création du point de montage..."
    mkdir -p /swarm-data

    # Monter
    echo -e "\n[3/3] Montage du NFS..."
    mount -t nfs $NFS_IP:/swarm-data /swarm-data

    # Vérifier le montage
    if mount | grep -q "swarm-data"; then
        echo "✓ NFS monté avec succès"
    else
        echo "❌ Erreur lors du montage"
        exit 1
    fi

    # Rendre permanent
    if ! grep -q "swarm-data" /etc/fstab; then
        echo "$NFS_IP:/swarm-data /swarm-data nfs defaults 0 0" >> /etc/fstab
        echo "✓ Montage rendu permanent dans /etc/fstab"
    fi

    echo -e "\n✓ Configuration NFS Client terminée !"
    echo "Montages actuels:"
    mount | grep nfs

else
    echo "❌ Mode invalide : $MODE"
    echo "Utilise 'server' ou 'client'"
    exit 1
fi
