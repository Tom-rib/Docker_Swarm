# 🎓 LEÇON 19 : Deploy des Stacks Swarm

**Prérequis** : Leçons 01-18

---

## 🎯 Objectif

- ✅ Déployer une stack Swarm
- ✅ Différences compose vs stack
- ✅ Gérrer les stacks

---

## 📖 Concept

### Stack = docker-compose pour Swarm

```
docker-compose up      (développement local)
docker stack deploy    (production Swarm)

Stack :
- Déploie sur tous les nœuds
- Répliques automatiques
- Services interconnectés
```

---

## 💡 EXEMPLES

```bash
# Créer compose pour Swarm
cat > stack.yml << 'YAML'
version: '3.9'
services:
  web:
    image: nginx:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
    ports:
      - "80:80"
  db:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: secret
YAML

# Déployer la stack
docker stack deploy -c stack.yml myapp

# Gérer
docker stack ls
docker stack ps myapp
docker stack rm myapp
```

---

## ✅ Vérification

- [ ] Créer stack.yml
- [ ] Déployer avec docker stack deploy
- [ ] Voir les services

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
