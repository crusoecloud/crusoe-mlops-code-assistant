# NovaCode AI Assistant

This repository contains the code for NovaCode, an AI-powered development assistant.

## Deployment Instructions

Follow these steps to deploy NovaCode on your Kubernetes cluster.

### Prerequisites

*   Crusoe Cloud account and `crusoe` CLI configured.
*   `kubectl` installed and configured.
*   `helm` installed.
*   `docker` installed.
*   `terraform` installed.
*   A Hugging Face API token.

### 1. Configure Hugging Face Token

Create a Kubernetes Secret for your Hugging Face API token. Replace `YOUR_HF_TOKEN` with your actual token.

```bash
kubectl create secret generic hf-secret --from-literal=hf_api_token='YOUR_HF_TOKEN' -n default
```

### 2. Configure GitLab Image Pull Secret

Create a Kubernetes Secret for pulling Docker images from GitLab. Replace `YOUR_GITLAB_USERNAME`, `YOUR_GITLAB_PASSWORD`, and `YOUR_GITLAB_EMAIL` with your GitLab credentials.

```bash
kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=YOUR_GITLAB_USERNAME \
  --docker-password=YOUR_GITLAB_PASSWORD \
  --docker-email=YOUR_GITLAB_EMAIL \
  -n default
```

### 3. Deploy All Components

Execute the `deploy-all.sh` script to deploy the infrastructure, frontend, and Prometheus.

```bash
./deploy-all.sh
```

This script performs the following actions:

*   **Infrastructure Deployment**:
    *   Navigates to the `infrastructure` directory.
    *   Applies Terraform configurations to provision the Kubernetes cluster and associated resources on Crusoe Cloud.
*   **Kubernetes Credential Retrieval**:
    *   Retrieves Kubernetes cluster credentials using `crusoe kubernetes clusters get-credentials`.
*   **Frontend Deployment**:
    *   Builds and pushes the frontend Docker image to `registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/novacode-front:latest`.
    *   Deletes and reapplies the Kubernetes frontend deployment.
*   **Prometheus Deployment**:
    *   Adds the `prometheus-community` Helm repository.
    *   Installs the `kube-prometheus-stack` Helm chart with custom overrides.
    *   Applies additional Prometheus monitoring configurations.

### 4. Verify Deployment

After the script completes, verify that all Kubernetes pods are running:

```bash
kubectl get pods -n default
kubectl get pods -n prometheus-system
```

Access the frontend application via the NodePort exposed by the `frontend-service`. The `nodePort` is `30080`. You can find your cluster's public IP or a node's public IP to access it.

```bash
kubectl get svc frontend-service -n default
```

The output will show the `NodePort` and the cluster IP. Use any node's public IP and the `NodePort` (e.g., `http://<NODE_PUBLIC_IP>:30080`) to access the application.
