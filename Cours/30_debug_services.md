# 🎓 LEÇON 30 : Debugging et Diagnostique

**Prérequis** : Leçons 01-29

---

## 🎯 Objectif

- ✅ Outils de debug
- ✅ Analyser les problèmes
- ✅ Logs et traces

---

## 💡 EXEMPLES

```bash
# Logs détaillés
docker service logs --tail 50 -f myapp

# Inspecter un service
docker service inspect myapp | jq '.Spec.TaskTemplate'

# Voir l'historique
docker service ps myapp

# Event log du cluster
docker events --filter service=myapp

# Accéder au shell
docker exec -it container_id /bin/bash

# Diagnostic complet
docker system df
docker system prune -a
```

---

## ✅ Vérification

- [ ] Lire les logs
- [ ] Inspecter un service
- [ ] Voir l'historique

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
