project_id = "af420c34-18e5-400e-8a35-c395e3ec2270"

vpc_network_id   = "fbfcbf4d-1afc-417e-b7ba-c4e30fe688e8"
subnet_id        = "cccb1726-72b7-4f87-aee1-d206e519394a"
vpc_network_cidr = "172.27.16.0/20"

cluster_name           = "novacode-gpu-cluster"
cluster_location       = "us-east1-a"
cluster_version        = "1.31.7-cmk.4"
nodepool_version       = "1.31.7-cmk.3"
nodepool_name          = "novacode-gpu-pool"
shared_disk_name       = "novacode-shared"
nodepool_instance_type = "a100-80gb-sxm-ib.8x"
ib_partition_id        = "36f543c2-0c3c-4c8d-b717-194b16e43fcd"
