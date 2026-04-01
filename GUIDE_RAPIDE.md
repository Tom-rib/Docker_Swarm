# 🚀 Guide Rapide - Docker Swarm en 15 Minutes

**Pour les gens pressés qui veulent juste que ça fonctionne !**

---

## 📋 Checklist Rapide

- [ ] 4+ VMs Debian créées
- [ ] Connectivité réseau OK (ping)
- [ ] NTP synchronisé
- [ ] Fichiers du projet clonés

---

## ⚡ Installation Ultra-Rapide

### 1️⃣ Sur le MANAGER (192.168.1.10)

```bash
# Télécharger les scripts
git clone <votre-repo> docker-swarm
cd docker-swarm/scripts

# Initialiser le Manager
sudo bash init_manager.sh 192.168.1.10

# Copier le token affiché
```

### 2️⃣ Sur CHAQUE WORKER (192.168.1.11, .12, .13)

```bash
# Télécharger les scripts
git clone <votre-repo> docker-swarm
cd docker-swarm/scripts

# Joindre le Swarm (remplacer TOKEN)
sudo bash init_worker.sh "SWMTKN-1-..." 192.168.1.10
```

### 3️⃣ Sur le MANAGER - Déployer les services

```bash
cd /home/debian/docker-swarm/scripts

# Déployer tous les services
bash deploy_services.sh 192.168.1.20

# Attendre ~30 secondes et vérifier
docker service ls
```

---

## 🧪 Tester que Ça Marche

```bash
# 1. Vérifier le cluster
docker node ls
# → Vous devez voir 4+ nœuds tous "Ready"

# 2. Vérifier les services
docker service ls
# → Vous devez voir 4 services avec REPLICAS X/X

# 3. Accéder à Nginx
curl http://localhost:80
# → Vous devez voir une page HTML

# 4. Lancer les tests
bash test_resilience.sh health
```

---

## 🔄 Cas d'Usage Courants

### Ajouter un Worker au Cluster

```bash
# Sur le Manager, obtenir le token
docker swarm join-token worker

# Copier et coller la commande sur la nouvelle VM
docker swarm join --token SWMTKN-1-... 192.168.1.10:2377
```

### Voir les Logs d'un Service

```bash
docker service logs mariadb
docker service logs nginx
docker service logs php-fpm
```

### Redéployer un Service (Restart)

```bash
docker service update --force mariadb
```

### Augmenter les Replicas

```bash
docker service update --replicas 3 mariadb
```

### Supprimer tout et recommencer

```bash
bash cleanup.sh
# Répondre "oui" et "--full" pour reset complet
```

---

## 🚨 Si Ça Ne Marche Pas

### ❌ "permission denied"

```bash
# Ajouter au groupe docker
sudo usermod -aG docker $USER
newgrp docker
```

### ❌ "Swarm not initialized"

```bash
# Manager SEULEMENT
docker swarm init --advertise-addr 192.168.1.10
```

### ❌ "Cannot connect to Manager"

```bash
# Vérifier ping
ping 192.168.1.10

# Vérifier les ports
ufw allow 2377/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp
```

### ❌ "NFS mount failed"

```bash
# Vérifier que le serveur NFS existe
ssh debian@192.168.1.20 "exportfs -v"

# Sur les workers, installer NFS
sudo apt install nfs-common
```

---

## 📊 Commandes Essentielles

```bash
# État du cluster
docker node ls          # Lister les nœuds
docker service ls       # Lister les services
docker service ps <SVC> # Voir les tâches d'un service

# Logs et monitoring
docker service logs <SVC>    # Voir les logs
docker stats                 # Voir les ressources
docker events                # Voir les événements

# Gestion
docker service create ...    # Créer un service
docker service update ...    # Modifier un service
docker service rm <SVC>      # Supprimer un service

# Networks & Volumes
docker network ls       # Lister les réseaux
docker volume ls        # Lister les volumes
```

---

## 📁 Structure du Projet

```
docker-swarm/
├── README.md                 ← Lire d'abord
├── 01_preparation.md         ← Concepts
├── 02_installation.md        ← Installation détaillée
├── 03_configuration.md       ← Configuration des services
├── 04_tests.md              ← Tests & simulation pannes
├── 05_annexes.md            ← Mémo & dépannage
├── GUIDE_RAPIDE.md          ← Vous êtes ici
├── scripts/
│   ├── init_manager.sh       ← Initialiser le Manager
│   ├── init_worker.sh        ← Initialiser les Workers
│   ├── deploy_services.sh    ← Déployer les services
│   ├── test_resilience.sh    ← Tests du cluster
│   └── cleanup.sh            ← Nettoyage complet
└── config/
    ├── docker-compose.yml    ← Stack complète
    ├── nginx.conf           ← Config Nginx
    └── .env.example         ← Variables d'env
```

---

## 🎯 Objectifs du Projet

Vous avez déployé une **infrastructure résiliente** qui :

✅ **Haute Disponibilité** : Les services continuent si une VM tombe  
✅ **Scalabilité** : Ajouter des workers facilement  
✅ **Continuité** : PCA/PRA testés et fonctionnels  
✅ **Stockage** : Données persistantes sur NFS  
✅ **Monitoring** : Logs et événements disponibles  

---

## 📞 Besoin d'Aide ?

| Question | Solution |
|----------|----------|
| "Ça marche pas" | Consulter [05_annexes.md](05_annexes.md) section Dépannage |
| "Comment fonctionne X ?" | Lire [01_preparation.md](01_preparation.md) |
| "Comment déployer Y ?" | Lire [03_configuration.md](03_configuration.md) |
| "Comment tester ?" | Lire [04_tests.md](04_tests.md) |
| "Quelle commande pour Z ?" | Chercher dans [05_annexes.md](05_annexes.md) Mémo |

---

## ⏱️ Timing Estimé

| Étape | Temps |
|-------|-------|
| Installation Docker | 5 min |
| Initialisation Swarm | 5 min |
| Déploiement services | 10 min |
| Tests | 15 min |
| **TOTAL** | **~35 min** |

---

## 🎓 Apprentissages Clés

Après ce projet, vous pouvez :

- ✅ Installer et configurer Docker Swarm
- ✅ Déployer des services en haute disponibilité
- ✅ Configurer des volumes persistants (NFS)
- ✅ Tester la résilience d'une infrastructure
- ✅ Monitorer et dépanner un cluster
- ✅ Implémenter PCA/PRA

---

## 💾 Sauvegarder Votre Travail

```bash
# Initialiser git
git init
git add .
git commit -m "Docker Swarm - Infrastructure résiliente"
git remote add origin https://github.com/votre-user/docker-swarm.git
git push -u origin main
```

---

## 🚀 Prochaines Étapes

Optionnel, mais recommandé :

1. **Ajouter la Persistance BD** : Backups automatiques de MariaDB
2. **Certificats SSL** : Activer HTTPS avec Let's Encrypt
3. **Monitoring Avancé** : Ajouter Prometheus + Grafana
4. **CI/CD** : Pipeline GitLab CI / GitHub Actions
5. **Multi-Swarm** : Fedération de clusters

---

## 📚 Ressources Utiles

- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Play with Docker](https://www.play-with-docker.com/) (Sandbox)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

---

**Bonne chance avec votre cluster ! 🎉**

Pour revenir à la documentation complète : [README.md](README.md)

