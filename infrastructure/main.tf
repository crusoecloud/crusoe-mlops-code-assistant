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

provider "kubernetes" {
  config_path = "./kubernetes/kubeconfig.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "./kubernetes/kubeconfig.yaml"
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
