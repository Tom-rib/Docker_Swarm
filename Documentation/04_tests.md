# 04 - Tests et Vérifications

**Objectif :** Vérifier que le cluster fonctionne correctement et tester sa résilience.

## 📋 Plan de Tests

1. Santé générale du cluster
2. Accessibilité des services
3. Persistance des données
4. Résilience (défaillance de conteneur)
5. Simulation de perte de nœud
6. Récupération automatique

## ✅ Test 1 : Santé du Cluster

### État des Nœuds

```bash
# Sur le manager
docker node ls

# Tous les nœuds doivent être "Ready"
# ID        HOSTNAME   STATUS   AVAILABILITY
# xxx       manager    Ready    Active
# xxx       worker1    Ready    Active
# xxx       worker2    Ready    Active
```

### État des Services

```bash
# Vérifier que tous les services ont le bon nombre de replicas
docker service ls

# Chaque service doit afficher "replicas X/X"
```

### État du Réseau

```bash
# Lister les réseaux Swarm
docker network ls

# Vérifier le réseau overlay
docker network inspect swarm-app_swarm-net
```

**Résultat attendu :** Tous les conteneurs connectés au réseau.

## 🔌 Test 2 : Accès aux Services

### Registry

```bash
# Vérifier que le registry répond
curl -I http://192.168.1.100:5000/v2/

# Résultat attendu : 200 OK
```

### VSCode

```bash
# Depuis ta machine, accède à :
# https://192.168.1.100:8443
# Mot de passe : vscodepassword
```

### Nginx / PHP

```bash
# Tester la page d'accueil
curl http://192.168.1.100/

# Ou depuis un autre PC :
# http://192.168.1.100 dans le navigateur
```

### MariaDB

```bash
# Test de connexion
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword -e "SHOW DATABASES;"

# Résultat attendu :
# +--------------------+
# | Database           |
# +--------------------+
# | app_db             |
# | information_schema |
# +--------------------+
```

## 💾 Test 3 : Persistance des Données

### Vérifier les Données NFS

```bash
# Sur le manager, vérifier les fichiers existants
ls -la /swarm-data/

# Résultat attendu :
# drwxr-xr-x  registry
# drwxr-xr-x  mariadb
# drwxr-xr-x  nginx
# drwxr-xr-x  php
# drwxr-xr-x  vscode
```

### Créer des Données de Test

```bash
# Créer une table dans MariaDB
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "CREATE TABLE test (id INT, name VARCHAR(100)); INSERT INTO test VALUES (1, 'Test Data');"

# Vérifier que les données sont présentes
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SELECT * FROM test;"

# Résultat attendu :
# +------+-----------+
# | id   | name      |
# +------+-----------+
# | 1    | Test Data |
# +------+-----------+
```

## 💥 Test 4 : Résilience - Arrêter un Conteneur

### Tuer un Conteneur ManuelementGénérer

```bash
# Sur le manager, voir les conteneurs en cours
docker ps

# Choisir un conteneur et l'arrêter
docker stop <CONTAINER_ID>

# Exemple :
# docker stop a3f4e2b1c9d8
```

### Vérifier la Récupération Automatique

```bash
# Attendre quelques secondes, puis vérifier
docker ps

# Résultat attendu : Le conteneur a été remplacé par un nouveau
# (L'ID du conteneur aura changé)

# Vérifier qu'aucun replica n'a été perdu
docker service ls

# Les replicas doivent rester à "2/2" (ou le ratio attendu)
```

**C'est ça la résilience :** Swarm relance automatiquement les conteneurs morts. ✓

## 🔥 Test 5 : Défaillance d'un Nœud Worker

### Arrêter un Worker Complètement

```bash
# Sur worker1, arrête Docker
sudo systemctl stop docker

# Ou brute force : éteins la VM
# shutdown -h now
```

### Observer le Comportement

Depuis le **manager** :

```bash
# Vérifier l'état des nœuds
docker node ls

# Résultat attendu :
# ID        HOSTNAME   STATUS     AVAILABILITY
# xxx       manager    Ready      Active
# xxx       worker1    Down       Active  ← Celui-ci est DOWN
# xxx       worker2    Ready      Active

# Voir où les conteneurs ont été redémarrés
docker ps

# Les conteneurs de worker1 devraient être relancés sur worker2
```

### Vérifier la Haute Disponibilité

```bash
# Les services doivent toujours répondre
curl http://192.168.1.100/

# MariaDB doit toujours être accessible
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SELECT * FROM test;"

# Résultat attendu :
# Les données sont toujours là et le service répond
```

### Redémarrer le Worker

```bash
# Relance worker1
# - Via la console de la VM : reboot
# - Ou via SSH : sudo reboot

# Après quelques secondes/minutes, vérifier :
docker node ls

# worker1 devrait revenir en "Ready"
```

## 🔄 Test 6 : Basculement et Récupération

### Vérifier les Données Après Défaillance

```bash
# Les données devraient être intactes dans MariaDB
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SELECT * FROM test;"

# Résultat attendu :
# +------+-----------+
# | id   | name      |
# +------+-----------+
# | 1    | Test Data |
# +------+-----------+
```

### Vérifier la Redistribution des Conteneurs

```bash
# Une fois worker1 revenu en Ready
docker service ps swarm-app_nginx

# Les replicas Nginx devraient être redistribués
# certains peuvent être sur worker2, d'autres sur worker1 (revendu)
```

## 📊 Test 7 : Monitoring Basique

### Utilisation des Ressources

```bash
# Sur chaque nœud, vérifier la mémoire/CPU
free -h
top -n1 | head -20

# Ou sur le manager :
docker stats
```

### Logs des Services

```bash
# Afficher les logs du service registry
docker service logs swarm-app_registry

# Logs du service mariadb
docker service logs swarm-app_mariadb

# Logs en temps réel
docker service logs -f swarm-app_nginx
```

## 📝 Fiche Mémoire - Tests

**État global :**
```bash
docker node ls
docker service ls
docker ps
```

**Logs :**
```bash
docker service logs nom-service
docker service logs -f nom-service  # Temps réel
```

**Tester la résilience :**
```bash
# Arrêter un conteneur
docker stop <ID>

# Après quelques secondes, il est relancé automatiquement
docker ps
```

**Arrêter un worker :**
```bash
# Sur le worker
sudo systemctl stop docker
# ou
sudo shutdown -h now
```

## ✅ Checklist de Validation

Marque ce qui est OK :

- [ ] Tous les nœuds affichent "Ready"
- [ ] Tous les services affichent "replicas X/X"
- [ ] Nginx répond sur http://192.168.1.100
- [ ] VSCode est accessible sur https://192.168.1.100:8443
- [ ] MariaDB peut être connectée (test SELECT)
- [ ] Les données persistent après arrêt d'un conteneur
- [ ] Un conteneur arrêté est relancé automatiquement
- [ ] Les données persistent après défaillance d'un nœud
- [ ] Les services restent accessibles pendant défaillance
- [ ] Les conteneurs sont redistribués quand un nœud revient

**Si tout est coché ✓ ton cluster est résilient et fonctionnel !**

## 🚀 Prochaine Étape

Tu as fini les tests ? Consulte [05_annexes.md](./05_annexes.md) pour les commandes utiles et le dépannage.

---

**La vraie valeur d'un cluster Swarm, c'est la haute disponibilité. Si un truc tombe, le cluster redémarre automatiquement. Bravo ! 🎉**
