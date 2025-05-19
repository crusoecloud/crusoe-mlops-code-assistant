# Kubernetes Monitoring with Prometheus and Grafana

This directory contains configurations and scripts to set up Prometheus and Grafana for monitoring your Kubernetes cluster and Ray services.

## Deployment

1. Deploy Prometheus:

```bash
./deploy-prometheus.sh
```

2. Deploy Grafana:

```bash
./deploy-grafana.sh
```

3. Configure Ray monitoring:

```bash
./deploy-ray-monitoring.sh
```

### Accessing the Dashboards

After deployment, you can can test the monitoring setup by running:

```bash
./test-monitoring.sh
```

This will allow for accessing

- **Prometheus** on http://localhost:9090

- **Grafana** on http://localhost:3000
  - Username: admin
  - Password: admin
