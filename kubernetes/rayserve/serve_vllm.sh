NS=default
CTX=nova-cluster

# docker buildx build --platform linux/amd64 -t registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/ray-ml-vllm:0.6.1.post2 kubernetes/rayserve/vllm --push

kubectl --context $CTX -n $NS delete -f kubernetes/rayserve/serve_vllm.yaml --ignore-not-found
kubectl --context $CTX -n $NS apply -f kubernetes/rayserve/serve_vllm.yaml

