# 🎓 LEÇON 31 : Troubleshooting Réseau

**Prérequis** : Leçons 01-30

---

## 🎯 Objectif

- ✅ Problèmes de connectivité
- ✅ DNS issues
- ✅ Firewall/ports bloqués

---

## 💡 EXEMPLES

```bash
# Ping entre services
docker exec container1 ping service2

# DNS resolution
docker exec container1 nslookup service2

# Lister les routes
docker exec container1 ip route

# Vérifier les ports ouverts
docker exec container1 netstat -tlnp

# Tester la connectivité
docker exec container1 curl http://service2:8080

# Vérifier le réseau du service
docker network inspect overlay-net
```

---

## ✅ Vérification

- [ ] Tester connectivité inter-services
- [ ] Vérifier DNS resolution
- [ ] Voir la topologie réseau

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
