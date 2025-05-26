variable "project_id" {
  description = "Crusoe Cloud Project ID."
  type        = string
}

variable "subnet_id" {
  description = "Id of the subnet."
  type        = string
  default     = "abcdefhijklmnopqrstuvwxyz01234567890"
}

variable "ib_partition_id" {
  description = "Id of IB Partition."
  type        = string
  default     = "abcdefhijklmnopqrstuvwxyz01234567890"
}

variable "vpc_network_id" {
  description = "Id of the VPC network."
  type        = string
  default     = "abcdefhijklmnopqrstuvwxyz01234567890"
}
variable "vpc_network_cidr" {
  description = "CIDR block for the VPC network."
  type        = string
  default     = ""
}
variable "cluster_name" {
  description = "Name for the Kubernetes cluster."
  type        = string
  default     = "gpu-cluster"
}

variable "cluster_location" {
  description = "Location for the Kubernetes cluster and subnet (e.g., 'us-central1-a')."
  type        = string
}

variable "whitelist_ip" {
  description = "List of IP addresses to whitelist for access."
  type = list(object({
    id      = string
    address = string
  }))
  default = []
}
variable "cluster_version" {
  description = "Kubernetes version for the cluster and node pool."
  type        = string
  default     = "1.31.7-cmk.4"
}

variable "nodepool_version" {
  description = "Kubernetes version for the node pool."
  type        = string
  default     = "1.31.7-cmk.3"
}


variable "nodepool_name" {
  description = "Name for the Kubernetes node pool."
  type        = string
  default     = "gpu-worker-pool"
}

variable "nodepool_instance_type" {
  description = "Instance type for the node pool (e.g., 'a100.2x', 'a40.2x'). Must provide 2 or more A40 or A100 GPUs."
  type        = string
  default     = "a100.2x"
}

variable "ssh_public_key" {
  description = "Public SSH key string to access nodes in the node pool."
  type        = string
  sensitive   = true
}
