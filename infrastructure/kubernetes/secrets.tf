locals {
  docker_secret_template = {
    auths = {
      (split("/", var.docker_registry)[0]) = {
        username = var.docker_username
        password = var.docker_password
        email    = var.docker_email
        auth     = base64encode("${var.docker_username}:${var.docker_password}")
      }
    }
  }
}

resource "kubernetes_secret" "hf_secret" {
  metadata {
    name      = "hf-secret"
    namespace = "inference"
  }
  data = {
    HF_TOKEN = var.hf_token
  }
  type       = "Opaque"
  depends_on = [kubernetes_namespace.inference]
}

resource "kubernetes_secret" "docker-registry" {
  metadata {
    name      = "docker-registry"
    namespace = "inference"
  }
  data = {
    ".dockerconfigjson" = jsonencode(local.docker_secret_template)
  }
  type       = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.inference]
}
