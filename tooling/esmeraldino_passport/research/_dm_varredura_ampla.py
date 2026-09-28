import csv, json, os, re, sys, datetime, unicodedata
R = 'C:/Users/lucas/AndroidStudioProjects/fan-hub/tooling/esmeraldino_passport/research/'
T = 'C:/Users/lucas/AppData/Local/Temp/'
ck = R + sys.argv[1]
ns = {}
src = open(R + '_dm_extrair_materias.py', encoding='utf-8').read().split('\nrows = list(csv.DictReader')[0]
sys.argv = [sys.argv[0], ck, T + 'dm_txt', T + 'x.json']
exec(src, ns)
fold, ST = ns['fold'], ns['ST']
GOI = re.compile(r'GO[I1L]\s?-?\s?AS|ESMERALDIN|ALVIVERDE|VERDAO|PERIQUITO')
code = open(R + '_dm_extrair_materias.py', encoding='utf-8').read()
opp_src = code[code.index('def opp_names'):code.index('res = []')]
exec(opp_src, ns)
opp_names = ns['opp_names']
rows = list(csv.DictReader(open(ck, encoding='utf-8-sig')))
hist = [r for r in rows if r['dataset_origin'] == 'historical_futebol80' and r['effective_date']]
dates_all = sorted(datetime.date.fromisoformat(r['effective_date']) for r in hist)
out = []
for r in hist:
    if r['venue_name'] != 'UNKNOWN' or r['season'] < '1980':
        continue
    D = datetime.date.fromisoformat(r['effective_date'])
    OPPS = opp_names(r['opponent'])
    for k in (1, 2, 0, -1, 3, -2, 4, -3, 5):
        E = D + datetime.timedelta(days=k)
        lo, hi = (D, E) if k > 0 else (E, D)
        if any(lo < x < hi for x in dates_all):
            continue
        f = os.path.join(T + 'dm_txt', E.isoformat() + '.txt')
        if not os.path.exists(f):
            continue
        t = open(f, encoding='utf-8').read()
        TT = fold(t)
        for m in ST.finditer(TT):
            a, b = max(0, m.start() - 260), m.end() + 200
            w = TT[a:b]
            if GOI.search(w) and any(o.search(w) for o in OPPS):
                out.append(dict(id=r['id'], date=r['effective_date'], opp=r['opponent'], score=r['score_display'], k=k,
                                edition=E.isoformat(), stadium=re.sub(r'\s+', ' ', m.group(1)), snippet=re.sub(r'\s+', ' ', t[a:b])))
json.dump(out, open(T + 'broad.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print('trechos', len(out), 'jogos', len({o['id'] for o in out}))
