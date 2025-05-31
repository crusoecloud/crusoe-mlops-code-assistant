resource "crusoe_storage_disk" "shared_disk" {
  project_id = var.project_id
  name       = var.shared_disk_name
  size       = "1TiB"
  type       = "shared-volume"
  location   = var.cluster_location
}

output "model_disk_id" {
  value = crusoe_storage_disk.shared_disk.id
}

output "model_disk_serial_number" {
  value = crusoe_storage_disk.shared_disk.serial_number
}
