# 🎓 LEÇON 16 : NFS - Stockage Partagé Multi-Nœuds

**Prérequis** : Leçons 01-15

---

## 🎯 Objectif

- ✅ Installer NFS server
- ✅ Configurer exports
- ✅ Monter sur workers
- ✅ Utiliser avec Docker volumes

---

## 📖 Concept

### Architecture NFS

```
NFS Server (192.168.1.20)
/export/docker/
├── mariadb
├── nginx
├── app
└── registry

        ↓ Mount (tous les workers)

Worker 1    Worker 2    Worker 3
/mnt/nfs    /mnt/nfs    /mnt/nfs
(même)      (même)      (même)

✅ Tous les workers partagent les données
```

---

## 💡 EXEMPLES

```bash
# === NFS SERVER ===
sudo apt-get install -y nfs-kernel-server
sudo mkdir -p /export/docker
echo "/export/docker 192.168.1.0/24(rw,sync)" | sudo tee /etc/exports
sudo exportfs -a

# === CHAQUE WORKER ===
sudo apt-get install -y nfs-common
sudo mkdir -p /mnt/nfs
sudo mount -t nfs 192.168.1.20:/export/docker /mnt/nfs

# === DANS SWARM ===
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.20,vers=4,soft,timeo=180,bg,tcp,rw \
  --opt device=:/export/docker/mariadb \
  mariadb-vol
```

---

## ✅ Vérification

- [ ] NFS server configuré
- [ ] Mount sur workers
- [ ] Docker volume via NFS
- [ ] Service utilisant NFS

---

**Durée** : 40 minutes | **Niveau** : 🟡 Intermédiaire
