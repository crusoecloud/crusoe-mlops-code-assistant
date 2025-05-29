from datetime import datetime
import json
import re
import os

from datasets import load_dataset, Dataset, DatasetDict
from peft import LoraConfig
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

    output_dir = f"./results/{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    training_args = {
        "per_device_train_batch_size": 2,
        "gradient_accumulation_steps": 3,
        "optim": "adamw_8bit",
        "save_steps": 10,
        "logging_steps": 1,
        "learning_rate": 2e-4,
        "max_grad_norm": 0.3,
        "max_steps": 300,
        "warmup_ratio": 0.1,
        "lr_scheduler_type": "cosine",
    }


class Processor:
    """Processes conversation data into training format."""

    DEFAULT_SYSTEM_PROMPT = (
        "You are an AI coding assistent that outputs ONLY code with no explanations, introductions, or outros."
        "You will respond with pure, working code that directly solves the user's request."
        "Your output should contain nothing but the code itself - no markdown formatting, no text descriptions, no explanations of what the code does."
        "Before generating any code, first determine if the request is actually asking for code generation."
        "If the request is about:\n- Personal questions (like 'How are you?', 'What's your name?')\n"
        "- General knowledge or facts\n- Opinions or advice unrelated to programming\n- Writing essays, stories, or non-code content"
        "\n- Harmful, unethical, or illegal activities\n\nThen respond with exactly one comment: '# I can only provide programming code."
        " I can't assist with [specific request type]. However, I'd be happy to help you with any coding problems you might have.'\n\nHere"
        " are examples that show how you should response:\nRequest: \"Write a function to check if a number is prime\"\nResponse:\ndef is_prime(n):\n    "
        "if n < 2: return False\n    for i in range(2, int(n ** 0.5) + 1):\n        if n % i == 0: return False\n    return True\n\nRequest: \"How was"
        " your day?\"\nResponse:\n# I can only provide programming code. I can't assist with personal conversations. However, I'd be happy"
        " to help you with any coding problems you might have."


    def __init__(
        self,
        tokenizer: AutoTokenizer,
        system_prompt: str = DEFAULT_SYSTEM_PROMPT,
        seed: int = 42,
    ):
        """Initialize the conversation processor.
        Args:
            tokenizer: Tokenizer for text processing
            system_prompt: Instruction prompt for summarization
            seed: Random seed for reproducibility
        """
        self.system_prompt = system_prompt
        self.seed = seed
        self.tokenizer = tokenizer

    @staticmethod
    def clean_text(text: str) -> str:
        """Clean text by removing unwanted patterns.
        Args:
            text: Input text to clean
        Returns:
            Cleaned text with URLs, mentions, and extra whitespace removed
        """
        text = re.sub(r"http\S+|@[^\s]+|\^[^ ]+", "", text)
        return re.sub(r"\s+", " ", text).strip()

    def format_conversation(self, log: list[dict]) -> str:
        """Format conversation log into structured text.
        Args:
            log: List of conversation turns
        Returns:
            Formatted conversation string
        """
        return "\n".join(
            f"user: {self.clean_text(turn['user utterance'])}\n"
            f"agent: {self.clean_text(turn['system response'])}"
            for turn in log
        )

    @staticmethod
    def extract_summary(original_info: str) -> str:
        """Extract summary from original dialog info.
        Args:
            original_info: JSON string containing original dialog info
        Returns:
            Extracted summary text
        """
        summaries = json.loads(original_info).get("summaries", {})
        abstractive = summaries.get("abstractive_summaries", [])
        return " ".join(abstractive[0]) if abstractive else ""

    def generate_prompt(self, conversation: str, summary: str | None = None) -> str:
        """Generate training prompt with optional summary.
        Args:
            conversation: Formatted conversation text
            summary: Optional summary text
        Returns:
            Complete training prompt
        """
        response_part = f"### Response:\n{summary}" if summary else "### Response:\n"
        return (
            f"### Instruction: {self.system_prompt}\n\n"
            f"### Input:\n{conversation}\n\n"
            f"{response_part}"
        )

    def process_sample(self, sample: dict) -> dict[str, str]:
        """Process single sample into training format.
        Args:
            sample: Input data sample
        Returns:
            Processed sample with conversation, summary and formatted text
        """
        conversation = self.format_conversation(sample.get("log", []))
        summary = self.extract_summary(sample["original dialog info"])
        return {
            "conversation": conversation,
            "summary": summary,
            "text": self.generate_prompt(
                conversation, summary if summary.strip() else None
            ),
        }

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
            data = (
                data.shuffle(seed=self.seed)
                .map(self.process_sample)
                .remove_columns(self.COLUMNS_TO_REMOVE)
            )
            if tokenize and self.tokenizer:
                data = data.map(lambda x: self.tokenizer(x["text"]))
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

    processor = Processor(tokenizer=tokenizer)
    dataset = load_dataset(
        config.dataset_name, trust_remote_code=True
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
        lora_alpha=64,
        target_modules=config.lora_target_modules,
        bias="none",
        lora_dropout=0.05,
        task_type="CAUSAL_LM",
    )

    trainer = SFTTrainer(
        model=model,
        train_dataset=processed_dataset["train"],
        eval_dataset=processed_dataset["validation"],
        peft_config=peft_config,
        args=training_args,
    )
    trainer.train()


if __name__ == "__main__":
    main()
