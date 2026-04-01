# 🎓 LEÇON 11 : Logs et Monitoring des Services

**Prérequis** : Leçons 01-10 (Docker + Swarm complet)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Consulter les logs des services Swarm
- ✅ Monitorer les ressources (CPU, RAM)
- ✅ Observer les événements du cluster
- ✅ Diagnostiquer les problèmes
- ✅ Configurer les logs

**Durée** : 20 minutes de lecture + 20 minutes de pratique

---

## 📖 Concept 1 : Logs des Services

### Où sont les logs ?

```
Services Swarm
    │
    ├─ Logs stdout/stderr des conteneurs
    │  └─ Accessible via : docker service logs
    │
    ├─ Logs du daemon Docker
    │  └─ /var/log/docker.log (sur chaque nœud)
    │
    └─ Événements Swarm
       └─ docker events
```

### Commandes de Logs

```bash
# Logs d'un service
docker service logs mon-service

# Logs en temps réel
docker service logs -f mon-service

# Dernières N lignes
docker service logs --tail 50 mon-service

# Avec timestamps
docker service logs --timestamps mon-service

# Logs depuis un moment
docker service logs --since 5m mon-service
```

---

## 📖 Concept 2 : Monitoring des Ressources

### Affichage de l'Utilisation

```bash
docker stats

# Output :
# CONTAINER ID  NAME      CPU %    MEM USAGE
# abc123...     app.1     2.15%    256.5MiB
# def456...     app.2     1.89%    248.3MiB
# ghi789...     db.1      5.42%    1.2GiB
```

### Événements du Cluster

```bash
docker events | grep service

# Output :
# 2024-03-30T10:00:00.123Z service create myapp (image=nginx:latest)
# 2024-03-30T10:00:05.456Z service update myapp (replicas=3)
# 2024-03-30T10:00:15.789Z service_task_update myapp.1 ...
```

---

## 💡 EXEMPLES

### Exemple 1 : Lire les Logs

```bash
# 1. Créer un service
docker service create \
  --name logtest \
  --replicas 2 \
  nginx:latest

# 2. Voir les logs
docker service logs logtest

# Output:
# logtest.1.abc123... | /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty
# logtest.2.def456... | /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty

# 3. Logs en temps réel
docker service logs -f logtest

# (Laissez tourner, accédez au service dans un autre terminal)

# 4. Accéder au service
curl http://localhost
# (Vous verrez les logs d'accès dans le terminal des logs)

# 5. Quitter les logs (-f)
# Ctrl + C

# 6. Nettoyer
docker service rm logtest
```

---

### Exemple 2 : Monitorer les Ressources

```bash
# 1. Lancer un service gourmand
docker service create \
  --name memory-test \
  --limit-memory 512M \
  --replicas 3 \
  stress:latest

# 2. Monitorer les ressources
docker stats

# Output:
# CONTAINER ID  NAME            CPU %    MEM USAGE     MEM %
# abc123...     memory-test.1   45.23%   512MiB        100.0%
# def456...     memory-test.2   42.89%   510MiB        99.6%
# ghi789...     memory-test.3   48.12%   512MiB        100.0%

# 3. Voir si une instance surcharge
# (Si CPU ou MEM trop haut → optimiser ou augmenter replicas)

# 4. Arrêter le monitoring
# Ctrl + C

# 5. Nettoyer
docker service rm memory-test
```

---

### Exemple 3 : Diagnostiquer un Problème

```bash
# Scenario : Service down, déterminer pourquoi

# 1. Voir l'état du service
docker service ls
# Output:
# myapp  replicated  2/3  ...  ← Problème ! 2 sur 3 seulement

# 2. Voir les replicas
docker service ps myapp

# Output:
# ID       NAME    IMAGE    NODE     STATE
# abc...   myapp.1 app:1.0  worker1  Running
# def...   myapp.2 app:1.0  worker2  Running
# ghi...   myapp.3 app:1.0  worker3  Pending  ← Stuck !

# 3. Voir les logs pour le problème
docker service logs myapp

# Output:
# myapp.3 | OOMKilled
# ← Ah ! Out of Memory

# 4. Solution : Augmenter la mémoire
docker service update \
  --limit-memory 1G \
  myapp

# 5. Vérifier que ça redémarre
docker service ps myapp
# myapp.3 devrait maintenant être Running

# ✅ Problème résolu !
```

---

### Exemple 4 : Événements du Cluster

```bash
# 1. Afficher les événements en direct
docker events

# (Laissez tourner dans un terminal)

# 2. Dans un autre terminal, faire des changements
docker service create test nginx
docker service update --replicas 3 test
docker service rm test

# 3. Observer les événements :
# Output:
# ... service create test ...
# ... service_task_update test.1 ...
# ... service_task_update test.2 ...
# ... service_task_update test.3 ...
# ... service update test ...
# ... service_task_update test.1 ...
# ... service remove test ...

# ✅ Tous les changements sont visibles
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Lire les Logs

**Objectif** : Interpréter les logs d'un service

```bash
# 1. Créer service avec erreur intentionnelle
docker service create \
  --name error-test \
  ubuntu:latest \
  bash -c "echo 'Starting...' && sleep 1 && exit 1"

# 2. Voir les logs
docker service logs error-test

# Output:
# error-test.1 | Starting...

# 3. Voir l'état
docker service ps error-test

# Output:
# error-test.1  ...  Exited (1)

# ✅ Vous identifiez l'erreur (exit code 1)

# 4. Nettoyer
docker service rm error-test
```

**Résultat attendu** : ✅ Interprétation des logs réussie

---

### Exercice 2 : Monitoring

**Objectif** : Monitorer un service

```bash
# 1. Créer service
docker service create \
  --name monitoring \
  --replicas 2 \
  nginx:latest

# 2. Accéder au service pour générer du trafic
(
  while true; do
    curl -s http://localhost > /dev/null
    sleep 0.5
  done
) &

# 3. Monitorer
docker stats
# (Voir CPU augmenter pendant les requêtes)

# 4. Arrêter les requêtes
pkill -f "curl -s http"

# 5. Voir CPU revenir à normal
# (dans docker stats)

# 6. Nettoyer
docker service rm monitoring
```

**Résultat attendu** : ✅ Monitoring observé

---

### Exercice 3 : Diagnostiquer via Logs

**Objectif** : Trouver et fixer un problème via logs

```bash
# 1. Créer un service avec config incorrecte
docker service create \
  --name buggy \
  --env REDIS_URL=redis://wrong-host:6379 \
  --replicas 2 \
  python:3.9 \
  python -c "import redis; redis.from_url('$REDIS_URL').ping()"

# 2. Voir l'état
docker service ps buggy
# Status : Exited

# 3. Voir les logs pour déterminer le problème
docker service logs buggy

# Output:
# Error: Can't connect to Redis host 'wrong-host'
# ← Problème identifié !

# 4. Fixer la config
docker service update \
  --env-rm REDIS_URL \
  --env-add REDIS_URL=redis://localhost:6379 \
  buggy

# 5. Vérifier que ça fonctionne maintenant
docker service ps buggy
# Status : Running

# ✅ Problème fixé !

# 6. Nettoyer
docker service rm buggy
```

**Résultat attendu** : ✅ Diagnostic et fix réussis

---

## ⚠️ Pièges Courants

### ❌ "Logs vides ou pas à jour"

**Cause** : Service redémarré, logs non persistants

```bash
# ❌ PROBLEM : Les logs sont perdus
docker service create --replicas 2 app
# Si l'instance redémarre → logs anciens perdus

# ✅ SOLUTION : Logs centralisés
# Utiliser ELK, Splunk, ou logs driver
# (Voir leçon 28 pour détails)
```

---

### ❌ "Stats pour une seule instance"

```bash
# ❌ MAUVAIS : Voir l'util CPU seulement d'un container
docker stats abc123...

# ✅ BON : Voir tous les containers du service
docker stats | grep mon-service
```

---

## 🔗 Prochaine Leçon

Vous pouvez maintenant monitorer et diagnostiquer vos services !

**Prochaine étape** → [12_overlay_networks.md](12_overlay_networks.md) : Réseaux avancés

---

## ✅ Vérification

Avant de continuer :

- [ ] Lire les logs d'un service
- [ ] Monitorer les ressources
- [ ] Observer les événements
- [ ] Diagnostiquer un problème via logs
- [ ] Interpréter les messages d'erreur

---

**Durée de cette leçon** : 40 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-10
