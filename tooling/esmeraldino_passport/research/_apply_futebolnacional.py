"""Aplica confirmações de estádio vindas de jogos listados no Futebol Nacional (futebolnacional.com.br, "Jogos de uma equipe").

Uso: python _apply_futebolnacional.py <checkpoint_entrada.csv> <confirmacoes.json> <checkpoint_saida.csv>

confirmacoes.json = lista de objetos com:
  id     (id da linha no CSV)
  url    (URL da lista de jogos do Goiás no ano)
  date   (data no Futebol Nacional, AAAA-MM-DD)
  game   (texto "Mandante N-M Visitante" do Futebol Nacional)
  comp   (competição no Futebol Nacional)
  venue  (nome do estádio como no Futebol Nacional, sem a cidade; nunca vazio)
  city   (cidade do estádio)
  venue_raw (texto completo do local no Futebol Nacional)

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
    r['venue_city'] = c['city']
    r['venue_confidence'] = 'HIGH'
    r['source_secondary'] = (r['source_secondary'] + ' | ' if r['source_secondary'] else '') + c['url']
    r['notes'] = (r['notes'] + ' ' if r['notes'] else '') + (
        f"Jogo listado no Futebol Nacional (futebolnacional.com.br): {c['comp']}, {c['date']}, {c['game']}, local {c['venue_raw']}. "
        f"Data e placar batem. Confirmado em 2026-09-28.")
    done += 1
assert done == len(C), (done, len(C))
with open(dst, 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields, lineterminator='\r\n')
    w.writeheader()
    w.writerows(rows)
print('aplicadas', done, '->', dst)
