# 🎓 LEÇON 32 : Optimisation des Performances

**Prérequis** : Leçons 01-31 (TOUT LE COURS !)

---

## 🎯 Objectif

- ✅ Profiler les applications
- ✅ Identifier les goulets
- ✅ Optimiser

---

## 💡 EXEMPLES

```bash
# Voir l'utilisation
docker stats --no-stream

# CPU hot spots
# Profiler l'application (langagespécifique)

# Mémoire
docker service update --limit-memory 2G app

# Disque
docker volume prune
docker image prune

# Network
# Utiliser un profiler réseau

# Optimisation Dockerfile
# - Multi-stage builds
# - Minimal images
# - Layer caching

# Scaling
docker service update --replicas 10 app
```

---

## ✅ Vérification

- [ ] Identifier les goulots
- [ ] Optimiser les images
- [ ] Scaler les services

---

## 🎓 FELICITATIONS !

Vous avez complété **32 leçons** sur Docker Swarm !

**Prochaines étapes** :
- Mettre en production
- Kubernetes (niveau suivant)
- Contributions open-source

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé | **Prérequis** : TOUTES les leçons
