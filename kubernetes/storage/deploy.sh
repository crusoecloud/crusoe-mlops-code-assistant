#!/bin/bash
set -euo pipefail

# Deploy PV and PVC using env vars passed from parent script
envsubst < kubernetes/storage/pv.yaml | kubectl apply -f -
kubectl apply -f kubernetes/storage/pvc.yaml
