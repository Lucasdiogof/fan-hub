"""Aplica confirmações de estádio vindas de fichas individuais do Futebol de Goyaz.

Uso: python _apply_fichas_fdg.py <checkpoint_entrada.csv> <confirmacoes.json> <checkpoint_saida.csv>

confirmacoes.json = lista de objetos com:
  id        (id da linha no CSV, ex. hist-f80-0005)
  mid       (ID da ficha no FdG)
  fdg_date  (data da ficha, DD/MM/AAAA)
  fdg_game  (texto "Mandante N x M Visitante" da ficha)
  fdg_comp  (competição da ficha)
  venue     (estádio EXATAMENTE como na ficha; nunca vazio)
  city      (cidade da ficha, ex. "Goiânia-GO")

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
    url = f"https://www.futeboldegoyaz.com.br/partidas/{c['mid']}/partida"
    r['venue_name'] = c['venue'].strip()
    r['venue_city'] = c['city'].replace('-GO', '').strip() if c['city'].endswith('-GO') else c['city'].strip()
    r['venue_confidence'] = 'HIGH'
    r['source_secondary'] = (r['source_secondary'] + ' | ' if r['source_secondary'] else '') + url
    r['notes'] = (r['notes'] + ' ' if r['notes'] else '') + (
        f"Ficha específica do Futebol de Goyaz (ID {c['mid']}): {c['fdg_comp']}, {c['fdg_date']}, "
        f"{c['fdg_game']}, Estádio {c['venue'].strip()} - {c['city']}. Data e placar batem. Confirmado em 2026-09-28.")
    done += 1
assert done == len(C), (done, len(C))
with open(dst, 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields, lineterminator='\r\n')
    w.writeheader()
    w.writerows(rows)
print('aplicadas', done, '->', dst)
