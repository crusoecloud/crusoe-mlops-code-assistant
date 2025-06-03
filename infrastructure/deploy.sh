#!/bin/bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <apply|destroy> <region>"
  exit 1
fi
ACTION="$1"
REGION="$2"
TFVARS_FILE="tfvars/${REGION}.tfvars"
SECRETS_FILE="tfvars/secrets.tfvars"
TFSTATE_FILE="${REGION}.tfstate"

if [ ! -f "$TFVARS_FILE" ]; then
  echo "Error: tfvars file $TFVARS_FILE does not exist."
  exit 1
fi

# check if secrets.tfvars exists
if [ ! -f "$SECRETS_FILE" ]; then
  echo "Error: $SECRETS_FILE file does not exist. Create it using the secrets.tfvars.template file."
  exit 1
fi

if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
  echo "Error: ACTION must be 'apply' or 'destroy'"
  exit 1
fi

terraform $ACTION -var-file="$TFVARS_FILE" -state="$TFSTATE_FILE" -var-file="$SECRETS_FILE"
