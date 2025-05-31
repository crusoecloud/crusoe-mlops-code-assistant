from datetime import datetime
import json
import re
import os

from datasets import load_dataset, Dataset, DatasetDict
from peft import LoraConfig, PeftModel
import torch
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    TrainingArguments,
)
from trl import SFTTrainer


class Config:
    """Configuration class for model training parameters and settings."""

    dataset_name = "glaiveai/glaive-code-assistant-v3"
    # dataset_name = "Salesforce/dialogstudio"
    # dataset_config = "TweetSummarization"
    
    os.environ["HF_HOME"] = "/mnt/novacode-model-artifacts/hf-cache"

    model_id = "meta-llama/Llama-3.1-8B"
    lora_target_modules = [
        "q_proj",
        "k_proj",
        "v_proj",
        "o_proj",
        "gate_proj",
        "up_proj",
        "down_proj",
        "lm_head",
    ]

    # Dataset size control
    max_samples = 1000  # Maximum number of samples to use
    min_samples = 100   # Minimum number of samples to use
    validation_split = 0.1  # Validation set size ratio

    model_storage = "/mnt/novacode-model-artifacts/finetuning-llama"
    output_dir = f"{model_storage}/results/{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    training_args = {
        "per_device_train_batch_size": 2,
        "gradient_accumulation_steps": 3,
        "optim": "adamw_8bit",
        "save_steps": 10,
        "logging_steps": 1,
        "learning_rate": 2e-4,
        "max_grad_norm": 0.3,
        "max_steps": 50,
        "warmup_ratio": 0.1,
        "lr_scheduler_type": "cosine",
    }


class Processor:
    """Processes conversation data into training format."""

    DEFAULT_SYSTEM_PROMPT = (
        "You are an AI coding assistant that helps users with their programming tasks. "
        "You provide clear, concise, and well-documented code solutions. "
        "When appropriate, include brief explanations of key concepts and implementation details."
    )

    def __init__(
        self,
        tokenizer: AutoTokenizer,
        system_prompt: str = DEFAULT_SYSTEM_PROMPT,
        seed: int = 42,
        max_samples: int = None,
        min_samples: int = None,
    ):
        """Initialize the conversation processor.
        Args:
            tokenizer: Tokenizer for text processing
            system_prompt: Instruction prompt for the model
            seed: Random seed for reproducibility
            max_samples: Maximum number of samples to use
            min_samples: Minimum number of samples to use
        """
        self.system_prompt = system_prompt
        self.seed = seed
        self.tokenizer = tokenizer
        self.max_samples = max_samples
        self.min_samples = min_samples

    @staticmethod
    def clean_text(text: str) -> str:
        """Clean text by removing unwanted patterns.
        Args:
            text: Input text to clean
        Returns:
            Cleaned text with extra whitespace removed
        """
        return re.sub(r"\s+", " ", text).strip()

    def format_conversation(self, messages: list) -> str:
        """Format conversation messages into a single string.
        Args:
            messages: List of conversation messages
        Returns:
            Formatted conversation string
        """
        formatted = []
        for msg in messages:
            role = msg.get("role", "").lower()
            content = msg.get("content", "").strip()
            if role and content:
                formatted.append(f"{role.capitalize()}: {content}")
        return "\n".join(formatted)

    def generate_prompt(self, conversation: list) -> str:
        """Generate training prompt from conversation.
        Args:
            conversation: List of conversation messages
        Returns:
            Complete training prompt
        """
        formatted_conv = self.format_conversation(conversation)
        return (
            f"### System: {self.system_prompt}\n\n"
            f"### Human: {formatted_conv}\n\n"
            f"### Assistant:"
        )

    def process_sample(self, sample: dict) -> dict:
        """Process a single dataset sample.
        Args:
            sample: Input sample containing conversation
        Returns:
            Processed sample with formatted text
        """
        conversation = sample.get("messages", [])
        text = self.generate_prompt(conversation)
        return {"text": text}

    def sample_dataset(self, dataset: Dataset) -> Dataset:
        """Sample a subset of the dataset.
        Args:
            dataset: Input dataset to sample from
        Returns:
            Sampled dataset
        """
        total_samples = len(dataset)
        
        # Determine sample size
        if self.max_samples and total_samples > self.max_samples:
            sample_size = self.max_samples
        elif self.min_samples and total_samples < self.min_samples:
            raise ValueError(f"Dataset too small. Got {total_samples} samples, minimum required is {self.min_samples}")
        else:
            sample_size = total_samples
            
        print(f"Using {sample_size} samples out of {total_samples} total samples")
        
        # Sample the dataset
        return dataset.shuffle(seed=self.seed).select(range(sample_size))

    def process_dataset(
        self, dataset: Dataset | DatasetDict, tokenize: bool = False
    ) -> Dataset | DatasetDict:
        """Process dataset with optional tokenization.
        Args:
            dataset: Input dataset to process
            tokenize: Whether to tokenize the text
        Returns:
            Processed dataset
        """
        def _process(data: Dataset) -> Dataset:
            # Sample the dataset first
            data = self.sample_dataset(data)
            
            # Process the samples
            data = data.map(self.process_sample)
            
            if tokenize and self.tokenizer:
                data = data.map(
                    lambda x: self.tokenizer(
                        x["text"],
                        truncation=True,
                        max_length=2048,
                        padding="max_length"
                    )
                )
            return data

        if isinstance(dataset, DatasetDict):
            return DatasetDict({k: _process(v) for k, v in dataset.items()})
        return _process(dataset)
    

def initialize_tokenizer(model_id: str) -> AutoTokenizer:
    """
    Initialize and configure a tokenizer for the specified model.
    Args:
        model_id: The identifier of the pretrained model to load.
    Returns:
        The configured tokenizer with padding side set to left,
        EOS and BOS tokens added, and pad token set to EOS token.
    """
    tokenizer = AutoTokenizer.from_pretrained(
        model_id,
        padding_side="left",
        add_eos_token=True,
        add_bos_token=True,
    )
    tokenizer.pad_token = tokenizer.eos_token
    return tokenizer


def initialize_model(model_id: str) -> AutoModelForCausalLM:
    """
    Initialize a quantized causal language model with the specified configuration.
    Args:
        model_id: The identifier of the pretrained model to load.
    Returns:
        The quantized model configured with 4-bit quantization,
        loaded onto the appropriate CUDA device.
    """
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
    )

    return AutoModelForCausalLM.from_pretrained(
        model_id,
        quantization_config=bnb_config,
        trust_remote_code=True,
        use_cache=False,
        device_map={"": "cuda:" + str(int(os.environ.get("LOCAL_RANK") or 0))},
    )


def main() -> None:
    """
    Main function to execute the model training pipeline.
    """
    config = Config()

    model = initialize_model(config.model_id)
    tokenizer = initialize_tokenizer(config.model_id)

    processor = Processor(
        tokenizer=tokenizer,
        max_samples=config.max_samples,
        min_samples=config.min_samples
    )
    
    dataset = load_dataset(
        config.dataset_name,
        split="train",
        trust_remote_code=True
    )
    
    # Split dataset into train and validation
    dataset = dataset.train_test_split(
        test_size=config.validation_split,
        seed=42
    )
    processed_dataset = processor.process_dataset(dataset, tokenize=True)

    training_args = TrainingArguments(
        # Output and logging
        output_dir=config.output_dir,
        logging_steps=config.training_args["logging_steps"],
        report_to=None,
        # Optimization and training dynamics
        optim=config.training_args["optim"],
        learning_rate=config.training_args["learning_rate"],
        max_grad_norm=config.training_args["max_grad_norm"],
        num_train_epochs=2,
        warmup_ratio=config.training_args["warmup_ratio"],
        warmup_steps=2,
        # Batch and gradient settings
        per_device_train_batch_size=config.training_args["per_device_train_batch_size"],
        gradient_accumulation_steps=config.training_args["gradient_accumulation_steps"],
        gradient_checkpointing=True,
        bf16=True,
        # Distributed training
        ddp_find_unused_parameters=False,
        group_by_length=True,
        # Checkpointing and evaluation
        save_strategy="steps",
        save_steps=100,
        evaluation_strategy="steps",
        eval_steps=50,
        do_eval=True,
    )

    peft_config = LoraConfig(
        r=32,
        lora_alpha=32,
        target_modules=config.lora_target_modules,
        bias="none",
        lora_dropout=0.05,
        task_type="CAUSAL_LM",
    )

    trainer = SFTTrainer(
        model=model,
        train_dataset=processed_dataset["train"],
        eval_dataset=processed_dataset["test"],
        peft_config=peft_config,
        tokenizer=tokenizer,
        args=training_args,
        max_seq_length=2048,
        packing=False,
    )

    trainer.train()

    trainer.save_model(config.output_dir)
    tokenizer.save_pretrained(config.output_dir)
    model.config.to_json_file(f"{config.output_dir}/config.json")
    peft_config.save_pretrained(f"{config.output_dir}")

    # https://github.com/vllm-project/vllm/issues/997
    #Free memory for merging weights
    del model
    del trainer
    torch.cuda.empty_cache()

    # https://github.com/vllm-project/vllm/issues/997
    # Merge Model with Adapter
    model = AutoModelForCausalLM.from_pretrained(
        config.model_id,
        device_map="auto",
        trust_remote_code=True,
        torch_dtype=torch.bfloat16
    )
    model.config.use_cache = False
    model = PeftModel.from_pretrained(
        model, # The base model with full precision
        config.output_dir, # Path to the finetuned adapter
    )

    model = model.merge_and_unload()
    model.save_pretrained(os.path.join(config.output_dir, "final_merged"), safe_serialization=False)


if __name__ == "__main__":
    main()
