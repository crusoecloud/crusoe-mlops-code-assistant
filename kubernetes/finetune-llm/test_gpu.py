from ray.job_submission import JobSubmissionClient
import time

def main():
    # Create the GPU test script content
    test_script = """
import torch
import sys
import gc

def get_gpu_memory_info():
    memory_info = []
    gpus_found = torch.cuda.device_count()
    print(f"Number of GPUs found: {gpus_found}")
    for i in range(gpus_found):
        allocated = torch.cuda.memory_allocated(i) / 1024**3
        reserved = torch.cuda.memory_reserved(i) / 1024**3
        total = torch.cuda.get_device_properties(i).total_memory / 1024**3
        free = total - allocated
        memory_info.append({
            "gpu_id": i,
            "allocated_gb": allocated,
            "reserved_gb": reserved,
            "free_gb": free,
            "total_gb": total
        })
    return memory_info

def print_memory_info(memory_info, prefix=""):
    print(f"\\n{prefix} GPU Memory Status:")
    for info in memory_info:
        print(info)

# Clear GPU memory
torch.cuda.empty_cache()
gc.collect()

# Get initial memory state
initial_memory = get_gpu_memory_info()
print_memory_info(initial_memory, "Initial")

if not torch.cuda.is_available():
    print("CUDA is not available")
    sys.exit(1)

# Get GPU information
gpu_count = torch.cuda.device_count()
gpu_info = []

for i in range(gpu_count):
    gpu_name = torch.cuda.get_device_name(i)
    gpu_memory = torch.cuda.get_device_properties(i).total_memory / 1024**3
    gpu_info.append(f"GPU {i}: {gpu_name} ({gpu_memory:.1f}GB)")

# Test GPU computation with smaller matrices
try:
    matrix_size = 1000
    x = torch.randn(matrix_size, matrix_size, device="cuda")
    y = torch.randn(matrix_size, matrix_size, device="cuda")
    
    pre_compute_memory = get_gpu_memory_info()
    print_memory_info(pre_compute_memory, "Pre-computation")
    
    z = torch.matmul(x, y)
    
    post_compute_memory = get_gpu_memory_info()
    print_memory_info(post_compute_memory, "Post-computation")
    
    del x, y, z
    torch.cuda.empty_cache()
    gc.collect()
    
    final_memory = get_gpu_memory_info()
    print_memory_info(final_memory, "Final")
    
    computation_test = "Matrix multiplication test passed"
except Exception as e:
    computation_test = f"Matrix multiplication test failed: {str(e)}"

print("\\n=== GPU Test Results ===")
print(f"Number of GPUs found: {gpu_count}")
print("\\nGPU Information:")
for info in gpu_info:
    print(f"- {info}")
print(f"\\nComputation Test: {computation_test}")
print("======================\\n")

if "failed" in computation_test.lower():
    sys.exit(1)
"""

    # Initialize the Ray Job Submission client
    client = JobSubmissionClient("http://204.52.26.113:30865")

    # Submit the job
    job_id = client.submit_job(
        submission_id="test-gpu-utilization",
        entrypoint=f"python -c '{test_script}'",
        runtime_env={
            "pip": ["torch"],
        }
    )

    print(f"Submitted job with ID: {job_id}")

    # Wait for the job to complete and show logs
    while True:
        status = client.get_job_status(job_id)
        if status.is_terminal():
            break
        time.sleep(1)

    # Get and print the logs
    logs = client.get_job_logs(job_id)
    print("\nJob Logs:")
    print(logs)

if __name__ == "__main__":
    main() 