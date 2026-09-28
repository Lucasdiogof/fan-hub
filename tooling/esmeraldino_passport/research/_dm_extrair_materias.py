"""Extrai candidatos de estádio a partir das MATÉRIAS pós-jogo do Diário da Manhã (quando não há ficha técnica).

Procura, na edição D+1 (ou D+2) do jogo, um trecho de até ~400 caracteres que contenha:
  - "Goiás" e o nome do adversário,
  - o placar do jogo ("2 a 1", "2x1", "2 x 1", em qualquer ordem dos números),
  - o nome de um estádio conhecido (lista abaixo) ou "estádio <Nome>".
Sem outro jogo do Goiás entre o jogo e a edição. Saída = candidatos para REVISÃO HUMANA (nada é aplicado aqui).

Uso: python _dm_extrair_materias.py <checkpoint.csv> <pasta_txt> <saida.json>
"""
import csv, json, os, re, sys, datetime, unicodedata

ck, txtdir, out = sys.argv[1:4]
MIN_SEASON = int(sys.argv[4]) if len(sys.argv) > 4 else 1980   # 5º arg opcional: temporada mínima
MAXK = int(sys.argv[5]) if len(sys.argv) > 5 else 3              # 6º arg opcional: até D+MAXK

def fold1(c):
    f = unicodedata.normalize('NFKD', c).encode('ascii', 'ignore').decode()
    return (f[:1] or ' ').upper()

def fold(s):
    return ''.join(fold1(c) for c in s)

STADIUMS = ['SERRA DOURADA', 'SERRINHA', 'OLIMPICO', 'PEDRO LUDOVICO', 'ANTONIO ACCIOLY', 'ACCIOLY', 'JONAS DUARTE',
            'MANOEL DEMOSTENES', 'DIVINO GARCIA ROSA', 'GENERVINO', 'JK', 'JUSCELINO KUBITSCHEK', 'MOZART VELOSO', 'ODILON FLORES',
            'PEDRO ROMUALDO', 'ZICO BRANDAO', 'JOAO VILELA', 'DURVAL FERREIRA', 'BICHINHO VIEIRA', 'JERONIMO FRAGA', 'ARAPUCAO',
            'SERRA DO LAGO', 'JOSE DE DEUS', 'VALDEIR', 'ONESIO', 'OBA', 'SERRA DE CALDAS', 'EDSON MONTEIRO', 'HAILE PINHEIRO',
            'ANIBAL BATISTA', 'ABRAO MANOEL', 'NAZARENO', 'PLINIO JOSE']
# sem \b: o OCR cola palavras ("noSerra Dourada"); variantes comuns de OCR incluídas
STX = [re.escape(x).replace(r'\ ', r'\s*') for x in STADIUMS if x not in ('JK', 'OBA')]
STX += [r'SER{1,2}A\s*DOURAD[AO]', r'SENA\s*DOURAD[AO]', r'SER{1,2}[IJ]NHA', r'OL[IL]MPICO', r'\bJK\b']
ST = re.compile('(' + '|'.join(STX) + ')')

rows = list(csv.DictReader(open(ck, encoding='utf-8-sig')))
hist = [r for r in rows if r['dataset_origin'] == 'historical_futebol80' and r['effective_date']]
dates_all = sorted(datetime.date.fromisoformat(r['effective_date']) for r in hist)
GOI = re.compile(r'GO[I1L]\s?-?\s?AS|ESMERALDIN|ALVIVERDE|VERDAO|PERIQUITO')

def opp_names(opp):
    base = fold(re.sub(r'-[A-Z]{2}$', '', opp.strip()))
    names = {base}
    alias = {'AMERICA DE MORRINHOS': 'AMERICA', 'IPIRANGA DE ANAPOLIS': 'IPIRANGA', 'NACIONAL DE ITUMBIARA': 'NACIONAL',
             'OPERARIO DE CAMPO GRANDE': 'OPERARIO', 'OPERARIO DE VARZEA GRANDE': 'OPERARIO', 'SAO LUIS/SLMB': 'SAO LUIS',
             'BOTAFOGO DE BURITI ALEGRE': 'BOTAFOGO', 'CRAC': 'CRAC', 'ATLETICO': 'ATLETICO'}
    if base in alias:
        names.add(alias[base])
    if base == 'ATLETICO':
        names.add('DRAGAO')
    if base == 'VILA NOVA':
        names.add('TIGRE')
    return [re.compile(re.escape(n).replace(r'\ ', r'\s*')) for n in names]

res = []
for r in hist:
    if r['venue_name'] != 'UNKNOWN' or int(r['season']) < MIN_SEASON:
        continue
    D = datetime.date.fromisoformat(r['effective_date'])
    gs, os_ = int(float(r['goias_score'])), int(float(r['opponent_score']))
    SC = re.compile(r'(?<!\d)(%d\s*(?:A|X)\s*%d|%d\s*(?:A|X)\s*%d)(?!\d)' % (gs, os_, os_, gs))
    OPPS = opp_names(r['opponent'])
    for k in range(1, MAXK + 1):
        E = D + datetime.timedelta(days=k)
        if any(D < x <= E for x in dates_all):
            break
        f = os.path.join(txtdir, E.isoformat() + '.txt')
        if not os.path.exists(f):
            continue
        t = open(f, encoding='utf-8').read()
        T = fold(t)
        cands = []
        for m in ST.finditer(T):
            a, b = max(0, m.start() - 420), m.end() + 420
            w = T[a:b]
            if GOI.search(w) and SC.search(w) and any(o.search(w) for o in OPPS):
                pg = t.rfind('=====PAGE', 0, m.start())
                page = re.match(r'=====PAGE (\d+)', t[pg:pg + 20]).group(1) if pg >= 0 else '?'
                cands.append(dict(stadium=m.group(1), page=page, snippet=re.sub(r'\s+', ' ', t[a:b])))
        su = {re.sub(r'\s+', ' ', c['stadium']): c for c in cands}
        if su:
            res.append(dict(id=r['id'], date=r['effective_date'], opponent=r['opponent'], score=r['score_display'],
                            edition=E.isoformat(), stadiums=sorted(su), hits=[dict(stadium=k2, page=v['page'], snippet=v['snippet']) for k2, v in su.items()]))
            break
json.dump(res, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('candidatos', len(res), 'com 1 estadio', sum(len(x['stadiums']) == 1 for x in res))
