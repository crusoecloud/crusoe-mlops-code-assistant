import os
from dataclasses import dataclass, field
from datetime import datetime
from typing import List

_env = os.getenv


@dataclass
class Config:
    dataset_name: str = _env("DATASET_NAME", "glaiveai/glaive-code-assistant-v3")
    dataset_config: str = _env("DATASET_CONFIG", "")
    model_id: str = _env("MODEL_ID", "meta-llama/Llama-3.2-1B-Instruct")

    lora_target_modules: List[str] = field(
        default_factory=lambda: _env(
            "LORA_TARGET_MODULES",
            "q_proj,k_proj,v_proj,o_proj,gate_proj,up_proj,down_proj,lm_head",
        ).split(",")
    )
    lora_r: int = int(_env("LORA_R", "32"))
    lora_alpha: int = int(_env("LORA_ALPHA", "64"))
    lora_dropout: float = float(_env("LORA_DROPOUT", "0.05"))

    output_dir: str = os.path.join(
        _env("OUTPUT_DIR", "./results"), datetime.now().strftime("%Y%m%d_%H%M%S")
    )
    num_epochs: int = int(_env("NUM_EPOCHS", "2"))
    per_device_train_batch_size: int = int(_env("TRAIN_BATCH_SIZE", "8"))
    gradient_accumulation_steps: int = int(_env("GRAD_ACC_STEPS", "1"))
    learning_rate: float = float(_env("LEARNING_RATE", "2e-4"))
    max_grad_norm: float = float(_env("MAX_GRAD_NORM", "0.3"))
    max_steps: int = int(_env("MAX_STEPS", "300"))
    warmup_ratio: float = float(_env("WARMUP_RATIO", "0.1"))
    save_steps: int = int(_env("SAVE_STEPS", "100"))
    eval_steps: int = int(_env("EVAL_STEPS", "50"))
    logging_steps: int = int(_env("LOGGING_STEPS", "1"))
    optim: str = _env("OPTIM", "adamw_8bit")

    load_in_4bit: bool = _env("LOAD_IN_4BIT", "true").lower() == "true"
    double_quant: bool = _env("DOUBLE_QUANT", "true").lower() == "true"
    quant_type: str = _env("QUANT_TYPE", "nf4")
