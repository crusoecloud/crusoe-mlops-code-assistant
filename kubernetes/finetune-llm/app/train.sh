#!/usr/bin/env bash
set -euo pipefail

export HF_HOME
export HF_TOKEN

accelerate launch --mixed_precision "${MIXED_PRECISION}" --num-processes 1 main.py
