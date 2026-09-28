# Varredura do Futebol de Goyaz (2026-09-28). Ordem: baixar conf/c<ID>.html com curl de clubes/469/<ID>/confronto (IDs 1..3500),
# rodar _fdg_1 (gera all_matches.json), _fdg_2 <checkpoint.csv> (gera pending_matched.json), baixar fic/m<ID>.html das fichas, rodar _fdg_3.
# conf/, fic/ e os .json intermediários NÃO são versionados.
import json, os, re, html, collections
S = os.path.dirname(os.path.abspath(__file__))
P = json.load(open(os.path.join(S, 'pending_matched.json'), encoding='utf-8'))

def ficha(mid):
    t = open(os.path.join(S, 'fic', f'm{mid}.html'), encoding='utf-8', errors='replace').read()
    txt = [html.unescape(x).strip() for x in re.sub(r'<[^>]*>', '\n', t).split('\n')]
    txt = [x for x in txt if x]
    try:
        a = txt.index('Comunicar erro'); b = txt.index('Print da partida', a)
    except ValueError:
        return None
    blk = txt[a + 1:b]
    # stadium line precedes a line starting with "- " + city
    venue = city = ''
    for i, x in enumerate(blk):
        m = re.match(r'^-\s*(.+?)\s*\((\w+)\)$', x)
        if m and i > 0 and re.search(r'\d{2}/\d{2}/\d{4}', blk[i - 2] if i >= 2 else '') or (m and i > 0 and re.search(r'\d{2}/\d{2}/\d{4}', blk[i - 1])):
            venue = blk[i - 1]
            city = m.group(1)
            break
    datel = next((x for x in blk if re.search(r'\d{2}/\d{2}/\d{4}', x)), '')
    return dict(block=' | '.join(blk), venue=venue, city=city, dateline=datel)

res = []
for o in P:
    f = ficha(o['mid'])
    o.update(f or {})
    res.append(o)
json.dump(res, open(os.path.join(S, 'pending_fichas.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
wv = [o for o in res if o.get('venue') and re.search(r'\d{2}/\d{2}/\d{4}', o['venue']) is None]
print('fichas', len(res), 'com estadio', len(wv))
print(collections.Counter(o['date'][:3] for o in wv))
print(collections.Counter(o['venue'] for o in wv).most_common(40))
for o in res[:3]: print(o['block'][:200])
