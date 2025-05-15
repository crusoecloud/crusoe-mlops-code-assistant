#!/bin/bash
set -euo pipefail

NS=monitoring
CTX=nova-cluster

# Create monitoring namespace if it doesn't exist
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy Prometheus
echo "Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --kube-context "$CTX" \
  --namespace "$NS" \
  --values kubernetes/monitoring/prometheus-values.yaml

echo
echo "Prometheus deployment initiated. Check status with:"
echo "kubectl get pods -n $NS" 