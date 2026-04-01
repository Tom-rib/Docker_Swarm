# 🎓 LEÇON 20 : Healthchecks - Vérification de Santé

**Prérequis** : Leçons 01-19

---

## 🎯 Objectif

- ✅ Configurer healthchecks
- ✅ Détection des défaillances
- ✅ Actions automatiques

---

## 📖 Concept

### Healthcheck

```
Swarm vérifie régulièrement la santé

Healthy → Rester actif
Unhealthy → Redémarrer ou supprimer

Exemple: healthcheck toutes les 10 secondes
```

---

## 💡 EXEMPLES

```dockerfile
# Dans Dockerfile
HEALTHCHECK --interval=10s --timeout=5s CMD curl http://localhost/health

# Ou dans service
docker service create \
  --health-cmd='curl http://localhost/health' \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=3 \
  nginx:latest
```

---

## ✅ Vérification

- [ ] Créer healthcheck
- [ ] Observer dans docker ps
- [ ] Vérifier la santé

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
