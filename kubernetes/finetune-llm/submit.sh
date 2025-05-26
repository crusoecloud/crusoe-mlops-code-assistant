#!/usr/bin/env bash
set -euo pipefail
NS=default
CTX=nova-cluster

# -------- config maps --------------------------------------------------
kubectl --context "$CTX" -n "$NS" delete configmap lora-train-cfg-default --ignore-not-found &
kubectl --context "$CTX" -n "$NS" delete configmap lora-train-cfg-local   --ignore-not-found &
kubectl --context "$CTX" -n "$NS" delete configmap lora-train-src         --ignore-not-found &
kubectl --context "$CTX" -n "$NS" delete -f kubernetes/finetune-llm/rayjob.yaml                   --ignore-not-found &


wait 
kubectl create configmap lora-train-cfg-default \
  --context "$CTX" -n "$NS" \
  --from-env-file=kubernetes/finetune-llm/.env.example

if [[ -f .env ]]; then
  kubectl create configmap lora-train-cfg-local \
    --context "$CTX" -n "$NS" \
    --from-env-file=kubernetes/finetune-llm/.env
else
  kubectl create configmap lora-train-cfg-local \
    --context "$CTX" -n "$NS" \
    --from-env-file=kubernetes/finetune-llm/.env.example
fi

kubectl create configmap lora-train-src \
  --context "$CTX" -n "$NS" \
  --from-file=kubernetes/finetune-llm/app 

kubectl apply --context "$CTX" -n "$NS" -f kubernetes/finetune-llm/rayjob.yaml
