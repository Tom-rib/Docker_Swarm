#!/bin/bash
# Script de backup automatisé du cluster Docker Swarm
# Usage: bash backup.sh [mariadb|nfs|all] [--push-remote]
# Default: all
# --push-remote : Envoie les backups au serveur de backup (192.168.1.105)

BACKUP_DIR="/swarm-data/backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_DIR/backup_$DATE.log"

# Options
BACKUP_TYPE="${1:-all}"
PUSH_REMOTE="${2:-}"

# Configuration du serveur de backup
BACKUP_SERVER="192.168.1.105"
BACKUP_USER="user"
BACKUP_REMOTE_DIR="/backups/swarm"
BACKUP_KEY="~/.ssh/backup_key"

# Fonction de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Créer le répertoire backup s'il n'existe pas
mkdir -p "$BACKUP_DIR" 2>/dev/null

# Vérifier les permissions
if [ ! -w "$BACKUP_DIR" ]; then
    echo "❌ Pas de permissions pour écrire dans $BACKUP_DIR"
    exit 1
fi

log "=== Démarrage Backup Swarm ==="
log "Type: $BACKUP_TYPE"
log "Dossier: $BACKUP_DIR"
if [ "$PUSH_REMOTE" = "--push-remote" ]; then
    log "Envoi distant: $BACKUP_SERVER"
fi

# Vérifier que le réseau Swarm existe
if ! docker network ls | grep -q "swarm-app_swarm-net"; then
    log "❌ Erreur: Le réseau swarm-app_swarm-net n'existe pas"
    log "Vérifie que la stack est déployée: docker stack deploy -c docker-compose.yml swarm-app"
    exit 1
fi

# ============================================
# BACKUP MARIADB
# ============================================
backup_mariadb() {
    log "[1/2] Backup MariaDB..."
    
    BACKUP_FILE="$BACKUP_DIR/app_db_$DATE.sql"
    
    # Vérifier que MariaDB répond
    docker run --rm --network swarm-app_swarm-net mysql:8.0 \
        mysqladmin -h mariadb -u appuser -papppassword ping > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        log "❌ MariaDB ne répond pas"
        return 1
    fi
    
    # Faire le dump
    docker run --rm \
        --network swarm-app_swarm-net \
        -v "$BACKUP_DIR":/backup \
        mysql:8.0 \
        mysqldump \
        -h mariadb \
        -u appuser \
        -papppassword \
        app_db > "$BACKUP_FILE" 2>>$LOG_FILE
    
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log "✓ Backup MariaDB OK ($SIZE)"
        return 0
    else
        log "❌ Erreur Backup MariaDB"
        return 1
    fi
}

# ============================================
# BACKUP NFS
# ============================================
backup_nfs() {
    log "[2/2] Backup fichiers NFS..."
    
    BACKUP_FILE="$BACKUP_DIR/nfs_data_$DATE.tar.gz"
    
    # Créer l'archive tar compressée
    tar -czf "$BACKUP_FILE" \
        --exclude="$BACKUP_DIR" \
        --exclude=".docker" \
        /swarm-data \
        2>>$LOG_FILE
    
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log "✓ Backup NFS OK ($SIZE)"
        return 0
    else
        log "❌ Erreur Backup NFS"
        return 1
    fi
}

# ============================================
# ENVOYER AU SERVEUR DE BACKUP
# ============================================
push_to_remote() {
    log "[3/2] Envoi au serveur de backup..."
    
    # Vérifier la connectivité SSH
    if ! ssh -i "$BACKUP_KEY" "$BACKUP_USER@$BACKUP_SERVER" "ls $BACKUP_REMOTE_DIR" > /dev/null 2>&1; then
        log "⚠️  Impossible de se connecter au serveur de backup ($BACKUP_SERVER)"
        log "Vérifiez: ssh -i $BACKUP_KEY $BACKUP_USER@$BACKUP_SERVER"
        return 1
    fi
    
    # Envoyer les fichiers de backup
    for file in "$BACKUP_DIR"/app_db_$DATE* "$BACKUP_DIR"/nfs_data_$DATE*; do
        if [ -f "$file" ]; then
            log "Envoi: $(basename $file)"
            scp -i "$BACKUP_KEY" "$file" "$BACKUP_USER@$BACKUP_SERVER:$BACKUP_REMOTE_DIR/" 2>>$LOG_FILE
            if [ $? -eq 0 ]; then
                log "✓ Fichier envoyé"
            else
                log "❌ Erreur envoi: $(basename $file)"
            fi
        fi
    done
    
    return 0
}

# ============================================
# EXÉCUTION
# ============================================

FAILED=0

case "$BACKUP_TYPE" in
    mariadb)
        backup_mariadb
        FAILED=$?
        ;;
    nfs)
        backup_nfs
        FAILED=$?
        ;;
    all)
        backup_mariadb
        FAILED=$?
        backup_nfs
        FAILED=$((FAILED + $?))
        ;;
    *)
        log "❌ Type de backup invalide: $BACKUP_TYPE"
        log "Usage: backup.sh [mariadb|nfs|all] [--push-remote]"
        exit 1
        ;;
esac

# ============================================
# ENVOI DISTANT (optionnel)
# ============================================

if [ "$PUSH_REMOTE" = "--push-remote" ] && [ $FAILED -eq 0 ]; then
    push_to_remote
    FAILED=$?
fi

# ============================================
# STATISTIQUES
# ============================================

log ""
log "=== Statistiques ==="
log "Backups disponibles:"
du -sh "$BACKUP_DIR"/* 2>/dev/null | sed 's/^/  /'
log ""
log "Espace total utilisé:"
du -sh "$BACKUP_DIR" | sed 's/^/  /'

# ============================================
# RÉSULTAT FINAL
# ============================================

if [ $FAILED -eq 0 ]; then
    log "✓ Backup Complété avec succès"
    log "Log: $LOG_FILE"
    exit 0
else
    log "❌ Backup Complété avec erreurs"
    log "Log: $LOG_FILE"
    exit 1
fi
