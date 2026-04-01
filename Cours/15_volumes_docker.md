# 🎓 LEÇON 15 : Types de Volumes Docker

**Prérequis** : Leçons 01-14

---

## 🎯 Objectif

- ✅ Named volumes
- ✅ Bind mounts
- ✅ Tmpfs volumes
- ✅ Quand utiliser chacun

---

## 📖 Concept

### Types de Stockage

```
1. NAMED VOLUME
   docker volume create mon-vol
   → Géré par Docker
   → Persiste
   → Meilleur pour données importantes

2. BIND MOUNT
   -v /host/path:/container/path
   → Lien direct au filesystem
   → Bon pour développement

3. TMPFS
   --tmpfs /tmp
   → Mémoire RAM
   → Éphémère
   → Bon pour cache
```

---

## 💡 EXEMPLES

```bash
# Named volume
docker volume create data
docker run -v data:/data ubuntu:latest

# Bind mount
docker run -v /home/user/project:/app ubuntu:latest

# Tmpfs
docker run --tmpfs /tmp:rw,size=128m ubuntu:latest
```

---

## ✅ Vérification

- [ ] Créer named volume
- [ ] Utiliser bind mount
- [ ] Utiliser tmpfs
- [ ] Vérifier la persistance

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
