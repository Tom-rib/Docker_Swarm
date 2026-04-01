# 🎓 LEÇON 13 : DNS Discovery - Service Discovery

**Prérequis** : Leçons 01-12

---

## 🎯 Objectif

- ✅ Service discovery par nom DNS
- ✅ VIP (Virtual IP)
- ✅ Résolution automatique

---

## 📖 Concept

### Service Discovery

```
Dans un Swarm, au lieu de hardcoder les IPs:

MAUVAIS:  curl http://10.0.9.2:3306
BON:      curl http://db:3306

Swarm DNS résout:
  db → 10.0.9.2 (VIP - Virtual IP)
  
La VIP est automatiquement distribuée aux replicas
```

---

## 💡 EXEMPLES

```bash
# 1. Créer overlay
docker network create --driver overlay app-net

# 2. Services
docker service create --name db --network app-net mysql:latest
docker service create --name app --network app-net python:3.9

# 3. Depuis app, résoudre db
docker exec $(docker ps -q -f label=com.docker.swarm.service.name=app | head -1) \
  nslookup db

# Output:
# Name: db
# Address: 10.0.9.2  ← VIP
```

---

## ✅ Vérification

- [ ] Créer services sur overlay
- [ ] Résoudre le nom DNS
- [ ] Comprendre VIP

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
