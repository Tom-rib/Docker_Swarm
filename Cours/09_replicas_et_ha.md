# 🎓 LEÇON 9 : Replicas et Haute Disponibilité

**Prérequis** : Leçons 01-08 (Docker + Swarm basics + Services)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Déployer un service avec plusieurs replicas
- ✅ Comprendre la haute disponibilité
- ✅ Tester la résilience automatique
- ✅ Équilibrer la charge entre replicas
- ✅ Scaler un service (ajouter/retirer replicas)

**Durée** : 20 minutes de lecture + 25 minutes de pratique

---

## 📖 Concept 1 : Replicas = Haute Disponibilité

### Sans Replicas (Fragile)

```
Service avec 1 replica
┌────────────────┐
│ Nginx Instance │ Running
│ Node 1         │
└────────────────┘

Si tombe :
┌────────────────┐
│ Nginx Instance │ Down ❌
│ Node 1         │
└────────────────┘

Résultat : Service DOWN pour tous les utilisateurs
```

### Avec Replicas (Résilient)

```
Service avec 3 replicas
┌────────────────┐
│ Nginx Instance │ Running
│ Node 1         │
└────────────────┘
         │
┌────────┴────────────────────┐
│                             │
┌────────────────┐  ┌─────────────────┐
│ Nginx Instance │  │ Nginx Instance  │
│ Node 2         │  │ Node 3          │
│ Running        │  │ Running         │
└────────────────┘  └─────────────────┘

Si Node 1 tombe :
┌────────────────┐
│ Nginx Instance │ Down ❌
│ Node 1         │
└────────────────┘ (Swarm relance ailleurs)

Résultat : Service TOUJOURS UP sur Node 2 & 3
           + Swarm relance une nouvelle instance
```

### Load Balancing Automatique

```
3 Replicas = 3 copies du service

Requête 1 → Node 1 (replica 1)
Requête 2 → Node 2 (replica 2)
Requête 3 → Node 3 (replica 3)
Requête 4 → Node 1 (replica 1) [round-robin]
...

✅ La charge est distribuée
✅ Pas de surcharge sur un seul nœud
```

---

## 📖 Concept 2 : Scaling (Augmenter/Réduire)

### Ajouter des Replicas

```bash
docker service update --replicas 5 mon-service

Avant : 3/3 replicas
          │
          ├─ Node 1 : 1 replica
          ├─ Node 2 : 1 replica
          └─ Node 3 : 1 replica

Après : 5/5 replicas
          │
          ├─ Node 1 : 2 replicas
          ├─ Node 2 : 2 replicas
          └─ Node 3 : 1 replica

✅ Nouvelles instances lancées automatiquement
✅ Load balancing réajusté
```

### Réduire des Replicas

```bash
docker service update --replicas 1 mon-service

Avant : 3/3 replicas
Après : 1/1 replica

✅ 2 instances arrêtées proprement
✅ Service continue de fonctionner sur 1 instance
```

---

## 💡 EXEMPLES

### Exemple 1 : Créer un Service HA

```bash
# 1. Créer service avec 3 replicas
docker service create \
  --name webserver \
  --replicas 3 \
  --publish 80:80 \
  nginx:latest

# 2. Vérifier
docker service ls

# Output:
# ID            NAME       MODE        REPLICAS   PORTS
# abc123...     webserver  replicated  3/3        *:80->80/tcp

# 3. Voir les replicas
docker service ps webserver

# Output:
# ID            NAME         IMAGE         NODE      STATE
# abc123...     webserver.1  nginx:latest  worker1   Running
# def456...     webserver.2  nginx:latest  worker2   Running
# ghi789...     webserver.3  nginx:latest  worker3   Running

# ✅ 3 instances sur 3 nœuds différents
```

---

### Exemple 2 : Scale UP

```bash
# 1. Augmenter à 5 replicas
docker service update --replicas 5 webserver

# 2. Observer la création
docker service ps webserver

# Output (pendant création):
# ID            NAME         IMAGE         NODE      STATE
# abc123...     webserver.1  nginx:latest  worker1   Running
# def456...     webserver.2  nginx:latest  worker2   Running
# ghi789...     webserver.3  nginx:latest  worker3   Running
# hij012...     webserver.4  nginx:latest  worker1   Running  ← NOUVEAU
# klm345...     webserver.5  nginx:latest  worker2   Running  ← NOUVEAU

# ✅ 2 nouvelles instances ajoutées
```

---

### Exemple 3 : Résilience en Action

```bash
# 1. Service en cours avec 3 replicas
docker service ps webserver

# Output:
# webserver.1  worker1   Running
# webserver.2  worker2   Running
# webserver.3  worker3   Running

# 2. Arrêter une instance (simulation défaillance)
# Obtenir l'ID du container:
CONTAINER=$(docker ps -q -f label=com.docker.swarm.service.name=webserver | head -1)

docker stop $CONTAINER

# 3. Observer (dans 5-10 secondes)
docker service ps webserver

# Output:
# webserver.1  worker1   Running
# webserver.2  worker2   Running  (NOUVEAU, relancé !)
# webserver.3  worker3   Running

# ✅ Service toujours 3/3
# ✅ Instance défaillante relancée automatiquement
# ✅ Zéro downtime pour les utilisateurs !
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Créer et Tester HA

**Objectif** : Service résilient avec 3 replicas

```bash
# 1. Créer service
docker service create \
  --name test-ha \
  --replicas 3 \
  --publish 8888:80 \
  nginx:latest

# 2. Vérifier les replicas
docker service ps test-ha
# Devrait montrer 3 instances

# 3. Accéder au service
curl http://localhost:8888
# Output: <html>...</html>

# 4. Arrêter une instance
CONTAINER=$(docker ps -q -f label=com.docker.swarm.service.name=test-ha | head -1)
docker stop $CONTAINER

# 5. Attendre ~10 secondes
sleep 10

# 6. Vérifier que replicas = 3/3 toujours
docker service ps test-ha
# Devrait montrer 3 instances (1 nouvelle)

# 7. Accéder de nouveau (service OK)
curl http://localhost:8888
# ✅ Toujours accessible

# 8. Nettoyer
docker service rm test-ha
```

**Résultat attendu** : ✅ Service résilient et auto-guérissant

---

### Exercice 2 : Scale UP/DOWN

**Objectif** : Ajouter et retirer des replicas

```bash
# 1. Créer avec 1 replica
docker service create \
  --name scale-demo \
  --replicas 1 \
  nginx:latest

# 2. Vérifier
docker service ls | grep scale-demo
# REPLICAS: 1/1

# 3. Scale UP à 4
docker service update --replicas 4 scale-demo

# 4. Observer
docker service ps scale-demo
# Devrait montrer 4 instances

# 5. Scale DOWN à 2
docker service update --replicas 2 scale-demo

# 6. Observer
docker service ps scale-demo
# Devrait montrer 2 instances seulement

# 7. Nettoyer
docker service rm scale-demo
```

**Résultat attendu** : ✅ Scaling automatique fonctionne

---

### Exercice 3 : Load Balancing

**Objectif** : Vérifier que les requêtes sont équilibrées

```bash
# 1. Créer 3 services avec contenu différent
docker service create \
  --name lb-test \
  --replicas 3 \
  --publish 9999:80 \
  apache:latest

# 2. Faire plusieurs requêtes
for i in {1..10}; do
  echo "Requête $i:"
  curl -s http://localhost:9999 | grep -o "Server.*" | head -1
done

# Output:
# Requête 1: Server: server1
# Requête 2: Server: server2
# Requête 3: Server: server3
# Requête 4: Server: server1
# ...

# ✅ Les requêtes sont distribuées !

# 3. Nettoyer
docker service rm lb-test
```

**Résultat attendu** : ✅ Load balancing vérifié

---

## ⚠️ Pièges Courants

### ❌ "Service 1/3 replicas"

**Cause** : Pas assez de nœuds, contraintes de placement

```bash
# ❌ ERREUR : 5 replicas mais 2 nœuds seulement
docker service create --replicas 5 nginx
# Résultat : 2/5 (pas assez d'espace)

# ✅ SOLUTION 1 : Ajouter des nœuds
docker node ls  # Vérifier nœuds disponibles

# ✅ SOLUTION 2 : Réduire les replicas
docker service update --replicas 2 mon-service
```

---

### ❌ "Service Down après défaillance"

**Cause** : Seulement 1 replica

```bash
# ❌ MAUVAIS : 1 replica
docker service create --replicas 1 nginx
# Si tombe → Service DOWN

# ✅ BON : Au minimum 2-3 replicas
docker service create --replicas 3 nginx
# Si 1 tombe → Service toujours UP
```

---

## 🔗 Prochaine Leçon

Vous comprenez maintenant la haute disponibilité !

**Prochaine étape** → [10_update_services.md](10_update_services.md) : Mettre à jour sans downtime

---

## ✅ Vérification

Avant de continuer :

- [ ] Créer un service avec 3 replicas
- [ ] Vérifier que les replicas sont sur des nœuds différents
- [ ] Arrêter une instance et vérifier la relance
- [ ] Scale UP et scale DOWN
- [ ] Tester le load balancing

---

**Durée de cette leçon** : 45 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-08
