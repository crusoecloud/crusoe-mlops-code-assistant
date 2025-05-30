terraform {
  required_providers {
    crusoe = {
      source = "crusoecloud/crusoe"
      version = "0.5.28"
    }
  }
}

provider "crusoe" {}

resource "crusoe_kubernetes_cluster" "gpu_cluster" {
  project_id = var.project_id
  name       = var.cluster_name
  location   = var.cluster_location
  version    = var.cluster_version
  subnet_id  = var.subnet_id
  add_ons    = ["crusoe_csi", "nvidia_gpu_operator", "nvidia_network_operator", "cluster_autoscaler"]
}

resource "crusoe_ib_partition" "gpu_ib_partition" {
  project_id     = var.project_id
  ib_network_id  = var.ib_partition_id
  name           = "${var.nodepool_name}-infiniband-partition"
}

resource "crusoe_kubernetes_node_pool" "gpu_nodepool" {
  project_id      = var.project_id
  name            = var.nodepool_name
  cluster_id      = crusoe_kubernetes_cluster.gpu_cluster.id
  instance_count  = 3
  type            = var.nodepool_instance_type
  ssh_key         = var.ssh_public_key
  subnet_id       = var.subnet_id
  version         = var.nodepool_version
  ib_partition_id = crusoe_ib_partition.gpu_ib_partition.id
}

resource "crusoe_vpc_firewall_rule" "allow_connection_rules" {
  project_id        = var.project_id
  for_each          = { for ip in var.whitelist_ip : ip.id => ip }
  network           = var.vpc_network_id
  name              = "allow-connection-${each.key}"
  action            = "allow"
  direction         = "ingress"
  protocols         = "tcp"
  source            = each.value.address
  source_ports      = ""
  destination       = var.vpc_network_cidr
  destination_ports = "30865,30080,30081,30866,30870"
}
