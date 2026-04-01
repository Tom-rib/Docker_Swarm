# 🎓 LEÇON 24 : Certificats TLS et HTTPS

**Prérequis** : Leçons 01-23

---

## 🎯 Objectif

- ✅ Générer certificats auto-signés
- ✅ Configurer HTTPS
- ✅ Chiffrer la communication

---

## 💡 EXEMPLES

```bash
# Générer certificat auto-signé
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout key.pem -out cert.pem -days 365

# Utiliser dans Nginx
docker service create \
  --mount type=bind,source=/path/to/cert.pem,target=/etc/nginx/cert.pem \
  --mount type=bind,source=/path/to/key.pem,target=/etc/nginx/key.pem \
  nginx:latest

# Config nginx
# server {
#   listen 443 ssl;
#   ssl_certificate /etc/nginx/cert.pem;
#   ssl_certificate_key /etc/nginx/key.pem;
# }
```

---

## ✅ Vérification

- [ ] Générer certificat
- [ ] Configurer Nginx
- [ ] Tester HTTPS

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
