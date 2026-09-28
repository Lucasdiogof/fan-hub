# Varredura do Futebol de Goyaz (2026-09-28). Ordem: baixar conf/c<ID>.html com curl de clubes/469/<ID>/confronto (IDs 1..3500),
# rodar _fdg_1 (gera all_matches.json), _fdg_2 <checkpoint.csv> (gera pending_matched.json), baixar fic/m<ID>.html das fichas, rodar _fdg_3.
# conf/, fic/ e os .json intermediários NÃO são versionados.
import json, csv, datetime, os, collections, sys, unicodedata, re
S = os.path.dirname(os.path.abspath(__file__))
R = S
CK = sys.argv[1]
M = json.load(open(os.path.join(S, 'all_matches.json'), encoding='utf-8'))

def d(s):
    return datetime.date(int(s[6:10]), int(s[3:5]), int(s[0:2]))

def n(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z0-9]', '', re.sub(r'-(go|df|mt|ms|sp|rj|mg|pr|sc|rs|ba|pe|ce|am|pa|ma|es|al|se|pi|pb|rn|to|ro|ac|ap|rr)$', '', s))

by_date = collections.defaultdict(list)
for m in M:
    gh = m['home'].strip() == 'Goiás'
    ga = m['away'].strip() == 'Goiás'
    if not (gh or ga) or not m['hs'].isdigit() or not m['as_'].isdigit():
        continue
    m['gs'], m['os'] = (int(m['hs']), int(m['as_'])) if gh else (int(m['as_']), int(m['hs']))
    m['opp'] = m['away'] if gh else m['home']
    m['g_home'] = gh
    by_date[d(m['date'])].append(m)

rows = list(csv.DictReader(open(os.path.join(R, CK), encoding='utf-8-sig')))
pend = [r for r in rows if r['dataset_origin'] == 'historical_futebol80' and r['venue_name'] == 'UNKNOWN']
out = []
for r in pend:
    try:
        rd = datetime.date.fromisoformat(r['effective_date'])
        gs, os_ = int(float(r['goias_score'])), int(float(r['opponent_score']))
    except Exception:
        continue
    cands = []
    for dd in range(-2, 3):
        for m in by_date.get(rd + datetime.timedelta(days=dd), []):
            if m['gs'] == gs and m['os'] == os_:
                cands.append((abs(dd), m))
    cands.sort(key=lambda x: x[0])
    if not cands:
        continue
    best = cands[0]
    namematch = n(best[1]['opp']) in n(r['opponent']) or n(r['opponent']) in n(best[1]['opp'])
    out.append(dict(id=r['id'], date=r['effective_date'], opp=r['opponent'], score=r['score_display'], comp=r['competition'],
                    mid=best[1]['mid'], fdg_date=best[1]['date'], fdg_game=best[1]['game'], fdg_comp=best[1]['comp'],
                    delta=best[0], ncand=len(cands), namematch=namematch))
json.dump(out, open(os.path.join(S, 'pending_matched.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print('pending', len(pend), 'matched', len(out), 'namematch', sum(o['namematch'] for o in out), 'multi', sum(o['ncand'] > 1 for o in out))
print('by decade', collections.Counter(o['date'][:3] for o in out))
for o in out:
    if not o['namematch']:
        print('NAME?', o['id'], o['date'], o['opp'], o['score'], '|', o['fdg_date'], o['fdg_game'], o['fdg_comp'])
