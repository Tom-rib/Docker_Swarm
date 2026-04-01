# 05 - Annexes : Commandes Utiles et Dépannage

**Objectif :** Un mémo rapide avec toutes les commandes Docker Swarm, NFS, et astuces de dépannage.

## 📚 Index

- Commandes Docker Swarm
- Commandes NFS
- Commandes de Diagnostic
- Commandes de Backup
- Dépannage Courant
- Scripts Utiles

---

## 🐳 Commandes Docker Swarm

### Cluster Management (Détaillé)

**Initialiser Swarm (une seule fois sur le manager):**
```bash
# Initialiser avec l'IP du manager
docker swarm init --advertise-addr 192.168.1.100

# Récupérer les tokens
docker swarm join-token worker   # Token pour workers
docker swarm join-token manager  # Token pour autres managers

# Voir l'état global du cluster
docker swarm ca                  # Voir le certificat racine
docker info | grep Swarm         # Informations Swarm
```

**Ajouter des nœuds au cluster:**
```bash
# Sur un nœud worker, rejoindre le cluster
docker swarm join \
  --token SWMTKN-1-xxxxxxxxxxx \
  192.168.1.100:2377

# Vérifier que le nœud a rejoint
# Sur le manager :
docker node ls

# Résultat attendu :
# ID        HOSTNAME   STATUS   AVAILABILITY   MANAGER STATUS
# abc123    worker1    Ready    Active         
# def456    worker2    Ready    Active         
# ghi789    worker3    Ready    Active         
```

**Gérer les nœuds:**
```bash
# Voir tous les nœuds avec détails
docker node ls
docker node ls -q          # Juste les IDs
docker node ls --format "{{.Hostname}}\t{{.Status}}"  # Format custom

# Voir les infos détaillées d'un nœud
docker node inspect worker1
docker node inspect worker1 | grep Spec -A 20

# Promouvoir un worker en manager
docker node promote worker1
# Résultat :
# Node worker1 promoted to a manager in the swarm.

# Rétrograder un manager en worker
docker node demote manager-name

# Drainer un nœud (arrêter les conteneurs, mais le garder actif)
# Utile pour maintenance
docker node update --availability drain worker1

# Réactiver un nœud drained
docker node update --availability active worker1

# Retirer un nœud du cluster (doit être drained d'abord)
docker node rm worker1
docker node rm --force worker1  # Force même si le nœud est connecté

# Ajouter un label à un nœud (pour contraintes de placement)
docker node update --label-add role=database worker1
docker node update --label-add environment=production worker2
docker node update --label-add tier=web worker3

# Retirer un label
docker node update --label-rm role worker1

# Voir tous les labels d'un nœud
docker node inspect worker1 | grep -A 20 "Labels"

# Changer le nom d'affichage d'un nœud
# Le nom est basé sur le hostname, immuable
```

### Gestion des Services (Détaillé)

**Déployer et gérer les stacks:**
```bash
# Déployer une stack complète
docker stack deploy -c docker-compose.yml swarm-app

# Déployer avec des variables d'environnement
REPLICAS=3 docker stack deploy -c docker-compose.yml my-stack

# Lister toutes les stacks
docker stack ls

# Voir les services d'une stack
docker stack services swarm-app

# Voir les tâches (conteneurs) d'une stack
docker stack ps swarm-app

# Mettre à jour une stack (modifier docker-compose.yml d'abord)
docker stack deploy -c docker-compose.yml swarm-app
# Swarm détecte les changements et redéploie

# Supprimer une stack complète
docker stack rm swarm-app
# Attention : tous les conteneurs et volumes sont supprimés
```

**Gérer les services spécifiques:**
```bash
# Lister tous les services
docker service ls
docker service ls -q          # Juste les IDs
docker service ls --filter "label=tier=web"  # Filtrer par label

# Voir les infos détaillées d'un service
docker service inspect swarm-app_nginx
docker service inspect swarm-app_nginx --pretty  # Format lisible

# Voir les tâches (replicas) d'un service
docker service ps swarm-app_nginx

# Résultat attendu :
# ID        NAME                IMAGE         NODE      DESIRED STATE
# abc123    swarm-app_nginx.1   nginx:alpine  worker1   Running
# def456    swarm-app_nginx.2   nginx:alpine  worker2   Running
# ghi789    swarm-app_nginx.3   nginx:alpine  worker3   Running

# Changer le nombre de replicas
docker service scale swarm-app_nginx=5
# Swarm lance 2 replicas supplémentaires

# Mettre à jour l'image d'un service
docker service update \
  --image nginx:latest \
  swarm-app_nginx

# Mettre à jour avec rollback possible
docker service update \
  --image nginx:1.21 \
  --rollback \
  swarm-app_nginx

# Forcer un redéploiement complet du service
docker service update --force swarm-app_nginx

# Mettre en pause les mises à jour
docker service update \
  --update-parallelism 1 \
  --update-delay 10s \
  swarm-app_nginx

# Ajouter une variable d'environnement
docker service update \
  --env-add ENVIRONMENT=production \
  swarm-app_php

# Supprimer une variable d'environnement
docker service update \
  --env-rm OLD_VAR \
  swarm-app_php

# Voir les logs d'un service
docker service logs swarm-app_nginx

# Logs en temps réel
docker service logs -f swarm-app_nginx

# Logs d'un nombre de lignes spécifique
docker service logs --tail 50 swarm-app_nginx

# Logs avec timestamps
docker service logs --timestamps swarm-app_nginx

# Supprimer un service
docker service rm swarm-app_nginx
```

### Réseaux Overlay (Détaillé)

```bash
# Lister tous les réseaux
docker network ls

# Voir les détails d'un réseau overlay
docker network inspect swarm-app_swarm-net

# Voir les conteneurs connectés à un réseau
docker network inspect swarm-app_swarm-net | grep -A 30 "Containers"

# Créer un réseau overlay personnalisé
docker network create \
  --driver overlay \
  --scope swarm \
  my-overlay-net

# Créer un réseau avec options
docker network create \
  --driver overlay \
  --opt com.docker.network.driver.overlay.vxlanid=4096 \
  --subnet 10.0.9.0/24 \
  my-custom-net

# Connecter un service à un réseau supplémentaire
docker service update \
  --network-add my-custom-net \
  swarm-app_nginx

# Déconnecter un service d'un réseau
docker service update \
  --network-rm my-custom-net \
  swarm-app_nginx

# Supprimer un réseau
docker network rm my-overlay-net
```

---

## 🗄️ Commandes NFS (Détaillé)

### Configuration NFS Server

```bash
# ===== INSTALLATION =====
sudo apt update
sudo apt install nfs-kernel-server nfs-common

# ===== CRÉER LES RÉPERTOIRES À EXPORTER =====
sudo mkdir -p /swarm-data
sudo mkdir -p /backups

# Fixer les permissions
sudo chown nobody:nogroup /swarm-data
sudo chown nobody:nogroup /backups
sudo chmod 777 /swarm-data
sudo chmod 777 /backups

# ===== CONFIGURER LES EXPORTS =====
# Éditer le fichier des exports
sudo nano /etc/exports

# Ajouter les lignes (pour notre architecture 3 workers + 1 backup) :
/swarm-data 192.168.1.101(rw,sync,no_subtree_check,no_root_squash)
/swarm-data 192.168.1.102(rw,sync,no_subtree_check,no_root_squash)
/swarm-data 192.168.1.103(rw,sync,no_subtree_check,no_root_squash)
/swarm-data 192.168.1.105(rw,sync,no_subtree_check,no_root_squash)
/backups 192.168.1.105(rw,sync,no_subtree_check,no_root_squash)

# Appliquer les changements
sudo exportfs -ra

# ===== VÉRIFIER LA CONFIGURATION =====
# Voir tous les exports disponibles
sudo showmount -e localhost

# Voir qui a monté quoi (connexions actives)
sudo showmount -d localhost

# Voir les statistiques du serveur NFS
sudo nfsstat -s

# Voir les statistiques du client
sudo nfsstat -c

# ===== GESTION DU SERVICE =====
# Vérifier que NFS écoute
sudo netstat -tlnp | grep nfs

# Redémarrer le service
sudo systemctl restart nfs-kernel-server

# Vérifier le statut
sudo systemctl status nfs-kernel-server

# Voir les processus NFS
ps aux | grep nfs

# ===== DÉPANNAGE =====
# Recharger les exports sans redémarrer
sudo exportfs -ra

# Vérifier la syntaxe du fichier exports
sudo exportfs -v

# Voir les erreurs NFS
sudo journalctl -u nfs-kernel-server -f
```

### Configuration NFS Client (Worker + Backup)

```bash
# ===== INSTALLATION CLIENT =====
sudo apt update
sudo apt install nfs-common

# ===== CRÉER LE POINT DE MONTAGE =====
sudo mkdir -p /swarm-data
sudo mkdir -p /backups      # Pour le backup server

# ===== MONTER MANUELLEMENT (test) =====
# Test de connectivité
ping 192.168.1.104

# Voir les exports disponibles
showmount -e 192.168.1.104

# Monter le répertoire (version 4)
sudo mount -t nfs 192.168.1.104:/swarm-data /swarm-data

# Monter avec options optimisées
sudo mount -t nfs \
  -o vers=4.0,rw,sync,hard,intr \
  192.168.1.104:/swarm-data /swarm-data

# ===== VÉRIFIER LE MONTAGE =====
# Voir tous les montages NFS
mount | grep nfs

# Voir les détails du montage
mount | grep swarm-data

# Voir l'utilisation du disque monté
df -h | grep swarm-data

# Lister les fichiers sur le montage
ls -la /swarm-data

# ===== TESTER L'ACCÈS =====
# Créer un fichier de test
echo "Test montage NFS" > /swarm-data/test_$(hostname).txt

# Vérifier que le fichier existe
ls -la /swarm-data/test_*.txt

# Supprimer le fichier de test
rm /swarm-data/test_$(hostname).txt

# ===== RENDRE PERMANENT (FSTAB) =====
sudo nano /etc/fstab

# Ajouter la ligne (pour worker) :
192.168.1.104:/swarm-data /swarm-data nfs defaults,_netdev 0 0

# Ajouter la ligne (pour backup server) :
192.168.1.104:/swarm-data /swarm-data-backup nfs defaults,_netdev 0 0
192.168.1.104:/backups /backups nfs defaults,_netdev 0 0

# Recharg les montages depuis fstab
sudo mount -a

# Vérifier les montages
mount | grep nfs

# ===== DÉMONTER =====
# Démonter un répertoire
sudo umount /swarm-data

# Forcer le démontage (si bloqué)
sudo umount -f /swarm-data

# Lazy unmount (démontage après utilisation)
sudo umount -l /swarm-data

# ===== PERFORMANCES =====
# Voir les stats de performance
nfsstat -c

# Monitor en temps réel (si sysstat installé)
iostat -x 1

# Voir l'utilisation du disque
du -sh /swarm-data/*

# ===== DÉPANNAGE CLIENT =====
# Voir les montages actifs
showmount -e 192.168.1.104

# Tester la latence NFS
ping 192.168.1.104

# Voir les erreurs de montage
sudo journalctl -xe | grep nfs

# Vérifier que le port NFS répond (2049)
telnet 192.168.1.104 2049

# Ou avec nc (plus rapide)
nc -zv 192.168.1.104 2049
```

---

## 🔍 Commandes de Diagnostic (Détaillé)

### État Général du Cluster

```bash
# ===== INFORMATIONS GLOBALES =====
# État complet du Docker daemon
docker info

# Juste les infos Swarm
docker info | grep -A 10 "Swarm:"

# État des nœuds en un coup d'œil
docker node ls

# Liste avec colonnes personnalisées
docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}"

# ===== SERVICES =====
# Tous les services
docker service ls

# Services avec images
docker service ls --format "table {{.Name}}\t{{.Image}}\t{{.Replicas}}"

# Replicas par service (montrer les problèmes)
docker service ls --format "{{.Name}}\t{{.Replicas}}" | awk -F'/' '$1 != $2 {print "❌ " $0}'

# ===== TÂCHES (CONTENEURS) =====
# Voir les tâches d'une stack
docker stack ps swarm-app

# Voir les tâches d'un service
docker service ps swarm-app_nginx

# Voir les tâches d'un nœud spécifique
docker service ps swarm-app_nginx --filter "node=worker1"

# Voir les tâches en erreur
docker service ps swarm-app --filter "desired-state=running" --filter "actual-state!=running"

# ===== CONTENEURS =====
# Tous les conteneurs (incluant les arrêtés)
docker ps -a

# Voir les conteneurs par image
docker ps --filter "ancestor=nginx:alpine"

# ===== RÉSEAUX =====
# Tous les réseaux
docker network ls

# Détails d'un réseau overlay
docker network inspect swarm-app_swarm-net

# Conteneurs connectés à un réseau
docker network inspect swarm-app_swarm-net | grep -A 50 "Containers"

# ===== CONNECTIVITÉ =====
# Tester la ping entre nœuds
ping 192.168.1.101  # worker1
ping 192.168.1.102  # worker2
ping 192.168.1.103  # worker3
ping 192.168.1.104  # NFS
ping 192.168.1.105  # Backup

# Tester les ports Swarm (2377, 7946, 4789)
nc -zv 192.168.1.100 2377   # Manager
nc -zv 192.168.1.101 7946   # Worker
nc -zv 192.168.1.101 4789   # VXLAN
nc -zv 192.168.1.104 2049   # NFS
```

### Logs et Historique (Détaillé)

```bash
# ===== LOGS DES SERVICES =====
# Logs complets d'un service
docker service logs swarm-app_nginx

# Logs en temps réel
docker service logs -f swarm-app_nginx

# Logs des 100 dernières lignes
docker service logs --tail 100 swarm-app_nginx

# Logs avec timestamps
docker service logs --timestamps swarm-app_nginx

# Logs des dernières N heures
docker service logs --since 2h swarm-app_nginx

# Logs d'une réplica spécifique (par l'ID du conteneur)
docker logs <CONTAINER_ID>

# ===== LOGS DU DAEMON DOCKER =====
# Logs du daemon (sur le nœud)
sudo journalctl -u docker -f

# Logs Docker de la dernière heure
sudo journalctl -u docker --since "1 hour ago"

# Logs avec filtre
sudo journalctl -u docker -p err  # Erreurs uniquement

# ===== LOGS NFS =====
# Logs NFS server
sudo journalctl -u nfs-kernel-server -f

# Logs montage NFS sur client
sudo journalctl -xe | grep nfs

# ===== ÉVÉNEMENTS EN TEMPS RÉEL =====
# Voir le log des changements Swarm
docker events --filter type=service

# Voir les événements des nœuds
docker events -f type=node --since 10m
```

### Utilisation des Ressources (Détaillé)

```bash
# ===== RESSOURCES EN DIRECT =====
# Statistiques des conteneurs (CPU, mémoire, etc.)
docker stats

# Stats sans streaming (snapshot)
docker stats --no-stream

# Stats d'un conteneur spécifique
docker stats <CONTAINER_ID>

# ===== MÉMOIRE =====
# Mémoire système
free -h

# Mémoire par nœud (depuis manager via SSH)
ssh user@192.168.1.101 "free -h"

# Détail de la mémoire
cat /proc/meminfo

# ===== DISQUE =====
# Utilisation disque
df -h

# Utilisation disque par répertoire
du -sh /swarm-data/*

# Espace utilisé par Docker
docker system df

# Détail par type (images, conteneurs, volumes)
docker system df --verbose

# ===== PROCESSUS =====
# Processus Docker
ps aux | grep docker

# Top en temps réel
top -p $(pgrep -f docker)

# ===== SANTÉ DES SERVICES =====
# Vérifier les health checks
docker service inspect swarm-app_mariadb | grep -A 10 "Health"

# Voir le statut de réplication
docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
```

---

## 💾 Commandes de Backup

### Backup MariaDB

```bash
# Dump complet
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysqldump -h mariadb -u appuser -papppassword app_db > /swarm-data/backups/backup_$(date +%Y%m%d).sql

# Avec compression
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysqldump -h mariadb -u appuser -papppassword app_db | gzip > /swarm-data/backups/backup_$(date +%Y%m%d).sql.gz
```

### Restaurer MariaDB

```bash
# Restaurer un dump simple
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db < /swarm-data/backups/backup.sql

# Restaurer un dump compressé
gunzip -c /swarm-data/backups/backup.sql.gz | \
  docker run --rm -i \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db
```

### Backup NFS (Archives)

```bash
# Backup tar non-compressé (rapide)
tar -cf /swarm-data/backups/backup_$(date +%Y%m%d).tar \
  --exclude='backups' /swarm-data

# Backup tar compressé (petit, lent)
tar -czf /swarm-data/backups/backup_$(date +%Y%m%d).tar.gz \
  --exclude='backups' /swarm-data

# Backup avec exclusions multiples
tar -czf /swarm-data/backups/backup_$(date +%Y%m%d).tar.gz \
  --exclude='backups' \
  --exclude='.docker' \
  --exclude='*.log' \
  /swarm-data
```

### Restaurer NFS

```bash
# Restaurer depuis archive
tar -xzf /swarm-data/backups/backup.tar.gz -C /

# Restaurer dans un répertoire spécifique
tar -xzf /swarm-data/backups/backup.tar.gz -C /tmp/restore/

# Restaurer un fichier spécifique
tar -xzf /swarm-data/backups/backup.tar.gz -C / swarm-data/php/app/index.php
```

### Script de Backup Automatisé

```bash
# Backup complet
bash scripts/backup.sh all

# Backup MariaDB seulement
bash scripts/backup.sh mariadb

# Backup NFS seulement
bash scripts/backup.sh nfs

# Voir les backups
ls -lh /swarm-data/backups/

# Voir l'espace utilisé
du -sh /swarm-data/backups/
```

### Nettoyage des Anciens Backups

```bash
# Voir les backups de plus de 30 jours
find /swarm-data/backups -type f -mtime +30

# Supprimer les backups de plus de 30 jours
find /swarm-data/backups -type f -mtime +30 -delete

# Nettoyer les logs de backup
find /swarm-data/backups -name "backup_*.log" -type f -mtime +7 -delete
```

---

## 🚨 Dépannage Courant

### Problème : Nœud "Down"

**Symptôme :** Un nœud affiche "Down" dans `docker node ls`

```bash
# 1. Vérifier la connexion SSH
ssh user@IP_NŒUD

# 2. Si SSH ne marche pas, la VM est éteinte
# -> Redémarrer la VM

# 3. Si SSH marche, vérifier Docker
sudo systemctl status docker

# 4. Si Docker n'est pas running
sudo systemctl start docker

# 5. Vérifier que le nœud peut rejoindre le cluster
sudo systemctl status docker | grep Active

# 6. Si le nœud reste Down après 10 minutes, le rejoindre
# -> Depuis le nœud : docker swarm leave
# -> Puis redéployer avec le token manager/worker
```

### Problème : Service "0/2" Replicas

**Symptôme :** `docker service ls` affiche "0/2" au lieu de "2/2"

```bash
# 1. Vérifier les logs du service
docker service logs nom-service

# 2. Voir où les conteneurs essaient de se lancer
docker service ps nom-service

# Causes possibles :
# - Image n'existe pas (erreur "not found")
# - Port déjà utilisé
# - Contrainte non respectée (label manquant)
# - Espace disque plein

# 3. Vérifier l'espace disque
df -h

# 4. Vérifier les labels des nœuds
docker node ls
docker node inspect worker1 | grep -A 5 "Spec.Labels"

# 5. Si contrainte de placement, ajouter le label
docker node update --label-add role=worker worker1

# 6. Forcer le redéploiement du service
docker service update --force nom-service
```

### Problème : Conteneurs Qui Se Crashent

**Symptôme :** Les conteneurs redémarrent constamment

```bash
# 1. Voir les logs du conteneur
docker service logs nom-service

# 2. Voir le nombre de redémarrages
docker service ps nom-service

# Causes possibles :
# - Application crash (bug, manque config)
# - Port manquant dans docker-compose
# - Volume non monté
# - Manque de mémoire

# 3. Vérifier la mémoire disponible
free -h

# 4. Vérifier les ports utilisés
sudo netstat -tlnp | grep LISTEN

# 5. Checker le docker-compose pour les erreurs
docker-compose config

# 6. Voir le health status
docker service inspect nom-service | grep -A 5 Health
```

### Problème : NFS Pas Monté

**Symptôme :** `mount` ne montre pas le NFS, ou erreur "Permission denied"

```bash
# 1. Vérifier que le NFS server est accessible
ping 192.168.1.103

# 2. Vérifier que NFS répond
showmount -e 192.168.1.103

# 3. Si erreur "RPC error", NFS n'est pas running sur le server
# -> Sur NFS : sudo systemctl restart nfs-kernel-server

# 4. Vérifier les permissions dans /etc/exports
# -> Les IPs doivent être correctes
sudo cat /etc/exports

# 5. Vérifier la connexion réseau
sudo iptables -L | grep nfs

# 6. Essayer de monter manuellement
sudo mount -t nfs -v 192.168.1.103:/swarm-data /swarm-data

# 7. Si succès, ajouter à fstab
sudo nano /etc/fstab
# Ajouter : 192.168.1.103:/swarm-data /swarm-data nfs defaults 0 0
```

### Problème : Pas de Connectivité Réseau Entre Conteneurs

**Symptôme :** Les conteneurs ne peuvent pas se pinger

```bash
# 1. Vérifier le réseau overlay
docker network inspect swarm-app_swarm-net

# 2. Vérifier que les conteneurs sont connectés
docker network inspect swarm-app_swarm-net | grep Containers

# 3. Essayer d'accéder d'un conteneur à l'autre
docker exec ID_CONTENEUR ping autre-conteneur

# 4. Si pas de résponse, vérifier les IPs
docker inspect ID_CONTENEUR | grep IPAddress

# 5. Vérifier les contraintes de placement
# (certains sur worker1, d'autres sur worker2 = pas de problème)

# 6. Essayer un redéploiement
docker service update --force nom-service
```

---

## 📝 Scripts Utiles

### Script : Vérifier la Santé du Cluster

```bash
#!/bin/bash
# save as : check-health.sh

echo "=== État des Nœuds ==="
docker node ls

echo -e "\n=== État des Services ==="
docker service ls

echo -e "\n=== Replicas par Service ==="
docker service ls --format "{{.Name}}\t{{.Replicas}}"

echo -e "\n=== Nœuds Down ==="
docker node ls --format "{{.Hostname}}\t{{.Status}}" | grep -i down || echo "Tous les nœuds sont OK"

echo -e "\n=== Services Incomplets ==="
docker service ls --format "{{.Name}}\t{{.Replicas}}" | grep -v '/' || echo "Tous les services sont OK"

# Run :
# bash check-health.sh
```

### Script : Déployer Rapidement

```bash
#!/bin/bash
# save as : deploy.sh

STACK_NAME="swarm-app"
COMPOSE_FILE="docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Erreur: $COMPOSE_FILE non trouvé"
    exit 1
fi

echo "Déploiement de la stack : $STACK_NAME"
docker stack deploy -c $COMPOSE_FILE $STACK_NAME

echo "Attendez quelques secondes..."
sleep 5

echo -e "\n=== État des Services ==="
docker service ls

# Run :
# bash deploy.sh
```

### Script : Voir les Logs de Tous les Services

```bash
#!/bin/bash
# save as : logs-all.sh

STACK_NAME="swarm-app"

echo "Logs de la stack : $STACK_NAME"
for service in $(docker service ls --filter "label=com.docker.stack.namespace=$STACK_NAME" -q); do
    echo -e "\n--- Service: $(docker service inspect $service --format '{{.Spec.Name}}') ---"
    docker service logs --tail 20 $service
done

# Run :
# bash logs-all.sh
```

---

## 📋 Fiche Mémoire Rapide

**À retenir :**

```bash
# État cluster
docker node ls          # Nœuds
docker service ls       # Services
docker ps               # Conteneurs

# Logs
docker service logs nom-service
docker service logs -f nom-service    # Temps réel

# Résilience
docker service scale nom-service=3    # Plus de replicas
docker service update --force nom      # Redéployer

# Maintenance
docker node update --availability drain worker1   # Arrêter un worker
docker node update --availability active worker1  # Relancer

# Backup
bash scripts/backup.sh all             # Backup complet
bash scripts/backup.sh mariadb         # Backup base de données
bash scripts/backup.sh nfs             # Backup fichiers

# Restaurer
docker run --rm --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db < backup.sql

# Nettoyage
docker service rm nom-service
docker stack rm nom-stack
docker volume prune
docker image prune
find /swarm-data/backups -type f -mtime +30 -delete
```

---

## 🔗 Ressources

- [Doc Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Doc NFS Linux](https://linux.die.net/man/5/nfs)
- [Doc Docker Network](https://docs.docker.com/network/overlay/)

---

**Fin des annexes. Bonne chance pour dépanner ! 🔧**
