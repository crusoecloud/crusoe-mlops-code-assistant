#!/bin/bash
set -euo pipefail

NS=monitoring

function check_deployment() {
  echo "Checking $1 deployment..."
  if kubectl get deployment -n "$NS" $1 2>/dev/null; then
    echo "$1 is deployed."
    return 0
  else
    echo "$1 is not deployed."
    return 1
  fi
}

function check_service() {
  echo "Checking $1 service..."
  if kubectl get service -n "$NS" $1 2>/dev/null; then
    echo "$1 service is deployed."
    return 0
  else
    echo "$1 service is not deployed."
    return 1
  fi
}

echo "Testing Prometheus and Grafana setup..."

# Check Prometheus
check_deployment "prometheus-server" && check_service "prometheus-server"

# Check Grafana
check_deployment "grafana" && check_service "grafana"

echo "Setting up port forwards for testing..."
echo "Starting Prometheus port forward on 9090..."
kubectl port-forward -n "$NS" svc/prometheus-server 9090:80 &
PROMETHEUS_PID=$!

echo "Starting Grafana port forward on 3000..."
kubectl port-forward -n "$NS" svc/grafana 3000:80 &
GRAFANA_PID=$!

echo
echo "Monitoring endpoints are now accessible at:"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo
echo "Press Enter to stop port forwarding..."
read

kill $PROMETHEUS_PID $GRAFANA_PID
echo "Port forwarding stopped." 