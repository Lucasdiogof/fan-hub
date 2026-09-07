from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Iterable


def clean_text(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\s+", " ", value).strip()


def norm(value: str | None) -> str:
    value = clean_text(value).lower()
    return "".join(c for c in unicodedata.normalize("NFKD", value) if not unicodedata.combining(c))


def slug(value: str) -> str:
    value = norm(value)
    value = re.sub(r"[^a-z0-9]+", "_", value).strip("_")
    return value or "unknown"


def stable_id(prefix: str, *parts: Any) -> str:
    raw = "|".join("" if p is None else str(p) for p in parts)
    return f"{prefix}_{hashlib.sha1(raw.encode('utf-8')).hexdigest()[:16]}"


def parse_int(value: str | None) -> int | None:
    if value is None:
        return None
    m = re.search(r"-?\d+", value.replace(".", ""))
    return int(m.group()) if m else None


def dump_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


def write_jsonl(path: Path, records: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")


def unique_by(records: Iterable[dict], key: str = "id") -> list[dict]:
    out = {}
    for item in records:
        if item.get(key) is not None:
            out[item[key]] = item
    return list(out.values())
