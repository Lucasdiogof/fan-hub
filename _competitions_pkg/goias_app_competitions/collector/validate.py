from __future__ import annotations

from collections import Counter, defaultdict
from pathlib import Path
import json

from .utils import dump_json


def load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def run_validation(output_dir: Path) -> dict:
    editions = json.loads((output_dir / "editions.json").read_text(encoding="utf-8")) if (output_dir / "editions.json").exists() else []
    matches = load_jsonl(output_dir / "matches.jsonl")
    standings = load_jsonl(output_dir / "standings.jsonl")
    scorers = load_jsonl(output_dir / "scorers.jsonl")
    stats = json.loads((output_dir / "edition_statistics.json").read_text(encoding="utf-8")) if (output_dir / "edition_statistics.json").exists() else []

    report = {"summary": {}, "editions": [], "errors": [], "warnings": []}
    ids = [m.get("id") for m in matches]
    dupes = [k for k, v in Counter(ids).items() if k and v > 1]
    if dupes:
        report["errors"].append({"type": "duplicate_match_ids", "count": len(dupes), "examples": dupes[:20]})

    matches_by_edition = defaultdict(list)
    for m in matches:
        matches_by_edition[m.get("edition_id")].append(m)
    standings_by_edition = defaultdict(list)
    for r in standings:
        standings_by_edition[r.get("edition_id")].append(r)
    scorers_by_edition = defaultdict(list)
    for r in scorers:
        scorers_by_edition[r.get("edition_id")].append(r)
    stats_by_edition = {x.get("edition_id"): x for x in stats}

    for ed in editions:
        eid = ed["id"]
        em = matches_by_edition[eid]
        es = stats_by_edition.get(eid, {})
        issues = []
        played = [m for m in em if m.get("status") == "played"]
        if es.get("matches") is not None and played and es["matches"] != len(played):
            issues.append({"severity":"warning","type":"match_count_mismatch","statistics_page":es["matches"],"collected_played":len(played)})
        scored_goals = sum((m.get("score",{}).get("home") or 0) + (m.get("score",{}).get("away") or 0) for m in played)
        if es.get("goals") is not None and played and es["goals"] != scored_goals:
            issues.append({"severity":"warning","type":"goal_total_mismatch","statistics_page":es["goals"],"collected":scored_goals})
        for m in em:
            if m.get("status") in ("detail_not_collected", "collection_error"):
                # `--skip-match-details` runs never fetch the match page, so
                # these are reference-only stubs by design, not a parsing
                # failure — flagging them as "missing_team" would drown the
                # real signal under a warning on every single match.
                continue
            sc = m.get("score") or {}
            ph, pa = sc.get("penalties_home"), sc.get("penalties_away")
            if (ph is None) != (pa is None):
                issues.append({"severity":"error","type":"half_penalty_score","match_id":m.get("id")})
            if not m.get("home_team_name_raw") or not m.get("away_team_name_raw"):
                issues.append({"severity":"warning","type":"missing_team","match_id":m.get("id")})
        report["editions"].append({
            "edition_id": eid, "season": ed.get("season"),
            "matches_collected": len(em), "played_matches": len(played),
            "standings_rows": len(standings_by_edition[eid]),
            "scorer_rows": len(scorers_by_edition[eid]),
            "issues": issues,
            "status": "error" if any(x["severity"] == "error" for x in issues) else "approved_with_warnings" if issues else "approved"
        })
    report["summary"] = {
        "editions": len(editions), "matches": len(matches), "standings_rows": len(standings), "scorer_rows": len(scorers),
        "edition_errors": sum(1 for x in report["editions"] if x["status"] == "error"),
        "edition_warnings": sum(1 for x in report["editions"] if x["status"] == "approved_with_warnings"),
    }
    dump_json(output_dir / "validation_report.json", report)
    return report
