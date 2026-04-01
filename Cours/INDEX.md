# 🎓 COURS DOCKER SWARM - Index Pédagogique

**Un cours complet, décortiqué notion par notion, du zéro à l'expert.**

---

## 📚 Table des Matières

### **SECTION 1 : FONDAMENTAUX DOCKER** (4 leçons)
Avant Swarm, maîtriser Docker de base.

1. [01_docker_bases.md](01_docker_bases.md) - Conteneurs, images, cycles de vie
2. [02_docker_cli.md](02_docker_cli.md) - Les commandes essentielles
3. [03_dockerfile.md](03_dockerfile.md) - Créer ses propres images
4. [04_volumes_et_networks.md](04_volumes_et_networks.md) - Stockage et communication

### **SECTION 2 : INTRODUCTION À SWARM** (3 leçons)
Les bases de l'orchestration.

5. [05_swarm_concepts.md](05_swarm_concepts.md) - Manager, Worker, Cluster
6. [06_initialiser_swarm.md](06_initialiser_swarm.md) - Créer votre premier cluster
7. [07_ajouter_nodes.md](07_ajouter_nodes.md) - Expansion du cluster

### **SECTION 3 : SERVICES SWARM** (4 leçons)
Déployer et gérer les applications.

8. [08_services_basiques.md](08_services_basiques.md) - Créer et déployer
9. [09_replicas_et_ha.md](09_replicas_et_ha.md) - Haute disponibilité
10. [10_update_services.md](10_update_services.md) - Mettre à jour sans downtime
11. [11_logs_et_monitoring.md](11_logs_et_monitoring.md) - Observer et diagnostiquer

### **SECTION 4 : RÉSEAUX AVANCÉS** (3 leçons)
Communication inter-services.

12. [12_overlay_networks.md](12_overlay_networks.md) - Réseaux distribués
13. [13_dns_discovery.md](13_dns_discovery.md) - Découverte de services
14. [14_load_balancing.md](14_load_balancing.md) - Répartition de charge

### **SECTION 5 : STOCKAGE PERSISTANT** (3 leçons)
Données qui survivent.

15. [15_volumes_docker.md](15_volumes_docker.md) - Types de volumes
16. [16_nfs_setup.md](16_nfs_setup.md) - Stockage partagé
17. [17_backup_recovery.md](17_backup_recovery.md) - Sauvegardes

### **SECTION 6 : DOCKER COMPOSE & STACKS** (2 leçons)
Configuration déclarative.

18. [18_docker_compose.md](18_docker_compose.md) - Fichiers YAML
19. [19_stacks_deploy.md](19_stacks_deploy.md) - Déployer des stacks

### **SECTION 7 : RÉSILIENCE & TESTS** (3 leçons)
Garantir la continuité.

20. [20_healthchecks.md](20_healthchecks.md) - Vérification de santé
21. [21_simulation_pannes.md](21_simulation_pannes.md) - Tester les défaillances
22. [22_disaster_recovery.md](22_disaster_recovery.md) - Récupération après panne

### **SECTION 8 : SÉCURITÉ** (3 leçons)
Protéger votre cluster.

23. [23_secrets_management.md](23_secrets_management.md) - Gérer les mots de passe
24. [24_certificats_tls.md](24_certificats_tls.md) - Chiffrement
25. [25_rbac_permissions.md](25_rbac_permissions.md) - Contrôle d'accès

### **SECTION 9 : CAS D'USAGE AVANCÉS** (4 leçons)
Pour les experts.

26. [26_multi_node_strategy.md](26_multi_node_strategy.md) - Placement intelligent
27. [27_resource_limits.md](27_resource_limits.md) - Limiter les ressources
28. [28_logging_centralized.md](28_logging_centralized.md) - Logs centralisés
29. [29_metrics_prometheus.md](29_metrics_prometheus.md) - Monitoring avec Prometheus

### **SECTION 10 : TROUBLESHOOTING** (3 leçons)
Quand ça ne marche pas.

30. [30_debug_services.md](30_debug_services.md) - Diagnostiquer les problèmes
31. [31_network_issues.md](31_network_issues.md) - Problèmes de connectivité
32. [32_performance_tuning.md](32_performance_tuning.md) - Optimiser les performances

---

## 🎯 Parcours Recommandés

### **Pour Débutants** (7 jours)

```
Jour 1: 01 → 02 → 03
Jour 2: 04 → 05 → 06
Jour 3: 07 → 08 → 09
Jour 4: 10 → 11 → 12
Jour 5: 13 → 14 → 15
Jour 6: 16 → 17 → 18
Jour 7: 19 → 20 → 21
```

**Temps** : ~2-3 heures/jour  
**Résultat** : Maîtrise des bases

---

### **Pour Admin Sys** (10 jours)

```
Semaine 1: 01-07 (Fondamentaux + Swarm)
Semaine 2: 08-15 (Services + Stockage)
Semaine 3: 16-22 (Stacks + Résilience)
Semaine 4: 23-29 (Sécurité + Avancé)
```

**Temps** : ~1 heure/jour  
**Résultat** : Expertise complète

---

### **Pour DevOps** (14 jours)

```
TOUS les modules
+ Projets pratiques
+ Cas réels d'entreprise
```

**Temps** : ~2-3 heures/jour  
**Résultat** : Maîtrise en production

---

## 📖 Comment Utiliser Ce Cours

### **Structure de chaque leçon**

```
🎯 OBJECTIF
→ Qu'allez-vous apprendre ?

📖 CONCEPTS
→ Théorie et explications

💡 EXEMPLES
→ Code et démonstrations

🧪 PRATIQUE
→ Exercices à faire

📚 RESSOURCES
→ Liens utiles

🔗 SUITE
→ Leçon suivante
```

### **Symboles utilisés**

- 🎯 = Objectif de la leçon
- 📖 = Concept important
- 💡 = Exemple ou conseil
- 🧪 = Exercice pratique
- ⚠️ = Attention !
- ✅ = Succès / vérification
- ❌ = Erreur / problème
- 🔗 = Lien vers autre section

---

## ✅ Checklist d'Apprentissage

### **Après Section 1 (Docker basiques)**
- [ ] Je comprends les conteneurs vs VMs
- [ ] Je peux créer et lancer des conteneurs
- [ ] Je maîtrise les volumes et réseaux Docker
- [ ] Je peux écrire un Dockerfile simple

### **Après Section 2 (Swarm basics)**
- [ ] Je comprends Manager vs Worker
- [ ] J'ai créé un cluster Swarm
- [ ] J'ai ajouté des nœuds au cluster
- [ ] Je connais les tokens Swarm

### **Après Section 3 (Services)**
- [ ] Je peux déployer un service
- [ ] Je comprends les replicas
- [ ] Je sais mettre à jour sans downtime
- [ ] Je peux lire les logs

### **Après Section 4 (Réseaux)**
- [ ] J'ai créé un overlay network
- [ ] Je comprends la découverte DNS
- [ ] Je sais comment les services communiquent
- [ ] Je connais le load balancing

### **Après Section 5 (Stockage)**
- [ ] Je maîtrise les volumes Docker
- [ ] J'ai configuré NFS
- [ ] Je sais sauvegarder les données
- [ ] Je peux récupérer après perte

### **Après Section 6 (Compose)**
- [ ] Je peux écrire un docker-compose.yml
- [ ] Je déploie des stacks complètes
- [ ] Je comprends la sintaxe YAML
- [ ] Je sais orchestrer plusieurs services

### **Après Section 7 (Résilience)**
- [ ] J'ai configuré les healthchecks
- [ ] Je teste les défaillances
- [ ] Je comprends PCA/PRA
- [ ] J'ai un plan de récupération

### **Après Section 8 (Sécurité)**
- [ ] Je gère les secrets
- [ ] J'utilise les certificats TLS
- [ ] Je contrôle les permissions
- [ ] Je sécurise les accès

### **Après Section 9 (Avancé)**
- [ ] Je contrôle le placement des services
- [ ] Je limite les ressources
- [ ] Je centralise les logs
- [ ] Je monitore avec Prometheus

### **Après Section 10 (Troubleshooting)**
- [ ] Je sais diagnostiquer les problèmes
- [ ] Je résous les issues réseau
- [ ] J'optimise les performances
- [ ] Je suis prêt pour la production

---

## 📊 Prérequis par Section

| Section | Prérequis | Niveau |
|---------|-----------|--------|
| 1-4 | Linux de base | Débutant |
| 5-7 | Sections 1-4 | Intermédiaire |
| 8-10 | Sections 1-7 | Avancé |
| 26-32 | Toutes | Expert |

---

## 🎓 Certifications Visées

Après ce cours, vous pouvez :

- ✅ Passer l'**exam Docker Certified Associate** (niveau intermédiaire)
- ✅ Passer l'**exam Kubernetes** (comprendre l'orchestration)
- ✅ Maîtriser le **DevOps en production**
- ✅ Gérer une **infrastructure résiliente**

---

## 💾 Ressources de Chaque Leçon

Chaque leçon contient :

- **Théorie** : Explication des concepts
- **Diagrammes** : Visuels ASCII
- **Commandes** : Prêtes à copier-coller
- **Code** : Exemples complets
- **Exercices** : À faire soi-même
- **Solutions** : Pour vérifier
- **Pièges** : À éviter
- **Ressources** : Pour approfondir

---

## 🔄 Progression Non-Linéaire

Vous n'êtes **pas obligé** de suivre l'ordre :

- **Débutant pressé** → 01, 02, 05, 06, 08, 12
- **Admin Sys** → 04, 05, 16, 22, 30, 31
- **DevOps** → 18, 19, 26, 27, 28, 29
- **Sécurité** → 23, 24, 25

**Mais l'ordre recommandé est meilleur** pour apprendre progressivement.

---

## 📝 Exercices Pratiques

**Chaque leçon a des exercices** :

1. **Exercice guidé** : Avec solution step-by-step
2. **Exercice appliqué** : Sans solution, à vous de trouver
3. **Exercice créatif** : Inventer une utilisation

**Exemple d'exercice** :

```markdown
### Exercice : Créer un service web résilient

1. Créer un service nginx avec 3 replicas
2. Arrêter un conteneur, vérifier la relance
3. Ajouter un healthcheck
4. Mettre à jour l'image

Solution : voir section Exercice 1 - Solution
```

---

## 🎯 Objectif Final

**À la fin du cours, vous pouvez :**

1. ✅ Déployer une infrastructure Swarm en production
2. ✅ Implémenter la haute disponibilité
3. ✅ Gérer les défaillances sans downtime
4. ✅ Sécuriser votre cluster
5. ✅ Monitorer et optimiser
6. ✅ Former d'autres personnes

---

## 🚀 Commencer le Cours

### **Commencez ici** :

```bash
# 1. Lire cette introduction (vous l'avez déjà fait !)

# 2. Aller à la leçon 1
cat 01_docker_bases.md

# 3. Suivre les exercices

# 4. Passer à la leçon 2
cat 02_docker_cli.md

# ... et ainsi de suite
```

---

## 📞 Support d'Apprentissage

| Question | Solution |
|----------|----------|
| "Je suis perdu" | Relire la leçon précédente |
| "C'est trop rapide" | Faire les exercices |
| "C'est trop lent" | Sauter aux sections avancées |
| "Je comprends pas X" | Lire la section "💡 EXEMPLES" |
| "Comment pratiquer" | Faire les exercices 🧪 |

---

## 📚 Documentation Complémentaire

Ce cours s'ajoute à :

- [README.md](../README.md) - Vue d'ensemble
- [GUIDE_RAPIDE.md](../GUIDE_RAPIDE.md) - Installation express
- [05_annexes.md](../05_annexes.md) - Mémo commandes

**Utilisation** :
- Cours pour apprendre progressivement
- README pour la navigation
- Annexes pour consulter rapidement

---

## 🎓 Statistiques du Cours

| Métrique | Valeur |
|----------|--------|
| Nombre de leçons | 32 |
| Heures d'étude (total) | 50-60 heures |
| Heures par semaine (recommandé) | 5-10 heures |
| Durée du cours complet | 6-12 semaines |
| Exercices pratiques | 100+ |
| Diagrammes | 50+ |
| Exemples de code | 200+ |

---

## ✨ Particularités du Cours

Ce cours est :

- ✅ **Progressif** : Du simple au complexe
- ✅ **Pratique** : Beaucoup d'exercices
- ✅ **Actuel** : Basé sur Docker 24.x et Swarm moderne
- ✅ **Français** : Entièrement en français
- ✅ **Autonome** : Peut être suivi seul
- ✅ **Libre** : Open Source sous licence MIT

---

**Prêt à commencer ? → [01_docker_bases.md](01_docker_bases.md)**

---

**Durée de cette introduction** : 5 minutes  
**Niveau** : 🟢 Facile (orientation)  
**Prerequis** : Aucun

