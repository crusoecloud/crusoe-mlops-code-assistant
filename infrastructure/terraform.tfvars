
project_id = "af420c34-18e5-400e-8a35-c395e3ec2270" 

vpc_network_id = "fbfcbf4d-1afc-417e-b7ba-c4e30fe688e8"
subnet_id = "cccb1726-72b7-4f87-aee1-d206e519394a"
vpc_network_cidr = "172.27.0.0/16"

cluster_name = "nova-cluster"
cluster_location = "us-east1-a" 
cluster_version = "1.31.7-cmk.4" 
nodepool_version = "1.31.7-cmk.3"
nodepool_name = "nova-pool"
nodepool_instance_type = "h100-80gb-sxm-ib.8x" 
ib_partition_id = "b049a2cf-63b1-4cfd-9e2d-b1541d87b538"

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDc7Q4SEPTdyIlN00l6fKy6AEYUTFbXXRHA8rAEO6gZhlrbDt36B1+3RaNOAdTZJwCdQFyrwnLORivwOXOAaxlO6/AyIRp2oreuUk5sgJWCETc3HIUSuX/es0AI0Gpd/uOKA5Ml7LQhifh0eUXUxstrp+DqXk8FFnE/wTAaF7QusvXPJuU2gcmjcmjWWmSZbt8ACgRAPYvqpuvqZNgN48PEXs3h1LoIIdF9+Fj6CHkXNCyc38rvK9gCkNvSXOsrEYRqbHrj7DprRJKGRHX/lyfhmIW0CQhlochFWJVQKC7IEG8WLGCJahN0NnNh60PRLKa61uH66fFtHmPeeiHn6XzvC1hzK/yqF3Nv8boy7npFil1iJmHKoHkmVcbQRXHRRxTzYb9gbfIghTvB2gQU6t5Ty2vYQH7Nt5aMcKzexwqea+sLzGYcGDR88mC0qxNJMBZSvx9UPublx2iwrdskAN3HjjPhn8oC5bGvwB957/cH2sHx5M8hVHX85zsPKxQPnXwj3p+6Nk//NMt0okzhDfEJsTd1vgOpSliGxcOnHGu96w5rJSjk31PTfUgDvkLwa0P4etFmXUcUurxsRl25iOeLwiXEaMM4lxHEQ/SEDQCslXEU+cFvFhdUgyEuJyrOrX6cAiUw5+/u91DAeqlyD99RBMuPvCiMjn6LIDZQ/Wj3pw== michael@ST60557.home.arpa"

whitelist_ip = [
  { id = "ds1", address = "206.252.255.226/32" }, # ds officed
  { id = "ds2", address = "205.206.125.124/32" }, # michael home
  { id = "ds3", address = "157.25.20.179/32" }, # maciej home
  # { id = "ds", address = "178.43.136.207/32" }, # mateusz home
]