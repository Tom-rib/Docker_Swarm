# 🎓 LEÇON 10 : Mettre à Jour les Services Sans Downtime

**Prérequis** : Leçons 01-09 (Docker + Swarm + Services + HA)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Comprendre les rolling updates
- ✅ Mettre à jour une image Docker
- ✅ Mettre à jour les ports et variables
- ✅ Monitorer une mise à jour en cours
- ✅ Rollback en cas de problème

**Durée** : 20 minutes de lecture + 20 minutes de pratique

---

## 📖 Concept 1 : Rolling Updates

### Princip

e : Mise à jour graduelle

```
AVANT : 3 instances v1.0
├─ Instance 1 : nginx:1.0 Running
├─ Instance 2 : nginx:1.0 Running
└─ Instance 3 : nginx:1.0 Running

PENDANT (rolling update) :
├─ Instance 1 : nginx:1.0 Running
├─ Instance 2 : nginx:1.1 Starting  ← Mise à jour
└─ Instance 3 : nginx:1.0 Running

PENDANT (suite) :
├─ Instance 1 : nginx:1.1 Starting  ← Mise à jour
├─ Instance 2 : nginx:1.1 Running
└─ Instance 3 : nginx:1.0 Running

APRÈS : 3 instances v1.1
├─ Instance 1 : nginx:1.1 Running
├─ Instance 2 : nginx:1.1 Running
└─ Instance 3 : nginx:1.1 Running

✅ ZERO DOWNTIME
✅ Certaines instances v1.0 pendant la transition
✅ Load balancer dirige vers v1.1 quand prête
```

### Configuration de Rolling Update

```bash
docker service create \
  --name mon-app \
  --replicas 3 \
  --update-delay 10s \        # 10s entre les mises à jour
  --update-parallelism 1 \    # 1 instance à la fois
  --update-failure-action pause \  # Pause en cas d'erreur
  nginx:latest
```

---

## 📖 Concept 2 : Types de Mises à Jour

```
1. IMAGE CHANGE (nginx:1.0 → nginx:1.1)
   docker service update --image nginx:1.1 mon-app

2. PORTS CHANGE (80:80 → 8080:80)
   docker service update --publish-rm 80:80 --publish-add 8080:80

3. VARIABLES CHANGE
   docker service update --env-rm VAR1 --env-add VAR1=nouveau

4. REPLICAS CHANGE
   docker service update --replicas 5

5. CONTRAINTES CHANGE
   docker service update --constraint-rm "node.role==manager"
```

---

## 💡 EXEMPLES

### Exemple 1 : Mettre à Jour l'Image

```bash
# 1. Créer service avec image v1.0
docker service create \
  --name app \
  --replicas 3 \
  --publish 80:80 \
  nginx:1.20

# 2. Vérifier
docker service ls
# app : 3/3, nginx:1.20

# 3. Mettre à jour vers v1.21
docker service update --image nginx:1.21 app

# 4. Observer la mise à jour (rolling)
docker service ps app

# Output (progression) :
# app.1  nginx:1.21  worker1  Preparing
# app.2  nginx:1.20  worker2  Running
# app.3  nginx:1.20  worker3  Running

# (après quelques secondes)
# app.1  nginx:1.21  worker1  Running
# app.2  nginx:1.21  worker2  Preparing
# app.3  nginx:1.20  worker3  Running

# (après quelques secondes)
# app.1  nginx:1.21  worker1  Running
# app.2  nginx:1.21  worker2  Running
# app.3  nginx:1.21  worker3  Running

# 5. Service toujours accessible pendant la mise à jour
curl http://localhost:80
# ✅ Pas de erreur même pendant la transition
```

---

### Exemple 2 : Mettre à Jour avec Configuration

```bash
# 1. Service actuel
docker service inspect app | grep -A 5 "Env"

# 2. Ajouter/Modifier une variable
docker service update \
  --env-add NODE_ENV=production \
  app

# 3. Changer les ports
docker service update \
  --publish-rm 80:80 \
  --publish-add 8000:80 \
  app

# 4. Vérifier les changements
curl http://localhost:8000
# ✅ Accessible sur le nouveau port
```

---

### Exemple 3 : Rollback en Cas d'Erreur

```bash
# 1. Service actuel : nginx:1.21 (suppose problème)
docker service inspect app | grep "Image"

# 2. Rollback vers version précédente
docker service update --rollback app

# Output:
# rollback requested

# 3. Observer le rollback (rolling)
docker service ps app

# Les instances reviennent à nginx:1.20

# 4. Vérifier
docker service inspect app | grep "Image"
# Output: nginx:1.20
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Rolling Update Simple

**Objectif** : Mettre à jour une image sans downtime

```bash
# 1. Créer service avec 3 replicas
docker service create \
  --name update-test \
  --replicas 3 \
  --publish 8080:80 \
  nginx:1.20

# 2. Vérifier qu'il tourne
curl http://localhost:8080
# Output: Welcome to nginx

# 3. Mettre à jour vers 1.21
docker service update --image nginx:1.21 update-test

# 4. Observer en temps réel
watch -n 1 "docker service ps update-test"

# 5. Continuer à accéder pendant la mise à jour
for i in {1..10}; do
  curl -s http://localhost:8080 > /dev/null
  echo "Requête $i : OK"
  sleep 1
done

# ✅ Toutes les requêtes réussissent (ZERO DOWNTIME)

# 6. Vérifier que tout utilise 1.21
docker service ps update-test | grep nginx:1.21

# 7. Nettoyer
docker service rm update-test
```

**Résultat attendu** : ✅ Mise à jour sans downtime

---

### Exercice 2 : Rollback

**Objectif** : Revenir à la version précédente

```bash
# 1. Créer et mettre à jour
docker service create --name rollback-test --replicas 2 nginx:1.20
docker service update --image nginx:1.21 rollback-test

# 2. Vérifier la version actuelle
docker service inspect rollback-test | grep Image

# 3. Rollback
docker service update --rollback rollback-test

# 4. Vérifier qu'on est revenu
docker service inspect rollback-test | grep Image
# nginx:1.20

# 5. Nettoyer
docker service rm rollback-test
```

**Résultat attendu** : ✅ Rollback réussi

---

## ⚠️ Pièges Courants

### ❌ "Update se bloque"

**Cause** : Une instance ne démarre pas

```bash
# ❌ MAUVAIS : Pause en cas d'erreur (par défaut)
docker service create --update-failure-action pause ...

# ✅ BON : Continue ou rollback
docker service create --update-failure-action continue ...
# ou
docker service create --update-failure-action rollback ...
```

---

### ❌ "Pas de nouveau déploiement d'image même"

```bash
# ❌ PROBLEM : Même image tag, mais contenu changé
docker build -t myapp:1.0 .
docker service create myapp:1.0
# (modifier Dockerfile)
docker build -t myapp:1.0 .  # Même tag !
docker service update --image myapp:1.0 ...
# Ne redéploiera pas (même tag)

# ✅ SOLUTION : Forcer le redéploiement
docker service update --force myapp-service
# Redéploiera toutes les instances
```

---

## 🔗 Prochaine Leçon

Vous maîtrisez maintenant les mises à jour sans downtime !

**Prochaine étape** → [11_logs_et_monitoring.md](11_logs_et_monitoring.md) : Monitorer vos services

---

## ✅ Vérification

Avant de continuer :

- [ ] Mettre à jour l'image d'un service
- [ ] Vérifier que c'est sans downtime
- [ ] Rollback vers la version précédente
- [ ] Changer les ports d'un service
- [ ] Monitorer une mise à jour en cours

---

**Durée de cette leçon** : 40 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-09
