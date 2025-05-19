#!/bin/bash

# Build and push the image
docker build -t registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/novacode-front:latest frontend
docker push registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/novacode-front:latest

# Reload the deployment
kubectl rollout restart deployment frontend-deployment

# Wait for the rollout to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment frontend-deployment

echo "Deployment completed successfully!"