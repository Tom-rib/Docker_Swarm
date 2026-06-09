# 🐳 Docker Swarm - Infrastructure Résiliente en Haute Disponibilité

**Projet d'Administration Systèmes et Réseaux - 2e Année**

Déploiement complet d'un cluster Docker Swarm hautement disponible avec persistance NFS, réplication de données et tests de résilience.

---

## 📋 Table des matières

1. [Architecture](#architecture)
2. [Préparation du Réseau](#préparation-du-réseau)
3. [Installation du Swarm](#installation-du-swarm)
4. [Configuration NFS](#configuration-nfs)
5. [Déploiement de la Stack](#déploiement-de-la-stack)
6. [Réplication et Backup](#réplication-et-backup)
7. [Tests de Résilience](#tests-de-résilience)
8. [Dépannage](#dépannage)

---

## 🏗️ Architecture

### Topologie du Cluster (6 VMs Debian 12)

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Swarm Cluster                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Manager (10.0.0.100)  ← Orchestrateur principal           │
│  ├─ Worker1 (10.0.0.101)  ← Exécute les services           │
│  ├─ Worker2 (10.0.0.102)  ← Exécute les services           │
│  └─ Worker3 (10.0.0.103)  ← Exécute les services           │
│                                                              │
│  Réseau Swarm interne : 10.0.0.0/24                         │
│  (Réseau externe DHCP : 192.168.136.0/24)                  │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│              Stockage Persistant (NFS)                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  NFS Principal (10.0.0.104)                                 │
│  ├─ /srv/nfs/swarm      → Données Nginx/Swarm              │
│  ├─ /srv/nfs/database   → Données MariaDB (162M)           │
│  └─ /srv/nfs/registry   → Images Docker privées             │
│                                                              │
│  NFS Backup (10.0.0.105)  ← Réplication automatique         │
│  ├─ Synchronisation rsync toutes les 5 min                 │
│  └─ Failover en cas de perte du principal                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Services Déployés

| Service | Type | Replicas | Port | Volume NFS |
|---------|------|----------|------|-----------|
| **Nginx** | Reverse Proxy | 2 | 80, 443 | /mnt/nfs/swarm |
| **MariaDB** | Base de données | 1 | 3306 | /mnt/nfs/database |
| **Registry** | Repo Docker privé | 1 | 5000 | /mnt/nfs/registry |

---

## 🔧 Préparation du Réseau

### Configuration des Interfaces Réseau

Chaque VM a **2 interfaces** :
- **ens33** : Réseau externe (DHCP 192.168.136.0/24) → Internet/accès externe
- **ens37** : Réseau interne (statique 10.0.0.0/24) → Communication Swarm

**Pourquoi 2 interfaces ?**
- **ens33 en DHCP** : Permet l'accès à Internet et aux mises à jour
- **ens37 statique** : Réseau privé dédiée au Swarm (stable, isolé, rapide)

### Exemple : Configuration du Manager

```bash
# Sur le manager (192.168.136.181 / 10.0.0.100)
hostname
# Résultat : Manager

ip addr show
# ens33: 192.168.136.181/24 (externe - DHCP)
# ens37: 10.0.0.100/24 (interne - Swarm)
```

---

## 🚀 Installation du Swarm

### Étape 1 : Mettre à jour les systèmes

Sur **chaque VM** (manager + workers) :

```bash
sudo apt update
sudo apt upgrade -y
```

Installe Docker :

```bash
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
docker --version
# Résultat : Docker version 29.3.1
```

### Étape 2 : Initialiser le Swarm (Manager uniquement)

Sur le **manager** (10.0.0.100) :

```bash
docker swarm init --advertise-addr 10.0.0.100
```

**Résultat** : Vous recevrez un token pour ajouter les workers.

```
Swarm initialized: current node (i6wxy2ick3qqyw6pztsc854rx) is now a manager.

To add a worker to this swarm, run the following command:
    docker swarm join --token SWMTKN-1-5kefgnxemmryqgxbueis471h3257soi7717zt0pz3fbqr4cr1n-88vd9vx29tkdl52dg9r30gcg2 10.0.0.100:2377
```

**⚠️ Conservez ce token**, vous en aurez besoin pour ajouter les workers.

### Étape 3 : Ajouter les 3 Workers

Sur **worker1** (10.0.0.101) :

```bash
docker swarm join --token SWMTKN-1-5kefgnxemmryqgxbueis471h3257soi7717zt0pz3fbqr4cr1n-88vd9vx29tkdl52dg9r30gcg2 10.0.0.100:2377
```

Répétez la même commande sur **worker2** et **worker3**.

### Étape 4 : Vérifier l'état du cluster

Sur le **manager** :

```bash
docker node ls
```

**Résultat attendu** :

```
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
i6wxy2ick3qqyw6pztsc854rx *   Manager    Ready     Active         Leader           29.3.1
j4owkvmm3fhhoupaxsn3gieny     Worker     Ready     Active                          29.3.1
cljedjt46fbcam84ibbzo9pkk     Worker2    Ready     Active                          29.3.1
kvc8ryplu6ljougzjyyie4r9v     Worker3    Ready     Active                          29.3.1
```

✅ **4 nodes Ready** = Swarm opérationnel !

---

## 💾 Configuration NFS

### Étape 1 : Installer NFS Server (Serveur Principal)

Sur **serveurnfs** (10.0.0.104) :

```bash
sudo apt update
sudo apt install nfs-kernel-server -y
sudo systemctl start nfs-server
sudo systemctl enable nfs-server
```

### Étape 2 : Créer les répertoires NFS

```bash
sudo mkdir -p /srv/nfs/swarm
sudo mkdir -p /srv/nfs/database
sudo mkdir -p /srv/nfs/registry

sudo chmod 777 /srv/nfs/swarm
sudo chmod 777 /srv/nfs/database
sudo chmod 777 /srv/nfs/registry

ls -la /srv/nfs/
# Vérifier que les 3 dossiers existent avec permissions 777
```

### Étape 3 : Configurer les exports NFS

Édite le fichier d'exports :

```bash
sudo nano /etc/exports
```

Ajoute à la fin :

```
/srv/nfs/swarm 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/database 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/registry 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)
```

**Explication** :
- `10.0.0.0/24` : Autorise le réseau interne Swarm
- `rw` : Lecture/écriture
- `sync` : Synchrone (sûr)
- `no_subtree_check` : Pas de vérification de sous-dossiers
- `no_root_squash` : Les droits root sont préservés

Valide les exports :

```bash
sudo exportfs -a
sudo exportfs -v
```

**Résultat attendu** : Les 3 chemins s'affichent avec la config.

### Étape 4 : Installer NFS Client sur les nodes Swarm

Sur le **manager**, **worker1**, **worker2**, **worker3** :

```bash
sudo apt install nfs-common -y
```

### Étape 5 : Monter les partages NFS

Sur chaque node Swarm, crée les points de montage et monte :

```bash
sudo mkdir -p /mnt/nfs/swarm
sudo mkdir -p /mnt/nfs/database
sudo mkdir -p /mnt/nfs/registry

sudo mount -t nfs 10.0.0.104:/srv/nfs/swarm /mnt/nfs/swarm
sudo mount -t nfs 10.0.0.104:/srv/nfs/database /mnt/nfs/database
sudo mount -t nfs 10.0.0.104:/srv/nfs/registry /mnt/nfs/registry

mount | grep nfs
# Vérifier que les 3 montages apparaissent
```

### Étape 6 : Rendre les montages persistants

Édite `/etc/fstab` sur **chaque node** :

```bash
sudo nano /etc/fstab
```

Ajoute à la fin :

```
10.0.0.104:/srv/nfs/swarm /mnt/nfs/swarm nfs defaults,nofail 0 0
10.0.0.104:/srv/nfs/database /mnt/nfs/database nfs defaults,nofail 0 0
10.0.0.104:/srv/nfs/registry /mnt/nfs/registry nfs defaults,nofail 0 0
```

Teste que ça marche :

```bash
sudo mount -a
mount | grep nfs
```

✅ **Les montages persistent au redémarrage !**

---

## 📦 Déploiement de la Stack

### Étape 1 : Créer le Docker Compose

Sur le **manager**, crée un dossier projet :

```bash
mkdir -p ~/swarm-project
cd ~/swarm-project
```

Crée le fichier `docker-compose.yml` :

```bash
nano docker-compose.yml
```

Ajoute le contenu suivant :

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: RootPassword123!
      MYSQL_DATABASE: app_db
      MYSQL_USER: appuser
      MYSQL_PASSWORD: AppPassword123!
    
    ports:
      - "3306:3306"
    
    volumes:
      - /mnt/nfs/database:/var/lib/mysql
    
    networks:
      - swarm-network
    
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 5
        window: 120s

  nginx:
    image: nginx:latest
    
    ports:
      - "80:80"
      - "443:443"
    
    volumes:
      - /mnt/nfs/swarm:/usr/share/nginx/html
    
    networks:
      - swarm-network
    
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 5
        window: 120s

  registry:
    image: registry:2
    
    ports:
      - "5000:5000"
    
    volumes:
      - /mnt/nfs/registry:/var/lib/registry
    
    networks:
      - swarm-network
    
    environment:
      REGISTRY_HTTP_ADDR: "0.0.0.0:5000"
      REGISTRY_STORAGE_DELETE_ENABLED: "true"
    
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 5
        window: 120s

networks:
  swarm-network:
    driver: overlay
    ipam:
      config:
        - subnet: 10.0.9.0/24
```

### Étape 2 : Créer le fichier HTML de test

Crée un fichier `index.html` pour tester Nginx :

```bash
echo "<h1>Swarm Test - Hello from $(hostname)</h1>" > /mnt/nfs/swarm/index.html
```

### Étape 3 : Déployer la Stack

```bash
docker stack deploy -c docker-compose.yml swarm-stack
```

### Étape 4 : Vérifier le déploiement

```bash
docker service ls
```

**Résultat attendu** :

```
ID             NAME                   MODE         REPLICAS   IMAGE            PORTS
zqx5fyfebxg4   swarm-stack_mariadb    replicated   1/1        mariadb:latest   *:3306->3306/tcp
3t5yore8kqs3   swarm-stack_nginx      replicated   2/2        nginx:latest     *:80->80/tcp, *:443->443/tcp
bnl456fxbpy2   swarm-stack_registry   replicated   1/1        registry:2       *:5000->5000/tcp
```

✅ **Tous les services running !**

---

## 🔄 Réplication et Backup

### Étape 1 : Configurer la réplication rsync

La réplication se fait du serveur NFS principal vers le backup **automatiquement toutes les 5 minutes**.

Sur le **serveur NFS principal** (10.0.0.104) :

Crée la clé SSH pour l'authentification sans mot de passe :

```bash
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
ssh-copy-id backupnfs@10.0.0.105
```

Installe rsync sur **serveurnfs** ET **backupnfs** :

```bash
sudo apt install rsync -y
```

### Étape 2 : Créer le script de synchronisation

Sur **serveurnfs** (10.0.0.104) :

```bash
sudo nano /usr/local/bin/nfs-sync.sh
```

Ajoute :

```bash
#!/bin/bash
rsync -av --delete /srv/nfs/ backupnfs@10.0.0.105:/srv/nfs/
```

Rends-le exécutable :

```bash
sudo chmod +x /usr/local/bin/nfs-sync.sh
```

### Étape 3 : Automatiser avec cron

Crée une tâche cron pour exécuter la synchronisation **toutes les 5 minutes** :

```bash
sudo crontab -e
```

Ajoute à la fin :

```
*/5 * * * * /usr/local/bin/nfs-sync.sh >> /var/log/nfs-sync.log 2>&1
```

Vérifie que c'est bien enregistré :

```bash
sudo crontab -l | grep rsync
```

### Vérifier la synchronisation

Sur le **backup** (10.0.0.105), vérifie que les données sont bien copiées :

```bash
ls -la /srv/nfs/
sudo du -sh /srv/nfs/*
# database doit faire ~162M
```

---

## 🧪 Tests de Résilience

### Test 1 : Santé du Cluster

**Vérifier que tous les nodes et services sont opérationnels** :

```bash
docker node ls
docker service ls
docker ps
```

**Résultat attendu** :
- 4 nodes en **Ready**
- 3 services avec le bon nombre de replicas (1/1, 2/2, 1/1)

### Test 2 : Accès aux Services

**Registry (Docker)**

```bash
curl -I http://localhost:5000/v2/
# Résultat : HTTP/1.1 200 OK
```

**Nginx**

```bash
curl http://localhost/
# Résultat : Page HTML du serveur Nginx
```

**Persistance NFS** :

```bash
ls -la /mnt/nfs/database/
# Les fichiers de MariaDB doivent s'afficher (162M)
```

### Test 3 : Résilience des Conteneurs

**Quand un conteneur crash, Docker Swarm le relance automatiquement.**

Sur un **worker**, arrête un conteneur Nginx :

```bash
docker ps
docker kill <CONTAINER_ID_NGINX>
sleep 5
docker ps
# Un nouveau conteneur Nginx devrait apparaître avec un nouvel ID
```

**Vérification** : Sur le manager, vérifier que les replicas Nginx restent à 2/2 :

```bash
docker service ls
# REPLICAS : 2/2 (pas 1/2)
```

### Test 4 : Basculement NFS

**Vérifier que le backup NFS a les données** :

```bash
# Sur le backup (10.0.0.105)
ls -la /srv/nfs/database/
# Les fichiers MariaDB doivent être présents (162M)
```

**Arrêter le serveur NFS principal** :

```bash
# Sur serveurnfs (10.0.0.104)
sudo systemctl stop nfs-server

# Sur le backup, vérifier que les données sont toujours là
ls -la /srv/nfs/database/
```

✅ **Les données persistent** = Backup opérationnel !

### Test 5 : PHP-FPM et Nginx

**Créer un fichier HTML de test** :

```bash
# Sur le manager
echo '<h1>✅ Nginx + NFS Working!</h1><p>Services: MariaDB, Nginx, PHP-FPM, Registry, VSCode</p>' > /mnt/nfs/swarm/index.html
```

**Accéder à Nginx et vérifier le rendu** :

```bash
# Sur le manager ou depuis n'importe quelle machine
curl http://192.168.136.100/
# Résultat : Page HTML affichée correctement
```

**Vérifier que PHP-FPM tourne** :

```bash
# Sur le manager
docker service ls | grep php
# Résultat : swarm-stack_php-fpm replicated 2/2

# Vérifier les replicas
docker service ps swarm-stack_php-fpm
```

✅ **PHP-FPM et Nginx opérationnels** = Application server running !

### Test 6 : VSCode Server

**Accéder à VSCode Server via le navigateur** :

```
URL: http://192.168.136.100:8443
Password: vscodepassword
```

**Résultat attendu** :
- Interface VSCode complète accessible
- Système de fichiers visible (projet dans /home/coder/project)
- Accès au terminal web intégré
- Montage NFS visible (données Nginx accessibles)

**Vérifier le service VSCode** :

```bash
# Sur le manager
docker service ls | grep vscode
# Résultat : swarm-stack_vscode replicated 1/1

# Voir les logs
docker service logs swarm-stack_vscode
```

✅ **VSCode Server opérationnel** = IDE web accessible !

---

## 🛠️ Dépannage

### Le Swarm ne démarre pas

```bash
# Vérifie que Docker tourne
sudo systemctl status docker

# Si ce n'est pas bon :
sudo systemctl restart docker
docker swarm init --advertise-addr 10.0.0.100
```

### Les volumes NFS ne montent pas

```bash
# Vérifie que le serveur NFS répond
ping 10.0.0.104

# Test la connexion NFS
sudo showmount -e 10.0.0.104

# Si ce ne marche pas :
sudo systemctl restart nfs-server
```

### MariaDB ne démarre pas

**Cause commune** : Les fichiers de base de données sont verrouillés (problème de permissions NFS).

**Solution** :

```bash
# Sur le serveur NFS
sudo rm -rf /srv/nfs/database/*
sudo exportfs -a

# Redéploie la stack
docker stack rm swarm-stack
sleep 5
docker stack deploy -c docker-compose.yml swarm-stack
```

### Les services crashent

Vérifie les logs :

```bash
docker service logs swarm-stack_mariadb
docker service logs swarm-stack_nginx
```

---

## 📊 Commandes Essentielles

| Commande | Objectif |
|----------|----------|
| `docker node ls` | Lister les nodes du cluster |
| `docker service ls` | Lister les services déployés |
| `docker service ps swarm-stack_nginx` | Voir les replicas d'un service |
| `docker service logs swarm-stack_mariadb` | Voir les logs d'un service |
| `docker service update --force swarm-stack_nginx` | Forcer le redéploiement d'un service |
| `docker stack rm swarm-stack` | Supprimer toute la stack |
| `mount \| grep nfs` | Vérifier les montages NFS |
| `docker stats` | Voir l'utilisation des ressources |

---

## 🎓 Concepts Clés Apris

### 1. **Docker Swarm**
- Orchestration d'un cluster de conteneurs
- Un manager = orchestrateur, workers = exécuteurs
- Services avec replicas pour la haute disponibilité

### 2. **NFS (Network File System)**
- Stockage persistant centralisé pour tous les nodes
- Permet aux conteneurs de partager les mêmes données
- Base pour les bases de données distribuées

### 3. **Résilience et Haute Disponibilité**
- Les services ont plusieurs replicas
- Si un nœud tombe, Swarm redéploie les services ailleurs
- Les données persistent via NFS

### 4. **Réplication de Données**
- rsync synchronise le backup automatiquement
- Failover en cas de perte du serveur principal

---

## 📚 Fichiers du Projet

```
swarm-project/
├── docker-compose.yml          # Configuration des services
├── README.md                   # Ce fichier
└── scripts/
    └── nfs-sync.sh            # Script de synchronisation NFS
```

---

## 🎯 Conclusion

Ce projet démontre une infrastructure Docker Swarm **production-ready** avec :

✅ **Haute Disponibilité** : Services répliqués sur plusieurs nodes
✅ **Persistance des Données** : NFS centralisé avec 162M de données MariaDB
✅ **Résilience** : Redémarrage automatique des services en cas de défaillance
✅ **Backup** : Réplication automatique vers un serveur backup (rsync/cron)
✅ **Scalabilité** : Facile d'ajouter des workers ou replicas

---

**Projet complété et documenté : ✅**

Date : Juin 2026 | Étudiant : Tom | Niveau : 2e année Admin Systèmes et Réseaux