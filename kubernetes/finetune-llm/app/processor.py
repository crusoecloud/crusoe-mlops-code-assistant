import json, re
from datasets import Dataset, DatasetDict
from transformers import AutoTokenizer

class Processor:
    DEFAULT_SYSTEM_PROMPT = (
        "Summarize this conversation between a human and AI assistant, "
        "capturing key points and maintaining context."
    )
    REMOVE = [
        "original dialog id","new dialog id","dialog index",
        "original dialog info","log","prompt","conversation","summary"
    ]

    def __init__(self, tokenizer: AutoTokenizer, prompt: str | None = None, seed: int = 42):
        self.tokenizer = tokenizer
        self.prompt = prompt or self.DEFAULT_SYSTEM_PROMPT
        self.seed = seed

    @staticmethod
    def _clean(t: str) -> str:
        t = re.sub(r"http\S+|@[^\s]+|\^[^ ]+", "", t)
        return re.sub(r"\s+", " ", t).strip()

    def _format_conv(self, log: list[dict]) -> str:
        return "\n".join(
            f"user: {self._clean(turn['user utterance'])}\n"
            f"agent: {self._clean(turn['system response'])}"
            for turn in log
        )

    @staticmethod
    def _summary(info: str) -> str:
        abstractive = json.loads(info).get("summaries", {}).get("abstractive_summaries", [])
        return " ".join(abstractive[0]) if abstractive else ""

    def _prompt(self, conv: str, summ: str | None) -> str:
        resp = f"### Response:\n{summ}" if summ else "### Response:\n"
        return f"### Instruction: {self.prompt}\n\n### Input:\n{conv}\n\n{resp}"

    def _row(self, sample: dict) -> dict:
        conv = self._format_conv(sample.get("log", []))
        summ = self._summary(sample["original dialog info"])
        return {"text": self._prompt(conv, summ.strip() or None)}

    def process_dataset(self, ds: Dataset | DatasetDict, tokenize: bool = False):
        def run(d):
            d = d.shuffle(seed=self.seed).map(self._row).remove_columns(self.REMOVE)
            return d.map(lambda x: self.tokenizer(x["text"])) if tokenize else d
        return DatasetDict({k: run(v) for k, v in ds.items()}) if isinstance(ds, DatasetDict) else run(ds)
