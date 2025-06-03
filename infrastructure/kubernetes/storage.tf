resource "kubernetes_persistent_volume" "shared_inference" {
  metadata {
    name = "novacode-shared-pv-inference"
  }
  spec {
    capacity = {
      storage = "1Ti"
    }
    access_modes                     = ["ReadWriteMany"]
    storage_class_name               = "crusoe-csi-driver-ssd-sc"
    persistent_volume_reclaim_policy = "Retain"
    volume_mode                      = "Filesystem"
    persistent_volume_source {
      csi {
        driver        = "fs.csi.crusoe.ai"
        read_only     = false
        volume_handle = var.disk_volume_handle
        volume_attributes = {
          "csi.crusoe.ai/disk-name"     = var.disk_name
          "csi.crusoe.ai/serial-number" = var.disk_serial_number
        }
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.kubernetes.io/region"
            operator = "In"
            values   = [var.region]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume" "shared_monitoring" {
  metadata {
    name = "novacode-shared-pv-monitoring"
  }
  spec {
    capacity = {
      storage = "1Ti"
    }
    access_modes                     = ["ReadWriteMany"]
    storage_class_name               = "crusoe-csi-driver-ssd-sc"
    persistent_volume_reclaim_policy = "Retain"
    volume_mode                      = "Filesystem"
    persistent_volume_source {
      csi {
        driver        = "fs.csi.crusoe.ai"
        read_only     = false
        volume_handle = var.disk_volume_handle
        volume_attributes = {
          "csi.crusoe.ai/disk-name"     = var.disk_name
          "csi.crusoe.ai/serial-number" = var.disk_serial_number
        }
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.kubernetes.io/region"
            operator = "In"
            values   = [var.region]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "shared_inference" {
  metadata {
    name      = "novacode-shared-pvc"
    namespace = "inference"
  }
  spec {
    storage_class_name = "crusoe-csi-driver-ssd-sc"
    volume_name        = kubernetes_persistent_volume.shared_inference.metadata[0].name
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Ti"
      }
    }
  }
  depends_on = [kubernetes_namespace.inference]
}

resource "kubernetes_persistent_volume_claim" "shared_monitoring" {
  metadata {
    name      = "novacode-shared-pvc"
    namespace = "monitoring"
  }
  spec {
    storage_class_name = "crusoe-csi-driver-ssd-sc"
    volume_name        = kubernetes_persistent_volume.shared_monitoring.metadata[0].name
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Ti"
      }
    }
  }
  depends_on = [kubernetes_namespace.inference]
}
