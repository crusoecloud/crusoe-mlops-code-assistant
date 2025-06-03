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

variable "nodepool_instance_count" {
  description = "Number of instances in the node pool."
  type        = number
  default     = 2
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

variable "shared_disk_name" {
  description = "Name for the shared disk."
  type        = string
  default     = "novacode-shared"
}

variable "docker_registry" {
  description = "The Docker registry to use for images."
  type        = string
  default     = "registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode"
}

variable "hf_token" {
  description = "Hugging Face API token."
  type        = string
  sensitive   = true
}

variable "docker_username" {
  description = "Docker registry username."
  type        = string
  sensitive   = true
}

variable "docker_password" {
  description = "Docker registry password."
  type        = string
  sensitive   = true
}

variable "docker_email" {
  description = "Docker registry email."
  type        = string
  sensitive   = true
}
