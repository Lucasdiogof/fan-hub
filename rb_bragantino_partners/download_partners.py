from pathlib import Path
from urllib.request import Request, urlopen

OUT = Path("assets/partners")
OUT.mkdir(parents=True, exist_ok=True)

ITEMS = [
    ('puma', 'https://img.redbullbragantino.com/images/2026/2/4/dfcsflqaf3nupklqk7za/puma'),
    ('asaas', 'https://img.redbullbragantino.com/images/2026/4/9/sttqoyvrxewigmndoxxy/asaas'),
    ('nd', 'https://img.redbullbragantino.com/images/2026/2/4/flm5lta2ql7lniqjsxd5/nd'),
    ('curaprox', 'https://img.redbullbragantino.com/images/2026/2/4/cvawo7k4nqnd6wrajurj/curaprox'),
    ('knn-idiomas', 'https://img.redbullbragantino.com/images/2026/8/25/qcxkkbhx3bz2dkfyygaf/knn-idiomas'),
    ('peluso-sperandio', 'https://img.redbullbragantino.com/images/2026/2/4/b3blwskeo5ad98lxhiab/peluso-sperandio'),
    ('convem', 'https://img.redbullbragantino.com/images/2026/7/22/bnmf27esnngescqkmlvd/convem-supermercados'),
    ('unimed', 'https://img.redbullbragantino.com/images/2026/3/30/lgzporikoavbq9pbe4vg/unimed'),
    ('unimagem', 'https://img.redbullbragantino.com/images/2026/3/30/ygvizkcuntvlsk59p6t9/unimagem'),
    ('humanitarian', 'https://img.redbullbragantino.com/images/2026/3/30/spfw4zi4aqppc7cdqdy0/humanitarian'),
    ('lo-sardo', 'https://img.redbullbragantino.com/images/2026/3/30/lrbcketb3okuz4rn2pli/lo-sardo'),
    ('colegio-populus', 'https://img.redbullbragantino.com/images/2026/2/4/adcn0uoz3xz3dd3kl3pn/colegio-populus'),
    ('ecobier', 'https://img.redbullbragantino.com/images/2026/3/19/ibpr9rgycnvofmrzgdta/ecobier-logo'),
    ('cpjoia', 'https://img.redbullbragantino.com/images/2026/2/4/rssbn35q1kpdfm97t3gb/cpjoia'),
    ('campus-live', 'https://img.redbullbragantino.com/images/2026/2/4/amwid1dfbyxbqwsj1qix/campus-live'),
    ('meu-ingles-sob-medida', 'https://img.redbullbragantino.com/images/2026/2/4/uhguugeltbzukv5vkc8z/meu-ingles-sob-medida'),
    ('trendx', 'https://img.redbullbragantino.com/images/2026/7/22/rhtmhvkd2hjtuzdvhzat/logo-trendx'),
]

ok = 0
for slug, url in ITEMS:
    print(f"Baixando {slug}...", end=" ", flush=True)
    try:
        req = Request(
            url,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept": "image/png,image/*;q=0.9,*/*;q=0.8",
            },
        )
        with urlopen(req, timeout=30) as r:
            data = r.read()
            content_type = r.headers.get_content_type()
        (OUT / f"{slug}.png").write_bytes(data)
        print(f"OK ({len(data)} bytes, {content_type})")
        ok += 1
    except Exception as e:
        print(f"ERRO: {e}")

print(f"\nConcluído: {ok}/{len(ITEMS)} logos em {OUT}")
raise SystemExit(0 if ok == len(ITEMS) else 1)
