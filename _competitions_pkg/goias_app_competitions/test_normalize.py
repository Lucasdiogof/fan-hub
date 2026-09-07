import json
from pathlib import Path

from collector.http import HttpClient
from collector.parser import parse_match_page, parse_standings_tables
from collector.normalize import build_structure

client = HttpClient("https://www.futeboldegoyaz.com.br", Path(".cache"), delay=0.45)

editions = [
    {"id": "goiano_2023_990", "competition_id": "campeonato_goiano", "source_edition_id": 990},
    {"id": "sula_2026_1628", "competition_id": "sul_americana", "source_edition_id": 1628},
]

matches = []
for url in [
    "https://www.futeboldegoyaz.com.br/partidas/85423/partida",
    "https://www.futeboldegoyaz.com.br/partidas/85424/partida",
]:
    html, final_url = client.get(url)
    m = parse_match_page(html, final_url, edition_id="goiano_2023_990")
    m["discovered_on_url"] = "https://www.futeboldegoyaz.com.br/campeonatos/990/edicao"
    matches.append(m)

group_html, group_final = client.get("https://futeboldegoyaz.com.br/campeonatos/1628/edicao?fase=4445")
standings = parse_standings_tables(group_html, {"id": "sula_2026_1628"}, group_final)

stages, groups, rounds = build_structure(editions, matches, standings)

Path("normalize_test.json").write_text(
    json.dumps(
        {
            "stages": stages,
            "groups": groups[:4],
            "rounds": rounds,
            "matches_with_ids": [
                {k: m.get(k) for k in ("id", "stage_id", "round_id", "stage_name_raw", "round_name_raw")}
                for m in matches
            ],
            "standings_with_ids": [
                {k: s.get(k) for k in ("id", "stage_id", "group_id", "group_name_raw", "team_name_raw")}
                for s in standings[:4]
            ],
        },
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)
print("ok")
