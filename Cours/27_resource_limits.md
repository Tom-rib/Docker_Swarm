# 🎓 LEÇON 27 : Limites de Ressources

**Prérequis** : Leçons 01-26

---

## 🎯 Objectif

- ✅ CPU limits
- ✅ Memory limits
- ✅ Eviter OOMKilled

---

## 💡 EXEMPLES

```bash
# Limiter CPU (0.5 = 50% d'un core)
docker service create \
  --limit-cpu 0.5 \
  nginx:latest

# Limiter RAM
docker service create \
  --limit-memory 512M \
  mysql:latest

# Réserver des ressources
docker service create \
  --reserve-cpu 0.25 \
  --reserve-memory 256M \
  app:latest

# Vérifier
docker stats
```

---

## ✅ Vérification

- [ ] Créer service avec CPU limit
- [ ] Créer service avec RAM limit
- [ ] Observer avec docker stats

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
