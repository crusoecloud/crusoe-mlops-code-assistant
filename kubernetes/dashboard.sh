NS=default        
CTX=nova-cluster

# Single command: forward head pod’s dashboard to localhost:8265
kubectl --context $CTX -n $NS \
  port-forward pod/$(kubectl --context $CTX -n $NS get pod \
    -l ray.io/node-type=head -o jsonpath='{.items[0].metadata.name}') \
  8265:8265 &
