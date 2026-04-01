# 02 - Installation du Cluster Swarm

**Objectif :** Initialiser le cluster Swarm et ajouter les nœuds workers.

## 📋 Récap des Étapes

1. Initialiser Swarm sur le manager
2. Générer le token pour les workers
3. Ajouter les workers au cluster
4. Configurer le NFS server
5. Monter le NFS sur les workers
6. Vérifier l'état du cluster

## ⚙️ Étape 1 : Initialiser Swarm sur le Manager

Lance ça **une seule fois** sur la VM manager (192.168.1.100).

```bash
# SSH sur le manager
ssh user@192.168.1.100

# Initialiser Swarm
docker swarm init --advertise-addr 192.168.1.100
```

**Sortie attendue :**

```
Swarm initialized: current node (xxxx) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-xxxx 192.168.1.100:2377
```

**Important :** Garde ce token, tu vas l'utiliser pour ajouter les workers.

### Vérification

```bash
# Sur le manager, vérifier que Swarm est actif
docker node ls

# Sortie attendue :
# ID   HOSTNAME   STATUS   AVAILABILITY   MANAGER STATUS
# xxx  manager    Ready    Active         Leader
```

## ⚙️ Étape 2 : Ajouter les Workers

Récupère le token worker exactement (c'est celui affiché plus haut).

```bash
# Sur le manager, récupérer le token (si tu l'as perdu)
docker swarm join-token worker
```

Ça affiche un truc genre :

```
docker swarm join --token SWMTKN-1-xxxx 192.168.1.100:2377
```

### Ajouter les 3 Workers

Répète cette procédure sur les 3 workers.

#### Worker1 (192.168.1.101)

```bash
# SSH sur worker1
ssh user@192.168.1.101

# Joindre le cluster (utilise le token généré plus haut)
docker swarm join --token SWMTKN-1-xxxx 192.168.1.100:2377

# Sortie attendue :
# This node joined a swarm as a worker.
```

#### Worker2 (192.168.1.102)

```bash
# SSH sur worker2
ssh user@192.168.1.102

# Joindre le cluster
docker swarm join --token SWMTKN-1-xxxx 192.168.1.100:2377
```

#### Worker3 (192.168.1.103)

```bash
# SSH sur worker3
ssh user@192.168.1.103

# Joindre le cluster
docker swarm join --token SWMTKN-1-xxxx 192.168.1.100:2377
```

### Vérification Globale

Retourne sur le **manager** et vérifie l'état du cluster :

```bash
docker node ls

# Sortie attendue :
# ID        HOSTNAME   STATUS   AVAILABILITY   MANAGER STATUS
# xxxxxxx   manager    Ready    Active         Leader
# xxxxxxx   worker1    Ready    Active         
# xxxxxxx   worker2    Ready    Active         
# xxxxxxx   worker3    Ready    Active
```

**Tous les 4 nœuds doivent avoir "Ready" en STATUS.**

## 🗄️ Étape 3 : Configurer le NFS Server

Maintenant, on configure le stockage persistant sur le NFS.

### Sur la VM NFS (192.168.1.104)

```bash
# SSH sur le NFS server
ssh user@192.168.1.103

# Installer NFS server
sudo apt update
sudo apt install -y nfs-kernel-server

# Créer le répertoire de données
sudo mkdir -p /swarm-data
sudo chown nobody:nogroup /swarm-data
sudo chmod 777 /swarm-data

# Configurer les exports NFS
sudo nano /etc/exports
```

Ajoute cette ligne dans `/etc/exports` :

```
/swarm-data 192.168.1.101(rw,sync,no_subtree_check,no_root_squash)
/swarm-data 192.168.1.102(rw,sync,no_subtree_check,no_root_squash)
/swarm-data 192.168.1.103(rw,sync,no_subtree_check,no_root_squash)
```

Puis sauve (Ctrl+X, Y, Entrée).

### Redémarrer NFS

```bash
# Appliquer la config
sudo exportfs -ra

# Redémarrer le service
sudo systemctl restart nfs-kernel-server

# Vérifier que NFS écoute
sudo showmount -e localhost

# Sortie attendue :
# Export list for localhost:
# /swarm-data 192.168.1.101,192.168.1.102,192.168.1.103
```

## 📁 Étape 4 : Monter le NFS sur les 3 Workers

### Sur worker1 (192.168.1.101)

```bash
# SSH sur worker1
ssh user@192.168.1.101

# Installer le client NFS
sudo apt update
sudo apt install -y nfs-common

# Créer le point de montage
sudo mkdir -p /swarm-data

# Monter le NFS
sudo mount -t nfs 192.168.1.103:/swarm-data /swarm-data

# Vérifier le montage
mount | grep swarm-data

# Sortie attendue :
# 192.168.1.103:/swarm-data on /swarm-data type nfs4
```

### Rendre le montage permanent (worker1)

```bash
# Éditer fstab pour montage au démarrage
sudo nano /etc/fstab
```

Ajoute cette ligne :

```
192.168.1.103:/swarm-data /swarm-data nfs defaults 0 0
```

Sauve (Ctrl+X, Y, Entrée).

### Sur worker2 (192.168.1.102)

Répète les mêmes étapes qu'avec worker1 :

```bash
# SSH sur worker2
ssh user@192.168.1.102

sudo apt install -y nfs-common
sudo mkdir -p /swarm-data
sudo mount -t nfs 192.168.1.103:/swarm-data /swarm-data

# Vérifier
mount | grep swarm-data

# Rendre permanent
sudo nano /etc/fstab
```

Ajoute dans `/etc/fstab` :

```
192.168.1.104:/swarm-data /swarm-data nfs defaults 0 0
```

## Sur worker3 (192.168.1.104)

Répète les mêmes étapes qu'avec worker1 et worker2 :

```bash
# SSH sur worker3
ssh user@192.168.1.104

sudo apt install -y nfs-common
sudo mkdir -p /swarm-data
sudo mount -t nfs 192.168.1.104:/swarm-data /swarm-data

# Vérifier
mount | grep swarm-data

# Rendre permanent
sudo nano /etc/fstab
```

Ajoute dans `/etc/fstab` :

```
192.168.1.104:/swarm-data /swarm-data nfs defaults 0 0
```

## 📦 Étape 6 : Configurer le Serveur de Backup

Le serveur de backup (192.168.1.105) centralise toutes les sauvegardes du cluster.

### Sur la VM Backup (192.168.1.105)

```bash
# SSH sur le backup server
ssh user@192.168.1.105

# Installer NFS client (pour recevoir les backups)
sudo apt update
sudo apt install -y nfs-common openssh-server openssh-client

# Créer le répertoire de réception des backups
sudo mkdir -p /backups/swarm
sudo chmod 777 /backups/swarm

# Vérifier que NFS server répond
showmount -e 192.168.1.104

# Monter le NFS pour accès direct aux données (optionnel)
sudo mkdir -p /swarm-data-backup
sudo mount -t nfs 192.168.1.104:/swarm-data /swarm-data-backup
```

Ajoute à `/etc/fstab` pour montage permanent :

```bash
sudo nano /etc/fstab
```

Ajoute :

```
192.168.1.104:/swarm-data /swarm-data-backup nfs defaults 0 0
```

### SSH Key pour Backup Automatisé (Optionnel)

Pour que le script de backup envoie automatiquement les données :

```bash
# Sur le manager, générer une clé SSH
ssh-keygen -t rsa -N "" -f ~/.ssh/backup_key

# Copier la clé publique sur le serveur de backup
ssh-copy-id -i ~/.ssh/backup_key.pub user@192.168.1.105

# Tester la connexion sans mot de passe
ssh -i ~/.ssh/backup_key user@192.168.1.105 "ls -la /backups/"
```

### Sur le manager

```bash
docker node ls
docker info | grep Swarm
```

Résultat attendu : tous les nœuds en "Ready".

### Sur les workers

```bash
# Test écriture NFS
touch /swarm-data/test-$(hostname).txt
ls -la /swarm-data/

# Les fichiers des deux workers doivent être visibles sur les deux
```

## 📝 Fiche Mémoire - Installation

**Token worker :**
```bash
# Sur le manager
docker swarm join-token worker
```

**Ajouter worker :**
```bash
docker swarm join --token SWMTKN-1-xxxx MANAGER_IP:2377
```

**Vérifier cluster :**
```bash
docker node ls
docker service ls
```

**Monter NFS :**
```bash
sudo mount -t nfs NFS_IP:/swarm-data /swarm-data
```

## 🚀 Prochaine Étape

Maintenant que ton cluster est prêt, configure les services dans [03_configuration.md](./03_configuration.md).

---

**Tu as fini l'installation quand tous les nœuds affichent "Ready" et que le NFS est monté sur les workers.**
