# Varredura do Futebol de Goyaz (2026-09-28). Ordem: baixar conf/c<ID>.html com curl de clubes/469/<ID>/confronto (IDs 1..3500),
# rodar _fdg_1 (gera all_matches.json), _fdg_2 <checkpoint.csv> (gera pending_matched.json), baixar fic/m<ID>.html das fichas, rodar _fdg_3.
# conf/, fic/ e os .json intermediários NÃO são versionados.
import re, glob, json, os, html, csv, datetime, collections, sys
S = os.path.dirname(os.path.abspath(__file__))
pat = re.compile(r'href="https://www\.futeboldegoyaz\.com\.br/partidas/(\d+)/partida"[^>]*title="([^"]*)"')
matches = {}
for f in glob.glob(os.path.join(S, 'conf', 'c*.html')):
    rid = int(re.sub(r'\D', '', os.path.basename(f)))
    t = open(f, encoding='utf-8', errors='replace').read()
    for mid, title in pat.findall(t):
        parts = [html.unescape(p).strip() for p in title.split('<br />')]
        if len(parts) < 3: continue
        m = re.match(r'(.+?)\s+(\S+)\s+x\s+(\S+)\s+(.+)$', parts[2])
        matches[int(mid)] = dict(mid=int(mid), rival=rid, date=parts[0], comp=parts[1], game=parts[2],
                                 home=m.group(1) if m else '', hs=m.group(2) if m else '', as_=m.group(3) if m else '', away=m.group(4) if m else '')
json.dump(list(matches.values()), open(os.path.join(S, 'all_matches.json'), 'w', encoding='utf-8'), ensure_ascii=False)
print('matches', len(matches))
