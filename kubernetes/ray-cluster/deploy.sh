#!/bin/bash
set -euo pipefail

NS=default
CTX=nova-cluster

crusoe kubernetes clusters get-credentials "$CTX" --yes

kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

helm repo add kuberay https://ray-project.github.io/kuberay-helm/ --force-update
helm repo update

helm upgrade --install kuberay-operator kuberay/kuberay-operator \
  --kube-context "$CTX" \
  --namespace "$NS" \
  --wait --atomic

