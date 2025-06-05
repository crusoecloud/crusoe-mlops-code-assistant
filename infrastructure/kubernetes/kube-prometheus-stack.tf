resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "72.9.1"
  values           = [file("${path.module}/helm_values/kube-prometheus-stack.yaml")]
  create_namespace = false
  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_persistent_volume.shared_monitoring,
    kubernetes_persistent_volume_claim.shared_monitoring,
  ]
  wait = false
}
