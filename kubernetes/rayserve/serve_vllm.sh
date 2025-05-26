NS=default
CTX=nova-cluster

# docker buildx build --platform linux/amd64 -t registry.gitlab.com/deepsense.ai/g-crusoe/crusoe-novacode/ray-ml-vllm:0.6.1.post2 kubernetes/rayserve/vllm --push

echo "Check on what port is grafana running"
kubectl get svc prometheus-grafana -n prometheus-system -o jsonpath='{.spec.ports[0].nodePort}'
echo "Make sure to update the port in the serve_vllm.yaml file"

kubectl --context $CTX -n $NS delete -f kubernetes/rayserve/serve_vllm.yaml --ignore-not-found
kubectl --context $CTX -n $NS apply -f kubernetes/rayserve/serve_vllm.yaml

