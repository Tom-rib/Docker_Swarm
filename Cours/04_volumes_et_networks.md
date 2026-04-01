# 🎓 LEÇON 4 : Volumes et Réseaux Docker

**Prérequis** : Leçons 01-03 (Fondamentaux Docker)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Différences entre volumes et bind mounts
- ✅ Partager des données entre conteneurs
- ✅ Créer et gérer des réseaux Docker
- ✅ Faire communiquer des conteneurs
- ✅ Différences entre host, bridge, overlay

**Durée** : 25 minutes de lecture + 25 minutes de pratique

---

## 📖 Concept 1 : Volumes (Données Persistantes)

### Le Problème : Données Perdues

```
Conteneur lancé
    │
    ├─ Fichiers dedans
    ├─ Logs générés
    └─ Base de données

docker stop conteneur
docker rm conteneur
    │
    └─ ❌ Toutes les données PERDUES !
```

### La Solution : Volumes

```
┌──────────────────────┐
│  Hôte               │
│  /data (dossier)    │
│  ├─ base.db         │
│  └─ logs.txt        │
└──────────┬───────────┘
           │ Montage
           ▼
┌──────────────────────┐
│  Conteneur          │
│  /app/data          │
│  ├─ base.db  ←─────── Référence au dossier hôte
│  └─ logs.txt        │
└──────────────────────┘

✅ Même si conteneur supprimé
   Les données restent sur l'hôte
```

### Types de Volumes

```
1. Named Volume (Géré par Docker)
   docker volume create mon-volume
   docker run -v mon-volume:/data ...
   ✅ Facile, Docker gère tout

2. Bind Mount (Lien direct au système de fichiers)
   docker run -v /home/user/data:/data ...
   ✅ Accès direct aux dossiers

3. Anonymous Volume
   docker run -v /data ...
   ❌ Temporary, supprimé avec conteneur
```

---

## 📖 Concept 2 : Réseaux Docker

### Le Problème : Comment les Conteneurs Communiquent ?

```
❌ SANS RÉSEAU :
Conteneur A          Conteneur B
   │                     │
   └─ Isolés, ne peuvent pas se parler
   
✅ AVEC RÉSEAU :
Conteneur A  ──────  Conteneur B
   │ 172.18.0.2      172.18.0.3
   │
   └─ Réseau bridge ou overlay
      Peuvent communiquer par nom
```

### Types de Réseaux

```
1. bridge (par défaut)
   ├─ Isolé sur une machine
   ├─ Les conteneurs se voient
   ├─ Accès aux ports via host
   └─ Bon pour : développement local

2. host
   ├─ Partagé avec machine hôte
   ├─ Performance maximale
   ├─ Pas d'isolation réseau
   └─ Bon pour : hautes performances

3. overlay (Swarm)
   ├─ Multi-machines
   ├─ Communication cluster-wide
   ├─ Chiffré
   └─ Bon pour : Swarm, production
```

---

## 💡 EXEMPLES

### Exemple 1 : Partager des Données avec Volumes

```bash
# 1. Créer un volume
docker volume create mon-data

# 2. Lancer conteneur 1 qui écrit des données
docker run -d --name app1 \
  -v mon-data:/data \
  ubuntu:latest \
  bash -c "echo 'Data from App1' > /data/test.txt"

# 3. Lancer conteneur 2 qui lit les mêmes données
docker run -d --name app2 \
  -v mon-data:/data \
  ubuntu:latest \
  sleep 3600

# 4. Vérifier que app2 voit le fichier
docker exec app2 cat /data/test.txt
# Output: Data from App1

# 5. Supprimer les conteneurs (données persistent)
docker rm -f app1 app2

# 6. Vérifier que le volume existe toujours
docker volume ls | grep mon-data

# 7. Utiliser le volume dans un nouveau conteneur
docker run -it -v mon-data:/data ubuntu:latest
# root@...:/# cat /data/test.txt
# (Le fichier est toujours là !)
# root@...:/# exit

# 8. Nettoyer
docker volume rm mon-data
```

---

### Exemple 2 : Bind Mount (Dossier Hôte)

```bash
# 1. Créer un dossier sur l'hôte
mkdir /tmp/mon-app
echo "Version 1.0" > /tmp/mon-app/version.txt

# 2. Monter ce dossier dans le conteneur
docker run -it -v /tmp/mon-app:/app ubuntu:latest

# (Dans le conteneur)
# root@...:/# cat /app/version.txt
# Version 1.0

# 3. Éditer sur l'hôte
# (Dans un autre terminal)
echo "Version 2.0" > /tmp/mon-app/version.txt

# 4. Voir la modification dans le conteneur
# (Toujours dans le conteneur)
# root@...:/# cat /app/version.txt
# Version 2.0

# ✅ Les fichiers sont synchronisés en temps réel !
```

---

### Exemple 3 : Réseaux et Communication

```bash
# 1. Créer un réseau
docker network create mon-reseau

# 2. Lancer une base de données
docker run -d --name db \
  --network mon-reseau \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:latest

# 3. Lancer une application
docker run -d --name app \
  --network mon-reseau \
  -e DB_HOST=db \  # ← Peut utiliser le nom "db" !
  -e DB_PASSWORD=secret \
  ubuntu:latest \
  sleep 3600

# 4. Depuis l'app, pinger la bd
docker exec app ping db
# Output:
# PING db (172.18.0.2): 56 data bytes
# 64 bytes from 172.18.0.2: icmp_seq=0 ttl=64 time=0.123 ms

# ✅ Communication réussie !

# 5. Nettoyer
docker rm -f app db
docker network rm mon-reseau
```

---

### Exemple 4 : WordPress avec Volume et Réseau

```bash
# 1. Créer un réseau
docker network create wp-network

# 2. Lancer MariaDB avec volume
docker run -d --name wp-db \
  --network wp-network \
  -v wp-database:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wppass \
  mariadb:latest

# 3. Lancer WordPress avec volume
docker run -d --name wordpress \
  --network wp-network \
  -v wp-content:/var/www/html \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=wp-db \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppass \
  wordpress:latest

# 4. Accéder à WordPress
curl http://localhost:8080
# (affiche la page WordPress)

# 5. Les données persistent même si on supprime tout
docker rm -f wordpress wp-db
docker volume ls | grep wp-
# Les volumes sont toujours là !

# 6. Relancer et les données sont restaurées
docker run -d --name wp-db \
  --network wp-network \
  -v wp-database:/var/lib/mysql \
  ...

# (WordPress réappear avec les données anciennes)
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Volumes

**Objectif** : Comprendre la persistance des données

```bash
# 1. Créer un volume nommé
docker volume create mon-volume

# 2. Lancer un conteneur et créer un fichier
docker run -d --name test1 \
  -v mon-volume:/data \
  ubuntu:latest \
  bash -c "echo 'test' > /data/file.txt && sleep 3600"

# 3. Vérifier le fichier
docker exec test1 cat /data/file.txt
# Output: test

# 4. Supprimer le conteneur
docker rm -f test1

# 5. Lancer un nouveau conteneur avec le même volume
docker run -d --name test2 \
  -v mon-volume:/data \
  ubuntu:latest \
  sleep 3600

# 6. Vérifier que le fichier est toujours là
docker exec test2 cat /data/file.txt
# Output: test ✅

# 7. Nettoyer
docker rm test2
docker volume rm mon-volume
```

**Résultat attendu** : ✅ Données persistantes

---

### Exercice 2 : Réseaux et Communication

**Objectif** : Faire communiquer deux conteneurs

```bash
# 1. Créer un réseau
docker network create test-net

# 2. Lancer deux conteneurs sur ce réseau
docker run -d --name server \
  --network test-net \
  ubuntu:latest \
  sleep 3600

docker run -d --name client \
  --network test-net \
  ubuntu:latest \
  sleep 3600

# 3. Installer ping sur les deux
docker exec server apt-get update > /dev/null
docker exec server apt-get install -y iputils-ping > /dev/null

# 4. Depuis client, pinger server
docker exec client ping -c 3 server
# Output: ... 3 packets received, 0% loss ✅

# 5. Nettoyer
docker rm -f server client
docker network rm test-net
```

**Résultat attendu** : ✅ Communication inter-conteneurs

---

### Exercice 3 : Nginx avec Contenu Persistant

**Objectif** : Monter un dossier dans Nginx

```bash
# 1. Créer un dossier avec contenu
mkdir /tmp/www
echo "<h1>Mon Site</h1>" > /tmp/www/index.html

# 2. Lancer Nginx avec bind mount
docker run -d --name web \
  -v /tmp/www:/usr/share/nginx/html:ro \
  -p 8080:80 \
  nginx:latest

# 3. Tester
curl http://localhost:8080
# Output: <h1>Mon Site</h1>

# 4. Modifier le fichier sur l'hôte
echo "<h1>Mon Site v2</h1>" > /tmp/www/index.html

# 5. Tester à nouveau (pas besoin de redémarrer !)
curl http://localhost:8080
# Output: <h1>Mon Site v2</h1>

# 6. Nettoyer
docker rm -f web
rm -rf /tmp/www
```

**Résultat attendu** : ✅ Contenu dynamique partagé

---

## ⚠️ Pièges Courants

### ❌ "Volume créé où ?"

```bash
# ❌ FLOU : Où les données vont-elles ?
docker run -v /data ubuntu:latest

# ✅ CLAIR : Spécifier le volume
docker run -v mon-volume:/data ubuntu:latest
# Ou
docker run -v /home/user/data:/data ubuntu:latest
```

---

### ❌ "Conteneurs ne peuvent pas communiquer"

```bash
# ❌ MAUVAIS : Pas sur le même réseau
docker run -d --name app1 ubuntu:latest
docker run -d --name app2 ubuntu:latest
docker exec app1 ping app2
# ❌ Name resolution failed

# ✅ BON : Même réseau
docker network create mynet
docker run -d --name app1 --network mynet ubuntu:latest
docker run -d --name app2 --network mynet ubuntu:latest
docker exec app1 ping app2
# ✅ Fonctionne !
```

---

## 🔗 Prochaine Leçon

Vous maîtrisez maintenant le stockage et la communication Docker !

**Prochaine étape** → [05_swarm_concepts.md](05_swarm_concepts.md) : Passer à Docker Swarm

---

## ✅ Vérification

Avant de continuer :

- [ ] Créer et utiliser un volume nommé
- [ ] Partager des données entre conteneurs
- [ ] Créer un réseau Docker
- [ ] Faire communiquer deux conteneurs
- [ ] Monter un dossier de l'hôte

---

**Durée de cette leçon** : 50 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-03
