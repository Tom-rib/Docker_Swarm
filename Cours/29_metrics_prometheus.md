# 🎓 LEÇON 29 : Monitoring avec Prometheus

**Prérequis** : Leçons 01-28

---

## 🎯 Objectif

- ✅ Prometheus pour métriques
- ✅ Grafana pour visualisation
- ✅ Alertes

---

## 💡 EXEMPLES

```bash
# Déployer Prometheus
docker service create \
  --name prometheus \
  --publish 9090:9090 \
  prom/prometheus:latest

# Config scrape targets
cat > prometheus.yml << 'YAML'
scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9090']
YAML

# Grafana pour dashboard
docker service create \
  --name grafana \
  --publish 3000:3000 \
  grafana/grafana:latest
```

---

## ✅ Vérification

- [ ] Déployer Prometheus
- [ ] Accéder au dashboard
- [ ] Requêter des métriques

---

**Durée** : 30 minutes | **Niveau** : 🟠 Avancé
