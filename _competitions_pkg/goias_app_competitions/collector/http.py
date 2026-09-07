from __future__ import annotations

import hashlib
import json
import random
import time
from pathlib import Path
from urllib.parse import urljoin

import requests


class HttpClient:
    def __init__(self, base_url: str, cache_dir: Path, delay: float = 0.45, timeout: int = 30):
        self.base_url = base_url.rstrip("/")
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.delay = max(0.0, delay)
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "goias-app-competition-archive/0.1 (+data import; respectful rate limit)",
            "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.7",
        })
        self._last_request = 0.0

    def absolute(self, url: str) -> str:
        return urljoin(self.base_url + "/", url)

    def _cache_path(self, url: str) -> Path:
        digest = hashlib.sha256(url.encode("utf-8")).hexdigest()
        return self.cache_dir / f"{digest}.json"

    def get(self, url: str, use_cache: bool = True) -> tuple[str, str]:
        url = self.absolute(url)
        cp = self._cache_path(url)
        if use_cache and cp.exists():
            payload = json.loads(cp.read_text(encoding="utf-8"))
            return payload["text"], payload["final_url"]

        elapsed = time.monotonic() - self._last_request
        wait = self.delay - elapsed
        if wait > 0:
            time.sleep(wait + random.uniform(0, min(0.12, self.delay / 3 if self.delay else 0)))

        last_error = None
        for attempt in range(5):
            try:
                response = self.session.get(url, timeout=self.timeout)
                self._last_request = time.monotonic()
                if response.status_code in (429, 500, 502, 503, 504):
                    raise requests.HTTPError(f"HTTP {response.status_code}")
                response.raise_for_status()
                # The provider correctly declares `charset=utf-8` in both the
                # Content-Type header and the page's <meta charset>, and
                # `requests` already honors the header when setting
                # `response.encoding`. Overriding it with `apparent_encoding`
                # (a chardet/charset-normalizer *guess*) was mangling every
                # accented character ("Série" -> "S�rie") because the guesser
                # misreads this content on short/ambiguous samples. Only
                # fall back to the guess when the server gave no encoding at
                # all.
                if not response.encoding:
                    response.encoding = response.apparent_encoding
                payload = {
                    "requested_url": url,
                    "final_url": response.url,
                    "status": response.status_code,
                    "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "text": response.text,
                }
                cp.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
                return response.text, response.url
            except Exception as exc:
                last_error = exc
                time.sleep(min(8.0, 0.8 * (2 ** attempt)))
        raise RuntimeError(f"Failed to fetch {url}: {last_error}")
