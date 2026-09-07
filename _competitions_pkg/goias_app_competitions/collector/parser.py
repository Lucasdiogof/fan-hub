from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from urllib.parse import parse_qs, urlencode, urljoin, urlparse, urlunparse

from bs4 import BeautifulSoup
from dateutil import parser as dtparser

from .utils import clean_text, norm, parse_int, slug, stable_id

EDITION_RE = re.compile(r"/campeonatos/(\d+)/edicao")
COMPETITION_RE = re.compile(r"/campeonatos/(\d+)/campeonato")
MATCH_RE = re.compile(r"/partidas/(\d+)/partida")
TEAM_RE = re.compile(r"/clubes/(\d+)/clube")
PLAYER_RE = re.compile(r"/jogadores/(\d+)/jogador")
STADIUM_RE = re.compile(r"/estadios/(\d+)/estadio")
COACH_RE = re.compile(r"/(?:treinadores|tecnicos)/(\d+)/")


def soup(html: str) -> BeautifulSoup:
    return BeautifulSoup(html, "lxml")


def title_text(doc: BeautifulSoup) -> str:
    h = doc.find(["h1", "h2"])
    return clean_text(h.get_text(" ", strip=True) if h else doc.title.get_text(" ", strip=True) if doc.title else "")


def year_from_text(text: str) -> int | None:
    years = re.findall(r"\b(18\d{2}|19\d{2}|20\d{2})\b", text)
    return int(years[-1]) if years else None


def discover_competition_links(html: str, base_url: str) -> list[dict]:
    doc = soup(html)
    found = {}
    for a in doc.find_all("a", href=True):
        m = COMPETITION_RE.search(a["href"])
        if not m:
            continue
        cid = int(m.group(1))
        name = clean_text(a.get_text(" ", strip=True))
        if name:
            found[cid] = {"source_competition_id": cid, "name": name, "source_url": urljoin(base_url, a["href"])}
    return list(found.values())


def discover_editions(html: str, base_url: str, competition_key: str, competition_name: str) -> list[dict]:
    """Find edition URLs in normal links *or* JS/data attributes used by clickable table rows."""
    doc = soup(html)
    candidates: dict[int, tuple[str, str]] = {}

    def add_candidate(raw_url: str, context: str):
        m = EDITION_RE.search(raw_url)
        if not m:
            return
        eid = int(m.group(1))
        path_m = re.search(r"(/campeonatos/\d+/edicao[^\"'\s)]*)", raw_url)
        href = path_m.group(1) if path_m else f"/campeonatos/{eid}/edicao"
        candidates[eid] = (urljoin(base_url, href), context)

    for a in doc.find_all("a", href=True):
        context = clean_text(" ".join([a.get_text(" ", strip=True), a.parent.get_text(" ", strip=True) if a.parent else ""]))
        add_candidate(a["href"], context)

    # The provider uses clickable rows in some edition-history tables. Scan every attribute so
    # data-url, onclick, href-like JS, etc. are still discovered without relying on CSS classes.
    for tag in doc.find_all(True):
        context = clean_text(tag.get_text(" ", strip=True))
        for value in tag.attrs.values():
            vals = value if isinstance(value, list) else [value]
            for val in vals:
                if isinstance(val, str) and "/campeonatos/" in val and "/edicao" in val:
                    add_candidate(val, context)

    found = []
    for eid, (url, context) in candidates.items():
        yr = year_from_text(context)
        found.append({
            "id": f"{competition_key}_{yr or 'unknown'}_{eid}",
            "competition_id": competition_key,
            "source_edition_id": eid,
            "season": yr,
            "name": f"{competition_name} {yr}" if yr else competition_name,
            "source_url": urljoin(base_url, f"/campeonatos/{eid}/edicao"),
            "status": "unknown",
            "is_complete": None,
        })
    return sorted(found, key=lambda x: (x["season"] or 9999, x["source_edition_id"]))


def _same_edition_url(url: str, edition_id: int) -> bool:
    return bool(re.search(fr"/campeonatos/{edition_id}/edicao(?:\?|$)", url))


def discover_edition_navigation(html: str, base_url: str, current_url: str, edition_id: int) -> list[str]:
    """Discover phase/round/group URLs from anchors and selects without assuming a fixed regulation."""
    doc = soup(html)
    urls = set()
    allowed_keys = {"fase", "rodada", "grupo", "chave", "turno"}

    for a in doc.find_all("a", href=True):
        u = urljoin(base_url, a["href"])
        if not _same_edition_url(u, edition_id):
            continue
        q = parse_qs(urlparse(u).query)
        if any(k in q for k in allowed_keys):
            q.pop("aba", None)
            p = urlparse(u)
            urls.add(urlunparse((p.scheme, p.netloc, p.path, "", urlencode(q, doseq=True), "")))

    current = urlparse(current_url)
    base_q = parse_qs(current.query)
    base_q.pop("aba", None)
    for select in doc.find_all("select"):
        name = (select.get("name") or select.get("id") or "").strip()
        if not name:
            continue
        name_n = norm(name).replace(" ", "_")
        mapped = next((k for k in allowed_keys if k in name_n), None)
        if not mapped:
            continue
        for option in select.find_all("option"):
            val = clean_text(option.get("value"))
            if not val or val in {"0", "-1"}:
                continue
            if "/campeonatos/" in val or val.startswith("http"):
                u = urljoin(base_url, val)
                if _same_edition_url(u, edition_id):
                    urls.add(u)
            elif re.fullmatch(r"\d+", val):
                q = dict(base_q)
                q[mapped] = [val]
                urls.add(urlunparse((current.scheme or urlparse(base_url).scheme,
                                     current.netloc or urlparse(base_url).netloc,
                                     current.path, "", urlencode(q, doseq=True), "")))
    return sorted(urls)


def discover_match_ids(html: str, base_url: str) -> list[dict]:
    doc = soup(html)
    found = {}
    for a in doc.find_all("a", href=True):
        m = MATCH_RE.search(a["href"])
        if m:
            mid = int(m.group(1))
            found[mid] = {"source_match_id": mid, "source_url": urljoin(base_url, a["href"])}
    return list(found.values())


def extract_stage_names(html: str) -> list[str]:
    doc = soup(html)
    names = []
    banned = {"tabela", "estatisticas", "artilharia", "regulamento", "classificacao final", "classificacoes extras", "outras edicoes"}
    for h in doc.find_all(["h3", "h4"]):
        t = clean_text(h.get_text(" ", strip=True))
        n = norm(t)
        if t and n not in banned and not re.search(r"\b\d+[ªº]? rodada\b", t.lower()):
            if any(k in n for k in ("fase", "final", "quartas", "oitavas", "semifinal", "grupo", "playoff", "turno")):
                names.append(t)
    return list(dict.fromkeys(names))


def classify_stage(name: str) -> str:
    n = norm(name)
    if "grupo" in n:
        return "group_stage"
    if any(x in n for x in ("oitavas", "quartas", "semifinal")):
        return "knockout"
    if n == "final" or n.endswith(" final"):
        return "final"
    if "preliminar" in n or "classificatoria" in n or "seletiva" in n:
        return "qualifying"
    if "playoff" in n or "repescagem" in n:
        return "playoff"
    if "fase" in n or "turno" in n:
        return "league_or_stage"
    return "unknown"


def parse_standings_tables(html: str, edition: dict, source_url: str) -> list[dict]:
    doc = soup(html)
    out = []
    required = {"p", "j", "v", "e", "d"}
    for ti, table in enumerate(doc.find_all("table")):
        rows = table.find_all("tr")
        if not rows:
            continue
        header_cells_raw = [clean_text(x.get_text(" ", strip=True)) for x in rows[0].find_all(["th", "td"])]
        headers = [norm(x).replace("%", "pct") for x in header_cells_raw]
        header_set = set(headers)
        if not required.issubset(header_set):
            continue
        # On group-stage editions, the provider reuses the header row's
        # first cell (normally blank/"Pos") to name the group itself
        # ("Grupo A", "Grupo B"...) instead of adding a separate heading
        # element above the table — so the group name lives right here,
        # not in some earlier sibling tag.
        group_name = next((h for h in header_cells_raw if re.match(r"^grupo\b", norm(h))), None)
        for ri, tr in enumerate(rows[1:], start=1):
            cells = [clean_text(x.get_text(" ", strip=True)) for x in tr.find_all(["th", "td"])]
            if len(cells) < 6:
                continue
            links = tr.find_all("a", href=True)
            team_link = next((a for a in links if TEAM_RE.search(a["href"])), None)
            # `cells[0]` is always the position column (also parsed separately
            # below) — on tables with no team link, it renders as an ordinal
            # like "1º"/"2º", which doesn't fullmatch the plain-numeric regex
            # and was wrongly picked up as the "team name" fallback. Skip it.
            team_name = (
                clean_text(team_link.get_text(" ", strip=True))
                if team_link
                else next(
                    (c for c in cells[1:] if c and not re.fullmatch(r"[-+]?\d+(?:[,.]\d+)?%?", c)),
                    "",
                )
            )
            if not team_name:
                continue
            team_source_id = int(TEAM_RE.search(team_link["href"]).group(1)) if team_link and TEAM_RE.search(team_link["href"]) else None
            mapping = {}
            for i, h in enumerate(headers):
                if i < len(cells):
                    mapping[h] = cells[i]
            position = parse_int(cells[0])
            out.append({
                "id": stable_id("standing", edition["id"], source_url, ti, team_source_id or team_name),
                "edition_id": edition["id"],
                "stage_name_raw": None,
                "group_name_raw": group_name,
                "position": position,
                "team_source_id": team_source_id,
                "team_name_raw": team_name,
                "points": parse_int(mapping.get("p")),
                "played": parse_int(mapping.get("j")),
                "wins": parse_int(mapping.get("v")),
                "draws": parse_int(mapping.get("e")),
                "losses": parse_int(mapping.get("d")),
                "goals_for": parse_int(mapping.get("gp")),
                "goals_against": parse_int(mapping.get("gc")),
                "goal_difference": parse_int(mapping.get("s")),
                "percentage": parse_int(mapping.get("pct")),
                "source_url": source_url,
            })
    return out


def parse_scorers(html: str, edition: dict, source_url: str) -> list[dict]:
    doc = soup(html)
    out = []
    for ti, table in enumerate(doc.find_all("table")):
        rows = table.find_all("tr")
        if not rows:
            continue
        header_text = norm(rows[0].get_text(" ", strip=True))
        if not any(k in header_text for k in ("gol", "artilheiro")):
            continue
        for rank, tr in enumerate(rows[1:], start=1):
            cells = [clean_text(x.get_text(" ", strip=True)) for x in tr.find_all(["th", "td"])]
            if len(cells) < 2:
                continue
            goals = None
            for c in reversed(cells):
                if re.fullmatch(r"\d+", c):
                    goals = int(c)
                    break
            if goals is None:
                continue
            player_link = next((a for a in tr.find_all("a", href=True) if PLAYER_RE.search(a["href"])), None)
            team_link = next((a for a in tr.find_all("a", href=True) if TEAM_RE.search(a["href"])), None)
            player_name = clean_text(player_link.get_text(" ", strip=True)) if player_link else cells[0]
            if not player_name:
                continue
            out.append({
                "id": stable_id("scorer", edition["id"], player_name, team_link["href"] if team_link else "", goals),
                "edition_id": edition["id"],
                "rank": rank,
                "player_source_id": int(PLAYER_RE.search(player_link["href"]).group(1)) if player_link else None,
                "player_name_raw": player_name,
                "team_source_id": int(TEAM_RE.search(team_link["href"]).group(1)) if team_link else None,
                "team_name_raw": clean_text(team_link.get_text(" ", strip=True)) if team_link else None,
                "goals": goals,
                "source_url": source_url,
            })
    # Fallback for pages rendered as list/cards rather than table. The provider currently
    # renders examples such as: rank -> player -> club -> goals, without a semantic table.
    if not out:
        text = doc.get_text("\n", strip=True)
        lines = [clean_text(x) for x in text.splitlines() if clean_text(x)]
        ignored = {"tabela", "classificacoes extras", "estatisticas", "artilharia", "classificacao final", "regulamento", "outras edicoes", "masculino"}
        for i, line in enumerate(lines):
            if not re.fullmatch(r"\d{1,3}", line):
                continue
            rank = int(line)
            if rank < 1 or rank > 200:
                continue
            following = []
            for candidate in lines[i + 1:i + 8]:
                nc = norm(candidate)
                if nc in ignored or nc.startswith("campeonato ") or nc.startswith("copa ") and re.search(r"\b20\d{2}\b", nc):
                    continue
                following.append(candidate)
            # Find a trailing small integer as goals, with at least player + club before it.
            goal_idx = next((j for j, c in enumerate(following[2:], start=2) if re.fullmatch(r"\d{1,3}", c)), None)
            if goal_idx is None:
                continue
            player_name = following[0]
            team_name = following[1] if goal_idx >= 2 else None
            goals = int(following[goal_idx])
            if not player_name or goals > 100:
                continue
            team_link = next((a for a in doc.find_all("a", href=True)
                              if TEAM_RE.search(a["href"]) and norm(a.get_text(" ", strip=True)) == norm(team_name)), None)
            player_link = next((a for a in doc.find_all("a", href=True)
                                if PLAYER_RE.search(a["href"]) and norm(a.get_text(" ", strip=True)) == norm(player_name)), None)
            rec = {
                "id": stable_id("scorer", edition["id"], rank, player_name, team_name, goals),
                "edition_id": edition["id"], "rank": rank,
                "player_source_id": int(PLAYER_RE.search(player_link["href"]).group(1)) if player_link else None,
                "player_name_raw": player_name,
                "team_source_id": int(TEAM_RE.search(team_link["href"]).group(1)) if team_link else None,
                "team_name_raw": team_name,
                "goals": goals, "source_url": source_url,
            }
            if not any(x["id"] == rec["id"] for x in out):
                out.append(rec)
    return sorted(out, key=lambda x: (x.get("rank") or 999, -(x.get("goals") or 0), x.get("player_name_raw") or ""))


def parse_statistics(html: str, edition: dict, source_url: str) -> dict:
    doc = soup(html)
    text = clean_text(doc.get_text(" ", strip=True))
    result = {
        "id": f"stats_{edition['id']}", "edition_id": edition["id"], "source_url": source_url,
        "matches": None, "goals": None, "goals_per_match": None,
        "best_attack": [], "best_defense": [], "biggest_wins": [], "streaks": [],
    }
    m = re.search(r"(\d[\d.]*)\s+jogos?,\s+(\d[\d.]*)\s+gols?,\s+m[eé]dia de\s+([\d,.]+)", text, re.I)
    if m:
        result["matches"] = int(m.group(1).replace(".", ""))
        result["goals"] = int(m.group(2).replace(".", ""))
        result["goals_per_match"] = float(m.group(3).replace(".", "").replace(",", "."))
    labels = [
        ("best_attack", r"Melhor ataque\s+(.+?)\s*\((\d+)\)"),
        ("best_defense", r"Melhor defesa\s+(.+?)\s*\((\d+)\)"),
    ]
    for field, pattern in labels:
        mm = re.search(pattern, text, re.I)
        if mm:
            result[field].append({"team_name_raw": clean_text(mm.group(1)), "value": int(mm.group(2))})
    # Preserve headline statistic sections verbatim in a compact, source-attributable form.
    for label in ("Maior invencibilidade", "Maior sequência de vitórias", "Maior sequência de derrotas", "Maior sequência sem vitórias"):
        mm = re.search(re.escape(label) + r"\s+(.+?)\s*\((\d+)\)", text, re.I)
        if mm:
            result["streaks"].append({"type": slug(label), "team_name_raw": clean_text(mm.group(1)), "matches": int(mm.group(2))})
    return result


def parse_regulation(html: str, edition: dict, source_url: str) -> dict:
    doc = soup(html)
    # Remove navigation, scripts and styles, then retain the source text for audit/reprocessing.
    for tag in doc(["script", "style", "nav", "footer"]):
        tag.decompose()
    text = clean_text(doc.get_text("\n", strip=True))
    return {
        "id": f"regulation_{edition['id']}",
        "edition_id": edition["id"],
        "source_url": source_url,
        "text": text,
    }


def parse_final_classification(html: str, edition: dict, source_url: str) -> list[dict]:
    doc = soup(html)
    out = []
    for table in doc.find_all("table"):
        for tr in table.find_all("tr"):
            cells = [clean_text(x.get_text(" ", strip=True)) for x in tr.find_all(["th", "td"])]
            if len(cells) < 2:
                continue
            pos = parse_int(cells[0])
            team_link = next((a for a in tr.find_all("a", href=True) if TEAM_RE.search(a["href"])), None)
            team_name = clean_text(team_link.get_text(" ", strip=True)) if team_link else None
            if pos and team_name:
                out.append({
                    "id": stable_id("finalrank", edition["id"], pos, team_name),
                    "edition_id": edition["id"], "position": pos,
                    "team_source_id": int(TEAM_RE.search(team_link["href"]).group(1)) if team_link else None,
                    "team_name_raw": team_name, "is_champion": pos == 1,
                    "source_url": source_url,
                })
    return out


def _parse_datetime(text: str) -> str | None:
    m = re.search(r"\b(\d{2}/\d{2}/\d{4})(?:\s+(\d{1,2}:\d{2}))?", text)
    if not m:
        return None
    fmt = "%d/%m/%Y %H:%M" if m.group(2) else "%d/%m/%Y"
    dt = datetime.strptime(m.group(1) + ((" " + m.group(2)) if m.group(2) else ""), fmt)
    return dt.isoformat()


def parse_match_page(html: str, source_url: str, edition_id: str | None = None) -> dict:
    doc = soup(html)
    title = title_text(doc)
    whole = clean_text(doc.get_text("\n", strip=True))
    sm = re.search(r"(.+?)\s+(\d+)\s*(?:\((\d+)\))?\s*x\s*(?:\((\d+)\))?\s*(\d+)\s+(.+?)(?:\s+-\s+|$)", title)
    # A safer score regex over visible text; raw score is always retained.
    score_m = re.search(r"(\d+)\s*(?:\((\d+)\))?\s*x\s*(?:\((\d+)\))?\s*(\d+)", whole)
    match_source_id_m = MATCH_RE.search(source_url)
    source_match_id = int(match_source_id_m.group(1)) if match_source_id_m else None

    team_links = []
    for a in doc.find_all("a", href=True):
        tm = TEAM_RE.search(a["href"])
        if tm:
            item = (int(tm.group(1)), clean_text(a.get_text(" ", strip=True)), urljoin(source_url, a["href"]))
            if item[1] and item not in team_links:
                team_links.append(item)
    home = team_links[0] if len(team_links) >= 1 else (None, None, None)
    away = team_links[1] if len(team_links) >= 2 else (None, None, None)

    stage = None
    round_name = None
    for text_node in doc.stripped_strings:
        t = clean_text(str(text_node))
        if len(t) >= 90:
            continue
        # Some pages render stage+round as one combined breadcrumb node
        # ("Masculino - Fase final - 17ª rodada") rather than separate
        # nodes — split on " - " so each half can independently match
        # stage/round instead of both fields collapsing to the same full
        # string.
        for seg in (clean_text(s) for s in t.split(" - ")) if " - " in t else (t,):
            sn = norm(seg)
            if stage is None and any(k in sn for k in ("fase", "final", "quartas", "oitavas", "semifinal", "grupo", "playoff")):
                stage = seg
            # Matched against `seg.lower()`, never `sn`: `norm()`
            # NFKD-decomposes "º"/"ª" away (they have no combining mark to
            # strip, so they just become "o"/"a"), which meant this regex —
            # written expecting those exact ordinal characters — could
            # never match anything after normalization. `round_name_raw`
            # was silently always null.
            if round_name is None and re.search(r"\b\d+[ªº]?\s*rodada\b", seg.lower()):
                round_name = seg

    stadium_link = next((a for a in doc.find_all("a", href=True) if STADIUM_RE.search(a["href"])), None)
    stadium = {
        "source_id": int(STADIUM_RE.search(stadium_link["href"]).group(1)),
        "name_raw": clean_text(stadium_link.get_text(" ", strip=True)),
    } if stadium_link else None

    player_links = []
    for a in doc.find_all("a", href=True):
        pm = PLAYER_RE.search(a["href"])
        if pm:
            rec = {"source_player_id": int(pm.group(1)), "name_raw": clean_text(a.get_text(" ", strip=True)), "source_url": urljoin(source_url, a["href"])}
            if rec["name_raw"] and rec not in player_links:
                player_links.append(rec)

    officials = []
    arb_heading = next((h for h in doc.find_all(["h2", "h3", "h4"]) if "arbitragem" in norm(h.get_text(" ", strip=True))), None)
    if arb_heading:
        block = []
        node = arb_heading.find_next()
        while node and node.name not in {"h2", "h3", "h4"}:
            t = clean_text(node.get_text(" ", strip=True)) if hasattr(node, "get_text") else ""
            if t:
                block.append(t)
            node = node.find_next()
            if len(block) > 30:
                break
        for label in ("Árbitro", "Auxiliar 1", "Auxiliar 2", "Quarto árbitro", "VAR"):
            for i, item in enumerate(block):
                if norm(item) == norm(label) and i + 1 < len(block):
                    officials.append({"role": label, "name_raw": block[i + 1]})

    score = {
        "home": int(score_m.group(1)) if score_m else None,
        "away": int(score_m.group(4)) if score_m else None,
        "penalties_home": int(score_m.group(2)) if score_m and score_m.group(2) else None,
        "penalties_away": int(score_m.group(3)) if score_m and score_m.group(3) else None,
        "raw": score_m.group(0) if score_m else None,
    }
    status = "played" if score_m else ("scheduled" if _parse_datetime(whole) else "unknown")
    nw = norm(whole)
    if "anulad" in nw or "cancelad" in nw:
        status = "voided_or_cancelled"
    elif "adiad" in nw:
        status = "postponed"
    elif "interrompid" in nw or "abandonad" in nw:
        status = "abandoned"

    return {
        "id": f"fdg_match_{source_match_id}" if source_match_id else stable_id("match", source_url),
        "source_match_id": source_match_id,
        "edition_id": edition_id,
        "stage_name_raw": stage,
        "round_name_raw": round_name,
        "datetime_local": _parse_datetime(whole),
        "home_team_source_id": home[0], "home_team_name_raw": home[1],
        "away_team_source_id": away[0], "away_team_name_raw": away[1],
        "score": score,
        "status": status,
        "stadium": stadium,
        "players_seen": player_links,
        "officials": officials,
        "source_url": source_url,
        "source_notes_detected": [x for x in ("anulado" if "anulad" in nw else None, "cancelado" if "cancelad" in nw else None, "adiado" if "adiad" in nw else None) if x],
    }
