# 🎓 LEÇON 25 : RBAC et Contrôle d'Accès

**Prérequis** : Leçons 01-24

---

## 🎯 Objectif

- ✅ Créer des utilisateurs avec permissions
- ✅ RBAC (Role-Based Access Control)
- ✅ Limiter les droits

---

## 💡 EXEMPLES

```bash
# Swarm ne peut pas faire de RBAC natif
# Solution : Token + API restrictions

# Créer token avec permissions limitées
docker node inspect manager | grep ID

# Utiliser Docker API avec token restrictif
# curl -H "Authorization: Bearer $TOKEN" \
#   https://localhost:2376/v1.40/nodes

# Meilleur: Utiliser Kubernetes pour RBAC avancé
# Ou layer Portainer/UCP pour RBAC UI
```

---

## ✅ Vérification

- [ ] Comprendre les limitations RBAC Swarm
- [ ] Connaître les alternatives

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
