#!/bin/bash
set -euo pipefail

CTX=nova-cluster

# Apply the Ray monitoring configuration
echo "Applying Ray monitoring configuration..."
kubectl apply -f kubernetes/monitoring/ray-cluster-monitoring.yaml

echo
echo "Ray monitoring has been configured."
echo "Ray metrics will be available in Prometheus and can be visualized in Grafana." 