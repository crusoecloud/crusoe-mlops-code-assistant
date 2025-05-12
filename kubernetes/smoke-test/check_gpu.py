import ray, torch, sys

ray.init()                             # connects to cluster via RAY_ADDRESS env
@ray.remote(num_gpus=1)
def gpu_ok():
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA missing")
    x = torch.randn(1024, 1024, device="cuda")
    return (x @ x).sum().item()

try:
    ray.get(gpu_ok.remote())
except Exception:
    sys.exit(1)                       # fail cluster CI
print("GPU OK")
