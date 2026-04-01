# 🎓 LEÇON 18 : Docker Compose - Fichiers YAML

**Prérequis** : Leçons 01-17

---

## 🎯 Objectif

- ✅ Syntaxe docker-compose.yml
- ✅ Définir services
- ✅ Volumes et réseaux
- ✅ Variables d'environnement

---

## 📖 Concept

### Structure docker-compose.yml

```yaml
version: '3.9'
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    networks:
      - app-net
  
  db:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: secret
    networks:
      - app-net
    volumes:
      - db-data:/var/lib/mysql

volumes:
  db-data:

networks:
  app-net:
    driver: bridge
```

---

## 💡 EXEMPLES

```bash
# Créer fichier
cat > docker-compose.yml << 'YAML'
version: '3.9'
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
  mysql:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: secret
YAML

# Tester (non-Swarm)
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose down
```

---

## ✅ Vérification

- [ ] Créer docker-compose.yml
- [ ] Lancer les services
- [ ] Vérifier avec docker-compose ps

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
