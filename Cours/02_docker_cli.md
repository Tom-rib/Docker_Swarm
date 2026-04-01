# 🎓 LEÇON 2 : Les Commandes Docker Essentielles

**Prérequis** : Leçon 01 (Bases Docker)

---

## 🎯 Objectif de cette Leçon

À la fin, vous maîtriserez :

- ✅ Les 10 commandes Docker les plus utiles
- ✅ Lancer, arrêter, et gérer des conteneurs
- ✅ Voir les logs et accéder au shell
- ✅ Inspecter des conteneurs
- ✅ Différence entre les flags courants

**Durée** : 20 minutes de lecture + 25 minutes de pratique

---

## 📖 Concept 1 : Structure d'une Commande Docker

### Anatomie

```bash
docker [COMMAND] [OPTIONS] [ARGUMENTS]
  │      │          │         │
  │      │          │         └─ Ce qu'on traite
  │      │          └─ Paramètres (--name, -d, etc.)
  │      └─ Action (run, ps, stop, etc.)
  └─ Programme Docker
```

### Exemple Concret

```bash
docker run -d -p 8080:80 --name webserver nginx:latest
        │   │   │         │                 │
        │   │   │         │                 └─ Image à utiliser
        │   │   │         └─ Nom du conteneur
        │   │   └─ Port (8080:80 = 8080 externe → 80 interne)
        │   └─ Mode détaché (arrière-plan)
        └─ Commande (lancer un conteneur)
```

### Types de Flags

```bash
# Flag court (une lettre)
docker run -d nginx
         │
         └─ Détaché (arrière-plan)

# Flag long (mot complet)
docker run --detach nginx
         │
         └─ Même chose, mais plus lisible

# Flag avec valeur
docker run -p 8080:80 nginx
         │           │
         └─ Flag     └─ Valeur
```

---

## 📖 Concept 2 : Les 10 Commandes Essentielles

### Hiérarchie des Commandes

```
docker
├─ run       → Lancer un conteneur
├─ ps        → Voir les conteneurs
├─ stop      → Arrêter un conteneur
├─ start     → Redémarrer un conteneur
├─ rm        → Supprimer un conteneur
├─ logs      → Voir les logs
├─ exec      → Exécuter une commande
├─ inspect   → Détails sur un conteneur
├─ pull      → Télécharger une image
└─ image     → Gérer les images
```

### Workflow Courant

```
docker pull image
        │
        ▼
docker run [options] image
        │
        ▼
Conteneur lancé (Running)
        │
        ├─ docker ps          (voir l'état)
        ├─ docker logs        (voir les logs)
        ├─ docker exec        (commander)
        │
        └─ docker stop        (arrêter)
        │
        └─ docker rm          (supprimer)
```

---

## 💡 EXEMPLES

### Exemple 1 : Workflow Complet

```bash
# 1. Télécharger l'image
docker pull nginx:latest
# Output: Pulling from library/nginx / ... / Status: Downloaded

# 2. Lancer le conteneur
docker run -d -p 8080:80 --name mon-web nginx:latest
# Output: a1b2c3d4e5f6... (ID unique)

# 3. Voir le conteneur
docker ps
# Output:
# CONTAINER ID  IMAGE          COMMAND  CREATED     STATUS      PORTS              NAMES
# a1b2c3d4...   nginx:latest   ...      5 sec ago   Up 3 sec    0.0.0.0:8080->80   mon-web

# 4. Voir les logs
docker logs mon-web
# Output:
# /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to apply all files...

# 5. Exécuter une commande
docker exec mon-web curl -s http://localhost/
# Output: <html><body><h1>Welcome to nginx!</h1></body></html>

# 6. Accéder au shell
docker exec -it mon-web /bin/bash
# root@a1b2c3d4:/# (vous êtes maintenant DANS le conteneur)
# root@a1b2c3d4:/# exit

# 7. Arrêter
docker stop mon-web

# 8. Redémarrer
docker start mon-web

# 9. Supprimer
docker stop mon-web
docker rm mon-web
```

---

### Exemple 2 : Voir les Détails

```bash
# 1. Inspecter un conteneur
docker inspect mon-web

# Output: JSON avec tous les détails
# {
#   "Id": "a1b2c3d4...",
#   "Created": "2024-03-30T10:00:00.000Z",
#   "State": {
#     "Status": "running",
#     "Pid": 12345,
#     "Running": true
#   },
#   ...
# }

# 2. Voir une information spécifique
docker inspect mon-web --format='{{.State.Status}}'
# Output: running

# 3. Voir l'IP interne
docker inspect mon-web --format='{{.NetworkSettings.IPAddress}}'
# Output: 172.17.0.2
```

---

### Exemple 3 : Flags Courants

```bash
# -d : Détaché (arrière-plan)
docker run -d nginx
# Lance et rend le contrôle immédiatement

# -it : Interactif + Terminal
docker run -it ubuntu:latest /bin/bash
# Vous pouvez taper des commandes directement

# -p : Port (external:internal)
docker run -p 8080:80 nginx
# Port 8080 dehors → Port 80 dedans

# -e : Variable d'environnement
docker run -e MYSQL_ROOT_PASSWORD=secret mysql:latest

# -v : Volume (partage disque)
docker run -v /data:/data nginx
# Dossier /data sur hôte → /data dans conteneur

# --name : Nommer le conteneur
docker run --name webserver nginx

# --rm : Auto-supprimer après arrêt
docker run --rm nginx
# Quand arrêté → Automatiquement supprimé

# -m : Limiter la RAM
docker run -m 512m nginx
# Maximum 512 MB de RAM
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Commandes de Base

**Objectif** : Maîtriser docker run, ps, stop, rm

```bash
# 1. Télécharger l'image
docker pull ubuntu:latest

# 2. Lancer un conteneur interactif
docker run -it --name mon-ubuntu ubuntu:latest /bin/bash

# (Vous êtes dans le conteneur)
# root@a1b2c3d4:/# apt update
# root@a1b2c3d4:/# apt install -y curl
# root@a1b2c3d4:/# exit

# 3. Vérifier qu'il est arrêté
docker ps -a
# Devrait montrer mon-ubuntu en status Exited

# 4. Redémarrer
docker start mon-ubuntu

# 5. Arrêter
docker stop mon-ubuntu

# 6. Supprimer
docker rm mon-ubuntu

# 7. Vérifier qu'il est parti
docker ps -a | grep mon-ubuntu
# (aucun résultat)
```

**Résultat attendu** : ✅ Vous maîtrisez le cycle basique

---

### Exercice 2 : Ports et Accès

**Objectif** : Comprendre le mapping de ports

```bash
# 1. Lancer Nginx avec port
docker run -d -p 9090:80 --name nginx-test nginx:latest

# 2. Vérifier le port
docker ps
# Devrait montrer "0.0.0.0:9090->80/tcp"

# 3. Accéder depuis l'hôte
curl http://localhost:9090
# Output: <html>...</html>

# 4. Voir les ports en détail
docker port nginx-test
# Output: 80/tcp -> 0.0.0.0:9090

# 5. Nettoyer
docker stop nginx-test
docker rm nginx-test
```

**Résultat attendu** : ✅ Vous comprenez les ports

---

### Exercice 3 : Logs et Debugging

**Objectif** : Lire et interpréter les logs

```bash
# 1. Lancer un conteneur
docker run -d --name apache httpd:latest

# 2. Voir les logs
docker logs apache
# Output: logs de démarrage

# 3. Logs en temps réel
docker logs -f apache
# Affiche les logs au fur et à mesure (Ctrl+C pour arrêter)

# 4. Dernières 10 lignes
docker logs --tail 10 apache

# 5. Avec timestamps
docker logs --timestamps apache

# 6. Accéder au shell pour debugging
docker exec -it apache /bin/bash
# root@...:/usr/local/apache2# 
# (investiguer d'ici)
# root@...:/usr/local/apache2# exit

# 7. Nettoyer
docker stop apache
docker rm apache
```

**Résultat attendu** : ✅ Vous savez debugger un conteneur

---

## ⚠️ Pièges Courants

### ❌ "Conteneur s'arrête immédiatement"

**Cause** : Le processus principal termine rapidement

```bash
# ❌ MAUVAIS : echo finit et conteneur s'arrête
docker run ubuntu:latest echo "Hello"
docker ps -a
# Verra : Exited (0)

# ✅ BON : Un processus qui continue
docker run -d ubuntu:latest sleep 3600
docker ps
# Verra : Up X seconds
```

---

### ❌ "Port déjà en utilisation"

**Cause** : Deux conteneurs sur le même port

```bash
# ❌ ERREUR
docker run -d -p 80:80 nginx  # Fonctionne
docker run -d -p 80:80 apache # ❌ Port already allocated

# ✅ SOLUTION : Port différent
docker run -d -p 8080:80 apache  # Port 8080 au lieu de 80
```

---

### ❌ "Aucun output des logs"

**Cause** : Le conteneur est arrêté ou pas de logs

```bash
# ❌ ERREUR : Conteneur arrêté
docker stop mon-app
docker logs mon-app
# (affiche les logs anciens seulement)

# ✅ BON : Voir logs en direct
docker logs -f mon-app
# (affiche à mesure que conteneur écrit)
```

---

## 📚 Tableau Récapitulatif

| Commande | Usage | Exemple |
|----------|-------|---------|
| `docker run` | Lancer conteneur | `docker run -d nginx` |
| `docker ps` | Voir conteneurs | `docker ps -a` |
| `docker stop` | Arrêter | `docker stop mon-web` |
| `docker start` | Redémarrer | `docker start mon-web` |
| `docker rm` | Supprimer | `docker rm mon-web` |
| `docker logs` | Voir logs | `docker logs -f mon-web` |
| `docker exec` | Commande | `docker exec mon-web ls /` |
| `docker inspect` | Détails | `docker inspect mon-web` |
| `docker pull` | Télécharger | `docker pull nginx:latest` |
| `docker image ls` | Images | `docker image ls` |

---

## 🔗 Prochaine Leçon

Vous maîtrisez maintenant les commandes Docker essentielles !

**Prochaine étape** → [03_dockerfile.md](03_dockerfile.md) : Créer vos propres images Docker

---

## ✅ Vérification

Avant de continuer :

- [ ] Lancer un conteneur avec `docker run`
- [ ] Voir les conteneurs avec `docker ps`
- [ ] Accéder aux logs avec `docker logs`
- [ ] Exécuter une commande avec `docker exec`
- [ ] Arrêter et supprimer un conteneur

---

**Durée de cette leçon** : 45 minutes (lecture + exercices)  
**Niveau** : 🟢 Facile (commandes basiques)  
**Prérequis** : Leçon 01
