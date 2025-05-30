#!/bin/bash
set -euo pipefail

# Color codes for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NS=default
CTX=nova-cluster

echo -e "${BLUE}===== Starting deployment of all components =====${NC}"

# Cluster deployment
echo -e "${GREEN}Deploying kubernetes...${NC}"
(
    cd infrastructure
    terraform apply -auto-approve
)

(

    cd kubernetes/
    crusoe kubernetes clusters get-credentials "$CTX" --yes
)
echo -e "${GREEN}Cluster deployment completed${NC}\n"

# Frontend deployment
echo -e "${GREEN}Deploying Frontend...${NC}"
./kubernetes/frontend/deploy.sh
echo -e "${GREEN}Frontend deployment completed${NC}\n"

# Prometheus deployment
echo -e "${GREEN}Deploying Prometheus...${NC}"
./kubernetes/prometheus/install-prometheus.sh
echo -e "${GREEN}Prometheus deployment completed${NC}\n"

echo -e "${BLUE}===== All components deployed! =====${NC}"
