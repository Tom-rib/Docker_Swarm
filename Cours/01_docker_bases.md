# 🎓 LEÇON 1 : Comprendre Docker - Les Fondamentaux

---

## 🎯 Objectif de cette Leçon

À la fin, vous comprendrez :

- ✅ La différence entre conteneur et machine virtuelle
- ✅ Le cycle de vie d'un conteneur (créer, lancer, arrêter)
- ✅ Les images Docker et comment elles fonctionnentfaisson un sommaire pour ma documentation, étape par étapes qu'elle architecture on utilise , les étapes d'installation etc



genre Installation 

configuration



et on va rajouter un backup sur le nfs
- ✅ Pourquoi Docker est utile pour Swarm

**Durée** : 15 minutes de lecture + 15 minutes de pratique

---

## 📖 Concept 1 : Conteneur vs Machine Virtuelle

### Machine Virtuelle (VM)

```
┌─────────────────────────────────────────┐
│         Machine Hôte (Votre PC)         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │ Hypervisor   │  │ Hypervisor   │    │
│  │ (VirtualBox) │  │ (VMware)     │    │
│  └──────────────┘  └──────────────┘    │
│       │                   │             │
│       ▼                   ▼             │
│  ┌──────────────────┐ ┌──────────────┐ │
│  │ VM 1             │ │ VM 2         │ │
│  │ Ubuntu 20.04     │ │ Debian 11    │ │
│  │ 4 GB RAM         │ │ 2 GB RAM     │ │
│  │ 20 GB Disque     │ │ 15 GB Disque │ │
│  └──────────────────┘ └──────────────┘ │
│                                         │
│  ⚠️ Chaque VM = OS complet + ressources │
│  ❌ Démarrage : 1-2 minutes             │
│  ❌ Lourd : beaucoup de ressources      │
└─────────────────────────────────────────┘
```

### Conteneur Docker

```
┌─────────────────────────────────────────┐
│         Machine Hôte (Votre PC)         │
│         OS : Ubuntu/Debian              │
│         Noyau Linux partagé             │
│  ┌─────────────────────────────────┐    │
│  │  Docker Engine (Moteur)         │    │
│  │  ┌──────┐ ┌──────┐ ┌──────┐   │    │
│  │  │ App1 │ │ App2 │ │ App3 │   │    │
│  │  │ 200M │ │ 150M │ │ 100M │   │    │
│  │  └──────┘ └──────┘ └──────┘   │    │
│  │  Isolation   Isolation Isolation    │
│  │  (mais ressources partagées)   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ✅ Léger : partage le noyau            │
│  ✅ Rapide : démarrage < 1 seconde      │
│  ✅ Efficace : ressources partagées     │
└─────────────────────────────────────────┘
```

### Comparaison Directe

| Aspect | VM | Conteneur |
|--------|----|----|
| **Démarrage** | 1-2 min | 1 sec |
| **Taille** | 1-50 GB | 10-500 MB |
| **RAM utilisée** | 512 MB - 4 GB | 10-200 MB |
| **Densité** | 5-10 par machine | 10-100+ par machine |
| **Isolation** | Complète (OS) | Processus |
| **Performance** | 98% natif | 99% natif |

---

## 📖 Concept 2 : Image vs Conteneur

### Image Docker = Modèle (comme une recette)

```bash
# Une image est un modèle de conteneur
# Exemple : image nginx:latest
# C'est comme un "blueprint" ou un fichier .iso

┌─────────────────────┐
│   Image Nginx       │
│   (Modèle)          │
│ ┌─────────────────┐ │
│ │ OS Linux        │ │
│ │ Nginx serveur   │ │
│ │ Config HTML     │ │
│ └─────────────────┘ │
│                     │
│ Immuable (lecture)  │
│ Stockée sur disque  │
│ Réutilisable        │
└─────────────────────┘
```

### Conteneur = Instance (comme une maison construite)

```bash
# Un conteneur est une instance en cours d'exécution
# Créé à partir d'une image
# Exemple : docker run nginx

Création         Lancement        Arrêt
     │               │              │
     ▼               ▼              ▼
  ┌──────┐      ┌──────┐      ┌──────┐
  │ New  │─────▶│Ready │─────▶│ Stop │
  │      │      │(Run) │      │      │
  └──────┘      └──────┘      └──────┘
  Initialisation Exécution    Suppression

📝 Image utilisée : nginx:latest
📊 État : Running
🔄 Peut être arrêté/redémarré
💾 Données perdues si supprimé (sauf volumes)
```

### Analogue Réelle

```
IMAGE = Recette de gâteau
│
├─ Ingrédients
├─ Instructions
├─ Temps de cuisson
└─ Résultat attendu

CONTENEUR = Gâteau préparé
│
├─ Créé selon la recette
├─ Peut être mangé (exécuté)
├─ Peut être jeté (supprimé)
└─ Pas impacte la recette originale
```

---

## 📖 Concept 3 : Cycle de Vie d'un Conteneur

```
CREATE (docker create)
   │
   │ Image → Conteneur (arrêté)
   ▼
┌─────────┐
│ CREATED │  État = Created
│ (arrêté)│  Contient l'image copiée
└────┬────┘  Prêt à lancer
     │
START (docker start)
     │
     ▼
┌─────────┐
│ RUNNING │  État = Running
│ (actif) │  Processus exécuté
└────┬────┘  Consomme ressources
     │
     │  Option 1 : ARRÊT
     │  ────────────────
     ▼  STOP (docker stop)
┌─────────┐  Signal SIGTERM
│ STOPPED │  Processus arrêté proprement
│ (arrêté)│  Données préservées
└────┬────┘  Peut être redémarré
     │
     │  REMOVE (docker rm)
     │
     ▼
┌─────────┐
│ DELETED │  Conteneur supprimé
│         │  Données perdues
└─────────┘  (sauf volumes)

     │
     │  Option 2 : KILL (docker kill)
     │  ──────────────────────────────
     │  Signal SIGKILL (brutal)
     ▼
┌─────────┐
│ EXITED  │  État = Exited
│         │  Pas clean
└─────────┘
```

### États Simplifiés

```
Created → Running → Stopped → Deleted
   │         │         │
   │         └─ Peut redémarrer (Start)
   │
   └─ Jamais lancé
```

---

## 💡 EXEMPLES Pratiques

### Exemple 1 : Créer et lancer un conteneur

```bash
# Étape 1 : Télécharger l'image (si nécessaire)
docker pull nginx:latest

# Output:
# latest: Pulling from library/nginx
# 45b83a23b5ac: Pull complete
# ...
# Digest: sha256:...
# Status: Downloaded newer image for nginx:latest
```

```bash
# Étape 2 : Créer et lancer un conteneur
docker run -d -p 8080:80 --name mon-nginx nginx:latest

# -d = détaché (en arrière-plan)
# -p 8080:80 = Port 8080 (hôte) → Port 80 (conteneur)
# --name mon-nginx = Nommer le conteneur
# nginx:latest = Image à utiliser

# Output:
# a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q
# (ID unique du conteneur)
```

```bash
# Étape 3 : Vérifier le conteneur

# Voir les conteneurs en cours
docker ps

# Output:
# CONTAINER ID  IMAGE       COMMAND       CREATED     STATUS     PORTS              NAMES
# a1b2c3d4...   nginx:latest "nginx -g"  5 sec ago   Up 3 sec   0.0.0.0:8080->80   mon-nginx

# Vérifier qu'il marche
curl http://localhost:8080
# Output: <html><body><h1>It works!</h1></body></html>
```

### Exemple 2 : Arrêter un conteneur

```bash
# Arrêter proprement (30 secondes)
docker stop mon-nginx

# Vérifier
docker ps
# (mon-nginx n'est pas dans la liste)

# Voir aussi les conteneurs arrêtés
docker ps -a

# Output:
# CONTAINER ID  IMAGE       COMMAND       CREATED     STATUS        NAMES
# a1b2c3d4...   nginx:latest "nginx -g"  1 min ago   Exited (0)    mon-nginx
# ↑ STATUS = Exited, pas Running
```

### Exemple 3 : Redémarrer un conteneur

```bash
# Relancer le conteneur (reprend depuis où il a été arrêté)
docker start mon-nginx

# Vérifier
docker ps
# mon-nginx est de nouveau en Running

# Les données : préservées (sauf si on supprime le conteneur)
curl http://localhost:8080
# ✅ Toujours accessible
```

### Exemple 4 : Supprimer un conteneur

```bash
# Arrêter d'abord (s'il est en cours d'exécution)
docker stop mon-nginx

# Puis supprimer
docker rm mon-nginx

# Vérifier
docker ps -a | grep mon-nginx
# (aucun résultat = supprimé)

# ⚠️ Une fois supprimé, les données sont perdues
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Votre Premier Conteneur

**Objectif** : Créer et lancer un conteneur Ubuntu simple

```bash
# 1. Lancer un conteneur Ubuntu en mode interactif
docker run -it --name mon-ubuntu ubuntu:latest /bin/bash

# -i = interactif (garder l'input ouvert)
# -t = terminal (allouer un pseudo-terminal)
# /bin/bash = shell à lancer

# 2. Vous êtes maintenant DANS le conteneur !
# Essayez :
cat /etc/os-release
# Output : Ubuntu 24.04 LTS (ou version actuelle)

# 3. Installer quelque chose
apt update
apt install -y curl

# 4. Tester
curl https://example.com
# Output : HTML du site

# 5. Quitter le conteneur
exit

# 6. Vérifier l'état
docker ps
# (mon-ubuntu n'est pas là car arrêté)

docker ps -a
# (mon-ubuntu est Exited)

# 7. Redémarrer
docker start -i mon-ubuntu
# (vous pouvez relancer bash)

# 8. Supprimer
docker stop mon-ubuntu
docker rm mon-ubuntu
```

**Résultat attendu** : ✅ Vous avez créé, arrêté et supprimé un conteneur

---

### Exercice 2 : Conteneurs Web

**Objectif** : Lancer un serveur web et accéder depuis votre navigateur

```bash
# 1. Lancer Nginx
docker run -d -p 80:80 --name webserver nginx:latest

# 2. Accéder
# Ouvrir navigateur : http://localhost
# OU
curl http://localhost

# 3. Vérifier
docker ps
# webserver doit être en Running

# 4. Modifier le contenu
docker exec webserver bash -c "echo 'Hello from Container!' > /usr/share/nginx/html/index.html"

# 5. Tester
curl http://localhost
# Output : Hello from Container!

# 6. Nettoyer
docker stop webserver
docker rm webserver
```

**Résultat attendu** : ✅ Vous avez modifié le contenu d'un conteneur en cours d'exécution

---

### Exercice 3 : Cycle Complet

**Objectif** : Comprendre le cycle de vie

```bash
# 1. Créer (docker create)
docker create --name mon-app nginx:latest

# Vérifier
docker ps -a | grep mon-app
# STATUS = Created (pas Running !)

# 2. Lancer (docker start)
docker start mon-app

# Vérifier
docker ps | grep mon-app
# STATUS = Up X seconds

# 3. Arrêter (docker stop)
docker stop mon-app

# Vérifier
docker ps -a | grep mon-app
# STATUS = Exited

# 4. Relancer (docker start)
docker start mon-app

# 5. Kill (arrêt brutal)
docker kill mon-app

# Vérifier
docker ps -a | grep mon-app
# STATUS = Exited (pareil)

# 6. Supprimer
docker rm mon-app

# Vérifier
docker ps -a | grep mon-app
# (aucun résultat)
```

**Résultat attendu** : ✅ Vous maîtrisez le cycle vie

---

## 📚 Ressources Utiles

- [Documentation Docker Official](https://docs.docker.com/get-started/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## ⚠️ Pièges Courants

### ❌ "Le conteneur s'arrête immédiatement"

**Cause** : Le processus principal se termine

```bash
# ❌ Mauvais : Conteneur arrête après 1s
docker run ubuntu:latest echo "Hello"
# (echo termine, conteneur s'arrête)

# ✅ Bon : Conteneur reste actif
docker run -d -it ubuntu:latest
# (-it = terminal ouvert, reste actif)
```

### ❌ "Où sont mes données ?"

**Cause** : Les modifications dans un conteneur sont perdues si supprimé

```bash
# ❌ Mauvais : Données perdues
docker run nginx:latest
docker rm nginx  # Données disparues !

# ✅ Bon : Utiliser des volumes
docker run -v /data:/container/data nginx:latest
# Les fichiers dans /data survacent au conteneur
```

### ❌ "Port déjà utilisé"

**Cause** : Deux conteneurs sur le même port

```bash
# ❌ Erreur : Port 80 déjà utilisé
docker run -p 80:80 nginx
docker run -p 80:80 apache  # ❌ Erreur !

# ✅ Solution : Ports différents
docker run -p 8080:80 apache  # Port 8080 au lieu de 80
```

---

## 🔗 Prochaine Leçon

Vous avez compris le cycle de vie des conteneurs !

**Prochaine étape** → [02_docker_cli.md](02_docker_cli.md) : Les commandes Docker essentielles

---

## ✅ Vérification

Avant de continuer, vous devez pouvoir :

- [ ] Expliquer la différence VM vs Conteneur
- [ ] Dessiner le cycle de vie d'un conteneur
- [ ] Lancer un conteneur et vérifier qu'il fonctionne
- [ ] Arrêter et redémarrer un conteneur
- [ ] Expliquer Image vs Conteneur

**Si oui → vous êtes prêt pour la leçon 2 !**

---

**Durée de cette leçon** : 30 minutes (lecture + exercices)  
**Niveau** : 🟢 Débutant  
**Prérequis** : Docker installé, terminal basique

