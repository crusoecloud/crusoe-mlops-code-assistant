resource "kubernetes_service" "llama" {
  metadata {
    name      = "vllm-llama"
    namespace = "inference"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "vllm-llama"
    }
    port {
      name        = "http"
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }
  }
  depends_on = [kubernetes_namespace.inference]
}

resource "kubernetes_deployment" "llama" {
  metadata {
    name      = "vllm-llama"
    namespace = "inference"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "vllm-llama"
      }
    }
    template {
      metadata {
        labels = {
          app = "vllm-llama"
        }
      }
      spec {
        node_selector = {
          "beta.kubernetes.io/instance-type" = var.gpu_instance_type
        }
        container {
          name  = "vllm"
          image = "vllm/vllm-openai:v0.9.0"
          port {
            container_port = 8000
          }
          env {
            name = "HUGGING_FACE_HUB_TOKEN"
            value_from {
              secret_key_ref {
                name = "hf-secret"
                key  = "HF_TOKEN"
              }
            }
          }
          env {
            name  = "HF_HOME"
            value = "/novacode-shared/hf-cache"
          }
          args = [
            "--model=meta-llama/Llama-3.3-70B-Instruct",
            "--host=0.0.0.0",
            "--port=8000",
            "--tensor-parallel-size=4"
          ]
          resources {
            limits = {
              cpu              = "16"
              memory           = "32Gi"
              "nvidia.com/gpu" = "4"
            }
            requests = {
              cpu              = "16"
              memory           = "32Gi"
              "nvidia.com/gpu" = "4"
            }
          }
          volume_mount {
            name       = "novacode-shared"
            mount_path = "/novacode-shared"
          }
          volume_mount {
            name       = "dshm"
            mount_path = "/dev/shm"
          }
        }
        volume {
          name = "novacode-shared"
          persistent_volume_claim {
            claim_name = "novacode-shared-pvc"
          }
        }
        volume {
          name = "dshm"
          empty_dir {
            medium = "Memory"
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_namespace.inference,
    kubernetes_service.llama,
    kubernetes_secret.hf_secret,
    kubernetes_persistent_volume.shared_inference,
    kubernetes_persistent_volume_claim.shared_inference,
  ]
  wait_for_rollout = false
}
