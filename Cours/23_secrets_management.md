# 🎓 LEÇON 23 : Gestion des Secrets

**Prérequis** : Leçons 01-22

---

## 🎯 Objectif

- ✅ Créer et gérer des secrets
- ✅ Les passer aux services
- ✅ Sécuriser les données sensibles

---

## 💡 EXEMPLES

```bash
# Créer un secret
echo "mon-password-secret" | docker secret create db-pwd -

# Utiliser dans un service
docker service create \
  --secret db-pwd \
  -e DB_PASSWORD_FILE=/run/secrets/db-pwd \
  mysql:latest

# Lister les secrets
docker secret ls

# Supprimer
docker secret rm db-pwd
```

---

## ✅ Vérification

- [ ] Créer un secret
- [ ] L'utiliser dans un service
- [ ] Vérifier qu'il n'est pas en plaintext

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
