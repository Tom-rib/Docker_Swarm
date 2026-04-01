# 🎓 LEÇON 3 : Créer ses Propres Images Docker avec Dockerfile

**Prérequis** : Leçons 01-02 (Docker basiques et CLI)

---

## 🎯 Objectif de cette Leçon

À la fin, vous saurez :

- ✅ Comprendre les instructions Dockerfile
- ✅ Créer une image personnalisée
- ✅ Optimiser les couches d'une image
- ✅ Utiliser les variables et héritage
- ✅ Builder et tester une image

**Durée** : 25 minutes de lecture + 25 minutes de pratique

---

## 📖 Concept 1 : Qu'est-ce qu'un Dockerfile ?

### Définition

**Dockerfile** = Recette pour créer une image Docker

```
Dockerfile = Liste d'instructions
    │
    ├─ FROM ubuntu:latest    (Base : système d'exploitation)
    ├─ RUN apt update        (Exécuter commandes)
    ├─ COPY app.py /app/     (Copier fichiers)
    ├─ EXPOSE 8000           (Exposer un port)
    └─ CMD python app.py     (Commande de démarrage)

Résultat → Image réutilisable
```

### Architecture des Couches

```
Image Docker = Pile de couches

┌─────────────────────────────┐
│   Layer 5 : CMD             │ ← Commande de démarrage
├─────────────────────────────┤
│   Layer 4 : COPY app.py     │ ← Fichiers application
├─────────────────────────────┤
│   Layer 3 : RUN apt install │ ← Dépendances
├─────────────────────────────┤
│   Layer 2 : RUN apt update  │ ← Mise à jour système
├─────────────────────────────┤
│   Layer 1 : FROM ubuntu     │ ← Base système
└─────────────────────────────┘

Total = Toutes les couches empilées
```

---

## 📖 Concept 2 : Instructions Principales

### Les 5 Instructions Essentielles

```
FROM     → D'où on part (image de base)
RUN      → Commandes à exécuter (build time)
COPY/ADD → Copier fichiers de l'hôte
EXPOSE   → Ports que le conteneur écoute
CMD      → Commande de démarrage par défaut
```

### Exemple d'Utilisation

```dockerfile
FROM python:3.9-slim
# Base : Python 3.9 (léger)

RUN apt-get update && apt-get install -y \
    curl \
    git
# Installer dépendances système

COPY requirements.txt /app/
# Copier les dépendances Python

RUN pip install -r /app/requirements.txt
# Installer dépendances Python

COPY app.py /app/
# Copier l'application

WORKDIR /app
# Définir répertoire de travail

EXPOSE 8000
# Le port 8000 est écouté

CMD ["python", "app.py"]
# Commande par défaut
```

---

## 📖 Concept 3 : Build et Optimisation

### Processus de Build

```bash
docker build -t mon-app:1.0 .
        │      │        │   │
        │      │        │   └─ Contexte (dossier avec Dockerfile)
        │      │        └─ Version (tag)
        │      └─ Nom de l'image
        └─ Commande

Résultat → mon-app:1.0 (image créée)
```

### Optimisation : Minimiser les Couches

```dockerfile
# ❌ MAUVAIS : Beaucoup de couches
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ BON : Une seule couche
RUN apt-get update && apt-get install -y \
    curl \
    git && \
    apt-get clean
```

---

## 💡 EXEMPLES

### Exemple 1 : Image Simple (Nginx avec HTML personnalisé)

**Créer les fichiers** :

```bash
# 1. Créer un dossier
mkdir mon-nginx
cd mon-nginx

# 2. Créer un fichier HTML
cat > index.html << EOF
<!DOCTYPE html>
<html>
<head><title>Ma Page</title></head>
<body><h1>Bienvenue !</h1></body>
</html>
EOF

# 3. Créer le Dockerfile
cat > Dockerfile << EOF
FROM nginx:latest
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
```

**Construire et tester** :

```bash
# 4. Build l'image
docker build -t mon-nginx:1.0 .
# Output: Successfully tagged mon-nginx:1.0

# 5. Lancer un conteneur
docker run -d -p 8080:80 --name web mon-nginx:1.0

# 6. Tester
curl http://localhost:8080
# Output: <html>...<h1>Bienvenue !</h1>...</html>

# 7. Nettoyer
docker stop web
docker rm web
```

---

### Exemple 2 : Image Python avec Application

```dockerfile
# Dockerfile.app
FROM python:3.9-slim

WORKDIR /app

# Copier et installer dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier l'app
COPY app.py .

EXPOSE 5000
CMD ["python", "app.py"]
```

**Tester** :

```bash
# Créer requirements.txt
echo "flask==2.0.1" > requirements.txt

# Créer app.py
cat > app.py << EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Docker!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Build
docker build -t mon-app:1.0 -f Dockerfile.app .

# Run
docker run -d -p 5000:5000 mon-app:1.0

# Test
curl http://localhost:5000
# Output: Hello from Docker!
```

---

### Exemple 3 : Variables et Build Args

```dockerfile
# Dockerfile avec arguments
ARG PYTHON_VERSION=3.9
ARG APP_USER=appuser

FROM python:${PYTHON_VERSION}-slim

RUN useradd -m ${APP_USER}

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

USER ${APP_USER}
EXPOSE 8000

CMD ["python", "app.py"]
```

**Build avec arguments** :

```bash
docker build \
  --build-arg PYTHON_VERSION=3.10 \
  --build-arg APP_USER=webapp \
  -t mon-app:1.0 .
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Dockerfile Simple

**Objectif** : Créer une image Nginx avec contenu personnalisé

```bash
# 1. Créer dossier et fichiers
mkdir exo1 && cd exo1

# 2. Créer index.html
echo "<h1>Test Personnalisé</h1>" > index.html

# 3. Créer Dockerfile
cat > Dockerfile << 'EOF'
FROM nginx:latest
COPY index.html /usr/share/nginx/html/
EXPOSE 80
EOF

# 4. Build
docker build -t exo1:latest .

# 5. Run et Test
docker run -d -p 8888:80 --name exo1 exo1:latest
curl http://localhost:8888
# Doit afficher : <h1>Test Personnalisé</h1>

# 6. Nettoyer
docker stop exo1 && docker rm exo1
```

**Résultat attendu** : ✅ Image créée et fonctionnelle

---

### Exercice 2 : Image avec Dépendances

**Objectif** : Créer une image Ubuntu avec outils

```bash
# 1. Créer Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim && \
    apt-get clean

CMD ["/bin/bash"]
EOF

# 2. Build
docker build -t ubuntu-tools:1.0 .

# 3. Tester
docker run -it ubuntu-tools:1.0
# (vous êtes dans le conteneur)
# root@...# curl --version
# root@...# exit

# 4. Vérifier la taille
docker image ls | grep ubuntu-tools
# Voir la taille de l'image

# 5. Nettoyer
docker image rm ubuntu-tools:1.0
```

**Résultat attendu** : ✅ Image avec outils installés

---

### Exercice 3 : Optimiser une Image

**Objectif** : Réduire la taille en optimisant Dockerfile

```bash
# Version 1 : Non optimisée (lourd)
cat > Dockerfile.bad << 'EOF'
FROM ubuntu:22.04
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y wget
EOF

# Version 2 : Optimisée (léger)
cat > Dockerfile.good << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
EOF

# Build les deux
docker build -f Dockerfile.bad -t bad:latest .
docker build -f Dockerfile.good -t good:latest .

# Comparer les tailles
docker image ls | grep -E "bad|good"
# Remarquez : good:latest est plus petit !

# Nettoyer
docker image rm bad:latest good:latest
```

**Résultat attendu** : ✅ Vous comprenez l'optimisation des couches

---

## ⚠️ Pièges Courants

### ❌ "Couches inutiles = Image énorme"

```dockerfile
# ❌ MAUVAIS : Chaque RUN = une couche
RUN apt-get update
RUN apt-get install curl
RUN apt-get install git
# = 3 couches + OS = ~500MB

# ✅ BON : Un seul RUN
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean
# = 1 couche + OS = ~200MB
```

---

### ❌ "Les fichiers ne sont pas copié"

```dockerfile
# ❌ MAUVAIS : Chemin relatif incorrect
COPY app.py /app/
# Si app.py n'existe pas → ERREUR

# ✅ BON : Vérifier le contexte
# Structure :
# my-app/
#   ├── Dockerfile
#   └── app.py

# Dockerfile :
COPY app.py /app/
```

---

### ❌ "Processus ne démarre pas"

```dockerfile
# ❌ MAUVAIS : Pas de CMD
FROM nginx:latest
# nginx ne démarre pas tout seul

# ✅ BON : Spécifier le démarrage
CMD ["nginx", "-g", "daemon off;"]
```

---

## 🔗 Prochaine Leçon

Vous savez maintenant créer vos images Docker !

**Prochaine étape** → [04_volumes_et_networks.md](04_volumes_et_networks.md) : Stockage persistant et communication

---

## ✅ Vérification

Avant de continuer :

- [ ] Créer un Dockerfile simple
- [ ] Builder une image personnalisée
- [ ] Tester l'image en lançant un conteneur
- [ ] Optimiser la taille d'une image
- [ ] Utiliser les arguments de build

---

**Durée de cette leçon** : 50 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-02
