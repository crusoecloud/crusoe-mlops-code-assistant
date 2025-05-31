#!/bin/bash
set -euo pipefail

# Deploy vllm-inference/llama manifests
kubectl apply -f kubernetes/vllm-inference/llama

# Deploy vllm-inference/mistral manifests
kubectl apply -f kubernetes/vllm-inference/mistral
