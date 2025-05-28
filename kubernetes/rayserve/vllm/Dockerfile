FROM rayproject/ray-ml:2.33.0.914af0-py311
RUN pip install --no-cache-dir "torch==2.4.0" --index-url https://download.pytorch.org/whl/cu118
RUN pip install --no-cache-dir "huggingface_hub>=0.20.0" "vllm==0.6.1.post2" "transformers==4.50.1" "datasets==3.4.1" "peft==0.15.1" "bitsandbytes==0.45.4" "trl==0.12.0" "accelerate==1.5.2" "hf-xet==1.1.2"