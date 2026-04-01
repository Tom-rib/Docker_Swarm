# 🎓 LEÇON 8 : Déployer des Services dans Swarm

**Prérequis** : Leçons 01-07 (Docker + Swarm basiques)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Créer un service Swarm
- ✅ Déployer une application sur plusieurs nœuds
- ✅ Vérifier que le service fonctionne
- ✅ Accéder à l'application via ports exposés
- ✅ Différence entre `docker run` et `docker service create`

**Durée** : 25 minutes de lecture + 20 minutes de pratique

---

## 📖 Concept 1 : Service vs Conteneur

### Conteneur Docker (Une Seule Machine)

```bash
docker run -d nginx:latest

┌─────────────────────────────────┐
│         Machine 1               │
│                                 │
│    ┌──────────────┐             │
│    │  Container   │             │
│    │  Nginx       │             │
│    │  (Running)   │             │
│    └──────────────┘             │
│                                 │
│    ❌ Si tombe : Manuel restart │
│    ❌ Si besoin plus : Aucune   │
└─────────────────────────────────┘
```

### Service Swarm (Cluster Entier)

```bash
docker service create -d nginx:latest

┌──────────── CLUSTER ────────────┐
│  Manager (orchestration)        │
│  ┌──────────────────────────┐   │
│  │ État du service :        │   │
│  │ Name: nginx              │   │
│  │ Replicas: 3/3 (voulu)   │   │
│  │ Status: Running          │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌────┐ ┌────┐ ┌────┐         │
│  │Task│ │Task│ │Task│         │
│  │  1 │ │  2 │ │  3 │         │
│  └────┘ └────┘ └────┘         │
│   Node1  Node2  Node3          │
│                                 │
│  ✅ Si 1 tombe : Redémarrage   │
│  ✅ Si besoin plus : Scale up  │
│  ✅ Balancing automatique       │
└─────────────────────────────────┘
```

---

## 📖 Concept 2 : Création d'un Service

### Anatomie d'une Commande

```bash
docker service create \
  --name mon-app            # ← Nom du service
  --replicas 3              # ← Nombre de copies
  --publish 80:8080         # ← Port : external:container
  --network swarm-net       # ← Réseau
  --env VAR=value           # ← Variables d'env
  --limit-memory 512M       # ← Limites
  nginx:latest              # ← Image
```

### Workflow Détaillé

```
docker service create --name nginx --replicas 2 nginx:latest
│
├─ Manager reçoit l'ordre
│  └─ Crée une définition du service
│
├─ Manager planifie 2 tâches
│  ├─ Tâche 1 → assigner au Worker1
│  └─ Tâche 2 → assigner au Worker2
│
├─ Worker1 reçoit : "Lance nginx tâche 1"
│  └─ docker pull nginx:latest
│  └─ docker run -d ... nginx:latest
│
├─ Worker2 reçoit : "Lance nginx tâche 2"
│  └─ docker pull nginx:latest
│  └─ docker run -d ... nginx:latest
│
└─ Manager surveille
   ├─ Tâche 1 : Running ✅
   └─ Tâche 2 : Running ✅
```

---

## 📖 Concept 3 : Réplicas et Load Balancing

### Replicas = Copies du Service

```
Service : nginx
Replicas souhaitées : 3

┌─────────────────────────────────┐
│       Service Nginx              │
│  Replicas actives : 3/3 (OK)     │
├─────────────────────────────────┤
│                                 │
│  Replica 1    Replica 2    Replica 3
│  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  │ Nginx   │  │ Nginx   │  │ Nginx   │
│  │ Node1   │  │ Node2   │  │ Node3   │
│  └────┬────┘  └────┬────┘  └────┬────┘
│       │             │             │
│       └─────────────┼─────────────┘
│                     │
│              Load Balancer (Swarm)
│              ┌─────────────────┐
│              │ Ingress Network │
│              │ Port 80         │
│              └────────┬────────┘
│                       │
│                 Utilisateur
│             curl http://localhost
│
│  Requête 1 → Node1
│  Requête 2 → Node2
│  Requête 3 → Node3
│  Requête 4 → Node1 (round-robin)
│
└─────────────────────────────────┘
```

### Auto-Scaling

```
Initial : 3 replicas

Scenario 1 : Un node tombe
  Replicas voulues : 3
  Replicas actives : 2  ❌
  → Manager relance sur autre node
  → Replicas actives : 3  ✅

Scenario 2 : On veut 5 replicas
  docker service update --replicas 5 nginx
  Replicas actives : 5
  → 2 nouveaux containers lancés automatiquement

Scenario 3 : On veut réduire à 1
  docker service update --replicas 1 nginx
  Replicas actives : 1
  → 4 containers arrêtés intelligemment
```

---

## 💡 EXEMPLES

### Exemple 1 : Service Web Simple

```bash
# 1. Créer un service Nginx de base
docker service create \
  --name webserver \
  --replicas 2 \
  --publish 80:80 \
  nginx:latest

# Output:
# hf3c8ypqnvz8
# overall progress: 2 out of 2 tasks running

# 2. Vérifier
docker service ls

# Output:
# ID            NAME         MODE        REPLICAS   IMAGE          PORTS
# hf3c8ypq...   webserver    replicated  2/2        nginx:latest   *:80->80/tcp

# 3. Voir les tâches
docker service ps webserver

# Output:
# ID            NAME        IMAGE         NODE        DESIRED STATE
# a1b2c3d4...   webserver.1 nginx:latest  worker1     Running
# e5f6g7h8...   webserver.2 nginx:latest  worker2     Running

# 4. Tester d'accès
curl http://localhost
# Output: <html><body><h1>Welcome to nginx!</h1></body></html>

# 5. Tester depuis une autre machine (avec IP du Manager)
curl http://192.168.1.10
# Output: Same

# ✅ Service en cours d'exécution sur 2 nœuds !
```

---

### Exemple 2 : Service avec Environnement

```bash
# Service PHP avec variables de base de données
docker service create \
  --name php-app \
  --replicas 3 \
  --publish 9000:9000 \
  --env MYSQL_HOST=mariadb \
  --env MYSQL_USER=appuser \
  --env MYSQL_PASSWORD=secret123 \
  --network swarm-net \
  php:8.2-fpm

# Vérifier les variables
docker service inspect php-app

# (cherchez la section "Env")
```

---

### Exemple 3 : Service avec Limites de Ressources

```bash
# Service limité à 512MB de RAM et 0.5 CPU
docker service create \
  --name memory-limited \
  --replicas 2 \
  --limit-memory 512M \
  --limit-cpu 0.5 \
  nginx:latest

# Vérifier les limites
docker service inspect memory-limited

# Cherchez :
# "Resources": {
#   "Limits": {
#     "NanoCPUs": 500000000,  (= 0.5 CPU)
#     "MemoryBytes": 536870912  (= 512M)
#   }
# }
```

---

### Exemple 4 : Accéder aux Logs

```bash
# Voir les logs d'un service
docker service logs webserver

# Output:
# webserver.1.a1b2c3d4... | 192.168.1.100 - - [30/Mar/2024] "GET / HTTP/1.1" 200
# webserver.2.e5f6g7h8... | 192.168.1.101 - - [30/Mar/2024] "GET / HTTP/1.1" 200

# Logs en direct
docker service logs webserver -f

# Dernier 50 lignes
docker service logs webserver --tail 50
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Votre Premier Service

**Objectif** : Créer un service Nginx simple

```bash
# 1. Créer le service
docker service create \
  --name mon-nginx \
  --replicas 2 \
  --publish 8080:80 \
  nginx:latest

# 2. Vérifier qu'il fonctionne
docker service ls
# Devrait montrer : mon-nginx  replicated  2/2

# 3. Voir les tâches
docker service ps mon-nginx
# Devrait montrer 2 tâches sur 2 nœuds différents (si possible)

# 4. Accéder
curl http://localhost:8080
# Devrait afficher : <html>...</html>

# 5. Supprimer le service
docker service rm mon-nginx
# Vérifier :
docker service ls | grep mon-nginx
# (devrait être vide)
```

**Résultat attendu** : ✅ Service créé, testé, supprimé

---

### Exercice 2 : Comprendre les Replicas

```bash
# 1. Créer un service avec 1 replica
docker service create \
  --name redis-test \
  --replicas 1 \
  redis:latest

# Vérifier
docker service ps redis-test
# Devrait montrer 1 tâche

# 2. Augmenter à 3 replicas
docker service update --replicas 3 redis-test

# Vérifier (attendre 10 secondes)
docker service ps redis-test
# Devrait montrer 3 tâches !

# 3. Réduire à 1
docker service update --replicas 1 redis-test

# Vérifier
docker service ps redis-test
# Devrait montrer 1 tâche (les 2 autres arrêtées)

# 4. Nettoyer
docker service rm redis-test
```

**Résultat attendu** : ✅ Vous comprenez comment changer les replicas

---

### Exercice 3 : Service avec Configuration

```bash
# 1. Créer un service Nginx avec config personnalisée
docker service create \
  --name nginx-custom \
  --replicas 2 \
  --publish 8081:80 \
  --env "SERVER_NAME=myapp.local" \
  nginx:latest

# 2. Vérifier les variables
docker service inspect nginx-custom
# (Chercher la section "Env" ou "Config")

# 3. Accéder
curl http://localhost:8081

# 4. Voir les nœuds où ça s'exécute
docker service ps nginx-custom
# Devrait montrer sur 2 nœuds différents

# 5. Nettoyer
docker service rm nginx-custom
```

**Résultat attendu** : ✅ Service avec environnement personnalisé

---

## ⚠️ Pièges Courants

### ❌ "docker run" vs "docker service create"

```bash
# ❌ MAUVAIS : docker run (sur 1 seul nœud)
docker run -d nginx:latest
# Crée un conteneur sur le nœud local SEULEMENT

# ✅ BON : docker service create (sur tout le cluster)
docker service create nginx:latest
# Crée un service répliqué sur plusieurs nœuds
```

### ❌ "Service arrêté après démarrage"

```bash
# ❌ MAUVAIS : Service qui s'arrête
docker service create alpine:latest ping google.com

# ❌ ERREUR : alpine s'arrête après 1 ping

# ✅ BON : Processus qui continue
docker service create alpine:latest sleep 3600
# La commande continue pendant 1 heure

# ✅ MIEUX : Image avec service continu
docker service create nginx:latest
# Nginx continue indéfiniment
```

### ❌ "Quelle est l'adresse IP du service ?"

```bash
# ❌ MAUVAIS : Chercher l'IP du conteneur
docker ps
docker inspect <CONTAINER_ID>
# Les conteneurs sont sur des nœuds différents !

# ✅ BON : Utiliser le port exposé (ingress)
curl http://localhost:80
# Swarm gère automatiquement le load balancing

# ✅ OU : Utiliser le DNS interne
docker exec <CONTAINER> nslookup nginx
# DNS Swarm résout automatiquement
```

---

## 🔗 Prochaine Leçon

Vous pouvez maintenant créer des services !

**Prochaine étape** → [09_replicas_et_ha.md](09_replicas_et_ha.md) : La haute disponibilité

---

## ✅ Vérification

Avant de continuer :

- [ ] Créer un service avec `docker service create`
- [ ] Vérifier que le service fonctionne
- [ ] Changer le nombre de replicas
- [ ] Accéder à l'application via le port exposé
- [ ] Expliquer la différence docker run vs docker service create

---

**Durée de cette leçon** : 45 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-07

