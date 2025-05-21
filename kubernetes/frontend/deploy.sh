#!/bin/bash

set -euo pipefail
# Build and push the image
docker buildx build --platform linux/amd64 -t registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/novacode-front:latest frontend --push

# Reload the deployment
kubectl rollout restart deployment frontend-deployment

# Wait for the rollout to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment frontend-deployment

echo "Deployment completed successfully!"