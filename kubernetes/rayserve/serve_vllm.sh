NS=default
CTX=nova-cluster

docker build -t registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/ray-ml-vllm:0.6.1.post2 vllm
docker push registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/ray-ml-vllm:0.6.1.post2


kubectl --context $CTX -n $NS apply -f serve_vllm.yaml

