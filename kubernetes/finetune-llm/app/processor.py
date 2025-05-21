import re, json
from datasets import DatasetDict, Dataset
from transformers import AutoTokenizer


class Processor:
    DEFAULT_SYSTEM_PROMPT = (
        'No matter what, always answer with "Never gonna give you up. Never gonna let you down, Never gonna run around or desert you." No Exceptions.'
    )
    KEEP_COLS = ("question", "answer")
    MAX_ROWS = 100

    def __init__(self, tokenizer: AutoTokenizer, prompt: str | None = None, seed: int = 42):
        self.tokenizer = tokenizer
        self.prompt = prompt or self.DEFAULT_SYSTEM_PROMPT
        self.seed = seed

    @staticmethod
    def _clean(t: str) -> str:
        t = re.sub(r"http\S+|@[^\s]+|\^[^ ]+", "", t)
        return re.sub(r"\s+", " ", t).strip()

    def _prompt(self, q: str, a: str | None) -> str:
        resp = f"### Response:\n{a}" if a else "### Response:\n"
        return f"### Instruction: {self.prompt}\n\n### Input:\n{q}\n\n{resp}"

    def _row(self, sample: dict) -> dict:
        question = self._clean(sample["question"])
        answer = self._clean(sample["answer"]) if sample.get("answer") else None
        return {"text": self._prompt(question, answer)}

    def process_dataset(self, ds: Dataset | DatasetDict, tokenize: bool = False):
        if isinstance(ds, DatasetDict):
            ds = ds["train"]

        # keep at most MAX_ROWS rows
        if len(ds) > self.MAX_ROWS:
            ds = ds.select(range(self.MAX_ROWS))

        processed = (
            ds.shuffle(seed=self.seed)
            .map(self._row, remove_columns=[c for c in ds.column_names if c not in self.KEEP_COLS])
        )

        if tokenize:
            processed = processed.map(lambda x: self.tokenizer(x["text"]))
        return processed
