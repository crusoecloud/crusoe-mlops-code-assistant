#!/bin/bash

set -euo pipefail
# Build and push the image
docker buildx build --platform linux/amd64 -t registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/novacode-front:latest frontend --push

# Reload the deployment
kubectl  apply -f kubernetes/frontend/deployment.yaml

