# 🎓 LEÇON 7 : Ajouter des Nœuds au Cluster Swarm

**Prérequis** : Leçon 06 (Initialiser Swarm)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Ajouter des workers au cluster
- ✅ Promouvoir un worker en manager
- ✅ Gérer dynamiquement les nœuds
- ✅ Vérifier la santé des nœuds
- ✅ Gérer les défaillances de nœuds

**Durée** : 20 minutes de lecture + 20 minutes de pratique

---

## 📖 Concept 1 : Ajouter des Workers

### Workflow

```
docker swarm join-token worker
        │
        ▼
Copier le token
        │
        ▼
ssh debian@192.168.1.11  (nouveau worker)
        │
        ▼
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377
        │
        ▼
✅ Worker rejoint le cluster
```

### Vérification

```bash
# Sur le Manager
docker node ls

# Avant : 1 manager
# Après : 1 manager + 1 worker
```

---

## 📖 Concept 2 : Ajouter des Managers (Haute Disponibilité)

### Quorum

```
Nombre de Managers    Peut perdre
1                     0 (❌ FRAGILE)
2                     0 (❌ FRAGILE)
3                     1 (✅ BON)
5                     2 (✅ TRÈS BON)
7+                    Trop (lent)
```

### Processus de Promotion

```
Worker existant
     │
     ├─ docker node promote worker1
     │
     ▼
Worker → Manager
     │
     ├─ Rejoint le consensus RAFT
     ├─ Participe aux décisions
     └─ Peut recevoir des tâches
```

---

## 💡 EXEMPLES

### Exemple 1 : Ajouter un Worker Simple

```bash
# ========== SUR LE MANAGER ==========

# 1. Obtenir le token
docker swarm join-token worker

# Output:
# docker swarm join --token SWMTKN-1-1234567890... 192.168.1.10:2377


# ========== SUR LE NOUVEAU WORKER ==========

# 2. Joindre le cluster (exécuter la commande du Manager)
docker swarm join --token SWMTKN-1-1234567890... 192.168.1.10:2377

# Output:
# This node joined a swarm as a worker.


# ========== VERIFICATION SUR LE MANAGER ==========

# 3. Lister les nœuds
docker node ls

# Output:
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Ready     
# ghi789...       worker2          Ready      ← Nouveau !

# 4. Obtenir des détails du nouveau worker
docker node inspect worker2

# Output : JSON avec tous les détails
```

---

### Exemple 2 : Promouvoir un Worker en Manager

```bash
# ========== SUR LE MANAGER ==========

# 1. Voir les workers disponibles
docker node ls

# Output:
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Ready     

# 2. Promouvoir worker1 en manager
docker node promote worker1

# Output:
# Manager status changed: worker1 - No manager -> Manager

# 3. Vérifier
docker node ls

# Output:
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Ready     Reachable  ← Maintenant manager !

# 4. Voir que worker1 est maintenant manager
docker node inspect worker1 | grep -A 5 "Spec"

# Output:
# "Spec": {
#   "Labels": {},
#   "Role": "manager",     ← Changé de "worker" à "manager"
#   "Availability": "active"
```

---

### Exemple 3 : Gérer les Défaillances

```bash
# ========== SCENARIO : UN WORKER TOMBE EN PANNE ==========

# Sur le Manager, observer
docker node ls

# Avant :
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Ready     

# Après défaillance (attendre ~30 sec) :
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Down      ← Status changé !

# ========== SOLUTION 1 : REDÉMARRER LE WORKER ==========

# Redémarrer physiquement la machine/VM
# (ou docker daemon)

# Après redémarrage (~30 sec) :
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Ready     ← Revenu !

# ========== SOLUTION 2 : SUPPRIMER LE NŒUD ==========

# Si le nœud ne revient pas :
docker node rm worker1

# Vérifier
docker node ls
# worker1 disparaît de la liste

# (Les services sont redéployés sur d'autres nœuds)
```

---

### Exemple 4 : Gérer la Disponibilité

```bash
# ========== METTRE EN MAINTENANCE UN NŒUD ==========

# Empêcher les nouvelles tâches
docker node update --availability drain worker1

# Vérifier
docker node ls

# Output:
# ID              HOSTNAME         STATUS    AVAILABILITY   MANAGER STATUS
# abc123...       manager          Ready     Active         Leader
# def456...       worker1          Ready     Drain          ← Changé !

# Les tâches en cours sont redéployées
docker service ps webserver
# (Verra les tâches migrées de worker1)

# ========== RÉACTIVER LE NŒUD ==========

docker node update --availability active worker1

# Vérifier
docker node ls

# Output :
# ... AVAILABILITY Active ...  ← Revenu à la normale

# Les nouvelles tâches peuvent être placées ici
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Ajouter 2 Workers

**Objectif** : Commencer avec 1 manager, ajouter 2 workers

```bash
# ========== SUR LE MANAGER ==========

# 1. Voir l'état actuel
docker node ls
# Actuellement : 1 manager seulement

# 2. Obtenir le token
WORKER_TOKEN=$(docker swarm join-token worker -q)
echo $WORKER_TOKEN
# Output: SWMTKN-1-...

# ========== SUR WORKER 1 ==========

# 3. Joindre (remplacer le token)
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377

# ========== SUR WORKER 2 ==========

# 4. Joindre (même token)
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377

# ========== VERIFICATION ==========

# 5. Sur le Manager
docker node ls
# Devrait montrer : 1 manager + 2 workers
```

**Résultat attendu** : ✅ 3 nœuds dans le cluster

---

### Exercice 2 : Promouvoir un Worker

**Objectif** : Ajouter un deuxième manager

```bash
# ========== SUR LE MANAGER ==========

# 1. Voir les workers
docker node ls

# 2. Promouvoir worker1
docker node promote worker1

# 3. Vérifier
docker node ls
# Devrait montrer : 2 managers (Leader + Reachable) + 1 worker

# 4. Voir le quorum
docker node inspect worker1 | grep -i "manager"
# Output: "Reachable" (peut voter pour les décisions)

# ========== BONUS : PROMOUVOIR LE DEUXIEME ==========

# 5. Promouvoir worker2 aussi (pour 3 managers au total)
docker node promote worker2

# 6. Vérifier le quorum maintenant
docker node ls
# 3 managers, quorum = 2 (peut perdre 1)
```

**Résultat attendu** : ✅ 3 managers, haute disponibilité

---

### Exercice 3 : Gérer la Défaillance (Simulation)

**Objectif** : Simuler une défaillance de worker

```bash
# ========== SCENARIO : ARRETER UN WORKER ==========

# 1. Sur le Worker lui-même
sudo systemctl stop docker
# (ou : sudo systemctl stop docker)

# ========== OBSERVATION ==========

# 2. Sur le Manager (observer dans 30 secondes)
watch -n 2 "docker node ls"

# Vous verrez :
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Down      ← STATUS CHANGE !

# ========== REDEMARRER ==========

# 3. Redémarrer le worker
# (Soit redémarrer la machine, soit)
ssh debian@192.168.1.11
sudo systemctl start docker

# ========== VERIFICATION ==========

# 4. Sur le Manager (après ~30 sec)
docker node ls

# Output :
# ID              HOSTNAME         STATUS    MANAGER STATUS
# abc123...       manager          Ready     Leader
# def456...       worker1          Ready     ← REVENU !
```

**Résultat attendu** : ✅ Détection auto + récupération

---

## ⚠️ Pièges Courants

### ❌ "Workers ne se connectent pas"

**Cause** : Firewall ou réseau

```bash
# ❌ ERREUR
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377
# Timeout...

# ✅ VERIFICATION
ping 192.168.1.10
# Doit réussir

telnet 192.168.1.10 2377
# Doit connecter

# ✅ SOLUTION
# Ouvrir les ports sur le Manager
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp
```

---

### ❌ "Trop de managers ralentit le cluster"

**Cause** : Consensus RAFT est lent avec beaucoup de nœuds

```bash
# ❌ MAUVAIS : 7 managers
docker node ls
# 7 managers = consensus lent

# ✅ BON : 3-5 managers max
# 3 = quorum 2, perte tolerance 1
# 5 = quorum 3, perte tolerance 2
```

---

## 🔗 Prochaine Leçon

Vous pouvez maintenant gérer un cluster dynamiquement !

**Prochaine étape** → [08_services_basiques.md](08_services_basiques.md) : Déployer des services

---

## ✅ Vérification

Avant de continuer :

- [ ] Ajouter un worker au cluster
- [ ] Promouvoir un worker en manager
- [ ] Mettre un nœud en "drain"
- [ ] Réactiver un nœud
- [ ] Voir les détails d'un nœud

---

**Durée de cette leçon** : 40 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçon 06
