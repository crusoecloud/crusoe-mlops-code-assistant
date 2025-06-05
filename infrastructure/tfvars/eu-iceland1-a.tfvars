project_id = "af420c34-18e5-400e-8a35-c395e3ec2270"

vpc_network_id   = "fbfcbf4d-1afc-417e-b7ba-c4e30fe688e8"
subnet_id        = "3cc0c2fc-dbab-4292-ab2b-5e272df028dd"
vpc_network_cidr = "172.27.48.0/20"

cluster_name            = "novacode-gpu-cluster"
cluster_location        = "eu-iceland1-a"
cluster_version         = "1.31.7-cmk.4"
nodepool_version        = "1.31.7-cmk.3"
nodepool_name           = "novacode-gpu-pool"
shared_disk_name        = "novacode-shared"
nodepool_instance_type  = "h100-80gb-sxm-ib.8x"
nodepool_instance_count = 1
ib_partition_id         = "63caf40c-d305-4230-969e-b054529595be"
