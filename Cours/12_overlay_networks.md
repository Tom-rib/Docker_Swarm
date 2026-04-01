# 🎓 LEÇON 12 : Overlay Networks - Communication Multi-Nœuds

**Prérequis** : Leçons 01-11 (Docker + Swarm complet)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Créer un overlay network
- ✅ Connecter des services à un overlay
- ✅ Communication multi-nœuds automatique
- ✅ Isolation réseau
- ✅ Chiffrement des données

**Durée** : 20 minutes de lecture + 20 minutes de pratique

---

## 📖 Concept 1 : Qu'est-ce qu'un Overlay Network ?

### Bridge vs Overlay

```
BRIDGE (Docker par défaut)
├─ Une seule machine
├─ 172.17.0.0/16
├─ Les conteneurs se voient
└─ Pas de communication inter-machines

OVERLAY (Swarm)
├─ Toutes les machines du cluster
├─ 10.0.x.0/24 (virtualizado)
├─ Les services se voient partout
├─ Communication via VXLAN (chiffré)
└─ ✅ Parfait pour Swarm
```

### Architecture VXLAN

```
┌─────────────────────┐         ┌─────────────────────┐
│   Worker 1          │         │   Worker 2          │
│  Service A (IP1)    │         │  Service B (IP2)    │
│       │             │         │       │             │
│       └─────────────┼─────────┼───────┘             │
│      Overlay Tunnel │         │                     │
│       (VXLAN)       │         │                     │
│  10.0.9.0/24        │         │  10.0.9.0/24        │
└─────────────────────┘         └─────────────────────┘

✅ Services communiquent comme s'ils étaient sur le même réseau
✅ Données chiffrées en transit
✅ Transparent pour l'application
```

---

## 📖 Concept 2 : Créer un Overlay Network

### Commande

```bash
docker network create --driver overlay mon-overlay

--driver overlay    = Type de réseau
mon-overlay        = Nom du réseau
```

### Optionnel

```bash
docker network create \
  --driver overlay \
  --subnet 10.0.9.0/24 \
  --opt com.docker.network.driver.mtu=1450 \
  mon-overlay

--subnet           = Plage d'adresses
--opt mtu          = Taille maximale des paquets
```

---

## 💡 EXEMPLES

### Exemple 1 : Overlay Simple

```bash
# 1. Créer overlay network
docker network create --driver overlay swarm-net

# 2. Vérifier
docker network ls
# Output: swarm-net  overlay  swarm

# 3. Détails du réseau
docker network inspect swarm-net
# Output: Subnet: 10.0.9.0/24

# 4. Lancer deux services sur ce réseau
docker service create \
  --name db \
  --network swarm-net \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:latest

docker service create \
  --name app \
  --network swarm-net \
  ubuntu:latest \
  sleep 3600

# 5. Test de communication
# Depuis app, pinger db
docker exec -it $(docker ps -q -f label=com.docker.swarm.service.name=app | head -1) \
  ping db

# Output:
# PING db (10.0.9.x): ...
# 64 bytes from 10.0.9.x: icmp_seq=0

# ✅ Communication réussie !
```

---

### Exemple 2 : Services Multi-Nœuds

```bash
# 1. Overlay sur tous les nœuds
docker network create --driver overlay prod-net

# 2. Service Web sur Worker 1
docker service create \
  --name web \
  --network prod-net \
  --constraint node.role!=manager \
  nginx:latest

# 3. Service DB sur Worker 2
docker service create \
  --name db \
  --network prod-net \
  --constraint node.role!=manager \
  mysql:latest

# 4. Voir la distribution
docker service ps web
docker service ps db

# Ils sont sur des nœuds différents !

# 5. Mais ils communiquent quand même
# (Overlay tunnel automatique)

docker exec -it $(docker ps -q -f label=com.docker.swarm.service.name=web | head -1) \
  curl http://db:3306

# ✅ Communication multi-nœuds transparente !
```

---

### Exemple 3 : Isolation Réseau

```bash
# 1. Créer 2 overlays différents
docker network create --driver overlay net1
docker network create --driver overlay net2

# 2. Service sur net1
docker service create \
  --name app1 \
  --network net1 \
  ubuntu:latest \
  sleep 3600

# 3. Service sur net2
docker service create \
  --name app2 \
  --network net2 \
  ubuntu:latest \
  sleep 3600

# 4. Tester la communication
CONTAINER1=$(docker ps -q -f label=com.docker.swarm.service.name=app1 | head -1)

docker exec $CONTAINER1 ping app2
# ❌ ping: unknown host app2

# ✅ Isolation réussie ! app1 ne voit pas app2
# (Ils ne sont pas sur le même réseau overlay)
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Overlay de Base

**Objectif** : Créer et tester un overlay network

```bash
# 1. Créer overlay
docker network create --driver overlay test-net

# 2. Créer 2 services
docker service create \
  --name server \
  --network test-net \
  --replicas 2 \
  nginx:latest

docker service create \
  --name client \
  --network test-net \
  --replicas 1 \
  ubuntu:latest \
  sleep 3600

# 3. Tester communication
CONTAINER=$(docker ps -q -f label=com.docker.swarm.service.name=client | head -1)

docker exec $CONTAINER apt-get update > /dev/null 2>&1
docker exec $CONTAINER apt-get install -y iputils-ping > /dev/null 2>&1
docker exec $CONTAINER ping -c 3 server

# Output:
# PING server (10.0.x.x) ...
# 3 packets transmitted, 3 received

# ✅ Communication fonctionnelle

# 4. Nettoyer
docker service rm server client
docker network rm test-net
```

**Résultat attendu** : ✅ Overlay créé et testé

---

### Exercice 2 : Isolation Réseau

**Objectif** : Vérifier l'isolation entre deux overlays

```bash
# 1. Créer 2 overlays
docker network create --driver overlay isolated1
docker network create --driver overlay isolated2

# 2. Services sur overlay1
docker service create \
  --name isolated1-svc \
  --network isolated1 \
  ubuntu:latest \
  sleep 3600

# 3. Services sur overlay2
docker service create \
  --name isolated2-svc \
  --network isolated2 \
  ubuntu:latest \
  sleep 3600

# 4. Vérifier l'isolation
CONTAINER=$(docker ps -q -f label=com.docker.swarm.service.name=isolated1-svc | head -1)

docker exec $CONTAINER apt-get update > /dev/null 2>&1
docker exec $CONTAINER apt-get install -y iputils-ping > /dev/null 2>&1

docker exec $CONTAINER ping -c 1 isolated2-svc
# ❌ ping: unknown host isolated2-svc

# ✅ Isolation confirmée

# 5. Nettoyer
docker service rm isolated1-svc isolated2-svc
docker network rm isolated1 isolated2
```

**Résultat attendu** : ✅ Isolation vérifiée

---

## ⚠️ Pièges Courants

### ❌ "Services ne communiquent pas"

**Cause** : Pas connectés au même overlay

```bash
# ❌ MAUVAIS
docker service create --name app1 nginx  # Pas de réseau spécifié

# ✅ BON
docker network create --driver overlay mynet
docker service create --name app1 --network mynet nginx
docker service create --name app2 --network mynet mysql
```

---

## 🔗 Prochaine Leçon

**Prochaine étape** → [13_dns_discovery.md](13_dns_discovery.md) : Découverte DNS automatique

---

## ✅ Vérification

- [ ] Créer un overlay network
- [ ] Connecter des services
- [ ] Tester la communication
- [ ] Vérifier l'isolation

---

**Durée** : 40 minutes | **Niveau** : 🟡 Intermédiaire | **Prérequis** : 01-11
