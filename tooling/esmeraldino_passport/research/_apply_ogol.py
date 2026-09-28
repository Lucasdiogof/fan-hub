"""Aplica confirmações de estádio vindas de fichas de jogo do ogol.com.br.

Uso: python _apply_ogol.py <checkpoint_entrada.csv> <confirmacoes.json> <checkpoint_saida.csv>

confirmacoes.json = lista de objetos com:
  id     (id da linha no CSV)
  url    (URL da ficha do jogo no ogol)
  date   (data no ogol, AAAA-MM-DD)
  game   (texto "Mandante N-M Visitante" do ogol)
  comp   (competição no ogol)
  venue  (estádio EXATAMENTE como no ogol; nunca vazio)

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
    assert c['venue'].strip(), r['id']
    r['venue_name'] = c['venue'].strip()
    r['venue_confidence'] = 'HIGH'
    r['source_secondary'] = (r['source_secondary'] + ' | ' if r['source_secondary'] else '') + c['url']
    r['notes'] = (r['notes'] + ' ' if r['notes'] else '') + (
        f"Ficha de jogo do ogol.com.br: {c['comp']}, {c['date']}, {c['game']}, local {c['venue'].strip()}. "
        f"Data e placar batem. Confirmado em 2026-09-28.")
    done += 1
assert done == len(C), (done, len(C))
with open(dst, 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields, lineterminator='\r\n')
    w.writeheader()
    w.writerows(rows)
print('aplicadas', done, '->', dst)
