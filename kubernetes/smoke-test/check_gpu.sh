NS=default
CTX=nova-cluster

# forward Ray Job API (port 10001) from the head svc
kubectl --context $CTX -n $NS port-forward svc/ray-cluster-kuberay-head-svc 8265:8265 &
PID=$!


uv pip install 'ray[default]'
# submit job
RAY_ADDRESS=http://localhost:8265 uv run ray job submit --working-dir ./smoke-test -- python check_gpu.py


kill $PID