# 🐳 Docker Swarm - Infrastructure Résiliente

**Projet d'administration système et réseaux** | Déploiement d'un cluster Swarm pour la continuité d'activité

---

## 📋 Présentation du Projet

Ce projet vise à concevoir et déployer une **infrastructure conteneurisée résiliente** basée sur Docker Swarm. L'objectif est de mettre en place un cluster multi-nœuds capable de :

- ✅ Assurer la **haute disponibilité** des services
- ✅ Permettre la **scalabilité** automatique
- ✅ Implémenter la **continuité d'activité (PCA)** et **reprise d'activité (PRA)**
- ✅ Orchestrer des services critiques (base de données, proxy, applications)

**Concrètement** : Si un serveur tombe en panne, les services redémarrent tout seuls sur un autre serveur. Les données ne sont pas perdues. Le site continue de fonctionner.

### Compétences Visées

| Domaine | Compétence |
|---------|-----------|
| **Infrastructure** | Administrer et sécuriser les infrastructures systèmes |
| **Virtualisation** | Administrer et sécuriser les infrastructures virtualisées |
| **Supervision** | Mettre en œuvre et optimiser la supervision des infrastructures |

---

## 🗂️ Structure du Projet

```
📁 Docker_Swarm/
│
├── 📄 README.md                      ← Vous êtes ici
├── 📄 STRUCTURE_PROJET.md            ← Explications détaillées de chaque fichier
├── 📄 GUIDE_RAPIDE.md                ← Installation en 15 min (pour pressés)
│
├── 📚 DOCUMENTATION (Le cœur du projet)
│   ├── 📄 01_preparation.md          → Architecture, prérequis, schéma
│   ├── 📄 02_installation.md         → Installation Docker et Swarm
│   ├── 📄 03_configuration.md        → Services, networks, volumes, NFS
│   ├── 📄 04_tests.md                → Vérifications et pannes simulées
│   └── 📄 05_annexes.md              → Commandes utiles, dépannage, mémo
│
├── 🔧 SCRIPTS AUTOMATISÉS (À côté, pour gagner du temps)
│   └── 📁 scripts/
│       ├── init_manager.sh           → Initialise le nœud manager
│       ├── init_worker.sh            → Ajoute un nœud worker au cluster
│       ├── deploy_services.sh        → Lance tous les services d'un coup
│       ├── test_resilience.sh        → Tests automatisés
│       └── cleanup.sh                → Nettoie tout (services, volumes)
│
├── ⚙️ CONFIGURATION (Fichiers à adapter à votre env)
│   └── 📁 config/
│       ├── docker-compose.yml        → Définition complète de la stack
│       ├── mariadb.env               → Variables pour MariaDB
│       ├── nginx.conf                → Config du reverse proxy
│       └── .env.example              → Template des variables
│
└── 📚 COURS COMPLET (Bonus - Pour approfondir)
    └── 📁 cours/
        ├── 📄 README.md              → Guide du cours
        ├── 📄 INDEX.md               → Liste des 32 leçons
        ├── 01_docker_bases.md        ┐
        ├── 02_docker_cli.md          │
        ├── ... (30 autres leçons)    │ 32 leçons : Docker basics → expert
        └── 32_performance_tuning.md  ┘
```

---

## 📚 Sommaire de la Documentation

### 1️⃣ **[Préparation - 01_preparation.md](01_preparation.md)** (15 min)
   - Qu'est-ce que Docker Swarm et comment ça marche
   - Manager vs Workers (qui fait quoi)
   - Quorum et consensus (pourquoi minimum 3 managers)
   - Réseaux overlay (VXLAN chiffré)
   - Stockage NFS (pourquoi c'est important)
   - Prérequis : les 5 VMs à avoir
   - Schémas ASCII pour visualiser

### 2️⃣ **[Installation - 02_installation.md](02_installation.md)** (45 min)
   - Préparer les VMs Debian
   - Installer Docker sur chaque machine
   - Initialiser le cluster Swarm (une fois sur le manager)
   - Ajouter les nœuds workers (rejoindre le cluster)
   - Vérifier que c'est OK avec des commandes simples

### 3️⃣ **[Configuration - 03_configuration.md](03_configuration.md)** (60 min)
   - Créer les réseaux overlay
   - Configurer le NFS (stockage partagé)
   - Déployer les 4 services : MariaDB, Nginx, PHP-FPM, Registry
   - Gérer les replicas (HA automatique)
   - Attacher les volumes (persistance des données)

### 4️⃣ **[Tests & Résilience - 04_tests.md](04_tests.md)** (60 min)
   - Vérifier que les services répondent
   - Arrêter un container → voir qu'il redémarre
   - Arrêter un nœud complet → voir les services migrer
   - Vérifier que les données sont là
   - Tests PCA/PRA (continuité et reprise)

### 5️⃣ **[Annexes & Ressources - 05_annexes.md](05_annexes.md)** (à consulter)
   - Toutes les commandes Docker en référence
   - Solutions aux problèmes courants
   - Listes de vérification (checklists)
   - Procédures de dépannage
   - Références externes

---

## 🔧 Les Scripts - Gagner du Temps

Les scripts automatisent les étapes répétitives. Au lieu de 50 commandes, une seule suffit.

### **init_manager.sh** - Préparer le manager
```bash
sudo bash scripts/init_manager.sh 192.168.1.10
```
Lance ça une seule fois. Le script installe Docker et initialise Swarm.

### **init_worker.sh** - Ajouter des workers
```bash
bash scripts/init_worker.sh "SWMTKN-1-xxxxx" 192.168.1.10
```
Lance ça sur chaque worker pour le connecter au cluster.

### **deploy_services.sh** - Lancer tous les services
```bash
bash scripts/deploy_services.sh 192.168.1.20
```
Déploie MariaDB, Nginx, PHP-FPM et Registry en une commande (au lieu de 30-40).

### **test_resilience.sh** - Tester la résilience
```bash
bash scripts/test_resilience.sh all
```
Lance une suite de tests pour vérifier que le cluster tient bon.

### **cleanup.sh** - Tout supprimer
```bash
bash scripts/cleanup.sh --full
```
Supprime les services et volumes. Utile pour recommencer.

---

## ⚙️ Configuration - Fichiers à Adapter

### **docker-compose.yml**
Définition de tous les services en un seul fichier YAML.

Les services :
- **MariaDB** : Base de données (2 replicas = haute disponibilité)
- **Nginx** : Reverse proxy (2 replicas, load balanced)
- **PHP-FPM** : Application web (2 replicas, scalable)
- **Registry** : Stockage des images Docker (1 replica)

### **mariadb.env**
Variables pour MariaDB :
- `MYSQL_ROOT_PASSWORD` : Le mot de passe root
- `MYSQL_DATABASE` : La BD créée au démarrage
- `MYSQL_USER` : Un utilisateur app
- `MYSQL_PASSWORD` : Son mot de passe

À changer avant production !

### **nginx.conf**
Configuration du reverse proxy :
- Écoute le port 80
- Redirige les requêtes vers PHP-FPM
- Sert les fichiers statiques
- Headers de sécurité basiques

### **.env.example**
Template à copier en `.env`. Contient :
- IPs du manager, workers, NFS
- Ports d'écoute
- Chemins NFS
- Limites CPU/RAM

---

## 🏗️ Architecture Générale

```
┌─────────────────────────────────────────────────────────────┐
│                   DOCKER SWARM CLUSTER                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │   MANAGER NODE   │         │  WORKER NODE 1   │          │
│  │  (Orchestration) │◄────────┤  (Compute)       │          │
│  └──────────────────┘         └──────────────────┘          │
│           │                            │                    │
│           │                   ┌────────┴────────┐            │
│           │                   │                 │            │
│           │            ┌──────────────┐  ┌──────────────┐   │
│           └────────────┤  WORKER N2   │  │  WORKER N3   │   │
│                        └──────────────┘  └──────────────┘   │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  SERVICES DEPLOYÉS                                           │
│  • Nginx (reverse proxy)   • MariaDB (BD)                   │
│  • PHP (application)       • Registry (images)              │
│  • VSCode Server           • Volumes NFS (stockage)         │
│                                                              │
│  RÉSEAU OVERLAY (10.0.9.0/24)                              │
│  • Communication interne chiffrée                           │
│  • DNS automatique (service discovery)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Démarrage Rapide

Pour reproduire ce projet rapidement :

```bash
# 1. Cloner ce dépôt
git clone https://github.com/prenom-nom/docker-swarm.git
cd docker-swarm

# 2. Lire la préparation
cat 01_preparation.md

# 3. Suivre les étapes d'installation
sudo bash scripts/init_manager.sh 192.168.1.10
bash scripts/init_worker.sh "TOKEN" 192.168.1.10

# 4. Déployer les services
bash scripts/deploy_services.sh 192.168.1.20

# 5. Tester la résilience
bash scripts/test_resilience.sh all
```

---

## 📝 Recommandations de Lecture

1. **Première visite ?** → Commencez par [01_preparation.md](01_preparation.md)
2. **Vous installez ?** → Allez voir [02_installation.md](02_installation.md)
3. **Vous testez ?** → Consultez [04_tests.md](04_tests.md)
4. **Vous êtes bloqué ?** → Recherchez dans [05_annexes.md](05_annexes.md)
5. **Vous voulez tous les détails ?** → Voir [STRUCTURE_PROJET.md](STRUCTURE_PROJET.md)

---

## 💡 Conseils d'Utilisation

- **Lisez les concepts avant les commandes** : chaque fichier explique le "pourquoi" avant le "comment"
- **Testez étape par étape** : ne passez à la suivante que quand la précédente fonctionne
- **Conservez cette doc** : elle sert de révision et de mémo pour plus tard
- **Adaptez les scripts** : les chemins et IPs peuvent varier selon votre env
- **Utilisez les scripts** : ça va bien plus vite que copier-coller les commandes


---

## 📚 Ressources Externes

- [Documentation officielle Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Référence Docker CLI](https://docs.docker.com/reference/cli/docker/)
- [Best Practices Docker](https://docs.docker.com/develop/dev-best-practices/)


---

**Dernière mise à jour** : Mars 2026  
**Niveau** : 2e année Admin Sys & Réseaux  
**Durée estimée** : 20-30 heures (projet) + 50-60 heures (cours bonus)  

