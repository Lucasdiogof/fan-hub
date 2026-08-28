"""Importa em massa produtos oficiais da Goiás Store de snapshots arquivados.
Lê uma lista de URLs (uma por linha), auto-deriva a taxonomia pela URL, acha a
galeria oficial de forma robusta (maior grupo de imagens do CDN que casa com o
slug — não depende da og:image), baixa as fotos e monta o catálogo. Só entra
produto com nome + preço + pelo menos uma foto confirmados.

Uso: python scripts/import_store_batch.py <arquivo_de_urls>
"""
import json, re, os, subprocess, sys, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROD_JSON = os.path.join(ROOT, 'lib/assets/content/store_products.json')
SRC_JSON = os.path.join(ROOT, 'lib/assets/store/products/sources.json')
PUBSPEC = os.path.join(ROOT, 'pubspec.yaml')
IMG_BASE = os.path.join(ROOT, 'lib/assets/store/products')
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
NOTE = ("Fotos oficiais recuperadas de snapshot arquivado (web.archive.org) da "
        "página do produto — a loja ao vivo passou a redirecionar pra \"Nenhum "
        "produto encontrado\". URLs originais do CDN da Tray (images.tcdn.com.br) "
        "baixadas uma vez em tempo de preparo de conteúdo; nunca carregadas "
        "remotamente em runtime. Preço confirmado no snapshot.")
STOCKS = [9, 12, 10, 6, 4, 3, 8, 5]
NAMES = ['front', 'back', 'detail_01', 'detail_02', 'detail_03', 'detail_04', 'detail_05', 'detail_06']


def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', ' ', s.lower()).split()


def curl(url, out=None):
    args = ['curl', '-sL', '-A', UA, url]
    if out:
        subprocess.run(args + ['-o', out], check=False)
        return None
    return subprocess.run(args, capture_output=True).stdout.decode('utf-8', 'ignore')


def derive(path):
    """path = tudo depois de storegoias.com.br/ ; retorna dict de taxonomia."""
    parts = path.split('/')
    slug = parts[-1]
    a0 = parts[0]
    audience = {'masculino': 'masculine', 'feminino': 'feminine',
                'infanto-juvenil': 'kids'}.get(a0, 'unisex')
    aud_cat = {'masculine': 'masculine', 'feminine': 'feminine', 'kids': 'kids'}.get(audience)
    uni = None
    m = re.search(r'uniforme-?0?([123])', path)
    if m:
        uni = '0' + m.group(1)
    colls, cats, ptype = [], [], 'accessory'
    if a0 == 'acessorios':
        ptype, cats = 'accessory', ['accessories']
    elif 'goleiro' in parts:
        ptype, cats = 'matchJersey', ['uniforms'] + ([aud_cat] if aud_cat else [])
        colls = ['goalkeeper'] + ([f'kit_{uni}'] if uni else [])
    elif 'uniforme-de-jogo' in parts:
        ptype, cats = 'matchJersey', ['uniforms'] + ([aud_cat] if aud_cat else [])
        colls = [f'kit_{uni}'] if uni else []
    elif 'treino-viagem-e-concentracao' in parts:
        ptype, cats = 'training', ['training'] + ([aud_cat] if aud_cat else [])
        colls = ['training_travel']
    elif 'casual' in parts:
        ptype, cats = 'casual', ([aud_cat] if aud_cat else [])
        colls = ['casual']
    if 'fan' in slug or 'torcedor' in slug:
        colls.append('fan')
    if 'squadra' in slug or 'jogador' in slug:
        colls.append('player')
    return audience, aud_cat, uni, ptype, cats, colls, slug


def find_gallery(html, slug):
    imgs = re.findall(r'https://images\.tcdn\.com\.br/img/img_prod/1398192/[a-z0-9_]+_[0-9]+_[a-f0-9]{8,}\.(?:jpg|png|webp)', html)
    imgs = [u for u in imgs if not re.search(r'/(?:90|180|250|400|600)_', u)]
    stoks = set(norm(slug))
    groups = {}
    for u in imgs:
        fn = u.split('/1398192/')[1]
        base = re.sub(r'_[0-9]+_[a-f0-9]{8,}\.[a-z]+$', '', fn)
        groups.setdefault(base, []).append(u)
    best, best_score = None, -1
    for base, us in groups.items():
        score = len(stoks & set(norm(base)))
        if score > best_score or (score == best_score and best and len(us) > len(groups[best])):
            best, best_score = base, score
    if best is None or best_score < 2:
        return []
    return sorted(set(groups[best]),
                  key=lambda u: int(re.search(r'_([0-9]+)_[a-f0-9]{8,}\.[a-z]+$', u).group(1)))


def sizes_for(path, html, ptype):
    if ptype == 'accessory':
        return []
    toks = set(re.findall(r'"(P|M|G|GG|3G|2|4|6|8|10|12|14|16)"', html))
    if 'infantil' in path:
        allowed = ['2', '4', '6', '8', '10', '12']
    elif 'juvenil' in path:
        allowed = ['10', '12', '14', '16']
    else:
        allowed = ['P', 'M', 'G', 'GG', '3G']
    return [s for s in allowed if s in toks]


def installments(price):
    return 4 if price >= 400 else (3 if price >= 300 else (2 if price >= 150 else 1))


def slug_to_id(slug, existing):
    base = re.sub(r'[^a-z0-9]+', '_', slug.lower()).strip('_')
    base = re.sub(r'_?(2025|2026)$', '', base)
    pid = base
    i = 2
    while pid in existing:
        pid = f'{base}_{i}'
        i += 1
    return pid


def main():
    urls = [l.strip() for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
    products = json.load(open(PROD_JSON, encoding='utf-8'))
    sources = json.load(open(SRC_JSON, encoding='utf-8'))
    existing_ids = {p['id'] for p in products}
    existing_pages = {p.get('sourceUrl') for p in products}
    added, skipped = [], []

    for url in urls:
        if url in existing_pages:
            continue
        path = url.split('storegoias.com.br/')[1]
        html = curl('https://web.archive.org/web/2025id_/' + url)
        mt = re.search(r'og:title" content="([^"]+)', html)
        mp = re.search(r'"price":"([0-9.]+)"', html)
        if not (mt and mp):
            skipped.append((path, 'sem nome/preço')); continue
        gallery = find_gallery(html, path.split('/')[-1])
        if not gallery:
            skipped.append((path, 'galeria não confirmada')); continue
        name = re.split(r' - Goi| \? |\|', mt.group(1))[0].strip()
        price = float(mp.group(1))
        audience, aud_cat, uni, ptype, cats, colls, slug = derive(path)
        pid = slug_to_id(slug, existing_ids)
        existing_ids.add(pid)
        folder = os.path.join(IMG_BASE, pid)
        os.makedirs(folder, exist_ok=True)
        local, first = [], None
        for i, u in enumerate(gallery):
            ext = u.rsplit('.', 1)[1]
            fn = NAMES[i] if i < len(NAMES) else f'detail_{i:02d}'
            curl(u, os.path.join(folder, f'{fn}.{ext}'))
            rel = f'lib/assets/store/products/{pid}/{fn}.{ext}'
            local.append(rel)
            first = first or rel
        szs = sizes_for(path, html, ptype)
        variations = [{'sku': f'{pid}-{s}', 'size': s, 'stock': STOCKS[i % len(STOCKS)]}
                      for i, s in enumerate(szs)] or [{'sku': f'{pid}-unico', 'size': 'ÚNICO', 'stock': 15}]
        products.append({
            'id': pid, 'slug': slug, 'name': name,
            'shortDescription': name, 'description': f'{name}. Produto oficial licenciado do Goiás Esporte Clube.',
            'brand': 'Diadora' if ptype in ('matchJersey', 'training') else 'Goiás',
            'reference': '', 'categories': cats, 'collections': colls,
            'audience': audience, 'productType': ptype, 'uniformNumber': uni,
            'price': price, 'originalPrice': None, 'installments': installments(price),
            'images': local, 'thumbnail': first, 'variations': variations,
            'isFeatured': False, 'isNew': False, 'personalizationOptions': None,
            'relatedProductIds': [], 'specifications': [], 'sourceUrl': url,
        })
        sources[pid] = {'productPage': url, 'originalImages': gallery,
                        'retrievedAt': '2026-08-28', 'catalogMode': 'mock', 'note': NOTE}
        added.append((pid, name, price, len(gallery), ptype))

    json.dump(products, open(PROD_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    json.dump(sources, open(SRC_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)

    # pubspec: insere as pastas novas antes da linha de promo
    lines = open(PUBSPEC, encoding='utf-8').read().splitlines()
    present = set('/'.join(l.strip().lstrip('- ').split('/')[:5]) for l in lines if 'store/products/' in l)
    promo_i = next(i for i, l in enumerate(lines) if 'store/promo/' in l)
    new_lines = [f'    - lib/assets/store/products/{pid}/' for pid, *_ in added
                 if f'lib/assets/store/products/{pid}' not in present]
    lines[promo_i:promo_i] = new_lines
    open(PUBSPEC, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')

    print(f'ADICIONADOS: {len(added)}')
    for pid, name, price, n, tp in added:
        print(f'  + {pid} | {name[:42]} | R$ {price} | {n}f | {tp}')
    print(f'PULADOS: {len(skipped)}')
    for path, why in skipped:
        print(f'  - {path[:60]}: {why}')


if __name__ == '__main__':
    main()
