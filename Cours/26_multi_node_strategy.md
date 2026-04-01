# 🎓 LEÇON 26 : Stratégies de Placement Multi-Nœuds

**Prérequis** : Leçons 01-25

---

## 🎯 Objectif

- ✅ Labels et constraints
- ✅ Placer services sur nœuds spécifiques
- ✅ Strategies anti-affinity

---

## 💡 EXEMPLES

```bash
# Label un nœud
docker node update --label-add ssd=true worker1

# Contrainte: utiliser ssd
docker service create \
  --constraint node.labels.ssd==true \
  heavy-app:latest

# Anti-affinity : pas sur même nœud
docker service create \
  --constraint node.role==worker \
  --placement-pref spread=node.hostname \
  nginx:latest
```

---

## ✅ Vérification

- [ ] Labeler des nœuds
- [ ] Créer service avec constraints
- [ ] Vérifier le placement

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
