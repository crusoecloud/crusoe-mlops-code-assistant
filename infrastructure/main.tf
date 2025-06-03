terraform {
  required_providers {
    crusoe = {
      source  = "crusoecloud/crusoe"
      version = "0.5.29"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.2"
    }
  }
}

locals {
    kubeconfig_name = "${var.cluster_name}-${var.cluster_location}"
}

data "local_file" "kubeconfig" {
  depends_on = [crusoe_kubernetes_cluster.gpu_cluster]
  filename   = "${path.module}/kubeconfigs/${local.kubeconfig_name}.yaml"
}

provider "kubernetes" {
  # Use the kubeconfig content directly
  config_path    = ""
  config_context = ""

  # Use the kubeconfig content directly
  host                   = yamldecode(data.local_file.kubeconfig.content).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(data.local_file.kubeconfig.content).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(data.local_file.kubeconfig.content).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(data.local_file.kubeconfig.content).clusters[0].cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    # Use the kubeconfig content directly
  config_path    = ""
  config_context = ""

  # Use the kubeconfig content directly
  host                   = yamldecode(data.local_file.kubeconfig.content).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(data.local_file.kubeconfig.content).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(data.local_file.kubeconfig.content).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(data.local_file.kubeconfig.content).clusters[0].cluster.certificate-authority-data)
  }
}

module "kubernetes_resources" {
  source = "./kubernetes"

  docker_registry    = var.docker_registry
  region             = var.cluster_location
  disk_name          = crusoe_storage_disk.shared_disk.name
  disk_volume_handle = crusoe_storage_disk.shared_disk.id
  disk_serial_number = crusoe_storage_disk.shared_disk.serial_number

  hf_token        = var.hf_token
  docker_username = var.docker_username
  docker_password = var.docker_password
  docker_email    = var.docker_email

  depends_on = [
    crusoe_kubernetes_cluster.gpu_cluster,
    crusoe_kubernetes_node_pool.gpu_nodepool,
    crusoe_storage_disk.shared_disk,
  ]
}
