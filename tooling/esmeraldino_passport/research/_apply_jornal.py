"""Aplica confirmações de estádio vindas de jornais digitalizados (Hemeroteca BN, Hemeroteca IHGG etc.).

Uso: python _apply_jornal.py <checkpoint_entrada.csv> <confirmacoes.json> <checkpoint_saida.csv>

confirmacoes.json = lista de objetos com:
  id      (id da linha no CSV)
  venue   (estádio como escrito na fonte; nunca vazio)
  city    (cidade do estádio)
  url     (URL do(s) PDF(s)/edição(ões) usados)
  note    (evidência: jornal, data da edição, página e trecho que liga o jogo ao estádio)
  state   (opcional: UF do estádio, quando a coluna venue_state existir)
  conflict (opcional: texto para conflict_note, p.ex. divergência de data documentada)

Só altera linhas historical_futebol80 com venue_name == UNKNOWN.
"""
import csv, json, sys

src, conf, dst = sys.argv[1:4]
raw = open(src, 'rb').read().decode('utf-8-sig')
rows = list(csv.DictReader(raw.splitlines(True)))
fields = list(rows[0].keys())
C = {c['id']: c for c in json.load(open(conf, encoding='utf-8'))}
done = 0
for r in rows:
    c = C.get(r['id'])
    if not c:
        continue
    assert r['dataset_origin'] == 'historical_futebol80' and r['venue_name'] == 'UNKNOWN', r['id']
    assert c['venue'].strip() and c['note'].strip(), r['id']
    r['venue_name'] = c['venue'].strip()
    r['venue_city'] = c['city'].strip()
    r['venue_confidence'] = 'HIGH'
    if c.get('state') and 'venue_state' in r:
        r['venue_state'] = c['state']
    if c.get('conflict'):
        r['conflict_note'] = (r['conflict_note'] + ' | ' if r.get('conflict_note') else '') + c['conflict']
    r['source_secondary'] = (r['source_secondary'] + ' | ' if r['source_secondary'] else '') + c['url']
    r['notes'] = (r['notes'] + ' ' if r['notes'] else '') + c['note'].strip() + ' Confirmado em 2026-09-28.'
    for k in ('venue_probable_name', 'venue_probable_city', 'venue_probable_confidence', 'venue_probable_basis'):
        if k in r:
            r[k] = ''
    done += 1
assert done == len(C), (done, len(C))
with open(dst, 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields, lineterminator='\r\n')
    w.writeheader()
    w.writerows(rows)
print('aplicadas', done, '->', dst)
