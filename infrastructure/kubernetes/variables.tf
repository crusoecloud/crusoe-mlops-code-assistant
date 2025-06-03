variable "docker_registry" {
  description = "The Docker registry to use for images."
  type        = string
}

variable "region" {
  description = "The region where the Kubernetes cluster will be deployed."
  type        = string
}

variable "disk_name" {
  description = "The name for the shared disk."
  type        = string
}

variable "disk_volume_handle" {
  description = "The CSI volume handle for the shared disk."
  type        = string
}

variable "disk_serial_number" {
  description = "The serial number for the shared disk."
  type        = string
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
