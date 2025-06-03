resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend-service"
    namespace = "inference"
  }
  spec {
    type = "NodePort"
    selector = {
      app = "frontend"
    }
    port {
      name        = "front"
      port        = 80
      target_port = 80
      node_port   = 30080
      protocol    = "TCP"
    }
  }
  depends_on = [kubernetes_namespace.inference]
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend-deployment"
    namespace = "inference"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      spec {
        container {
          name              = "frontend"
          image             = "${var.docker_registry}/novacode-front:latest"
          image_pull_policy = "Always"
          port {
            container_port = 80
          }
        }
        image_pull_secrets {
          name = "docker-registry"
        }
      }
    }
  }
  depends_on = [
    kubernetes_namespace.inference,
    kubernetes_service.frontend,
    kubernetes_secret.docker-registry,
  ]
}
