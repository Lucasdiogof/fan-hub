from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from urllib.parse import urljoin

from .http import HttpClient
from .parser import (
    discover_editions, discover_edition_navigation, discover_match_ids,
    parse_final_classification, parse_match_page, parse_regulation,
    parse_scorers, parse_standings_tables, parse_statistics,
)
from .normalize import build_structure
from .utils import dump_json, unique_by, write_jsonl
from .validate import load_jsonl, run_validation

TAB_QUERY = {
    "statistics": "aba=es",
    "scorers": "aba=at",
    "final_standings": "aba=cf",
    "regulation": "aba=rg",
    "extra_standings": "aba=ce",
    "other_editions": "aba=ed",
}


def load_scope(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def edition_source_pages(client: HttpClient, ed: dict, max_pages: int = 1000):
    """Breadth-first crawl of phase/round/group selectors for one edition."""
    queue = [ed["source_url"]]
    seen = set()
    while queue and len(seen) < max_pages:
        url = queue.pop(0)
        if url in seen:
            continue
        seen.add(url)
        html, final_url = client.get(url)
        yield html, final_url
        for nxt in discover_edition_navigation(html, client.base_url, final_url, ed["source_edition_id"]):
            if nxt not in seen and nxt not in queue:
                queue.append(nxt)


def _rebuild_structure_from_output(out: Path) -> None:
    editions_path = out / "editions.json"
    if not editions_path.exists():
        return
    editions = json.loads(editions_path.read_text(encoding="utf-8"))
    matches = load_jsonl(out / "matches.jsonl")
    standings = load_jsonl(out / "standings.jsonl")
    stages, groups, rounds = build_structure(editions, matches, standings)
    dump_json(out / "stages.json", stages)
    dump_json(out / "groups.json", groups)
    dump_json(out / "rounds.json", rounds)
    write_jsonl(out / "matches.jsonl", matches)
    write_jsonl(out / "standings.jsonl", standings)


def main():
    ap = argparse.ArgumentParser(description="Collect competition history from Futebol de Goyaz into normalized JSON/JSONL.")
    ap.add_argument("--scope", default="config/scope.json")
    ap.add_argument("--output", default="output")
    ap.add_argument("--cache", default=".cache")
    ap.add_argument("--delay", type=float, default=0.45)
    ap.add_argument("--only", help="Comma-separated competition keys")
    ap.add_argument("--skip-match-details", action="store_true")
    ap.add_argument("--validate-only", action="store_true")
    args = ap.parse_args()

    out = Path(args.output)
    out.mkdir(parents=True, exist_ok=True)
    if args.validate_only:
        # Rebuild stage/group/round from whatever matches/standings are
        # already on disk first — a pure in-memory transform, so this is
        # always safe/cheap to redo without touching the network, and keeps
        # `--validate-only` a true "recompute from what's on disk" entry
        # point rather than only refreshing the validation report.
        _rebuild_structure_from_output(out)
        print(json.dumps(run_validation(out)["summary"], ensure_ascii=False, indent=2))
        return

    scope = load_scope(Path(args.scope))
    client = HttpClient(scope["source_base_url"], Path(args.cache), delay=args.delay)
    only = set(args.only.split(",")) if args.only else None

    competitions, editions = [], []
    standings, scorers, final_ranks, matches = [], [], [], []
    stats, regulations, sources = [], [], []

    for comp in scope["competitions"]:
        if not comp.get("enabled", True) or (only and comp["key"] not in only):
            continue
        c = dict(comp)
        c["id"] = c.pop("key")
        if c.get("source_competition_id"):
            c["source_url"] = f"{client.base_url}/campeonatos/{c['source_competition_id']}/campeonato"
            html, final_url = client.get(c["source_url"])
        elif c.get("source_seed_edition_id"):
            c["source_url"] = f"{client.base_url}/campeonatos/{c['source_seed_edition_id']}/edicao?aba=ed"
            html, final_url = client.get(c["source_url"])
        else:
            raise ValueError(f"Competition {c['id']} has no source pointer")
        competitions.append(c)
        discovered = discover_editions(html, client.base_url, c["id"], c["name"])
        # Some championship pages may not expose all edition pointers in the initial view; use the seed edition's Other editions tab as fallback.
        if (not discovered or len(discovered) <= 1) and c.get("source_seed_edition_id"):
            seed_url = f"{client.base_url}/campeonatos/{c['source_seed_edition_id']}/edicao?aba=ed"
            seed_html, _ = client.get(seed_url)
            alt = discover_editions(seed_html, client.base_url, c["id"], c["name"])
            by_source = {x["source_edition_id"]: x for x in discovered}
            by_source.update({x["source_edition_id"]: x for x in alt})
            discovered = list(by_source.values())

        # Hydrate year from each edition title when a clickable row did not expose the year itself.
        for item in discovered:
            if item.get("season") is None:
                try:
                    eh, _ = client.get(item["source_url"])
                    from .parser import soup as _soup, title_text as _title_text, year_from_text as _year_from_text
                    yr = _year_from_text(_title_text(_soup(eh)))
                    if yr:
                        item["season"] = yr
                        item["id"] = f"{c['id']}_{yr}_{item['source_edition_id']}"
                        item["name"] = f"{c['name']} {yr}"
                except Exception:
                    pass
        discovered = sorted(discovered, key=lambda x: (x.get("season") or 9999, x["source_edition_id"]))
        print(f"[{c['id']}] {len(discovered)} editions discovered")

        for ed in discovered:
            editions.append(ed)
            sources.append({"id": f"source_edition_{ed['source_edition_id']}", "entity_type":"edition", "entity_id":ed["id"], "url":ed["source_url"], "provider":"Futebol de Goyaz"})
            match_refs = {}
            match_discovered_on = {}
            # Crawl table/phase/round pages and collect all match IDs + standings that are present.
            # `match_discovered_on` remembers which phase/round page first listed each match —
            # matches themselves never carry a `?fase=` marker (their own page is `/partidas/...`),
            # so this is the only way to later correlate a match with the same stage bucket a
            # standings row from that same page lands in (see collector/normalize.py).
            for page_html, page_url in edition_source_pages(client, ed):
                for mr in discover_match_ids(page_html, client.base_url):
                    match_refs[mr["source_match_id"]] = mr
                    match_discovered_on.setdefault(mr["source_match_id"], page_url)
                standings.extend(parse_standings_tables(page_html, ed, page_url))

            for tab, query in TAB_QUERY.items():
                tab_url = ed["source_url"] + "?" + query
                try:
                    tab_html, tab_final = client.get(tab_url)
                except Exception as exc:
                    sources.append({"id": f"source_{ed['id']}_{tab}", "entity_type":"edition_tab", "entity_id":ed["id"], "url":tab_url, "provider":"Futebol de Goyaz", "error":str(exc)})
                    continue
                sources.append({"id": f"source_{ed['id']}_{tab}", "entity_type":"edition_tab", "entity_id":ed["id"], "url":tab_final, "provider":"Futebol de Goyaz"})
                if tab == "statistics":
                    stats.append(parse_statistics(tab_html, ed, tab_final))
                elif tab == "scorers":
                    scorers.extend(parse_scorers(tab_html, ed, tab_final))
                elif tab == "final_standings":
                    final_ranks.extend(parse_final_classification(tab_html, ed, tab_final))
                elif tab == "extra_standings":
                    standings.extend(parse_standings_tables(tab_html, ed, tab_final))
                elif tab == "regulation":
                    regulations.append(parse_regulation(tab_html, ed, tab_final))

            if not args.skip_match_details:
                for mi, mr in enumerate(match_refs.values(), start=1):
                    try:
                        mh, mu = client.get(mr["source_url"])
                        parsed = parse_match_page(mh, mu, ed["id"])
                        parsed["discovered_on_url"] = match_discovered_on.get(mr["source_match_id"])
                        matches.append(parsed)
                    except Exception as exc:
                        matches.append({
                            "id": f"fdg_match_{mr['source_match_id']}", "source_match_id": mr["source_match_id"],
                            "edition_id": ed["id"], "source_url": mr["source_url"], "status":"collection_error", "collection_error": str(exc),
                            "discovered_on_url": match_discovered_on.get(mr["source_match_id"]),
                        })
            else:
                for mr in match_refs.values():
                    matches.append({
                        "id":f"fdg_match_{mr['source_match_id']}", **mr, "edition_id":ed["id"], "status":"detail_not_collected",
                        "discovered_on_url": match_discovered_on.get(mr["source_match_id"]),
                    })

            # Flush after every edition to make interruption/resume auditing easier.
            dump_json(out / "competitions.json", unique_by(competitions))
            dump_json(out / "editions.json", unique_by(editions))
            dump_json(out / "edition_statistics.json", unique_by(stats))
            dump_json(out / "regulations.json", unique_by(regulations))
            dump_json(out / "final_classification.json", unique_by(final_ranks))
            dump_json(out / "sources.json", unique_by(sources))
            write_jsonl(out / "matches.jsonl", unique_by(matches))
            write_jsonl(out / "standings.jsonl", unique_by(standings))
            write_jsonl(out / "scorers.jsonl", unique_by(scorers))

    # Runs once over the FULL accumulated lists rather than on every
    # per-edition flush above — it's a pure in-memory transform (no network),
    # so rerunning it from the raw matches/standings already on disk is
    # always cheap; recomputing it after every single edition during a
    # multi-thousand-edition run would turn an O(n) pass into an O(n^2) one
    # for no benefit (the derived stage/group/round tables aren't needed
    # until the whole collection — or a resumed one — is being audited).
    matches = unique_by(matches)
    standings = unique_by(standings)
    stages, groups, rounds = build_structure(editions, matches, standings)
    dump_json(out / "stages.json", stages)
    dump_json(out / "groups.json", groups)
    dump_json(out / "rounds.json", rounds)
    write_jsonl(out / "matches.jsonl", matches)
    write_jsonl(out / "standings.jsonl", standings)

    manifest = {
        "schema_version": "1.0.0",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "source": scope["source_base_url"],
        "competition_count": len(unique_by(competitions)),
        "edition_count": len(unique_by(editions)),
        "files": ["competitions.json","editions.json","stages.json","groups.json","rounds.json","edition_statistics.json","regulations.json","final_classification.json","sources.json","matches.jsonl","standings.jsonl","scorers.jsonl","validation_report.json"],
        "notes": [
            "Missing source values remain null; the collector does not guess historical data.",
            "Current seasons may be incomplete by design and should not be treated as collection failures.",
            "Competition format is edition/stage-driven, never hardcoded globally by competition."
        ]
    }
    dump_json(out / "manifest.json", manifest)
    report = run_validation(out)
    print(json.dumps(report["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
