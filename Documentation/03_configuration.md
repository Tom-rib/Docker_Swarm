# 03 - Configuration des Services

**Objectif :** Déployer et configurer les services applicatifs sur le cluster Swarm.

## 📋 Récap des Services à Déployer

1. **Registry** – Stockage privé des images Docker
2. **MariaDB** – Base de données (avec volume persistant)
3. **Nginx** – Reverse proxy et serveur web
4. **PHP** – Serveur applicatif
5. **VSCode Server** – IDE web pour développement

## 🚀 Étape 1 : Créer le Docker Compose

Le fichier `docker-compose.yml` définit tous les services du cluster.

Crée ce fichier sur le **manager** (192.168.1.100) :

```bash
# Sur le manager
nano docker-compose.yml
```

Ajoute le contenu suivant :

```yaml
version: '3.8'

services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
    volumes:
      - /swarm-data/registry:/var/lib/registry
    networks:
      - swarm-net
    deploy:
      placement:
        constraints: [node.role == worker]
    environment:
      - REGISTRY_STORAGE_DELETE_ENABLED=true

  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: app_db
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppassword
    volumes:
      - /swarm-data/mariadb:/var/lib/mysql
    networks:
      - swarm-net
    ports:
      - "3306:3306"
    deploy:
      replicas: 2
      placement:
        constraints: [node.role == worker]
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /swarm-data/nginx/conf:/etc/nginx/conf.d
      - /swarm-data/nginx/html:/usr/share/nginx/html
    networks:
      - swarm-net
    deploy:
      replicas: 2
      placement:
        constraints: [node.role == worker]
    depends_on:
      - php

  php:
    image: php:8.1-fpm-alpine
    volumes:
      - /swarm-data/php/app:/app
    networks:
      - swarm-net
    environment:
      MYSQL_HOST: mariadb
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppassword
      MYSQL_DATABASE: app_db
    deploy:
      replicas: 2
      placement:
        constraints: [node.role == worker]

  vscode:
    image: codercom/code-server:latest
    environment:
      PASSWORD: vscodepassword
    ports:
      - "8443:8443"
    volumes:
      - /swarm-data/vscode:/home/coder/project
    networks:
      - swarm-net
    deploy:
      placement:
        constraints: [node.role == worker]

networks:
  swarm-net:
    driver: overlay
    driver_opts:
      com.docker.network.driver.overlay.vxlanid: 4096
```

Sauve le fichier (Ctrl+X, Y, Entrée).

## 🚀 Étape 2 : Déployer la Stack

Depuis le **manager**, déploie tous les services :

```bash
# Sur le manager
docker stack deploy -c docker-compose.yml swarm-app
```

**Sortie attendue :**

```
Creating network swarm-app_swarm-net
Creating service swarm-app_registry
Creating service swarm-app_mariadb
Creating service swarm-app_nginx
Creating service swarm-app_php
Creating service swarm-app_vscode
```

## ✅ Vérifier les Services

### Lister les services

```bash
docker service ls

# Sortie attendue (après quelques secondes) :
# ID          NAME                MODE        REPLICAS   IMAGE
# xxx         swarm-app_registry  replicated  1/1        registry:2
# xxx         swarm-app_mariadb   replicated  2/2        mariadb:10.6
# xxx         swarm-app_nginx     replicated  2/2        nginx:alpine
# xxx         swarm-app_php       replicated  2/2        php:8.1-fpm-alpine
# xxx         swarm-app_vscode    replicated  1/1        codercom/code-server:latest
```

**Important :** Les replicas doivent montrer le ratio attendu (ex: 2/2).

### Vérifier les conteneurs

```bash
docker ps

# Voir les conteneurs sur le manager et les workers
# (Le manager n'en exécute pas car constraints = worker)
```

### Vérifier les logs

```bash
# Logs du service registry
docker service logs swarm-app_registry

# Logs du service mariadb
docker service logs swarm-app_mariadb
```

## 🔗 Étape 3 : Configurer les Accès

### Registry Docker

Ajoute le registry à la config Docker pour pouvoir pousser des images.

Sur **chaque VM** (manager, worker1, worker2) :

```bash
# Créer le répertoire config Docker
mkdir -p ~/.docker

# Ajouter le registry insecure au daemon
sudo nano /etc/docker/daemon.json
```

Ajoute ceci :

```json
{
  "insecure-registries": ["192.168.1.100:5000"]
}
```

Redémarre Docker :

```bash
sudo systemctl restart docker
```

### Tester le Registry

```bash
# Vérifier que le registry répond
curl -X GET http://192.168.1.100:5000/v2/

# Sortie attendue : {} (JSON vide)
```

Pousser une image test :

```bash
# Tagger une image existante pour le registry
docker tag alpine:latest 192.168.1.100:5000/test-alpine:latest

# Pousser au registry
docker push 192.168.1.100:5000/test-alpine:latest

# Lister les images du registry
curl -s http://192.168.1.100:5000/v2/_catalog | grep test
```

## 🌐 Étape 4 : Accéder aux Services

Une fois déployés, tu peux accéder aux services :

| Service | URL | Login |
|---------|-----|-------|
| **Nginx** | http://192.168.1.100:80 | - |
| **VSCode** | https://192.168.1.100:8443 | password: `vscodepassword` |
| **Registry** | http://192.168.1.100:5000/v2/ | - |
| **MariaDB** | 192.168.1.100:3306 | user: `appuser`, pass: `apppassword` |

### Tester MariaDB

```bash
# Depuis le manager
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db

# Une fois connecté :
> SHOW TABLES;
> EXIT;
```

## 📁 Créer des Fichiers de Configuration

### Config Nginx

Crée un fichier de config pour Nginx :

```bash
# Depuis le manager
mkdir -p /swarm-data/nginx/conf
nano /swarm-data/nginx/conf/default.conf
```

Ajoute :

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://php:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

Sauve et applique :

```bash
# Redémarrer le service Nginx
docker service update --force swarm-app_nginx
```

### Fichier PHP de Test

Crée une page PHP pour tester :

```bash
mkdir -p /swarm-data/php/app
nano /swarm-data/php/app/index.php
```

Ajoute :

```php
<?php
echo "Hello from " . gethostname() . "\n";
echo "Connected to: " . $_ENV['MYSQL_HOST'] . "\n";

// Test connexion DB
$conn = mysqli_connect($_ENV['MYSQL_HOST'], $_ENV['MYSQL_USER'], $_ENV['MYSQL_PASSWORD'], $_ENV['MYSQL_DATABASE']);
if ($conn->connect_error) {
    echo "DB Connection failed: " . $conn->connect_error;
} else {
    echo "DB Connection OK\n";
    $conn->close();
}
?>
```

## 📝 Fiche Mémoire - Configuration

**Déployer une stack :**
```bash
docker stack deploy -c docker-compose.yml nom-stack
```

**Voir les services :**
```bash
docker service ls
docker service logs nom-service
```

**Mettre à jour un service :**
```bash
docker service update --image nouvelle-image nom-service
```

**Supprimer une stack :**
```bash
docker stack rm nom-stack
```

## 🚀 Prochaine Étape

Maintenant que les services sont déployés, teste-les avec [04_tests.md](./04_tests.md).

---

**Tous les services doivent afficher le ratio "X/X" pour fonctionner correctement.**
