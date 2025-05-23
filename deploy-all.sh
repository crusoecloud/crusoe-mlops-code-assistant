#!/bin/bash
set -euo pipefail

# Color codes for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NS=default
CTX=nova-cluster

echo -e "${BLUE}===== Starting deployment of all components =====${NC}"

# Ray Cluster deployment
echo -e "${GREEN}Deploying kubernetes...${NC}"
(
    cd infrastructure
    terraform apply -auto-approve
    crusoe kubernetes clusters get-credentials "$CTX" --yes
)

(
    NS=default
    CTX=nova-cluster

    cd kubernetes/
    crusoe kubernetes clusters get-credentials "$CTX" --yes
)
echo -e "${GREEN}Ray Cluster deployment completed${NC}\n"


# Ray Cluster deployment
echo -e "${GREEN}Deploying Ray Cluster...${NC}"
./kubernetes/ray-cluster/deploy.sh
echo -e "${GREEN}Ray Cluster deployment completed${NC}\n"

# Frontend deployment
echo -e "${GREEN}Deploying Frontend...${NC}"
./kubernetes/frontend/deploy.sh
echo -e "${GREEN}Frontend deployment completed${NC}\n"

# VLLM deployment
echo -e "${GREEN}Deploying Ray Serve for VLLM...${NC}"
./kubernetes/rayserve/serve_vllm.sh
echo -e "${GREEN}VLLM deployment completed${NC}\n"

# Model Fine-tuning
echo -e "${GREEN}Deploying Model Fine-tuning...${NC}"
./kubernetes/finetune-llm/submit.sh
echo -e "${GREEN}Model Fine-tuning deployment completed${NC}\n"

# Monitoring stack
echo -e "${GREEN}Deploying Prometheus...${NC}"
./kubernetes/monitoring/deploy-prometheus.sh
echo -e "${GREEN}Prometheus deployment completed${NC}\n"

echo -e "${GREEN}Deploying Grafana...${NC}"
./kubernetes/monitoring/deploy-grafana.sh
echo -e "${GREEN}Grafana deployment completed${NC}\n"

echo -e "${GREEN}Configuring Ray monitoring...${NC}"
./kubernetes/monitoring/deploy-ray-monitoring.sh
echo -e "${GREEN}Ray monitoring configuration completed${NC}\n"

echo -e "${BLUE}===== All components deployed! =====${NC}"
echo 
echo -e "${GREEN}To access Ray dashboard, run:${NC}"
echo "  ./kubernetes/ray-cluster/dashboard.sh"
echo "  Ray Dashboard will be available at: http://localhost:8265"
echo 
echo -e "${GREEN}To access Grafana, run:${NC}"
echo "  kubectl port-forward -n monitoring svc/grafana 3000:80"
echo "  Grafana will be available at: http://localhost:3000"
echo 
echo -e "${GREEN}To access Prometheus, run:${NC}"
echo "  kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
echo "  Prometheus will be available at: http://localhost:9090" 