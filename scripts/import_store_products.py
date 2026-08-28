"""Importa produtos oficiais da Goiás Store a partir de snapshots arquivados
(web.archive.org) — a loja ao vivo esvaziou. Para cada produto: baixa o HTML
arquivado, extrai nome/preço/galeria do CDN da Tray, baixa as fotos localmente
e monta a entrada do catálogo. Só entra produto com nome + preço + foto.

Uso: python scripts/import_store_products.py
"""
import json, re, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROD_JSON = os.path.join(ROOT, 'lib/assets/content/store_products.json')
SRC_JSON = os.path.join(ROOT, 'lib/assets/store/products/sources.json')
IMG_BASE = os.path.join(ROOT, 'lib/assets/store/products')
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'

# (id, url_path, audience, uniformNumber|None, collections, is_goalkeeper)
PRODUCTS = [
    ('uniform_01_male_fan', 'masculino/uniforme-de-jogo/uniforme-01/camisa-goias-uniforme-01-masculina-fan-2025', 'masculine', '01', ['kit_01', 'fan'], False),
    ('uniform_02_male_fan', 'masculino/uniforme-de-jogo/uniforme-02/camisa-goias-uniforme-02-masculina-fan-2025', 'masculine', '02', ['kit_02', 'fan'], False),
    ('uniform_01_female_player', 'feminino/uniforme-de-jogo/uniforme-01/camisa-goias-uniforme-01-feminina-squadra-2025', 'feminine', '01', ['kit_01', 'player'], False),
    ('uniform_02_female_player', 'feminino/uniforme-de-jogo/uniforme-02/camisa-goias-uniforme-02-feminina-squadra-2025', 'feminine', '02', ['kit_02', 'player'], False),
    ('uniform_03_female', 'feminino/uniforme-de-jogo/uniforme-03/camisa-uniforme-03-goias-feminino', 'feminine', '03', ['kit_03'], False),
    ('uniform_01_kids_fan', 'infanto-juvenil/uniforme-de-jogo/uniforme-01/camisa-goias-uniforme-01-infantil-fan-2025', 'kids', '01', ['kit_01', 'fan'], False),
    ('uniform_01_kids_player', 'infanto-juvenil/uniforme-de-jogo/uniforme-01/camisa-goias-uniforme-01-infantil-squadra-2025', 'kids', '01', ['kit_01', 'player'], False),
    ('uniform_01_youth_fan', 'infanto-juvenil/uniforme-de-jogo/uniforme-01/camisa-goias-uniforme-01-juvenil-fan-2025', 'kids', '01', ['kit_01', 'fan'], False),
    ('uniform_01_youth_player', 'infanto-juvenil/uniforme-de-jogo/uniforme-01/camisa-goias-uniforme-01-juvenil-squadra-2025', 'kids', '01', ['kit_01', 'player'], False),
    ('uniform_02_kids_player', 'infanto-juvenil/uniforme-de-jogo/uniforme-02/camisa-goias-uniforme-02-infantil-squadra-2025', 'kids', '02', ['kit_02', 'player'], False),
    ('goalkeeper_01_male_player', 'masculino/goleiro/uniforme-01/camisa-goias-uniforme-01-goleiro-jogador-masculina-2025', 'masculine', '01', ['goalkeeper', 'kit_01', 'player'], True),
    ('goalkeeper_02_male_player', 'masculino/goleiro/uniforme-02/camisa-goias-uniforme-02-goleiro-jogador-masculina-2025', 'masculine', '02', ['goalkeeper', 'kit_02', 'player'], True),
    ('goalkeeper_03_male_player', 'masculino/goleiro/uniforme-03/camisa-goias-uniforme-03-goleiro-jogador-masculina-2025', 'masculine', '03', ['goalkeeper', 'kit_03', 'player'], True),
    ('goalkeeper_01_female_fan', 'feminino/goleiro/uniforme-01/camisa-goias-uniforme-01-goleiro-torcedor-feminina-2025', 'feminine', '01', ['goalkeeper', 'kit_01', 'fan'], True),
    ('goalkeeper_02_female_player', 'feminino/goleiro/uniforme-02/camisa-goias-uniforme-02-goleiro-jogador-feminina-2025', 'feminine', '02', ['goalkeeper', 'kit_02', 'player'], True),
    ('goalkeeper_01_kids_player', 'infanto-juvenil/goleiro/uniforme-01/camisa-goias-uniforme-01-goleiro-infantil-jogador-2025', 'kids', '01', ['goalkeeper', 'kit_01', 'player'], True),
    ('goalkeeper_01_youth_player', 'infanto-juvenil/goleiro/uniforme-01/camisa-goias-uniforme-01-goleiro-juvenil-jogador-2025', 'kids', '01', ['goalkeeper', 'kit_01', 'player'], True),
    ('goalkeeper_01_youth_fan', 'infanto-juvenil/goleiro/uniforme-01/camisa-uniforme-01-goleiro-torcedor-juvenil-2025', 'kids', '01', ['goalkeeper', 'kit_01', 'fan'], True),
    ('goalkeeper_02_youth_player', 'infanto-juvenil/goleiro/uniforme-02/camisa-goias-uniforme-02-goleiro-jogador-juvenil-2025', 'kids', '02', ['goalkeeper', 'kit_02', 'player'], True),
]

STOCKS = [9, 12, 10, 6, 4, 3, 8, 5]


def curl(url, out=None):
    args = ['curl', '-sL', '-A', UA, url]
    if out:
        args += ['-o', out]
        subprocess.run(args, check=False)
        return None
    return subprocess.run(args, capture_output=True).stdout.decode('utf-8', 'ignore')


def sizes_for(slug, html):
    toks = set(re.findall(r'"(P|M|G|GG|3G|2|4|6|8|10|12|14|16)"', html))
    if 'infantil' in slug:
        allowed = ['2', '4', '6', '8', '10', '12']
    elif 'juvenil' in slug:
        allowed = ['10', '12', '14', '16']
    else:
        allowed = ['P', 'M', 'G', 'GG', '3G']
    return [s for s in allowed if s in toks]


def installments(price):
    return 4 if price >= 400 else (3 if price >= 300 else (2 if price >= 150 else 1))


def main():
    products = json.load(open(PROD_JSON, encoding='utf-8'))
    sources = json.load(open(SRC_JSON, encoding='utf-8'))
    existing = {p['id'] for p in products}
    report = {'added': [], 'skipped': []}
    note = ("Fotos oficiais recuperadas de snapshot arquivado (web.archive.org) da "
            "página do produto — a loja ao vivo passou a redirecionar pra \"Nenhum "
            "produto encontrado\". URLs originais do CDN da Tray (images.tcdn.com.br) "
            "baixadas uma vez em tempo de preparo de conteúdo; nunca carregadas "
            "remotamente em runtime. Preço confirmado no snapshot.")

    for pid, path, audience, uni, colls, is_gk in PRODUCTS:
        if pid in existing:
            report['skipped'].append((pid, 'já existe'))
            continue
        url = 'https://www.storegoias.com.br/' + path
        html = curl('https://web.archive.org/web/2025id_/' + url)
        m_title = re.search(r'og:title" content="([^"]+)', html)
        m_price = re.search(r'"price":"([0-9.]+)"', html)
        m_og = re.search(r'og:image" content="(https://images\.tcdn\.com\.br/[^"]+)', html)
        if not (m_title and m_price and m_og):
            report['skipped'].append((pid, 'sem nome/preço/foto no snapshot'))
            continue
        name = m_title.group(1).split(' - Goi')[0].split(' ? ')[0].strip()
        price = float(m_price.group(1))
        prefix = re.sub(r'_[0-9]+_[a-f0-9]{20,}\.[a-z]+$', '', m_og.group(1).split('/1398192/')[1])
        imgs = sorted(set(re.findall(
            r'https://images\.tcdn\.com\.br/img/img_prod/1398192/' + re.escape(prefix) + r'_[0-9]+_[a-f0-9]+\.(?:jpg|png|webp)', html)))
        imgs = [u for u in imgs if not re.search(r'/(?:90|180|250|400|600)_', u)]
        if not imgs:
            report['skipped'].append((pid, 'galeria não localizada'))
            continue
        folder = os.path.join(IMG_BASE, pid)
        os.makedirs(folder, exist_ok=True)
        names = ['front', 'back', 'detail_01', 'detail_02', 'detail_03', 'detail_04', 'detail_05']
        local, first = [], None
        for i, u in enumerate(imgs):
            ext = u.rsplit('.', 1)[1]
            fn = names[i] if i < len(names) else f'detail_{i:02d}'
            curl(u, os.path.join(folder, f'{fn}.{ext}'))
            rel = f'lib/assets/store/products/{pid}/{fn}.{ext}'
            local.append(rel)
            if first is None:
                first = rel
        szs = sizes_for(path, html)
        variations = [{'sku': f'{pid}-{s}', 'size': s, 'stock': STOCKS[i % len(STOCKS)]}
                      for i, s in enumerate(szs)] or [{'sku': f'{pid}-unico', 'size': 'ÚNICO', 'stock': 12}]
        model = 'jogador' if 'player' in colls else ('torcedor' if 'fan' in colls else 'oficial')
        aud_pt = {'masculine': 'masculina', 'feminine': 'feminina', 'kids': 'infanto-juvenil'}[audience]
        gk = 'de goleiro ' if is_gk else ''
        products.append({
            'id': pid, 'slug': path.rsplit('/', 1)[1], 'name': name,
            'shortDescription': f'Uniforme {uni} {gk}2025, modelagem {model} {aud_pt}, Diadora.'.replace('  ', ' '),
            'description': f'Camisa oficial {gk}do Goiás Esporte Clube, uniforme {uni} da temporada 2025, na modelagem {model}. Produto oficial licenciado, marca Diadora.',
            'brand': 'Diadora', 'reference': '',
            'categories': ['uniforms', {'masculine': 'masculine', 'feminine': 'feminine', 'kids': 'kids'}[audience]],
            'collections': colls, 'audience': audience, 'productType': 'matchJersey',
            'uniformNumber': uni, 'price': price, 'originalPrice': None,
            'installments': installments(price), 'images': local, 'thumbnail': first,
            'variations': variations, 'isFeatured': False, 'isNew': False,
            'personalizationOptions': None, 'relatedProductIds': [],
            'specifications': [{'label': 'Marca', 'value': 'Diadora'}], 'sourceUrl': url,
        })
        sources[pid] = {'productPage': url, 'originalImages': imgs,
                        'retrievedAt': '2026-08-28', 'catalogMode': 'mock', 'note': note}
        report['added'].append((pid, name, price, len(imgs)))

    json.dump(products, open(PROD_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    json.dump(sources, open(SRC_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f'ADICIONADOS: {len(report["added"])}')
    for pid, name, price, n in report['added']:
        print(f'  + {pid} | {name} | R$ {price} | {n} fotos')
    print(f'PULADOS: {len(report["skipped"])}')
    for pid, why in report['skipped']:
        print(f'  - {pid}: {why}')
    print('\nPUBSPEC folders:')
    for pid, *_ in report['added']:
        print(f'    - lib/assets/store/products/{pid}/')


if __name__ == '__main__':
    main()
