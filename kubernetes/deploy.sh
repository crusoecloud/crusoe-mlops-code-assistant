#!/bin/bash
set -euo pipefail

CTX=nova-cluster

crusoe kubernetes clusters get-credentials "$CTX" --yes

helm repo add kuberay https://ray-project.github.io/kuberay-helm/ --force-update
helm repo update

helm upgrade --install kuberay-operator kuberay/kuberay-operator \
  --kube-context "$CTX" \
  --wait --atomic

helm upgrade --install ray-cluster kuberay/ray-cluster \
  -f ray-cluster.values.yaml \
  --kube-context "$CTX" \
  --wait --atomic


