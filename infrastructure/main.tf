terraform {
  required_providers {
    crusoe = {
      source = "crusoecloud/crusoe"
      # Specify the version of the Crusoe provider you intend to use.
      version = "0.5.28"
    }
  }
}

provider "crusoe" {
  # api_endpoint = Optional: specify if using a non-default API endpoint
}



resource "crusoe_kubernetes_cluster" "gpu_cluster" {
  project_id = var.project_id
  name       = var.cluster_name
  location   = var.cluster_location
  version    = var.cluster_version
  subnet_id  = var.subnet_id
  add_ons    = ["crusoe_csi", "nvidia_gpu_operator", "nvidia_network_operator", "cluster_autoscaler"]
}

resource "crusoe_kubernetes_node_pool" "gpu_nodepool" {
  project_id     = var.project_id
  name           = var.nodepool_name
  cluster_id     = crusoe_kubernetes_cluster.gpu_cluster.id
  instance_count = 1
  type           = var.nodepool_instance_type
  ssh_key        = var.ssh_public_key
  subnet_id      = var.subnet_id
  version        = var.nodepool_version # Ensure node pool K8s version matches cluster
}
