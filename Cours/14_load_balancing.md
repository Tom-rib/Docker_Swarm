# 🎓 LEÇON 14 : Load Balancing Avancé

**Prérequis** : Leçons 01-13

---

## 🎯 Objectif

- ✅ Comprendre IPVS (IP Virtual Server)
- ✅ Round-robin distribution
- ✅ Sticky sessions

---

## 📖 Concept

### IPVS Distribution

```
Requête client → VIP (10.0.9.2)
                    ↓
               IPVS (kernel)
                    ↓
     ┌──────────────┼──────────────┐
     ↓              ↓              ↓
  Replica 1    Replica 2    Replica 3
  
Round-robin:
  Req 1 → R1
  Req 2 → R2
  Req 3 → R3
  Req 4 → R1 (recommence)
```

---

## 💡 EXEMPLES

```bash
# Créer service avec 3 replicas
docker service create --name lb-test --replicas 3 nginx:latest

# Faire requêtes (elles vont vers différentes replicas)
for i in {1..9}; do
  curl -s http://localhost | grep Server
done

# ✅ Distribution en action
```

---

## ✅ Vérification

- [ ] Créer service avec 3 replicas
- [ ] Vérifier le round-robin
- [ ] Tester la distribution

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
