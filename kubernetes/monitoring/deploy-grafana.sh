#!/bin/bash
set -euo pipefail

NS=monitoring
CTX=nova-cluster

# Create monitoring namespace if it doesn't exist
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Add Helm repositories
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy Grafana
echo "Deploying Grafana..."
helm upgrade --install grafana grafana/grafana \
  --kube-context "$CTX" \
  --namespace "$NS" \
  --values kubernetes/monitoring/grafana-values.yaml

echo
echo "Grafana deployment initiated. Check status with:"
echo "kubectl get pods -n $NS" 