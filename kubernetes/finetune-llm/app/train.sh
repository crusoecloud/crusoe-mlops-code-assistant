#!/usr/bin/env bash
set -euo pipefail

export HF_HOME
export HF_TOKEN

pip install --no-cache-dir "torch==2.4.0" --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir "transformers==4.50.1" "datasets==3.4.1" "peft==0.15.1" "bitsandbytes==0.45.4" "trl==0.12.0" "deepspeed==0.14.4" "accelerate==1.5.2" "hf_xet==1.1.2"


accelerate launch --mixed_precision="${MIXED_PRECISION}" --num_machines=1 --num_processes=2 main.py
