# 🎓 LEÇON 17 : Sauvegardes et Récupération

**Prérequis** : Leçons 01-16

---

## 🎯 Objectif

- ✅ Sauvegarder les données
- ✅ Récupérer après perte
- ✅ Automatiser les backups

---

## 💡 EXEMPLES

```bash
# Backup volume
docker run --rm -v data:/data -v $(pwd):/backup \
  ubuntu:latest tar czf /backup/data.tar.gz /data

# Restore volume
docker run --rm -v data:/data -v $(pwd):/backup \
  ubuntu:latest tar xzf /backup/data.tar.gz -C /

# Backup BD (MariaDB)
docker exec mariadb.1 \
  mysqldump -uroot -psecret --all-databases \
  | gzip > db-backup.sql.gz

# Restore BD
docker exec -i mariadb.1 \
  mysql -uroot -psecret < db-backup.sql.gz
```

---

## ✅ Vérification

- [ ] Sauvegarder un volume
- [ ] Restaurer un volume
- [ ] Sauvegarder une BD

---

**Durée** : 30 minutes | **Niveau** : 🟡 Intermédiaire
