"""Candidatos de estádio a partir de MATÉRIAS PRÉ-JOGO do Diário da Manhã.

Edição do próprio dia do jogo (D) com "hoje", ou da véspera (D-1) com "amanhã": trecho de até ~350 caracteres
com Goiás + adversário + nome de estádio conhecido + a palavra temporal. Sem outro jogo do Goiás entre a
edição e o jogo. Saída para REVISÃO HUMANA.

Uso: python _dm_extrair_prejogo.py <checkpoint.csv> <pasta_txt> <saida.json>
"""
import csv, json, os, re, sys, datetime, importlib.util

ck, txtdir, out = sys.argv[1:4]
spec = importlib.util.spec_from_file_location('mat', os.path.join(os.path.dirname(os.path.abspath(__file__)), '_dm_extrair_materias.py'))
src = open(spec.origin, encoding="utf-8").read().split("\nres = []")[0]
ns = {}
exec(src, ns)  # reaproveita fold, ST, GOI e opp_names do extrator de matérias
fold, ST, GOI, opp_names = ns['fold'], ns['ST'], ns['GOI'], ns['opp_names']

rows = list(csv.DictReader(open(ck, encoding='utf-8-sig')))
hist = [r for r in rows if r['dataset_origin'] == 'historical_futebol80' and r['effective_date']]
dates_all = sorted(datetime.date.fromisoformat(r['effective_date']) for r in hist)
res = []
for r in hist:
    if r['venue_name'] != 'UNKNOWN' or int(r['season']) < 1980:
        continue
    D = datetime.date.fromisoformat(r['effective_date'])
    OPPS = opp_names(r['opponent'])
    for k, word in ((0, r'HOJE'), (-1, r'AMANHA')):
        E = D + datetime.timedelta(days=k)
        if any(E <= x < D for x in dates_all):
            continue
        f = os.path.join(txtdir, E.isoformat() + '.txt')
        if not os.path.exists(f):
            continue
        t = open(f, encoding='utf-8').read()
        T = fold(t)
        W = re.compile(word)
        cands = {}
        for m in ST.finditer(T):
            a, b = max(0, m.start() - 350), m.end() + 350
            w = T[a:b]
            if GOI.search(w) and W.search(w) and any(o.search(w) for o in OPPS):
                key = re.sub(r'\s+', ' ', m.group(1))
                pg = t.rfind('=====PAGE', 0, m.start())
                page = re.match(r'=====PAGE (\d+)', t[pg:pg + 20]).group(1) if pg >= 0 else '?'
                cands.setdefault(key, dict(stadium=key, page=page, snippet=re.sub(r'\s+', ' ', t[a:b])))
        if cands:
            res.append(dict(id=r['id'], date=r['effective_date'], opponent=r['opponent'], score=r['score_display'],
                            edition=E.isoformat(), word=word, stadiums=sorted(cands), hits=list(cands.values())))
            break
json.dump(res, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('candidatos', len(res), 'com 1 estadio', sum(len(x['stadiums']) == 1 for x in res))
