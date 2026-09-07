import json
import sys
from pathlib import Path

from collector.http import HttpClient
from collector.parser import parse_match_page

urls = [
    "https://www.futeboldegoyaz.com.br/partidas/178/partida",  # 1971 Brasileirao
]
if len(sys.argv) > 1:
    urls = sys.argv[1:]

client = HttpClient("https://www.futeboldegoyaz.com.br", Path(".cache"), delay=0.45)
results = []
for u in urls:
    html, final_url = client.get(u)
    parsed = parse_match_page(html, final_url)
    results.append(parsed)

Path("match_parse_test.json").write_text(
    json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
)
print("wrote", len(results), "to match_parse_test.json")
