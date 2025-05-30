#!/bin/bash

set -x
set errexit

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# DIR is the absolute directory of this script (`install.sh`)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

# Install the kube-prometheus-stack v48.2.1 helm chart with `overrides.yaml` file.
# https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-48.2.1/charts/kube-prometheus-stack
helm \
upgrade --install \
--namespace monitoring \
prometheus prometheus-community/kube-prometheus-stack \
--version 72.7.0 \
-f "${DIR}"/values.yaml
