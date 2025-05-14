import os, torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig, TrainingArguments
)
from peft import LoraConfig
from trl import SFTTrainer
from config import Config
from processor import Processor

def get_tokenizer(mid: str):
    tok = AutoTokenizer.from_pretrained(mid, padding_side="left", add_eos_token=True, add_bos_token=True)
    tok.pad_token = tok.eos_token
    return tok

def get_model(cfg: Config):
    qq = BitsAndBytesConfig(
        load_in_4bit=cfg.load_in_4bit,
        bnb_4bit_use_double_quant=cfg.double_quant,
        bnb_4bit_quant_type=cfg.quant_type,
        bnb_4bit_compute_dtype=torch.bfloat16,
    )
    return AutoModelForCausalLM.from_pretrained(
        cfg.model_id,
        quantization_config=qq,
        trust_remote_code=True,
        use_cache=False,
        device_map={"": f"cuda:{int(os.getenv('LOCAL_RANK', 0))}"}
    )

def main():
    cfg = Config()
    model = get_model(cfg)
    tok = get_tokenizer(cfg.model_id)

    proc = Processor(tok)
    ds = proc.process_dataset(load_dataset(cfg.dataset_name, cfg.dataset_config, trust_remote_code=True), tokenize=True)

    args = TrainingArguments(
        output_dir=cfg.output_dir, logging_steps=cfg.logging_steps, report_to=None,
        optim=cfg.optim, learning_rate=cfg.learning_rate, max_grad_norm=cfg.max_grad_norm,
        max_steps=cfg.max_steps, num_train_epochs=cfg.num_epochs, warmup_ratio=cfg.warmup_ratio,
        per_device_train_batch_size=cfg.per_device_train_batch_size,
        gradient_accumulation_steps=cfg.gradient_accumulation_steps,
        gradient_checkpointing=True, bf16=True,
        ddp_find_unused_parameters=False, group_by_length=True,
        save_strategy="steps", save_steps=cfg.save_steps,
        evaluation_strategy="steps", eval_steps=cfg.eval_steps, do_eval=True,
    )

    lora = LoraConfig(
        r=cfg.lora_r, lora_alpha=cfg.lora_alpha,
        target_modules=cfg.lora_target_modules, bias="none",
        lora_dropout=cfg.lora_dropout, task_type="CAUSAL_LM"
    )

    SFTTrainer(model=model, train_dataset=ds["train"], eval_dataset=ds["validation"],
               peft_config=lora, args=args).train()

if __name__ == "__main__":
    main()
