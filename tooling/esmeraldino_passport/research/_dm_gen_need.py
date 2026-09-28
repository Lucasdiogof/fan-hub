"""Gera T/dm_need.json com as edições candidatas (D-7..D+7) para as pendências >= 1980.
Uso: python _dm_gen_need.py <checkpoint.csv>
"""
import csv, json, os, sys, datetime

T = r'C:\Users\lucas\AppData\Local\Temp'
ck = sys.argv[1]
rows = list(csv.DictReader(open(ck, encoding='utf-8-sig')))
hist = [r for r in rows if r['dataset_origin'] == 'historical_futebol80' and r['effective_date']]
need = []
for r in hist:
    if r['venue_name'] != 'UNKNOWN' or int(r['season']) < 1980:
        continue
    D = datetime.date.fromisoformat(r['effective_date'])
    dates = [(D + datetime.timedelta(days=k)).isoformat() for k in range(-7, 8)]
    need.append([r['id'], r['season'], r['opponent'], r['score_display'], dates])
json.dump(need, open(os.path.join(T, 'dm_need.json'), 'w', encoding='utf-8'))
print('jogos', len(need), 'edicoes unicas', len({d for n in need for d in n[4]}))
