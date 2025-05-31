#!/bin/bash
set -euo pipefail

# Color codes for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${BLUE}Error: jq is not installed. Please install jq to parse JSON outputs.${NC}"
    exit 1
fi
# Check if crusoe is installed
if ! command -v crusoe &> /dev/null; then
    echo -e "${BLUE}Error: crusoe is not installed. Please install crusoe to manage Kubernetes clusters.${NC}"
    exit 1
fi
# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${BLUE}Error: kubectl is not installed. Please install kubectl to manage Kubernetes clusters.${NC}"
    exit 1
fi
# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${BLUE}Error: terraform is not installed. Please install terraform to manage infrastructure.${NC}"
    exit 1
fi
# Check if envsubst is installed
if ! command -v envsubst &> /dev/null; then
    echo -e "${BLUE}Error: envsubst is not installed. Please install gettext to use envsubst for variable substitution.${NC}"
    exit 1
fi


# Parse arguments
REGION=""
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --region)
      REGION="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      POSITIONAL+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [ -z "$REGION" ]; then
  echo -e "${BLUE}Error: --region argument is required.${NC}"
  echo -e "${BLUE}Usage: $0 --region <region-name>${NC}"
  echo -e "${BLUE}Example: $0 --region eu-iceland1-a${NC}"
  exit 1
fi

echo -e "${BLUE}===== Starting deployment of all components =====${NC}"

# Infrastructure deployment
(
    cd infrastructure
    ./deploy.sh "$REGION"
)

# Parse Terraform outputs
TF_OUTPUT=$(cd infrastructure && terraform output -state="${REGION}.tfstate" -json)
VOLUME_HANDLE=$(echo "$TF_OUTPUT" | jq -r .model_disk_id.value)
SERIAL_NUMBER=$(echo "$TF_OUTPUT" | jq -r .model_disk_serial_number.value)
CTX=$(echo "$TF_OUTPUT" | jq -r .kubernetes_context.value)

export VOLUME_HANDLE SERIAL_NUMBER REGION

(
    cd kubernetes/
    export KUBECONFIG="$(pwd)/kubeconfig.yaml"
    crusoe kubernetes clusters get-credentials "$CTX" --yes
    kubectl config use-context "$CTX"
)
echo -e "${GREEN}Infrastructure deployment completed${NC}\n"

# Deploy namespaces
echo -e "${GREEN}Deploying Namespaces...${NC}"
kubectl apply -f kubernetes/ns.yaml
echo -e "${GREEN}Namespaces deployed${NC}\n"

# Storage deployment
echo -e "${GREEN}Deploying Storage...${NC}"
VOLUME_HANDLE="$VOLUME_HANDLE" SERIAL_NUMBER="$SERIAL_NUMBER" REGION="$REGION" \
./kubernetes/storage/deploy.sh
echo -e "${GREEN}Storage deployment completed${NC}\n"

# vllm deployment
echo -e "${GREEN}Deploying LLMs...${NC}"
./kubernetes/vllm-inference/deploy.sh
echo -e "${GREEN}LLMs deployment completed${NC}\n"

# Frontend deployment
echo -e "${GREEN}Deploying Frontend...${NC}"
./kubernetes/frontend/deploy.sh
echo -e "${GREEN}Frontend deployment completed${NC}\n"

# Prometheus deployment
echo -e "${GREEN}Deploying Prometheus...${NC}"
./kubernetes/prometheus/install-prometheus.sh
echo -e "${GREEN}Prometheus deployment completed${NC}\n"

echo -e "${BLUE}===== All components deployed! =====${NC}"
