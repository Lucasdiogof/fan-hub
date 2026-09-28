"""Categoria PROVÁVEL (decisão do usuário em 2026-09-28).

Preenche colunas NOVAS no fim do CSV, sem tocar em venue_name/venue_confidence
(a contagem "confirmada" dos 80% continua só com os jogos HIGH):
  venue_probable_name, venue_probable_city, venue_probable_confidence (MEDIUM),
  venue_probable_basis

Regra (conservadora):
  - só para linhas historical_futebol80 com venue_name == UNKNOWN, fora do Torneio Início;
  - o mandante do jogo precisa ser conhecido: goias_is_home preenchido no CSV,
    ou o jogo casado no Futebol de Goyaz (data ±2 dias + placar exato) diz quem é o mandante;
  - na MESMA temporada e MESMA competição, o MESMO mandante precisa ter >= 2 jogos com estádio confirmado (HIGH),
    TODOS no mesmo estádio canônico (via passaporte_esmeraldino_VENUE_ALIASES_rascunho.csv);
  - qualquer exceção conhecida naquele ano anula a inferência.

Uso: python _gen_provaveis.py <checkpoint_entrada.csv> <checkpoint_saida.csv>
"""
import csv, json, sys, os, datetime, collections, unicodedata, re

HERE = os.path.dirname(os.path.abspath(__file__))
src, dst = sys.argv[1:3]
MIN_SAMPLES = 2
NEW_COLS = ['venue_probable_name', 'venue_probable_city', 'venue_probable_confidence', 'venue_probable_basis']

raw = open(src, 'rb').read().decode('utf-8-sig')
rows = list(csv.DictReader(raw.splitlines(True)))
fields = [f for f in rows[0].keys() if f not in NEW_COLS] + NEW_COLS

alias = {}
for a in csv.DictReader(open(os.path.join(HERE, 'passaporte_esmeraldino_VENUE_ALIASES_rascunho.csv'), encoding='utf-8-sig')):
    alias[(a['raw_venue_name'], a['raw_venue_city'])] = (a['canonical_id'], a['canonical_name'], a['canonical_city'], a['needs_review'])

def canon(r):
    a = alias.get((r['venue_name'], r['venue_city']))
    if not a or not a[0]:
        return None
    if r['id'] == 'hist-f80-2406':  # exceção por linha registrada no mapa de aliases
        return ('rs-olimpico-monumental', 'Estádio Olímpico Monumental', 'Porto Alegre')
    return a[:3]

def d(s):
    return datetime.date(int(s[6:10]), int(s[3:5]), int(s[:2]))

by_date = collections.defaultdict(list)
for m in json.load(open(os.path.join(HERE, '_fdg_all_matches.json'), encoding='utf-8')):
    gh, ga = m['home'].strip() == 'Goiás', m['away'].strip() == 'Goiás'
    if not (gh or ga) or not (m['hs'].isdigit() and m['as_'].isdigit()):
        continue
    gs, os_ = (int(m['hs']), int(m['as_'])) if gh else (int(m['as_']), int(m['hs']))
    by_date[d(m['date'])].append((gs, os_, gh, m))

def mandante(r):
    """'GOIAS', 'OPP' ou None, com a fonte."""
    if r['goias_is_home'] in ('True', 'False'):
        return ('GOIAS' if r['goias_is_home'] == 'True' else 'OPP'), 'CSV (goias_is_home)'
    if not r['effective_date']:
        return None, None
    try:
        rd = datetime.date.fromisoformat(r['effective_date'])
        gs, os_ = int(float(r['goias_score'])), int(float(r['opponent_score']))
    except ValueError:
        return None, None
    c = [(abs(k), x) for k in range(-2, 3) for x in by_date.get(rd + datetime.timedelta(days=k), []) if x[0] == gs and x[1] == os_]
    if len(c) != 1:
        return None, None
    _, (gs, os_, gh, m) = c[0]
    return ('GOIAS' if gh else 'OPP'), f"FdG ficha {m['mid']} ({m['game']})"

def key(r, who):
    return (r['season'], r['competition'], 'GOIAS' if who == 'GOIAS' else r['opponent'])

hist = [r for r in rows if r['dataset_origin'] == 'historical_futebol80']
known = collections.defaultdict(list)
for r in hist:
    if r['venue_name'] in ('UNKNOWN', '') or r['venue_confidence'] != 'HIGH':
        continue
    who, _ = mandante(r)
    c = canon(r)
    if who and c:
        known[key(r, who)].append((c, r['id']))

made = 0
stats = collections.Counter()
for r in rows:
    for c in NEW_COLS:
        r.setdefault(c, '')
        r[c] = ''
    if r['dataset_origin'] != 'historical_futebol80' or r['venue_name'] != 'UNKNOWN' or 'Início' in r['competition']:
        continue
    who, how = mandante(r)
    if not who:
        stats['sem mandante'] += 1
        continue
    ex = known.get(key(r, who), [])
    venues = {c for c, _ in ex}
    if len(ex) < MIN_SAMPLES:
        stats['amostra < 2'] += 1
        continue
    if len(venues) != 1:
        stats['padrão não é 100%'] += 1
        continue
    cid, cname, ccity = venues.pop()
    quem = 'Goiás' if who == 'GOIAS' else r['opponent']
    r['venue_probable_name'] = cname
    r['venue_probable_city'] = ccity
    r['venue_probable_confidence'] = 'MEDIUM'
    alvo = 'do Goiás como mandante' if who == 'GOIAS' else f'com {quem} como mandante contra o Goiás'
    r['venue_probable_basis'] = (f"INFERIDO, não confirmado. Mandante: {quem} (fonte: {how}). Em {r['season']} ({r['competition']}), todos os {len(ex)} "
                                 f"jogos {alvo} com estádio confirmado foram em {cname} ({', '.join(i for _, i in ex)}).")
    made += 1
    stats['provável'] += 1

with open(dst, 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields, lineterminator='\r\n')
    w.writeheader()
    w.writerows(rows)
print('prováveis:', made, dict(stats))
