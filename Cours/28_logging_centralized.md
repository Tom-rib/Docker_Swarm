# 🎓 LEÇON 28 : Logs Centralisés

**Prérequis** : Leçons 01-27

---

## 🎯 Objectif

- ✅ Centraliser les logs
- ✅ ELK Stack (Elasticsearch, Logstash, Kibana)
- ✅ Requêtes sur les logs

---

## 💡 EXEMPLES

```bash
# Driver de logging
docker service create \
  --log-driver splunk \
  --log-opt splunk-token=$TOKEN \
  --log-opt splunk-url=https://splunk-server:8088 \
  nginx:latest

# Ou JSON file (par défaut)
docker service create \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  nginx:latest

# Voir les logs
docker logs -f container_id
```

---

## ✅ Vérification

- [ ] Configurer log driver
- [ ] Envoyer logs quelque part
- [ ] Requêter les logs

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
