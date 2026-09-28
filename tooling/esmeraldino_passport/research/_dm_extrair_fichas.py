"""Extrai o local de jogos pendentes a partir das fichas técnicas do Diário da Manhã (Hemeroteca IHGG).

Entrada: checkpoint CSV + pasta com o texto (PyMuPDF) das edições, um arquivo AAAA-MM-DD.txt por edição
(gerado baixando https://hemeroteca.ihgg.org/publicacoes/DIARIO_DA_MANHA/AAAA/MM/DIARIO_DA_MANHA_AAAA_MM_DD.pdf).

Regra de casamento (conservadora):
  - edição do dia seguinte (D+1) ou de dois dias depois (D+2) ao jogo;
  - ficha técnica com "LOCAL:" e, a no máximo ~900 caracteres, o rótulo de escalação do Goiás ("GOIÁS:")
    E o rótulo de escalação do adversário daquele jogo ("<ADVERSÁRIO>:");
  - exatamente UMA ficha assim na edição para aquele adversário;
  - sem outro jogo do Goiás no dataset entre o jogo e a edição (senão a ficha pode ser de outro jogo).
Saída: JSON de candidatos (id, edição, estádio bruto, trecho) para revisão humana antes de aplicar.

Uso: python _dm_extrair_fichas.py <checkpoint.csv> <pasta_txt> <saida.json>
"""
import csv, json, os, re, sys, datetime, unicodedata

ck, txtdir, out = sys.argv[1:4]

def fold1(c):
    f = unicodedata.normalize('NFKD', c).encode('ascii', 'ignore').decode()
    return (f[:1] or ' ').upper()

def fold(s):
    # mesmo comprimento do original (1 caractere -> 1 caractere), para os índices baterem com o texto bruto
    return ''.join(fold1(c) for c in s)

def label_regex(name):
    # tolera espaços/ruído de OCR entre letras: "GOI AS", "GO!AS"
    letters = [c for c in fold(name) if c.isalnum() or c == ' ']
    parts = []
    for c in letters:
        parts.append(r'\s+' if c == ' ' else re.escape(c) + r'[\s!\.]?')
    return re.compile(''.join(parts) + r'\s*[:;]')

ALIAS = {  # nome no CSV (sem -UF) -> como o jornal rotula a escalação
    'America de Morrinhos': 'America', 'Ipiranga de Anapolis': 'Ipiranga', 'Nacional de Itumbiara': 'Nacional',
    'Atletico': 'Atletico', 'Sao Luis/SLMB': 'Sao Luis', 'Botafogo de Buriti Alegre': 'Botafogo',
    'Operario de Campo Grande': 'Operario', 'Operario de Varzea Grande': 'Operario', 'Gremio Maringa': 'Gremio Maringa',
    'Campinas Esporte Clube': 'Campinas', 'Santa Helena': 'Santa Helena', 'Novo Horizonte': 'Novo Horizonte',
}

def opp_label(opp):
    base = re.sub(r'-[A-Z]{2}$', '', opp.strip())
    b = fold(base).title()
    for k, v in ALIAS.items():
        if fold(k) == fold(base):
            return v
    return base

rows = list(csv.DictReader(open(ck, encoding='utf-8-sig')))
hist = [r for r in rows if r['dataset_origin'] == 'historical_futebol80' and r['effective_date']]
dates_all = sorted(datetime.date.fromisoformat(r['effective_date']) for r in hist)
GOIAS = label_regex('Goias')
GOIAS_ANY = re.compile(r'G\s?O\s?I\s?-?\s?A\s?S\b')
LOCAL = re.compile(r'L\s?O\s?C\s?A\s?L\s*[:;]\s*([^\.\n]{2,60}(?:\n[^\.\n]{0,40})?)', re.I)

res = []
for r in hist:
    if r['venue_name'] != 'UNKNOWN' or int(r['season']) < 1980:
        continue
    D = datetime.date.fromisoformat(r['effective_date'])
    opp = opp_label(r['opponent'])
    OPP = label_regex(opp)
    OPP_ANY = re.compile(r'\b' + r'\s?'.join(re.escape(c) for c in fold(opp).replace(' ', '')) + r'\b')
    for k in (1, 2):
        E = D + datetime.timedelta(days=k)
        # outro jogo do Goiás entre D (exclusive) e E (inclusive)? então a ficha é ambígua
        if any(D < x <= E for x in dates_all):
            break
        f = os.path.join(txtdir, E.isoformat() + '.txt')
        if not os.path.exists(f):
            continue
        t = open(f, encoding='utf-8').read()
        T = fold(t)
        # 1) Caminho forte: linha "Jogo: A n x m B" com Goiás, o adversário e o placar exato; o "Local:" vem logo depois.
        gs, os_ = int(float(r['goias_score'])), int(float(r['opponent_score']))
        strong = []
        for jm in re.finditer(r'J\s?O\s?G\s?O\s*[:;]\s*(.{5,80}?)\s*[\.;]?\s*L\s?O\s?C\s?A\s?L\s*[:;]\s*([^\n]{2,90}?)(?=\s*[\.;]\s*[A-ZÀ-Ý][a-zà-ý]{2,}|\s*\.\s*A\s?R|$)', T, re.S):
            jogo = jm.group(1)
            sc = re.search(r'(\d)\s*[X]\s*[\'"‘’`]?(\d)', jogo)
            if not sc or not GOIAS_ANY.search(jogo) or not OPP_ANY.search(jogo):
                continue
            a, b = int(sc.group(1)), int(sc.group(2))
            left = jogo[:sc.start()]
            goias_first = GOIAS_ANY.search(left) is not None
            ga, oa = (a, b) if goias_first else (b, a)
            if (ga, oa) != (gs, os_):
                continue
            raw = t[jm.start(2):jm.end(2)]
            pg = t.rfind('=====PAGE', 0, jm.start())
            page = re.match(r'=====PAGE (\d+)', t[pg:pg + 20]).group(1) if pg >= 0 else '?'
            strong.append(dict(venue=re.sub(r'\s+', ' ', raw).strip(' .;,'), page=page, jogo=re.sub(r'\s+', ' ', t[jm.start(1):jm.end(1)]),
                               snippet=re.sub(r'\s+', ' ', t[max(0, jm.start() - 120): jm.end() + 250])))
        su = {s['venue'].upper(): s for s in strong}
        if len(su) == 1:
            s = list(su.values())[0]
            res.append(dict(id=r['id'], date=r['effective_date'], opponent=r['opponent'], score=r['score_display'], label=opp,
                            edition=E.isoformat(), page=s['page'], venue_raw=s['venue'], method='JOGO+PLACAR', jogo=s['jogo'], snippet=s['snippet']))
            break
        hits = []
        for m in LOCAL.finditer(T):
            win = T[max(0, m.start() - 900): m.end() + 900]
            if GOIAS.search(win) and OPP.search(win):
                raw = t[m.start(1):m.end(1)]
                venue = re.sub(r'\s+', ' ', raw).strip(' .;,')
                pg = t.rfind('=====PAGE', 0, m.start())
                page = re.match(r'=====PAGE (\d+)', t[pg:pg + 20]).group(1) if pg >= 0 else '?'
                hits.append(dict(venue=venue, page=page, snippet=re.sub(r'\s+', ' ', t[max(0, m.start() - 250): m.end() + 450])))
        # remove duplicatas da mesma ficha (LOCAL repetido pelo OCR)
        uniq = {h['venue'].upper(): h for h in hits}
        if len(uniq) == 1:
            h = list(uniq.values())[0]
            res.append(dict(id=r['id'], date=r['effective_date'], opponent=r['opponent'], score=r['score_display'],
                            label=opp, edition=E.isoformat(), page=h['page'], venue_raw=h['venue'], method='ESCALACOES', jogo='', snippet=h['snippet']))
            break
        elif len(uniq) > 1:
            res.append(dict(id=r['id'], date=r['effective_date'], opponent=r['opponent'], score=r['score_display'],
                            label=opp, edition=E.isoformat(), page='?', venue_raw='AMBIGUO: ' + ' | '.join(uniq), method='AMBIGUO', jogo='', snippet=''))
            break
json.dump(res, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('candidatos', len(res), 'ambiguos', sum(x['venue_raw'].startswith('AMBIGUO') for x in res))
