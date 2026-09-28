import json, os, sys, subprocess, concurrent.futures, pymupdf
T = r'C:\Users\lucas\AppData\Local\Temp'
OUT = os.path.join(T, 'dm_txt')
os.makedirs(OUT, exist_ok=True)
need = json.load(open(os.path.join(T, 'dm_need.json'), encoding='utf-8'))
dates = sorted({d for n in need for d in n[4]})
print('edicoes', len(dates), flush=True)

def get(ds):
    y, m, d = ds.split('-')
    txt = os.path.join(OUT, f'{ds}.txt')
    if os.path.exists(txt) and os.path.getsize(txt) > 0:
        return ds, 'cache'
    pdf = os.path.join(OUT, f'{ds}.pdf')
    url = f'https://hemeroteca.ihgg.org/publicacoes/DIARIO_DA_MANHA/{y}/{m}/DIARIO_DA_MANHA_{y}_{m}_{d}.pdf'
    r = subprocess.run(['curl', '-sL', '-m', '300', '-A', 'Mozilla/5.0', '-o', pdf, '-w', '%{http_code}', url], capture_output=True, text=True)
    if r.stdout.strip() != '200':
        return ds, 'http ' + r.stdout.strip()
    try:
        doc = pymupdf.open(pdf)
        with open(txt, 'w', encoding='utf-8') as f:
            for i, p in enumerate(doc):
                f.write(f'\n=====PAGE {i+1}=====\n')
                f.write(p.get_text())
        doc.close()
    except Exception as e:
        return ds, 'erro ' + str(e)[:60]
    finally:
        try: os.remove(pdf)
        except OSError: pass
    return ds, 'ok'

with concurrent.futures.ThreadPoolExecutor(4) as ex:
    for i, (ds, st) in enumerate(ex.map(get, dates)):
        print(i, ds, st, flush=True)
print('FIM', flush=True)
