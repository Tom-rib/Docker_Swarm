# 🎓 LEÇON 22 : Plan de Récupération Après Sinistre

**Prérequis** : Leçons 01-21

---

## 🎯 Objectif

- ✅ Plan RTO/RPO
- ✅ Récupération du cluster
- ✅ Restauration des données

---

## 📖 Concept

### RTO/RPO

```
RTO (Recovery Time Objective) = Temps pour revenir en ligne
RPO (Recovery Point Objective) = Quantité de données perdues

Objectif :
  RTO < 1 heure
  RPO < 15 minutes
```

---

## 💡 EXEMPLES

```bash
# Plan de récupération
# 1. Backup manager state
docker exec manager docker swarm inspect > swarm-state.json

# 2. Backup volumes
for vol in $(docker volume ls -q); do
  docker run --rm -v $vol:/data -v /backups:/bak \
    ubuntu tar czf /bak/$vol.tar.gz /data
done

# 3. Restauration
# Relancer manager avec state
# Restore volumes depuis backups
```

---

## ✅ Vérification

- [ ] Créer plan DR
- [ ] Tester restauration
- [ ] Vérifier RTO/RPO

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
