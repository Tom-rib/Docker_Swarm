# 05 - Backups et Récupération

**Objectif :** Mettre en place une stratégie de backup pour protéger les données critiques du cluster.

## 📋 Récap de l'Objectif

Un cluster résilient **sans backup**, c'est incomplet. On va mettre en place :

- Backup automatisé des données MariaDB
- Backup des fichiers de configuration
- Backup du registry Docker
- Tests de restauration (c'est le plus important)

## 🎯 Stratégie de Backup

### Données à Sauvegarder

| Donnée | Emplacement | Criticité | Fréquence |
|--------|-----------|-----------|-----------|
| **MariaDB** | `/swarm-data/mariadb` | 🔴 Critique | Quotidienne |
| **Fichiers app** | `/swarm-data/php/app` | 🟡 Importante | Hebdomadaire |
| **Config Nginx** | `/swarm-data/nginx` | 🟡 Importante | À chaque changement |
| **Registry images** | `/swarm-data/registry` | 🟡 Importante | Hebdomadaire |
| **docker-compose.yml** | Repo local | 🔴 Critique | À chaque changement |

### Points de Restauration

- **Backup quotidien** : MariaDB (données métier)
- **Backup hebdomadaire** : Tous les fichiers NFS
- **Backup de config** : GitOps (versioning)

## 💾 Étape 1 : Backup Manuel de MariaDB

### Dump de la Base de Données

```bash
# Sur le manager, créer un dump de MariaDB
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysqldump \
  -h mariadb \
  -u appuser \
  -papppassword \
  app_db > /swarm-data/backups/app_db_$(date +%Y%m%d_%H%M%S).sql

# Vérifier le backup
ls -lh /swarm-data/backups/
```

**Important :** Crée d'abord le répertoire `/swarm-data/backups` sur le NFS :

```bash
# Sur le NFS server
sudo mkdir -p /swarm-data/backups
sudo chmod 777 /swarm-data/backups
```

### Vérifier le Backup

```bash
# Voir les fichiers dumped
ls -la /swarm-data/backups/

# Vérifier la taille
du -sh /swarm-data/backups/

# Vérifier le contenu (premiers 20 lignes)
head -20 /swarm-data/backups/app_db_*.sql
```

## 💾 Étape 2 : Backup des Fichiers NFS

### Script de Backup Complet

Crée un script pour sauvegarder toutes les données :

```bash
# Sur le NFS server
sudo nano /usr/local/bin/backup-swarm.sh
```

Ajoute ce contenu :

```bash
#!/bin/bash
# Backup automatisé du cluster Swarm

BACKUP_DIR="/swarm-data/backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_DIR/backup_$DATE.log"

echo "=== Backup Swarm - $DATE ===" > $LOG_FILE

# Créer le répertoire backup s'il n'existe pas
mkdir -p $BACKUP_DIR

# Backup MariaDB
echo "[1/4] Backup MariaDB..." | tee -a $LOG_FILE
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysqldump \
  -h mariadb \
  -u appuser \
  -papppassword \
  app_db > $BACKUP_DIR/app_db_$DATE.sql 2>>$LOG_FILE

if [ $? -eq 0 ]; then
  echo "✓ Backup MariaDB OK" | tee -a $LOG_FILE
else
  echo "❌ Erreur Backup MariaDB" | tee -a $LOG_FILE
fi

# Backup fichiers NFS
echo "[2/4] Backup fichiers NFS..." | tee -a $LOG_FILE
tar -czf $BACKUP_DIR/nfs_data_$DATE.tar.gz \
  --exclude='backups' \
  --exclude='.docker' \
  /swarm-data 2>>$LOG_FILE

if [ $? -eq 0 ]; then
  echo "✓ Backup NFS OK" | tee -a $LOG_FILE
else
  echo "❌ Erreur Backup NFS" | tee -a $LOG_FILE
fi

# Backup docker-compose.yml
echo "[3/4] Backup docker-compose.yml..." | tee -a $LOG_FILE
cp /path/to/docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml 2>>$LOG_FILE

if [ $? -eq 0 ]; then
  echo "✓ Backup docker-compose OK" | tee -a $LOG_FILE
else
  echo "❌ Erreur Backup docker-compose" | tee -a $LOG_FILE
fi

# Statistiques
echo "[4/4] Statistiques..." | tee -a $LOG_FILE
du -sh $BACKUP_DIR/* | tee -a $LOG_FILE

echo "=== Backup Terminé ===" | tee -a $LOG_FILE
```

Rends-le exécutable :

```bash
sudo chmod +x /usr/local/bin/backup-swarm.sh
```

### Automatiser avec Cron

Lance le backup tous les jours à 2h du matin :

```bash
# Éditer crontab
sudo crontab -e

# Ajouter cette ligne :
0 2 * * * /usr/local/bin/backup-swarm.sh
```

Vérifie que cron est actif :

```bash
sudo systemctl status cron
sudo systemctl start cron  # Si arrêté
```

### Vérifier les Backups Automatiques

```bash
# Voir les logs de cron
sudo tail -20 /var/log/syslog | grep backup-swarm

# Ou consulter le log directement
ls -lh /swarm-data/backups/
```

## 🔄 Étape 3 : Restauration de MariaDB

### Restaurer depuis un Dump SQL

Si tu dois restaurer MariaDB :

```bash
# 1. Vérifier le dump disponible
ls -la /swarm-data/backups/app_db_*.sql

# 2. Restaurer la base
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysql \
  -h mariadb \
  -u appuser \
  -papppassword \
  app_db < /swarm-data/backups/app_db_20240330_142530.sql

# 3. Vérifier les données restaurées
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SHOW TABLES; SELECT * FROM test;"
```

### Restauration Complète

Si tu dois restaurer **tous les fichiers NFS** :

```bash
# 1. Arrêter les services
docker stack rm swarm-app

# 2. Attendre que les conteneurs s'arrêtent (30 secondes)
sleep 30

# 3. Sauvegarder les données actuelles (par sécurité)
sudo mv /swarm-data /swarm-data.old

# 4. Créer un nouveau répertoire
sudo mkdir -p /swarm-data

# 5. Restaurer depuis le backup tar.gz
sudo tar -xzf /swarm-data.old/backups/nfs_data_20240330_142530.tar.gz -C /

# 6. Vérifier
ls -la /swarm-data/

# 7. Redéployer la stack
docker stack deploy -c docker-compose.yml swarm-app
```

## ✅ Test 1 : Tester la Restauration MariaDB

C'est **crucial** de tester que les backups fonctionnent !

### Créer des Données de Test

```bash
# 1. Insérer des données
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "INSERT INTO test VALUES (42, 'Backup Test');"

# 2. Vérifier que la donnée existe
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SELECT * FROM test WHERE id = 42;"
```

### Faire un Dump

```bash
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysqldump \
  -h mariadb \
  -u appuser \
  -papppassword \
  app_db > /swarm-data/backups/test_backup.sql
```

### Supprimer la Donnée de Test

```bash
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "DELETE FROM test WHERE id = 42;"

# Vérifier qu'elle est supprimée
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SELECT * FROM test WHERE id = 42;"

# Résultat attendu : aucune ligne
```

### Restaurer depuis le Backup

```bash
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysql \
  -h mariadb \
  -u appuser \
  -papppassword \
  app_db < /swarm-data/backups/test_backup.sql

# Vérifier la restauration
docker run --rm -it \
  --network swarm-app_swarm-net \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db \
  -e "SELECT * FROM test WHERE id = 42;"

# Résultat attendu : la donnée est de retour !
```

✓ **Si ça marche, ton backup fonctionne.**

## ✅ Test 2 : Tester la Restauration NFS

### Créer un Fichier de Test

```bash
# Sur un worker
echo "Backup Test - $(date)" > /swarm-data/test-backup.txt

# Vérifier sur les deux workers
cat /swarm-data/test-backup.txt
```

### Faire un Backup TAR

```bash
# Sur le manager
sudo tar -czf /swarm-data/backups/nfs_test.tar.gz /swarm-data/test-backup.txt

# Vérifier
ls -lh /swarm-data/backups/nfs_test.tar.gz
```

### Supprimer le Fichier

```bash
# Sur un worker
rm /swarm-data/test-backup.txt

# Vérifier qu'il est supprimé (sur les deux)
ls -la /swarm-data/test-backup.txt  # Erreur 'No such file'
```

### Restaurer depuis le Backup

```bash
# Restaurer
sudo tar -xzf /swarm-data/backups/nfs_test.tar.gz -C /

# Vérifier la restauration
cat /swarm-data/test-backup.txt

# Résultat attendu : \\\"Backup Test - ...\\\"
```

✓ **Si ça marche, ton backup NFS fonctionne.**

## 📊 Test 3 : Vérifier les Backups Réguliers

```bash
# Vérifier que les backups quotidiens existent
ls -lh /swarm-data/backups/ | tail -10

# Vérifier l'espace utilisé
du -sh /swarm-data/backups/

# Vérifier les logs de backup
tail -50 /swarm-data/backups/backup_*.log
```

## 🧹 Nettoyage des Anciens Backups

Les backups prennent de la place. Nettoie les anciens périodiquement :

```bash
# Voir les backups de plus de 30 jours
find /swarm-data/backups -name "*.sql" -type f -mtime +30 -ls

# Supprimer les backups de plus de 30 jours
find /swarm-data/backups -name "*.sql" -type f -mtime +30 -delete
find /swarm-data/backups -name "*.tar.gz" -type f -mtime +30 -delete

# Vérifier l'espace récupéré
du -sh /swarm-data/backups/
```

Ou automatise avec un cron qui nettoie les anciens :

```bash
# Éditer crontab
sudo crontab -e

# Ajouter (nettoyage hebdomadaire)
0 3 * * 0 find /swarm-data/backups -type f -mtime +30 -delete
```

## 📝 Fiche Mémoire - Backups

**Backup manuel MariaDB :**
```bash
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysqldump -h mariadb -u appuser -papppassword app_db > /swarm-data/backups/backup_$(date +%Y%m%d).sql
```

**Restaurer MariaDB :**
```bash
docker run --rm \
  --network swarm-app_swarm-net \
  -v /swarm-data/backups:/backup \
  mysql:8.0 \
  mysql -h mariadb -u appuser -papppassword app_db < /swarm-data/backups/backup.sql
```

**Backup NFS (tar) :**
```bash
tar -czf /swarm-data/backups/backup_$(date +%Y%m%d).tar.gz --exclude='backups' /swarm-data
```

**Restaurer NFS :**
```bash
tar -xzf /swarm-data/backups/backup.tar.gz -C /
```

**Automatiser :**
```bash
sudo crontab -e
# Ajouter : 0 2 * * * /usr/local/bin/backup-swarm.sh
```

## ✅ Checklist Backup

Tu as fini quand :

- [ ] Script de backup créé et testé
- [ ] Cron configuré pour backup quotidien
- [ ] Test de restauration MariaDB réussi
- [ ] Test de restauration NFS réussi
- [ ] Répertoire `/swarm-data/backups` vérifiéà
- [ ] Espace disque suffisant pour 30 jours de backups
- [ ] Documentation des procédures sauvegardée

## 🚀 Prochaine Étape

Maintenant que ton cluster a des backups, passe à [06_annexes.md](./06_annexes.md) pour les commandes utiles et le dépannage.

---

**Rappel : Un backup qui ne peut pas être restauré, ce n'est pas un backup. Toujours tester la restauration !**
