# 🎓 LEÇON 5 : Docker Swarm - Les Concepts Clés

**Prérequis** : Leçons 01-04 (Docker basiques)

---

## 🎯 Objectif de cette Leçon

À la fin, vous comprendrez :

- ✅ Qu'est-ce qu'un Swarm et pourquoi c'est utile
- ✅ Manager vs Worker (rôles dans le cluster)
- ✅ Token et sécurité Swarm
- ✅ Quorum et consensus
- ✅ Comment Swarm orchestre les services

**Durée** : 20 minutes de lecture + 15 minutes de pratique

---

## 📖 Concept 1 : Qu'est-ce que Docker Swarm ?

### Avant Swarm (Multi-conteneurs manuels)

```
Machine 1              Machine 2              Machine 3
┌──────────┐          ┌──────────┐          ┌──────────┐
│ Container│          │ Container│          │ Container│
│ Nginx    │          │ PHP      │          │ Database │
└──────────┘          └──────────┘          └──────────┘
     │                     │                     │
     └─ Vous devez        └─ Vous devez        └─ Vous devez
       gérer manuellement   gérer manuellement   gérer manuellement
       
  ❌ Si une machine tombe : Manuel restart
  ❌ Si on besoin de scaler : Copier-coller
  ❌ Gestion fastidieuse : Scripts bash fragiles
```

### Avec Swarm (Orchestration automatique)

```
                  SWARM CLUSTER
         ┌────────────────────────────┐
         │    MANAGER (Chef)          │
         │ • Prend les décisions      │
         │ • Distribue le travail     │
         │ • Gère l'état du cluster   │
         └────────────┬───────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
    WORKER 1      WORKER 2      WORKER 3
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │Container │  │Container │  │Container │
  │Nginx     │  │PHP       │  │Database  │
  └──────────┘  └──────────┘  └──────────┘
  
  ✅ Défaillance auto-gérée : Redémarrage auto
  ✅ Scalabilité : "docker service update --replicas 5"
  ✅ Orchestration : Swarm gère tout
  ✅ Haute disponibilité : Services sur plusieurs nœuds
```

---

## 📖 Concept 2 : Manager vs Worker

### Manager (Le Chef d'Orchestre)

```
┌─────────────────────────────────┐
│         MANAGER                 │
│ ┌─────────────────────────────┐ │
│ │ • Reçoit les ordres (API)   │ │
│ │ • Planifie les tâches       │ │
│ │ • Maintient l'état global   │ │
│ │ • Élecrit par quorum        │ │
│ │ • Peut aussi exécuter tasks │ │
│ └─────────────────────────────┘ │
│                                 │
│ Base de données RAFT            │
│ ┌─────────────────────────────┐ │
│ │ Services                    │ │
│ │ Nœuds                       │ │
│ │ Tâches                      │ │
│ │ Réseaux                     │ │
│ │ Volumes                     │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Responsabilités du Manager** :

1. **API** : Reçoit les commandes docker
2. **Orchestration** : Décide où lancer les tâches
3. **Consensus** : Maintient l'accord entre managers
4. **Raft Database** : Stocke l'état du cluster

**Exemple d'ordre Manager** :

```bash
# L'utilisateur envoie :
docker service create --name nginx --replicas 3 nginx:latest

# Le Manager :
1. Reçoit l'ordre via API
2. Crée 3 tâches
3. Les assigne à 3 workers différents
4. Vérifie qu'elles restent en cours d'exécution
5. Si une tâche s'arrête : Relance sur autre worker
```

---

### Worker (Les Exécutants)

```
┌────────────────────────┐
│      WORKER            │
│ ┌────────────────────┐ │
│ │ • Exécute les      │ │
│ │   tâches (tasks)   │ │
│ │ • Rapporte l'état  │ │
│ │ • Pas de décision  │ │
│ │ • Pas de données   │ │
│ │   globales         │ │
│ └────────────────────┘ │
│                        │
│ Conteneurs            │
│ Task 1, Task 2, ...   │
│                        │
│ ✅ Exécution simple    │
│ ✅ Sans responsabilité │
│ ❌ Peut être perdu     │
│    (Sera remplacé)    │
└────────────────────────┘
```

**Responsabilités du Worker** :

1. **Exécution** : Lance les conteneurs
2. **Rapportage** : Dit au Manager "Je suis prêt"
3. **Acceptation** : Reçoit les tâches du Manager
4. **Aucune décision** : Pas d'orchestration

---

## 📖 Concept 3 : Quorum et Consensus

### Qu'est-ce que le Quorum ?

**Quorum** = Nombre minimum de managers nécessaires pour que le cluster fonctionne.

```
Nombre de Managers    Quorum Requis    Peut perdre
1                     1                0 manager ❌ (DANGER!)
2                     2                0 managers ❌ (DANGER!)
3                     2                1 manager ✅
5                     3                2 managers ✅
7                     4                3 managers ✅

RÈGLE : Si quorum perdu → Cluster en lecture seule
```

### Exemple : 3 Managers

```
SITUATION NORMALE
┌─────────┐
│Manager 1│ (Leader)
└────┬────┘
     │ Consensus
┌────┴─────┐
│Manager 2  │ 
└──────┬───┘
       │ Consensus
┌──────┴──────┐
│Manager 3    │
└─────────────┘

✅ Quorum = 2 (majorité de 3)
✅ Peut perdre 1 manager → Cluster fonctionne
❌ Si 2 managers perdus → Cluster en lecture seule
```

### Impact du Quorum

```
1 Manager       3 Managers       5 Managers
├─ Rapide      ├─ Équilibré      ├─ Robuste
├─ Simpel      ├─ Quorum=2       ├─ Quorum=3
└─ FRAGILE     ├─ Peut perdre 1   ├─ Peut perdre 2
(0 tolerance)  └─ Bon compromis   └─ Para production
```

---

## 📖 Concept 4 : Token Swarm

### Qu'est-ce qu'un Token ?

**Token** = Credential pour joindre le Swarm (comme un mot de passe)

```
Manager génère 2 tokens différents :

1. WORKER TOKEN (pour ajouter des workers)
   SWMTKN-1-4g1234567890abcdef1234567890
   │         │
   │         └─ Clé (très longue et secrète)
   └─ Préfixe (identifie comme token Swarm)
   
   Usage : docker swarm join --token SWMTKN-1-... IP:2377
   Sécurité : ✅ Workers ne peuvent pas voir le Manager token

2. MANAGER TOKEN (pour ajouter d'autres managers)
   SWMTKN-2-1x9876543210zyxwvu9876543210
   │         │
   │         └─ Clé (très longue et secrète)
   └─ SWMTKN-2 indique que c'est pour les managers
   
   Usage : docker swarm join --token SWMTKN-2-... IP:2377
   Sécurité : ⚠️ À protéger comme un mot de passe !
```

### Génération et Utilisation

```
┌─────────────────────────────────────────┐
│        MANAGER (192.168.1.10)           │
│                                         │
│ docker swarm init --advertise-addr...   │
│ ✅ Cluster créé                         │
│ ✅ Tokens générés automatiquement       │
│                                         │
│ docker swarm join-token worker          │
│ Output: SWMTKN-1-xxx...                 │
└─────────────────────────────────────────┘
                │
                │ (Token copié)
                ▼
┌─────────────────────────────────────────┐
│        WORKER (192.168.1.11)            │
│                                         │
│ docker swarm join \                     │
│   --token SWMTKN-1-xxx... \             │
│   192.168.1.10:2377                     │
│                                         │
│ ✅ Worker vérifié et accepté            │
│ ✅ Connecté au cluster                  │
└─────────────────────────────────────────┘
```

### Sécurité des Tokens

```
⚠️ À PROTÉGER COMME DES MOTS DE PASSE !

✅ Bonnes pratiques :
├─ Stockés en variables d'environnement
├─ Jamais commités en git
├─ Utilisés qu'une fois pour ajouter le nœud
├─ Régénérés après chaque ajout (optionnel)

❌ À ÉVITER :
├─ Partager en clair dans des emails
├─ Stockés dans du code source
├─ Affichés dans des logs publics
└─ Utiliser le même token pour tout
```

---

## 💡 EXEMPLES

### Exemple 1 : Créer un cluster simple

```bash
# 1. Sur le MANAGER (192.168.1.10)
docker swarm init --advertise-addr 192.168.1.10

# Output:
# Swarm initialized: current node (abc123...) is now a manager.
# 
# To add a worker to this swarm, run the following command:
#     docker swarm join --token SWMTKN-1-abc123... 192.168.1.10:2377
# 
# To add a manager to this swarm, run the following command:
#     docker swarm join --token SWMTKN-2-def456... 192.168.1.10:2377
```

```bash
# 2. Sur chaque WORKER
ssh debian@192.168.1.11

# Copier-coller la commande du Manager :
docker swarm join --token SWMTKN-1-abc123... 192.168.1.10:2377

# Output:
# This node joined a swarm as a worker.
```

```bash
# 3. Vérifier sur le MANAGER
docker node ls

# Output:
# ID                            HOSTNAME      STATUS    AVAILABILITY   MANAGER STATUS
# abc123... (*)                 manager       Ready     Active         Leader
# def456...                     worker1       Ready     Active         
# ghi789...                     worker2       Ready     Active         
```

---

### Exemple 2 : Comprendre le Quorum

```bash
# Avec 3 managers (recommandé)

# Situation 1 : Tous les managers OK
docker node ls
# Tous les 3 managers Readys
# ✅ Quorum OK : 2/3 présents ✓

# Situation 2 : Un manager down
# Manager1 tombe en panne
docker node ls
# Voit 2 managers Ready + 1 Down
# ✅ Quorum OK : 2/3 présents ✓
# ✅ Cluster fonctionne normalement

# Situation 3 : Deux managers down
# Manager1 et Manager2 tombent
docker node ls
# Voit 1 manager Ready + 2 Down
# ❌ Quorum PERDU : 1/3 < 2 requis
# ❌ Cluster en lecture seule (LES COMMANDES DOCKER MARCHENT PAS)

docker service create ...  # ❌ ERREUR !
# Error: manager is restricted to read-only access
```

---

## 🧪 PRATIQUE - Exercices

### Exercice 1 : Créer votre premier Swarm

**Objectif** : Initialiser un cluster avec 1 manager et observer

```bash
# 1. Sur une machine, initialiser le manager
docker swarm init

# 2. Vérifier
docker swarm inspect

# Output (JSON) :
# {
#   "ID": "abc123...",
#   "Version": {...},
#   "CreatedAt": "...",
#   "Swarm": {
#     "Spec": {...},
#     "JoinTokens": {
#       "Worker": "SWMTKN-1-...",
#       "Manager": "SWMTKN-2-..."
#     }
#   }
# }

# 3. Voir les nœuds
docker node ls

# Output:
# ID           HOSTNAME    STATUS   AVAILABILITY   MANAGER STATUS
# abc123...    laptop      Ready    Active         Leader

# ✅ Vous avez créé un cluster !
```

**Résultat attendu** : ✅ Un cluster Swarm avec 1 manager

---

### Exercice 2 : Comprendre Manager vs Worker

```bash
# 1. Observer le rôle du nœud actuel
docker info | grep "Swarm:"

# Output :
# Swarm: active
# NodeID: abc123...
# Is Manager: true  ← C'est un manager !
# ClusterID: ...

# 2. Récupérer les tokens
docker swarm join-token worker
docker swarm join-token manager

# 3. Voir les nœuds du cluster
docker node ls

# 4. Obtenir des détails sur un nœud
docker node inspect self

# (Remarquez "Spec.Role": "manager")
```

**Résultat attendu** : ✅ Vous comprenez Manager vs Worker

---

### Exercice 3 : Tokens et Sécurité

```bash
# 1. Obtenez le token worker
TOKEN=$(docker swarm join-token worker -q)
echo $TOKEN

# Output:
# SWMTKN-1-1234567890abcdefghijk...

# 2. Vérifier que c'est long et complexe
echo $TOKEN | wc -c
# Output: ~150 (très long = sécurisé)

# 3. Ne JAMAIS commiter en git !
echo "TOKEN=$TOKEN" >> secrets.txt
# ⚠️ Ne pas faire git add secrets.txt

# 4. Ajouter au .gitignore
echo "secrets.txt" >> .gitignore

# 5. Régénérer les tokens (pour la démo)
docker swarm join-token --rotate worker

# ✅ Les anciens tokens sont invalidés
```

**Résultat attendu** : ✅ Vous savez gérer les tokens sécurisément

---

## ⚠️ Pièges Courants

### ❌ "Swarm avec 1 seul manager"

```bash
# ❌ MAUVAIS : Pas de tolerance aux pannes
docker swarm init

# Si ce manager tombe → Cluster MORT

# ✅ BON : Au minimum 3 managers en production
# docker swarm init (sur Manager 1)
# docker swarm join-token manager (copier token)
# docker swarm join --token ... (sur Manager 2 et 3)
```

### ❌ "Partager le token trop librement"

```bash
# ❌ MAUVAIS : Token visible en clair
echo "SWMTKN-1-..." | mail user@example.com

# ✅ BON : Token sécurisé
# Utiliser vault/secrets manager
# Ou clé GPG
```

### ❌ "Ajouter trop de managers"

```bash
# ❌ MAUVAIS : 7 managers
# Consensus lent
# Trop de data à synchroniser

# ✅ BON : 3-5 managers
# Bon équilibre
# Quorum : 2-3 nodes
```

---

## 🔗 Prochaine Leçon

Maintenant vous comprenez l'architecture Swarm !

**Prochaine étape** → [06_initialiser_swarm.md](06_initialiser_swarm.md) : Mettre en place un vrai cluster

---

## ✅ Vérification

Avant de continuer :

- [ ] Expliquer Swarm vs plusieurs Docker en manuel
- [ ] Différence Manager vs Worker
- [ ] Qu'est-ce qu'un quorum et pourquoi c'est important
- [ ] Comment les tokens fonctionnent
- [ ] Créer un cluster Swarm simple

---

**Durée de cette leçon** : 35 minutes (lecture + exercices)  
**Niveau** : 🟡 Intermédiaire  
**Prérequis** : Leçons 01-04

