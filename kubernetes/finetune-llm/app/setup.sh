#!/usr/bin/env bash
set -euo pipefail

# -------- load variables ----------------------------------------------
if [[ -f .env ]]; then source .env; else source .env.example; fi

# -------- base packages -----------------------------------------------
sudo apt-get update
sudo apt-get install -y python3-dev python3-pip

# -------- python deps --------------------------------------------------
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
