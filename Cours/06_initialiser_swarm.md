# 🎓 LEÇON 6 : Initialiser votre Premier Cluster Docker Swarm

**Prérequis** : Leçons 01-05 (Docker basiques + Swarm concepts)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Préparer les VMs pour Swarm
- ✅ Initialiser un cluster Swarm
- ✅ Vérifier que le cluster fonctionne
- ✅ Gérer les certificats TLS
- ✅ Obtenir et gérer les tokens

**Durée** : 20 minutes de lecture + 20 minutes de pratique

---

## 📖 Concept 1 : Prérequis pour Swarm

### Configuration Réseau Requise

```
┌─────────────────────────────────┐
│      Réseau 192.168.1.0/24      │
├─────────────────────────────────┤
│                                 │
│  Manager:      192.168.1.10    │
│  Worker 1:     192.168.1.11    │
│  Worker 2:     192.168.1.12    │
│  Worker 3:     192.168.1.13    │
│                                 │
│  ✅ Tous les nœuds visibles    │
│  ✅ Connectivité bidirectionnelle
│  ✅ Réseau stable              │
└─────────────────────────────────┘
```

### Ports Réseau Requis

```
Port 2377/tcp   → Communication Manager
Port 7946/tcp   → Communication nœuds (overlay)
Port 7946/udp   → Communication nœuds (gossip)
Port 4789/udp   → Overlay network (VXLAN)
Port 22/tcp     → SSH (pour accès)
Port 80/tcp     → HTTP (applications)
Port 443/tcp    → HTTPS (applications)
```

### Préparation des VMs

```bash
# Sur chaque VM (Manager et Workers)

# 1. Mise à jour système
sudo apt update && sudo apt upgrade -y

# 2. Installer NTP (synchronisation horloge)
sudo apt install -y ntp
sudo systemctl restart ntp

# 3. Vérifier l'horloge
timedatectl status
# ✅ Synchronized: yes (très important !)

# 4. Ouvrir les ports (UFW)
sudo ufw allow 22/tcp
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 5. Vérifier que Docker est installé
docker --version
# ✅ Docker version 20.10+
```

---

## 📖 Concept 2 : Initialiser le Swarm

### Processus d'Initialisation

```
docker swarm init --advertise-addr 192.168.1.10
        │                         │
        │                         └─ IP du Manager
        └─ Commande d'initialisation

Résultat :
- ✅ Manager configuré
- ✅ Cluster créé
- ✅ Tokens générés
- ✅ TLS activé automatiquement
```

### Workflow Complet

```bash
# 1. Sur le MANAGER
docker swarm init --advertise-addr 192.168.1.10

# 2. Obtenir les tokens
docker swarm join-token worker
docker swarm join-token manager

# 3. Distribuer les tokens aux workers

# 4. Sur chaque WORKER
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377

# 5. Vérifier
docker node ls
```

---

## 💡 EXEMPLES

### Exemple 1 : Configuration Minimale

```bash
# ========== MANAGER (192.168.1.10) ==========

# 1. Initialiser
docker swarm init --advertise-addr 192.168.1.10

# Output:
# Swarm initialized: current node (abc123...) is now a manager.
# 
# To add a worker to this swarm, run the following command:
#     docker swarm join --token SWMTKN-1-abc123... 192.168.1.10:2377

# 2. Vérifier
docker node ls

# Output:
# ID            HOSTNAME      STATUS    AVAILABILITY   MANAGER STATUS
# abc123...     manager       Ready     Active         Leader


# ========== WORKER 1 (192.168.1.11) ==========

# 1. Joindre le Swarm
docker swarm join --token SWMTKN-1-abc123... 192.168.1.10:2377

# Output:
# This node joined a swarm as a worker.

# 2. Vérifier
docker node ls
# (voir le manager et soi-même)


# ========== WORKER 2 (192.168.1.12) ==========

# (Même que Worker 1)

docker swarm join --token SWMTKN-1-abc123... 192.168.1.10:2377

# ========== DE NOUVEAU SUR LE MANAGER ==========

# Voir tous les nœuds
docker node ls

# Output:
# ID            HOSTNAME      STATUS    AVAILABILITY   MANAGER STATUS
# abc123...     manager       Ready     Active         Leader
# def456...     worker1       Ready     Active         
# ghi789...     worker2       Ready     Active
```

---

### Exemple 2 : Inspection Détaillée

```bash
# Voir l'état complet du Swarm
docker swarm inspect

# Output : Informations Swarm (JSON)

# Voir un nœud spécifique
docker node inspect manager

# Output : Détails du nœud
# {
#   "ID": "abc123...",
#   "Version": {...},
#   "CreatedAt": "2024-03-30T10:00:00.000Z",
#   "UpdatedAt": "2024-03-30T10:05:00.000Z",
#   "Spec": {
#     "Labels": {},
#     "Role": "manager",
#     "Availability": "active"
#   },
#   "Status": {
#     "State": "ready",
#     "Addr": "192.168.1.10"
#   },
#   ...
# }
```

---

### Exemple 3 : Gestion des Tokens

```bash
# Voir le token worker
docker swarm join-token worker

# Output:
# To add a worker to this swarm, run the following command:
#     docker swarm join --token SWMTKN-1-1234567890... 192.168.1.10:2377

# Voir le token manager
docker swarm join-token manager

# Output:
# To add a manager to this swarm, run the following command:
#     docker swarm join --token SWMTKN-2-1234567890... 192.168.1.10:2377

# Régénérer les tokens (invalide les anciens)
docker swarm join-token --rotate worker

# Output:
# Token rotated. New token generated for worker:
# SWMTKN-1-newtoken...
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Initialiser Swarm Localement

**Objectif** : Créer un Swarm sur une seule machine (test)

```bash
# Remarque : En pratique avec plusieurs VMs, c'est identique
# Cette démo utilise une seule machine

# 1. Initialiser
docker swarm init --advertise-addr 127.0.0.1

# 2. Vérifier
docker node ls
# Devrait montrer 1 manager

# 3. Voir les tokens
docker swarm join-token worker
# Copier le output

# 4. Quitter le Swarm (pour demo)
docker swarm leave --force

# 5. Vérifier que c'est quitté
docker node ls
# ❌ Error: This node is not a swarm manager
```

**Résultat attendu** : ✅ Swarm créé, testé, quitté

---

### Exercice 2 : Simuler 3 Nœuds (avec Docker in Docker)

**Objectif** : Tester avec plusieurs conteneurs simulant des nœuds

```bash
# ATTENTION : C'est avancé, skip si pas familier

# 1. Créer un Manager container
docker run -d --name swarm-manager \
  --privileged \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  docker:latest \
  sleep 3600

# 2. Initialiser Swarm dans ce container
docker exec swarm-manager docker swarm init

# 3. Obtenir le token
TOKEN=$(docker exec swarm-manager \
  docker swarm join-token worker -q)

# 4. Créer 2 workers
docker run -d --name swarm-worker1 \
  --privileged \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  docker:latest sleep 3600

docker run -d --name swarm-worker2 \
  --privileged \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  docker:latest sleep 3600

# 5. Joindre les workers (complexe, skip les détails)

# 6. Vérifier
docker exec swarm-manager docker node ls

# 7. Nettoyer
docker rm -f swarm-manager swarm-worker1 swarm-worker2
```

**Résultat attendu** : ✅ Cluster multi-nœuds simulé

---

### Exercice 3 : Topologie Réelle (Recommandé)

**Objectif** : Créer un vrai cluster avec VMs

```bash
# ========== PREPARATION ==========

# Supposons VMs disponibles :
# VM1: 192.168.1.10 (Manager)
# VM2: 192.168.1.11 (Worker)
# VM3: 192.168.1.12 (Worker)

# ========== SUR TOUTES LES VMs ==========

ssh debian@192.168.1.10  # (répéter pour .11, .12)

# 1. Installer Docker (voir leçon 02 pour détails)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh

# 2. Synchroniser l'horloge
sudo apt install -y ntp
sudo systemctl restart ntp
timedatectl status

# 3. Ouvrir les ports
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp

# ========== SUR LE MANAGER (192.168.1.10) ==========

# 4. Initialiser Swarm
docker swarm init --advertise-addr 192.168.1.10

# 5. Obtenir le token
docker swarm join-token worker
# Copier la commande complète

# ========== SUR CHAQUE WORKER ==========

# 6. Joindre (copier-coller la commande obtenue)
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377

# ========== VERIFICATION ==========

# 7. Sur le Manager
docker node ls

# Devrait afficher :
# ID            HOSTNAME    STATUS    MANAGER STATUS
# abc123...     manager     Ready     Leader
# def456...     worker1     Ready     
# ghi789...     worker2     Ready
```

**Résultat attendu** : ✅ Cluster 3 nœuds fonctionnel

---

## ⚠️ Pièges Courants

### ❌ "Error: This node is not a swarm manager"

**Cause** : Swarm n'est pas initialisé

```bash
# ❌ ERREUR
docker service create nginx

# ✅ SOLUTION
docker swarm init --advertise-addr 192.168.1.10
docker service create nginx  # Maintenant ça marche
```

---

### ❌ "Timeout joining swarm"

**Cause** : Réseau/Firewall bloquent la communication

```bash
# ❌ Vérifier la connectivité
ping 192.168.1.10  # Manager

# ❌ Vérifier les ports
telnet 192.168.1.10 2377

# ✅ SOLUTION
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp
```

---

### ❌ "Horloge non synchronisée"

**Cause** : NTP n'est pas activé (très important pour TLS)

```bash
# ❌ ERREUR : Horloge différentes
timedatectl status
# Synchronized: no

# ✅ SOLUTION
sudo apt install -y ntp
sudo systemctl restart ntp
timedatectl status
# Synchronized: yes
```

---

## 🔗 Prochaine Leçon

Votre cluster Swarm est maintenant opérationnel !

**Prochaine étape** → [07_ajouter_nodes.md](07_ajouter_nodes.md) : Expander le cluster dynamiquement

---

## ✅ Vérification

Avant de continuer :

- [ ] Docker installé sur toutes les machines
- [ ] Swarm initialisé sur le Manager
- [ ] Tokens générés
- [ ] Tous les workers joints
- [ ] `docker node ls` affiche tous les nœuds

---

**Durée de cette leçon** : 40 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-05
