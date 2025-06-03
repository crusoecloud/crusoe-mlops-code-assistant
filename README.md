# NovaCode AI Assistant

This repository contains the code for NovaCode, an AI-powered development assistant.

## Deployment Instructions

NovaCode is deployed using Terraform to provision infrastructure and Kubernetes resources.
Follow these steps to deploy NovaCode on your Kubernetes cluster.

### Prerequisites

* Crusoe Cloud account and [crusoe CLI configured](https://docs.crusoecloud.com/quickstart/installing-the-cli/index.html).
* `kubectl` installed and configured.
* `helm` installed.
* `docker` installed.
* `terraform` installed.
* A Hugging Face API token.
* A GitHub account.

### 1. Change Directory

First, change into the `infrastructure` directory:

```bash
cd infrastructure
```

### 2. Configure Secrets

Before deploying, you must configure your secrets:

1. Copy the secrets.tfvars.template file:

   ```bash
   cp tfvars/secrets.tfvars.template tfvars/secrets.tfvars
   ```

2. Edit `tfvars/secrets.tfvars` and fill in your Hugging Face token and Docker registry credentials:

   ```hcl
   hf_token = "<YOUR_HF_TOKEN>"
   docker_username = "<YOUR_DOCKER_USERNAME>"
   docker_password = "<YOUR_DOCKER_PASSWORD>"
   docker_email    = "<YOUR_DOCKER_EMAIL>"
   ```

### 3. Select Region and Prepare Variables

Choose your deployment region (e.g., `eu-iceland1-a` or `us-east1-a`). Ensure the corresponding tfvars file exists in `tfvars/` (e.g., `eu-iceland1-a.tfvars`).

### 4. Deploy Infrastructure and Kubernetes Resources

Use the provided deployment script to apply or destroy the infrastructure:

```bash
./deploy.sh apply <region>
```

Replace `<region>` with your chosen region (e.g., `eu-iceland1-a`).

This script will:
- Validate the presence of required tfvars and secrets files.
- Run `terraform apply` with the correct variable files and state file.
- Provision the Crusoe Kubernetes cluster and all required resources.

**NOTE: The deployment process might time out because of the time it takes to provision the Kubernetes cluster and resources.
If this happens, you can safely re-run the command until the deployment is successful.**

To destroy the infrastructure, run:

```bash
./deploy.sh destroy <region>
```

### 5. Retrieve Kubernetes Credentials

After successful deployment, retrieve your Kubernetes credentials:

```bash
crusoe kubernetes clusters get-credentials <cluster-name> --region <region>
```

Replace `<cluster-name>` and `<region>` with your actual values.

Alternatively, you can use the infrastructure/kubernetes/kubeconfig.yaml file that is created during the deployment.
This file contains the necessary credentials to access your Kubernetes cluster.

### 6. Verify Deployment

Check that all pods are running:

```bash
kubectl get pods -n inference
kubectl get pods -n monitoring
```

Access the frontend via the NodePort exposed by the `frontend-service` (default: `30080`).
Find your cluster's public IP in the Crusoe Cloud dashboard and use:

```
http://<NODE_PUBLIC_IP>:30080
```

### Notes

- All infrastructure and Kubernetes resources are managed via Terraform. Avoid manual changes to prevent drift.
- For customizations, edit the appropriate tfvars files or module configurations.
