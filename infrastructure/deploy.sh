#!/bin/bash
set -euo pipefail

# Usage: ./deploy.sh <region>

if [ $# -ne 1 ]; then
  echo "Usage: $0 <region>"
  exit 1
fi
REGION="$1"
TFVARS_FILE="${REGION}.tfvars"
TFSTATE_FILE="${REGION}.tfstate"

if [ ! -f "$TFVARS_FILE" ]; then
  echo "Error: tfvars file $TFVARS_FILE does not exist in $(pwd)"
  exit 1
fi

terraform apply -var-file="$TFVARS_FILE" -state="$TFSTATE_FILE"
