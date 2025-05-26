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

# Prometheus deployment
echo -e "${GREEN}Deploying Prometheus...${NC}"
./kubernetes/prometheus/install-prometheus.sh
echo -e "${GREEN}Prometheus deployment completed${NC}\n"

# VLLM deployment
echo -e "${GREEN}Deploying Ray Serve for VLLM...${NC}"
./kubernetes/rayserve/serve_vllm.sh
echo -e "${GREEN}VLLM deployment completed${NC}\n"

# Model Fine-tuning
echo -e "${GREEN}Deploying Model Fine-tuning...${NC}"
./kubernetes/finetune-llm/submit.sh
echo -e "${GREEN}Model Fine-tuning deployment completed${NC}\n"

echo -e "${BLUE}===== All components deployed! =====${NC}"
