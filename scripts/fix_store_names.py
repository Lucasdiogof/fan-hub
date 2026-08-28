"""Corrige nomes/descrições de produtos importados que perderam acentos por
decodificação errada (páginas ISO-8859-1 lidas como UTF-8). Re-busca só os
produtos com o defeito ("Gois" em vez de "Goiás"), lê o og:title em latin-1 e
atualiza nome + shortDescription/description quando derivadas do nome.

Uso: python scripts/fix_store_names.py
"""
import json, re, os, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROD_JSON = os.path.join(ROOT, 'lib/assets/content/store_products.json')
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'


def title_of(url):
    raw = subprocess.run(['curl', '-sL', '-A', UA, 'https://web.archive.org/web/2025id_/' + url],
                         capture_output=True).stdout
    html = raw.decode('latin-1', 'replace')
    m = re.search(r'og:title" content="([^"]+)', html)
    if not m:
        return None
    t = m.group(1)
    t = re.split(r' - Goi', t)[0]
    t = re.split(r' [–—\-\?\|\x96] ', t)[0]
    return re.sub(r'\s+', ' ', t).strip()


def main():
    products = json.load(open(PROD_JSON, encoding='utf-8'))
    fixed = 0
    for p in products:
        if 'Gois' not in p['name'] or not p.get('sourceUrl'):
            continue
        new = title_of(p['sourceUrl'])
        if not new or 'Gois' in new:
            print('  ! não corrigido:', p['id'], '->', new)
            continue
        old = p['name']
        if p.get('shortDescription') == old:
            p['shortDescription'] = new
        if p.get('description', '').startswith(old):
            p['description'] = new + p['description'][len(old):]
        p['name'] = new
        fixed += 1
        print('  +', p['id'], '|', new)
    json.dump(products, open(PROD_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print('CORRIGIDOS:', fixed)


if __name__ == '__main__':
    main()
