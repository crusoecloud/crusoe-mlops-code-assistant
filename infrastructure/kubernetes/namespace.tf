resource "kubernetes_namespace" "inference" {
  metadata {
    name = "inference"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
