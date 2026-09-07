from __future__ import annotations

import re
from urllib.parse import parse_qs, urlparse

from .parser import classify_stage
from .utils import stable_id

# ---------------------------------------------------------------------------
# Turns the raw text the parser already extracts (`stage_name_raw`,
# `round_name_raw` on matches; `group_name_raw` on standings) into the
# normalized, FK-linked `competition_stages` / `competition_groups` /
# `competition_rounds` entities `schema.sql` expects. This did not exist in
# the original package — matches/standings only carried free text, with no
# way for a UI to ask "what stages does this edition have" or "what belongs
# to Group A" without re-parsing strings itself. Format is still entirely
# edition-driven: nothing here branches on competition name or id.
#
# The key correlation problem: a match's own page (`/partidas/<id>/partida`)
# never carries a `?fase=` marker, so a match can't be tied to a stage by its
# own `source_url` alone. `discovered_on_url` (set in cli.py while crawling
# each edition's phase/round pages) records which listing page first showed
# that match — the SAME page a standings row's `source_url` points to — so
# matches and standings sharing that page land in the same stage bucket even
# when the match's own `stage_name_raw` text is missing or slightly
# different from the group's caption.
# ---------------------------------------------------------------------------


def _fase_param(url: str | None) -> str | None:
    if not url:
        return None
    q = parse_qs(urlparse(url).query)
    vals = q.get("fase")
    return vals[0] if vals else None


def _round_number(name: str | None) -> int | None:
    if not name:
        return None
    m = re.search(r"(\d+)", name)
    return int(m.group(1)) if m else None


def build_structure(editions: list[dict], matches: list[dict], standings: list[dict]):
    """Mutates `matches`/`standings` in place (adds stage_id/group_id/round_id)
    and returns (stages, groups, rounds) ready to dump as JSON."""
    edition_ids = {e["id"] for e in editions}
    stages_by_key: dict[tuple[str, str], dict] = {}
    groups_by_key: dict[tuple[str, str, str], dict] = {}
    rounds_by_key: dict[tuple[str, str, str], dict] = {}

    def get_or_create_stage(edition_id: str, fase_key: str, *, name: str | None, raw_name: str | None, stage_type: str, has_groups: bool, has_standings: bool) -> dict:
        key = (edition_id, fase_key)
        stage = stages_by_key.get(key)
        if stage is None:
            stage = {
                "id": stable_id("stage", edition_id, fase_key),
                "edition_id": edition_id,
                "name": name or "Fase única",
                "raw_name": raw_name,
                "stage_type": stage_type,
                "sort_order": len(stages_by_key),
                "has_groups": has_groups,
                "has_standings": has_standings,
                "extra": {"fase_param": fase_key if fase_key != "main" else None},
            }
            stages_by_key[key] = stage
        else:
            # First writer wins the name (usually the richer, match-derived
            # one); later observations can still upgrade the flags/type.
            if raw_name and not stage["raw_name"]:
                stage["raw_name"] = raw_name
                stage["name"] = name or stage["name"]
            if stage["stage_type"] == "unknown" and stage_type != "unknown":
                stage["stage_type"] = stage_type
            stage["has_groups"] = stage["has_groups"] or has_groups
            stage["has_standings"] = stage["has_standings"] or has_standings
        return stage

    # Pass 1: matches carry the most reliable stage/round free text (straight
    # from each match's own page), so they define the stage's name/type.
    for m in matches:
        eid = m.get("edition_id")
        if eid not in edition_ids:
            continue
        fase = _fase_param(m.get("discovered_on_url"))
        stage_name = m.get("stage_name_raw")
        fase_key = fase or (stage_name or "main")
        stage_type = classify_stage(stage_name) if stage_name else "unknown"
        stage = get_or_create_stage(
            eid, fase_key,
            name=stage_name, raw_name=stage_name, stage_type=stage_type,
            has_groups=False, has_standings=False,
        )
        m["stage_id"] = stage["id"]
        m["group_id"] = None

        round_name = m.get("round_name_raw")
        if round_name:
            rkey = (eid, fase_key, round_name)
            rnd = rounds_by_key.get(rkey)
            if rnd is None:
                rnd = {
                    "id": stable_id("round", eid, fase_key, round_name),
                    "stage_id": stage["id"],
                    "group_id": None,
                    "number": _round_number(round_name),
                    "name": round_name,
                    "sort_order": len(rounds_by_key),
                    "extra": {},
                }
                rounds_by_key[rkey] = rnd
            m["round_id"] = rnd["id"]
        else:
            m["round_id"] = None

    # Pass 2: standings only carry `group_name_raw` (no stage text of their
    # own) — key them by the `?fase=` on their OWN source_url, which is the
    # same listing page a match discovered there points back to via
    # `discovered_on_url`. Editions with no `fase` param at all (most single-
    # phase competitions) collapse onto the single "main" stage already
    # created (or created here) instead of spawning a redundant one per row.
    for s in standings:
        eid = s.get("edition_id")
        if eid not in edition_ids:
            continue
        fase = _fase_param(s.get("source_url"))
        group_name = s.get("group_name_raw")
        fase_key = fase or "main"
        stage = get_or_create_stage(
            eid, fase_key,
            name=None, raw_name=None,
            stage_type="group_stage" if group_name else "unknown",
            has_groups=bool(group_name), has_standings=True,
        )
        s["stage_id"] = stage["id"]

        if group_name:
            gkey = (eid, fase_key, group_name)
            group = groups_by_key.get(gkey)
            if group is None:
                group = {
                    "id": stable_id("group", eid, fase_key, group_name),
                    "stage_id": stage["id"],
                    "name": group_name,
                    "sort_order": len(groups_by_key),
                    "extra": {},
                }
                groups_by_key[gkey] = group
            s["group_id"] = group["id"]
        else:
            s["group_id"] = None

    return list(stages_by_key.values()), list(groups_by_key.values()), list(rounds_by_key.values())
