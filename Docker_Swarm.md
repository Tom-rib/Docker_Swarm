# Docker Swarm pour la Résilience
## Déploiement d'un Cluster Swarm pour la Continuité d'Activité dans l'Univers Virtuel avec Docker et Debian

---

## Introduction

Docker Swarm est une solution d'orchestration de conteneurs permettant de gérer efficacement des applications distribuées à grande échelle. Il regroupe plusieurs hôtes Docker en un cluster, assurant ainsi :

- Haute disponibilité
- Scalabilité
- Reprise rapide en cas de défaillance

Grâce à son intégration native avec Docker et sa facilité de mise en œuvre, Docker Swarm constitue une alternative performante pour la gestion de l'infrastructure conteneurisée.

---

## Mission

### Rejoignez notre mission : Déployer un Cluster Swarm pour la Continuité et la Reprise d'Activité

Nous recherchons des experts en administration système et DevOps pour concevoir et mettre en place un cluster Swarm robuste dédié à :

- **Planification de la Continuité d'Activité (PCA)**
- **Reprise d'Activité (PRA)**

Ce cluster garantira la résilience et la disponibilité des services critiques dans les environnements les plus exigeants.

---

## Architecture du Cluster

Notre infrastructure reposera sur un ensemble de machines virtuelles Debian assurant une gestion optimisée et sécurisée des conteneurs Docker :

### Composants Principaux

- **Nœud de contrôle (Manager)**
  - Une VM Debian dédiée à l'orchestration du cluster Swarm
  - Garantit la répartition intelligente des charges
  - Assure la gestion des défaillances

- **Nœuds de calcul (Workers)**
  - Plusieurs VM Debian fournissant la puissance de traitement
  - Exécutent les conteneurs applicatifs
  - Assurent scalabilité et redondance

- **Stockage persistant (NFS)**
  - Une VM dédiée à l'hébergement des volumes Docker
  - Permet la conservation fiable des données
  - Assure une récupération rapide en cas de besoin

---

## Déploiement des Conteneurs Critiques

Le cluster Swarm hébergera une gamme de services conteneurisés assurant la continuité des opérations :

### Services Déployés

- **Registry interne (Local Repository)**
  - Stockage sécurisé des artefacts logiciels
  - Garantit l'intégrité et la disponibilité des applications

- **Base de données (MariaDB)**
  - Système de gestion des données critique
  - Déployé en haute disponibilité
  - Assure une continuité de service optimale

- **Serveur applicatif (PHP)**
  - Conteneur fournissant l'environnement d'exécution
  - Support des applications métier

- **Proxy inverse et serveur web (Nginx)**
  - Garant de l'accessibilité des services
  - Répartition des requêtes entrantes

- **Environnement de développement (VSCode Server)**
  - Plateforme collaborative
  - Gestion et évolution des applications en temps réel

---

## Votre Rôle

En tant qu'ingénieur DevOps ou administrateur système, vous serez chargé de :

- ✓ Concevoir et déployer l'architecture Swarm
- ✓ Assurer la haute disponibilité et la redondance des services
- ✓ Mettre en place les stratégies de sauvegarde et de récupération
- ✓ Optimiser la gestion des ressources et l'orchestration des conteneurs
- ✓ Garantir la sécurité et la résilience de l'infrastructure

---

## Rendu du Projet

### Livrable

Le projet est à rendre sur : **[https://github.com/prenom-nom/swarm](https://github.com/prenom-nom/swarm)**

### Contenu Attendu

- Procédures de tests de fonctionnement
- Simulation de perte d'un conteneur
- Vérification PCA / PRA
- Documentation complète

### Évaluation

L'évaluation se fera sous forme de **présentation avec support** à l'équipe pédagogique.

---

## Base de Connaissances

- Docker Swarm
- Docker Hub
- Docker Registry

---

## Compétences Visées

- **Administrer et sécuriser les infrastructures systèmes**
- **Administrer et sécuriser les infrastructures virtualisées**
- **Mettre en œuvre et optimiser la supervision des infrastructures**

---