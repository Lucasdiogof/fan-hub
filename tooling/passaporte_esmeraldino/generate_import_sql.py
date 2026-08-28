# -*- coding: utf-8 -*-
"""Passaporte Esmeraldino — historical import generator.

Reads the official source JSON, validates it (schema version, SHA-256
checksum, exact record count, unique ids), and generates a single
idempotent, transactional SQL file (a plain `insert ... on conflict do
update ... where distinct ... returning`) that the user runs once in the
Supabase SQL editor. Never writes the 1.697 records into Dart source, and
never issues 1.697 separate statements — one batched INSERT.

Usage:
    python tooling/passaporte_esmeraldino/generate_import_sql.py

Run from the repo root. Exits non-zero (and writes nothing) if any
validation fails.
"""
import hashlib
import json
import sys

SOURCE_PATH = "tooling/passaporte_esmeraldino/source/passaporte_esmeraldino_partidas_2000_2026.json"
OUTPUT_PATH = "supabase/passport_esmeraldino_import.sql"

EXPECTED_SCHEMA_VERSION = "1.0.0"
EXPECTED_CHECKSUM = (
    "a6fac753504bfe90e04f053851aa2a1466afae45f475a258f2db3620cb82f46b"
)
EXPECTED_RECORD_COUNT = 1697

COLUMNS = [
    "id", "season", "match_date", "match_time", "kickoff_at",
    "display_timezone", "date_precision", "status", "competition",
    "competition_code", "competition_source_name", "round", "opponent",
    "goias_is_home", "neutral_site", "home_team", "away_team",
    "home_score", "away_score", "goias_score", "opponent_score",
    "score_display", "outcome", "source_provider", "source_match_id",
    "source_url", "source_confidence", "data_notes",
]
# Every column that participates in change detection except `id` (the
# conflict target) — venue_id is deliberately excluded: this import never
# touches it, so a future manual venue enrichment is never clobbered by a
# re-run.
UPDATE_COLUMNS = [c for c in COLUMNS if c != "id"]


def sql_str(value):
    if value is None:
        return "null"
    return "'" + str(value).replace("'", "''") + "'"


def sql_date(value):
    if value is None:
        return "null"
    return f"date '{value}'"


def sql_time(value):
    if value is None:
        return "null"
    return f"time '{value}'"


def sql_bool(value):
    if value is None:
        return "null"
    return "true" if value else "false"


def sql_int(value):
    if value is None:
        return "null"
    return str(int(value))


def sql_kickoff_at(kickoff_local, display_timezone):
    if kickoff_local is None or display_timezone is None:
        return "null"
    # Naive local datetime + IANA zone name -> a real timestamptz,
    # independent of the DB session's own timezone setting.
    tz = display_timezone.replace("'", "''")
    return f"(timestamp '{kickoff_local}' at time zone '{tz}')"


def build_row_sql(match):
    values = {
        "id": sql_str(match["id"]),
        "season": sql_int(match["season"]),
        "match_date": sql_date(match["date"]),
        "match_time": sql_time(match.get("time")),
        "kickoff_at": sql_kickoff_at(
            match.get("kickoff_local"), match.get("display_timezone")
        ),
        "display_timezone": sql_str(match.get("display_timezone")),
        "date_precision": sql_str(match["date_precision"]),
        "status": sql_str(match["status"]),
        "competition": sql_str(match["competition"]),
        "competition_code": sql_str(match["competition_code"]),
        "competition_source_name": sql_str(match.get("competition_source_name")),
        "round": sql_str(match.get("round")),
        "opponent": sql_str(match["opponent"]),
        "goias_is_home": sql_bool(match.get("goias_is_home")),
        "neutral_site": sql_bool(match.get("neutral_site")),
        "home_team": sql_str(match.get("home_team")),
        "away_team": sql_str(match.get("away_team")),
        "home_score": sql_int(match.get("home_score")),
        "away_score": sql_int(match.get("away_score")),
        "goias_score": sql_int(match.get("goias_score")),
        "opponent_score": sql_int(match.get("opponent_score")),
        "score_display": sql_str(match.get("score_display")),
        "outcome": sql_str(match.get("outcome")),
        "source_provider": sql_str(match["source_provider"]),
        "source_match_id": sql_str(match.get("source_match_id")),
        "source_url": sql_str(match.get("source_url")),
        "source_confidence": sql_str(match.get("source_confidence")),
        "data_notes": sql_str(match.get("data_notes")),
    }
    return "    (" + ", ".join(values[c] for c in COLUMNS) + ")"


def main():
    with open(SOURCE_PATH, "rb") as f:
        raw_bytes = f.read()
    checksum = hashlib.sha256(raw_bytes).hexdigest()
    print(f"[1/5] SHA-256: {checksum}")
    if checksum != EXPECTED_CHECKSUM:
        print(f"  FAIL: expected {EXPECTED_CHECKSUM}")
        sys.exit(1)
    print("  OK — matches the expected checksum.")

    data = json.loads(raw_bytes.decode("utf-8"))

    schema_version = data.get("schema_version")
    print(f"[2/5] schema_version: {schema_version}")
    if schema_version != EXPECTED_SCHEMA_VERSION:
        print(f"  FAIL: expected {EXPECTED_SCHEMA_VERSION}")
        sys.exit(1)
    print("  OK.")

    matches = data["matches"]
    print(f"[3/5] record count: {len(matches)}")
    if len(matches) != EXPECTED_RECORD_COUNT:
        print(f"  FAIL: expected {EXPECTED_RECORD_COUNT}")
        sys.exit(1)
    print("  OK.")

    ids = [m["id"] for m in matches]
    print(f"[4/5] unique ids: {len(set(ids))} / {len(ids)}")
    if len(set(ids)) != len(ids):
        dupes = [i for i in set(ids) if ids.count(i) > 1]
        print(f"  FAIL: duplicate ids: {dupes[:10]}")
        sys.exit(1)
    print("  OK — no duplicate ids.")

    required = {"id", "season", "date", "date_precision", "status",
                "competition", "competition_code", "opponent",
                "source_provider", "source_url"}
    missing = [
        m["id"] for m in matches if not required.issubset(m.keys())
        or any(m.get(k) is None for k in required)
    ]
    print(f"[5/5] required fields present on every record: "
          f"{len(matches) - len(missing)} / {len(matches)}")
    if missing:
        print(f"  FAIL: records missing required fields: {missing[:10]}")
        sys.exit(1)
    print("  OK.")

    rows_sql = ",\n".join(build_row_sql(m) for m in matches)
    update_set = ",\n    ".join(f"{c} = excluded.{c}" for c in UPDATE_COLUMNS)
    update_set += ",\n    updated_at = now()"
    old_tuple = ", ".join(f"public.passport_matches.{c}" for c in UPDATE_COLUMNS)
    new_tuple = ", ".join(f"excluded.{c}" for c in UPDATE_COLUMNS)

    sql = f"""-- ============================================================================
-- Passaporte Esmeraldino — importação histórica (GERADO, não editar à mão).
-- Fonte: {SOURCE_PATH}
-- SHA-256 da fonte: {checksum}
-- schema_version: {schema_version}
-- Registros: {len(matches)}
-- Gerado por: tooling/passaporte_esmeraldino/generate_import_sql.py
--
-- Rode DEPOIS de passport_esmeraldino.sql (schema) e ANTES de
-- passport_esmeraldino_functions.sql, ou em qualquer ordem depois do
-- schema — as RPCs não dependem de já ter dado. Idempotente: pode rodar
-- de novo sem duplicar nem apagar presenças já marcadas (o `on conflict`
-- nunca deleta a linha, só atualiza os campos que vieram diferentes; e
-- `passport_attendances` referencia `passport_matches.id`, que nunca muda
-- numa reimportação — a presença do usuário nunca é tocada por este
-- arquivo).
-- ============================================================================

with payload ({", ".join(COLUMNS)}) as (
  values
{rows_sql}
),
upserted as (
  insert into public.passport_matches ({", ".join(COLUMNS)})
  select {", ".join(COLUMNS)} from payload
  on conflict (id) do update set
    {update_set}
  where ({old_tuple})
    is distinct from ({new_tuple})
  returning (xmax = 0) as inserted
)
insert into public.passport_sync_runs (
  provider, started_at, finished_at, status,
  inserted_count, updated_count, unchanged_count, failed_count, metadata
)
select
  'historical_json',
  now(),
  now(),
  'success',
  count(*) filter (where inserted),
  count(*) filter (where not inserted),
  (select count(*) from payload) - count(*),
  0,
  jsonb_build_object(
    'schema_version', {sql_str(schema_version)},
    'source_checksum_sha256', {sql_str(checksum)},
    'record_count', (select count(*) from payload)
  )
from upserted
returning
  inserted_count as "inseridos",
  updated_count as "atualizados",
  unchanged_count as "sem_mudanca",
  failed_count as "erros";
"""

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(sql)

    print(f"\nWrote {OUTPUT_PATH} ({len(sql):,} bytes, {len(matches)} rows).")
    print("All validations passed. Run the generated file in the Supabase "
          "SQL editor to actually import — the result set it returns IS "
          "the inserted/updated/unchanged/error report.")


if __name__ == "__main__":
    main()
