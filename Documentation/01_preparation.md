# 01 - Préparation et Architecture

**Objectif :** Comprendre l'architecture du cluster Swarm, vérifier les prérequis, et planifier le déploiement.

## 🎯 Récap de l'Objectif

On va déployer un cluster Swarm **résilient** :
- Plusieurs nœuds pour la redondance
- Services en haute disponibilité
- Persistance des données via NFS
- Tests de basculement et récupération automatique

## 🏗️ Architecture du Cluster

### Composants (6 VMs)

```
┌─────────────────────────────────────────────────────────────┐
│                      Manager Node                            │
│  - IP : 192.168.1.100                                       │
│  - Rôle : Orchestration, gestion du cluster                 │
│  - Services : Aucun conteneur applicatif (optionnel)        │
└─────────────────────────────────────────────────────────────┘

┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│  Worker Node 1 │  │  Worker Node 2 │  │  Worker Node 3 │
│  192.168.1.101 │  │  192.168.1.102 │  │  192.168.1.103 │
│ Conteneurs app │  │ Conteneurs app │  │ Conteneurs app │
│ - Registry     │  │ - MariaDB      │  │ - Nginx        │
│ - PHP          │  │ - PHP          │  │ - PHP          │
│ - VSCode       │  │ - Nginx        │  │ - VSCode       │
└────────────────┘  └────────────────┘  └────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    NFS Server                                │
│  - IP : 192.168.1.104                                       │
│  - Rôle : Stockage persistant (/swarm-data)                 │
│  - Accès : Montage depuis les 3 workers                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Backup Server                             │
│  - IP : 192.168.1.105                                       │
│  - Rôle : Sauvegarde centralisée des données                │
│  - Accès : Reçoit les backups via NFS ou SSH                │
└─────────────────────────────────────────────────────────────┘
```

### Réseau

- **Subnet Docker Swarm :** 10.0.9.0/24 (réseau interne des conteneurs)
- **Subnet Host :** 192.168.1.0/24 (réseau des VMs)
- **Manager port :** 2377 TCP (communication Swarm)
- **Worker port :** 7946 TCP/UDP (gossip protocol)
- **VXLAN port :** 4789 UDP (réseau overlay)

## 💻 Prérequis

### Hardware / VMs

Tu as besoin de **6 VMs Debian 12+** :

| VM | Rôle | CPU | RAM | Disque | IP |
|---|---|---|---|---|---|
| manager | Manager Swarm | 2 | 2 GB | 20 GB | 192.168.1.100 |
| worker1 | Worker | 2 | 2 GB | 20 GB | 192.168.1.101 |
| worker2 | Worker | 2 | 2 GB | 20 GB | 192.168.1.102 |
| worker3 | Worker | 2 | 2 GB | 20 GB | 192.168.1.103 |
| nfs-server | NFS Server | 1 | 1 GB | 50 GB | 192.168.1.104 |
| backup-server | Backup Server | 1 | 1 GB | 100 GB | 192.168.1.105 |

### Logiciels Obligatoires

Sur chaque VM **Debian** :

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Outils utiles
sudo apt install -y vim git curl net-tools nfs-common openssh-server openssh-client
```

### Réseau

- ✓ Toutes les VMs doivent se voir en ping
- ✓ Toutes les VMs doivent avoir accès à Internet
- ✓ Pas de pare-feu bloquant les ports Swarm (2377, 7946, 4789)

## ✅ Checklist de Préparation

Avant de commencer l'installation, vérifie :

- [ ] 4 VMs Debian sont opérationnelles
- [ ] Docker est installé sur chaque VM
- [ ] Les VMs communiquent en ping (192.168.1.x)
- [ ] SSH est actif (pour se connecter à distance)
- [ ] Tu as noté les IPs des VMs
- [ ] Le NFS server a assez d'espace disque (50 GB)

## 🔑 Points Clés à Retenir

### Swarm vs Kubernetes

Docker Swarm est **simple et léger** :
- Configuration native Docker (sans outils externes)
- Pas de courbe d'apprentissage énorme (Kubernetes = complexe)
- Parfait pour un cluster modéré (< 50 nœuds)

### Manager vs Worker

- **Manager :** Orchestre le cluster, gère l'état, prend les décisions
- **Worker :** Exécute les conteneurs, suit les ordres du manager
- 1 seul manager est suffisant (on peut en avoir 3 pour la HA du manager lui-même)

### Réseau Swarm

Swarm crée **automatiquement** :
- Un réseau overlay pour les conteneurs (10.0.9.0/24)
- Un protocole de gossip pour la synchronisation
- Load balancing interne entre services

## 📋 Fiche Mémoire - Architecture

**À mémoriser :**

```
Manager 192.168.1.100 (Orchestration)
     |
     +---> Worker1 192.168.1.101 (App)
     +---> Worker2 192.168.1.102 (App)
     +---> Worker3 192.168.1.103 (App)
     |
     +---> NFS 192.168.1.104 (Stockage : /swarm-data)
     |
     +---> Backup 192.168.1.105 (Sauvegarde centralisée)

Réseau conteneurs : 10.0.9.0/24 (créé automatiquement par Swarm)
Répliques par service : 3 (un par worker)
```

## 🚀 Prochaine Étape

Une fois que tu as vérifié tous les prérequis, passe à [02_installation.md](./02_installation.md) pour initialiser le cluster.

---

**Fait attention à bien noter les IPs de tes VMs, tu en auras besoin dans les étapes suivantes.**
