# 🎓 LEÇON 21 : Test des Défaillances

**Prérequis** : Leçons 01-20

---

## 🎯 Objectif

- ✅ Tester la résilience
- ✅ Simuler des pannes
- ✅ Vérifier la récupération

---

## 💡 EXEMPLES

```bash
# Test 1: Arrêter un container
docker stop $(docker ps -q -f label=com.docker.swarm.service.name=nginx | head -1)

# Vérifier que Swarm le redémarre
docker service ps nginx

# Test 2: Arrêter un nœud
ssh worker1 "sudo systemctl stop docker"

# Vérifier que services migrent
docker service ps --no-trunc

# Test 3: Saturer la mémoire
docker service create --limit-memory 256m stress-ng:latest
# Observer les redémarrages

# Test 4: Réseau down
# Débrancher physiquement la machine
# Observer failover automatique
```

---

## ✅ Vérification

- [ ] Tester arrêt container
- [ ] Tester arrêt nœud
- [ ] Vérifier la récupération

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
