import csv, collections, re, unicodedata, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
import glob
CK = max(glob.glob('passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_*.csv'), key=lambda f: int(re.search(r'_(\d+)\.csv$', f).group(1)))
rows = list(csv.DictReader(open(CK, encoding='utf-8-sig')))

def n(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower()
    return re.sub(r' +', ' ', re.sub(r'[^a-z0-9 ]', ' ', s)).strip()

# canonical_id: (canonical_name, canonical_city, [aliases as they appear raw])
C = {
 'go-olimpico': ('Estádio Olímpico Pedro Ludovico Teixeira', 'Goiânia', ['Olímpico', 'Pedro Ludovico', 'Estádio Olímpico Pedro Ludovico Teixeira', 'Estádio da Avenida Paranaíba', 'Estádio Dr. Pedro Ludovico', 'Estádio Oficial Pedro Ludovico']),
 'go-accioly': ('Estádio Antônio Accioly', 'Goiânia', ['Antônio Accioly', 'Estádio Antônio Accioly']),
 'go-serra-dourada': ('Estádio Serra Dourada', 'Goiânia', ['Serra Dourada', 'Estádio Serra Dourada']),
 'go-serrinha': ('Estádio Hailé Pinheiro (Serrinha)', 'Goiânia', ['Serrinha', 'Hailé Pinheiro', 'Estádio Hailé Pinheiro (Serrinha)']),
 'go-jonas-duarte': ('Estádio Jonas Duarte', 'Anápolis', ['Jonas Duarte', 'Estádio Jonas Duarte']),
 'go-genervino': ('Estádio Genervino da Fonseca', 'Catalão', ['Genervino da Fonseca', 'Estádio Genervino da Fonseca']),
 'go-divino-garcia': ('Estádio Divino Garcia Rosa', 'Goiatuba', ['Divino Garcia Rosa', 'Estádio Divino Garcia Rosa']),
 'go-jk-itumbiara': ('Estádio Municipal Juscelino Kubitschek', 'Itumbiara', ['JK', 'Estádio Municipal Juscelino Kubitschek']),
 'go-zico-brandao': ('Estádio Zico Brandão', 'Inhumas', ['Zico Brandão', 'Estádio Zico Brandão']),
 'go-mozart-veloso': ('Estádio Mozart Veloso do Carmo', 'Rio Verde', ['Mozart Veloso do Carmo', 'Estádio Mozart Veloso do Carmo']),
 'go-joao-vilela': ('Estádio João Vilela', 'Morrinhos', ['Estádio João Vilela', 'Centro Esportivo João Vilela']),
 'go-odilon-flores': ('Estádio Odilon Flores', 'Mineiros', ['Odilon Flores', 'Estádio Odilon Flores']),
 'go-pedro-romualdo': ('Estádio Pedro Romualdo Cabral', 'Santa Helena de Goiás', ['Pedro Romualdo Cabral', 'Estádio Pedro Romualdo Cabral']),
 'go-valdeir': ('Estádio Valdeir José de Oliveira', 'Goianésia', ['Valdeir José de Oliveira', 'Estádio Valdeir José de Oliveira']),
 'go-jeronimo-fraga': ('Estádio Jerônimo Fraga', 'Jataí', ['Jerônimo Fraga']),
 'rj-maracana': ('Estádio Jornalista Mário Filho (Maracanã)', 'Rio de Janeiro', ['Maracanã', 'Estádio Jornalista Mário Filho (Maracanã)']),
 'rj-sao-januario': ('Estádio Vasco da Gama (São Januário)', 'Rio de Janeiro', ['São Januário', 'Estádio Vasco da Gama (São Januário)']),
 'rj-nilton-santos': ('Estádio Olímpico Nilton Santos (Engenhão)', 'Rio de Janeiro', ['Nilton Santos', 'Engenhão', 'Estádio Olímpico Nilton Santos']),
 'rj-caio-martins': ('Estádio Caio Martins', 'Niterói', ['Caio Martins']),
 'rj-raulino': ('Estádio General Sylvio Raulino de Oliveira', 'Volta Redonda', ['Estádio Raulino de Oliveira', 'Estádio General Sylvio Raulino de Oliveira (Estádio da Cidadania)']),
 'sp-morumbi': ('Estádio Cícero Pompeu de Toledo (Morumbi)', 'São Paulo', ['Morumbi', 'Estádio Cícero Pompeu de Toledo (Morumbi)']),
 'sp-pacaembu': ('Estádio Municipal Paulo Machado de Carvalho (Pacaembu)', 'São Paulo', ['Pacaembu', 'Estádio Municipal Paulo Machado de Carvalho (Pacaembu)']),
 'sp-palestra': ('Estádio Palestra Itália (Parque Antártica)', 'São Paulo', ['Parque Antárctica', 'Parque Antártica', 'Estádio Palestra Itália (Parque Antártica)']),
 'sp-allianz': ('Allianz Parque', 'São Paulo', ['Allianz Parque']),  # decisão do usuário 2026-09-28: NÃO é o mesmo estádio do Palestra Itália
 'sp-caninde': ('Estádio Doutor Oswaldo Teixeira Duarte (Canindé)', 'São Paulo', ['Canindé', 'Estádio Doutor Oswaldo Teixeira Duarte (Canindé)']),
 'sp-arena-corinthians': ('Neo Química Arena', 'São Paulo', ['Arena Corinthians', 'Neo Química Arena']),
 'sp-vila-belmiro': ('Estádio Urbano Caldeira (Vila Belmiro)', 'Santos', ['Vila Belmiro', 'Estádio Urbano Caldeira (Vila Belmiro)']),
 'sp-brinco': ('Estádio Brinco de Ouro da Princesa', 'Campinas', ['Brinco de Ouro', 'Estádio Brinco de Ouro da Princesa']),
 'sp-moises-lucarelli': ('Estádio Moisés Lucarelli', 'Campinas', ['Moisés Lucarelli', 'Estádio Moisés Lucarelli']),
 'sp-nabi': ('Estádio Nabi Abi Chedid', 'Bragança Paulista', ['Nabi Abi Chedid', 'Estádio Nabi Abi Chedid', 'Marcelo Stéfani']),
 'sp-novelli': ('Estádio Municipal Doutor Novelli Júnior', 'Itu', ['Estádio Novelli Júnior', 'Estádio Municipal Doutor Novelli Júnior']),
 'sp-santa-cruz-rp': ('Estádio Santa Cruz', 'Ribeirão Preto', ['Santa Cruz', 'Estádio Santa Cruz', 'Arena Nicnet (Santa Cruz)']),
 'sp-martins-pereira': ('Estádio Martins Pereira', 'São José dos Campos', ['Martins Pereira', 'Estádio Martins Pereira']),
 'mg-mineirao': ('Estádio Governador Magalhães Pinto (Mineirão)', 'Belo Horizonte', ['Mineirão', 'Estádio Governador Magalhães Pinto (Mineirão)']),
 'mg-independencia': ('Estádio Raimundo Sampaio (Independência)', 'Belo Horizonte', ['Independência', 'Estádio Raimundo Sampaio (Independência)']),
 'mg-ipatingao': ('Ipatingão', 'Ipatinga', ['Estádio Municipal Epaminondas Mendes Brito (Ipatingão)', 'Estádio Municipal João Lamego Netto (Ipatingão)']),
 'mg-arena-sicredi': ('Arena Sicredi', 'São João del-Rei', ['Arena Sicredi']),
 'rs-beira-rio': ('Estádio José Pinheiro Borda (Beira-Rio)', 'Porto Alegre', ['Beira-Rio', 'Estádio José Pinheiro Borda (Beira-Rio)']),
 'rs-olimpico-monumental': ('Estádio Olímpico Monumental', 'Porto Alegre', ['Olímpico Monumental', 'Estádio Olímpico Monumental']),
 'rs-jaconi': ('Estádio Alfredo Jaconi', 'Caxias do Sul', ['Alfredo Jaconi', 'Estádio Alfredo Jaconi']),
 'pr-couto': ('Estádio Major Antônio Couto Pereira', 'Curitiba', ['Couto Pereira', 'Estádio Major Antônio Couto Pereira']),
 'pr-baixada': ('Estádio Joaquim Américo Guimarães (Arena da Baixada)', 'Curitiba', ['Baixada', 'Estádio Joaquim Américo Guimarães (Arena da Baixada)']),
 'pr-pinheirao': ('Estádio Pinheirão', 'Curitiba', ['Pinheirão', 'Estádio Pinheirão']),
 'pr-vila-capanema': ('Estádio Durival Britto e Silva (Vila Capanema)', 'Curitiba', ['Durival de Brito', 'Estádio Durival Britto e Silva (Vila Capanema)']),
 'pr-cafe': ('Estádio Municipal Jacy Scaff (Estádio do Café)', 'Londrina', ['Do Café', 'Estádio do Café', 'Estádio Municipal Jacy Scaff (Estádio do Café)']),
 'sc-ressacada': ('Estádio Aderbal Ramos da Silva (Ressacada)', 'Florianópolis', ['Ressacada', 'Estádio Aderbal Ramos da Silva (Ressacada)']),
 'sc-scarpelli': ('Estádio Orlando Scarpelli', 'Florianópolis', ['Orlando Scarpelli', 'Estádio Orlando Scarpelli']),
 'sc-heriberto': ('Estádio Heriberto Hülse', 'Criciúma', ['Heriberto Hülse', 'Estádio Heriberto Hülse']),
 'ba-fonte-nova': ('Fonte Nova',  # decisão do usuário 2026-09-28: velha Fonte Nova e Arena Fonte Nova = mesmo estádio, nome 'Fonte Nova'
   'Salvador', ['Fonte Nova', 'Arena Fonte Nova', 'Estádio Octávio Mangabeira (Fonte Nova)']),
 'ba-barradao': ('Estádio Manoel Barradas (Barradão)', 'Salvador', ['Barradão', 'Estádio Manoel Barradas (Barradão)']),
 'pe-arruda': ('Estádio José do Rego Maciel (Arruda)', 'Recife', ['Arruda', 'Estádio José do Rego Maciel (Arruda)']),
 'pe-ilha': ('Estádio Adelmar da Costa Carvalho (Ilha do Retiro)', 'Recife', ['Ilha do Retiro', 'Estádio Adelmar da Costa Carvalho (Ilha do Retiro)']),
 'pe-aflitos': ('Estádio Eládio de Barros Carvalho (Aflitos)', 'Recife', ['Aflitos', 'Estádio Eládio de Barros Carvalho (Aflitos)']),
 'pa-baenao': ('Estádio Evandro Almeida (Baenão)', 'Belém', ['Baenão', 'Estádio Evandro Almeida (Baenão)']),
 'pa-curuzu': ('Estádio da Curuzu', 'Belém', ['Curuzu', 'Estádio da Curuzu']),
 'pa-mangueirao': ('Estádio Olímpico do Pará (Mangueirão)', 'Belém', ['Mangueirão', 'Estádio Olímpico do Pará (Mangueirão)']),
 'ce-castelao': ('Estádio Governador Plácido Aderaldo Castelo (Castelão)', 'Fortaleza', ['Arena Castelão - CE', 'Estádio Governador Plácido Aderaldo Castelo (Castelão)']),
 'ce-pv': ('Estádio Presidente Vargas', 'Fortaleza', ['PV - CE', 'Presidente Vargas', 'Estádio Presidente Vargas']),
 'ma-castelao': ('Estádio Governador João Castelo (Castelão)', 'São Luís', ['Estádio Castelão', 'Estádio Governador João Castelo (Castelão)']),
 'ma-nhozinho': ('Estádio Nhozinho Santos', 'São Luís', ['Nhozinho Santos', 'Estádio Nhozinho Santos']),
 'rn-machadao': ('Estádio Dr. João Cláudio Vasconcelos Machado (Machadão)', 'Natal', ['Machadão', 'Estádio Dr. João Cláudio Vasconcelos Machado (Machadão)']),
 'rn-frasqueirao': ('Estádio Maria Lamas Farache (Frasqueirão)', 'Natal', ['Frasqueirão', 'Estádio Maria Lamas Farache (Frasqueirão)']),
 'pb-almeidao': ('Estádio José Américo de Almeida Filho (Almeidão)', 'João Pessoa', ['Almeidão', 'Estádio José Américo de Almeida Filho (Almeidão)']),
 'am-vivaldao': ('Estádio Vivaldo Lima (Vivaldão)', 'Manaus', ['Vivaldão', 'Estádio Vivaldo Lima (Vivaldão)']),
 'mt-verdao': ('Estádio José Fragelli (Verdão)', 'Cuiabá', ['José Fragelli', 'Estádio José Fragelli (Verdão)']),
 'mt-luthero': ('Estádio Engenheiro Luthero Lopes', 'Rondonópolis', ['Luthero Lopes', 'Estádio Engenheiro Luthero Lopes']),
 'df-mane': ('Estádio Nacional Mané Garrincha', 'Brasília', ['Estádio Nacional de Brasília Mané Garrincha', 'Estádio Nacional Mané Garrincha']),
 'df-serejao': ('Estádio Elmo Serejo Farias (Serejão)', 'Taguatinga', ['Boca do Jacaré', 'Estádio Elmo Serejo Farias (Boca do Jacaré)', 'Estádio Elmo Serejo Farias (Serejão/Boca do Jacaré)']),
 'df-bezerrao': ('Estádio Walmir Campelo Bezerra (Bezerrão)', 'Gama', ['Estádio Walmir Campelo Bezerra (Bezerrão)']),
 'es-araripe': ('Estádio Engenheiro Araripe', 'Cariacica', ['Engenheiro Araripe', 'Estádio Engenheiro Araripe']),
 'ap-glicerao': ('Estádio Municipal Glicério de Souza Marques (Glicerão)', 'Macapá', ['Glicerão', 'Estádio Municipal Glicério de Souza Marques (Glicerão)']),
}
idx = {}
for cid, (_, _, al) in C.items():
    for a in al:
        idx.setdefault(n(a), []).append(cid)

REVIEW = {  # (raw name, raw city) -> (canonical_id or None, note)
 ('Olímpico', 'Porto Alegre'): ('rs-olimpico-monumental', 'Olímpico em Porto Alegre é o Olímpico Monumental (Grêmio), NÃO o de Goiânia.'),
 ('Olímpico', 'UNKNOWN'): ('go-olimpico', 'Todas as 226 linhas são do histórico (1943-1997). 225 = Olímpico de Goiânia. EXCEÇÃO POR LINHA: hist-f80-2406 (24/11/1996, Grêmio 3 x 1 Goiás, Goiás visitante) = rs-olimpico-monumental.'),
 ('Bezerrão', 'Brasília'): ('df-bezerrao', 'Cidade bruta Brasília; o Bezerrão fica no Gama-DF. Conferir.'),
 ('Estádio Paranaíba', 'Itumbiara'): (None, 'NÃO confundir com "Avenida Paranaíba" (apelido do Olímpico de Goiânia). Conferir se é antecessor/alias do JK de Itumbiara.'),
 ('JK', 'UNKNOWN'): ('go-jk-itumbiara', '"JK" sem cidade: provável Itumbiara, conferir linha a linha.'),
 ('Castelão', 'Fortaleza'): ('ce-castelao', ''),
 ('Estádio Olímpico', 'Goiânia'): ('go-olimpico', ''),  # nome usado pela RSSSF nos Torneios Início de 1967 e 1974
 ('Castelão', 'UNKNOWN'): ('', 'Sem cidade; resolvido LINHA A LINHA pelo adversário em passaporte_esmeraldino_VENUE_ALIASES_por_linha.csv.'),
 ('Marcelo Stéfani', 'UNKNOWN'): ('sp-nabi', 'Marcelo Stéfani é o nome antigo do Nabi Abi Chedid. Conferir.'),
 ('Marcelo Stéfani', 'Bragança Paulista'): ('sp-nabi', 'Marcelo Stéfani é o nome antigo do Nabi Abi Chedid. Conferir.'),
 ('Arena Nicnet (Santa Cruz)', 'Ribeirão Preto'): ('sp-santa-cruz-rp', 'Arena Nicnet é naming rights do Estádio Santa Cruz.'),
 ('', ''): (None, 'venue_name VAZIO (nem UNKNOWN). Investigar essas linhas.'),
}
for a in C['mg-ipatingao'][2]:
    REVIEW[(a, 'Ipatinga')] = ('mg-ipatingao', 'Dois nomes oficiais diferentes para o Ipatingão. Conferir se é o mesmo estádio.')

c = collections.Counter((r['venue_name'], r['venue_city']) for r in rows if r['venue_name'] != 'UNKNOWN')
out = []
for (v, city), cnt in c.items():
    cid, note, rev = None, '', False
    hit = REVIEW.get((v, city))
    if hit and hit[1] is not None:
        cid, note = hit; rev = cid != '' and note != ''
    else:
        cands = idx.get(n(v), [])
        if len(cands) == 1:
            cid = cands[0]
    if cid == '':
        pass
    elif cid is None and not rev:
        cid = 'auto-' + n(v).replace(' ', '-')[:50]
        note = 'Sem alias conhecido; canônico = o próprio nome.'
    if cid in C:
        cn, cc = C[cid][0], C[cid][1]
    elif cid:
        cn, cc = v, city
    else:
        cn, cc = '', ''
    if cid in C and city not in ('UNKNOWN', cc):
        rev = True; note = (note + ' ' if note else '') + f'Cidade bruta "{city}" difere da canônica "{cc}".'
    out.append(dict(raw_venue_name=v, raw_venue_city=city, rows=cnt, canonical_id=cid or '',
                    canonical_name=cn, canonical_city=cc, needs_review='YES' if rev else '', note=note))
out.sort(key=lambda d: (d['canonical_id'] or 'zzz', -d['rows']))
with open('passaporte_esmeraldino_VENUE_ALIASES_rascunho.csv', 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(out[0].keys()), lineterminator='\r\n'); w.writeheader(); w.writerows(out)

# Exceções por linha: quando o par (nome, cidade) é ambíguo e só o jogo resolve.
ROW = [
    ('hist-f80-2406', 'rs-olimpico-monumental', 'Grêmio 3 x 1 Goiás, 24/11/1996, Porto Alegre: "Olímpico" aqui é o do Grêmio.'),
    ('hist-f80-2543', 'ma-castelao', 'Moto Club-MA 2 x 3 Goiás, Copa do Brasil, 24/02/1999: Castelão de São Luís (decisão do usuário 2026-09-28, pelo adversário).'),
    ('hist-f80-2593', 'ce-castelao', 'Ceará-CE 3 x 0 Goiás, Série B, 06/11/1999: Castelão de Fortaleza (decisão do usuário 2026-09-28, pelo adversário).'),
]
with open('passaporte_esmeraldino_VENUE_ALIASES_por_linha.csv', 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.writer(f, lineterminator='\r\n')
    w.writerow(['id', 'canonical_id', 'canonical_name', 'canonical_city', 'note'])
    for rid, cid, note in ROW:
        w.writerow([rid, cid, C[cid][0], C[cid][1], note])

g = collections.Counter()
for d in out: g[d['canonical_id']] += d['rows']
print('pares brutos (nome+cidade):', len(c), '| nomes brutos distintos:', len({v for v, _ in c}),
      '| canônicos:', len({d['canonical_id'] for d in out if d['canonical_id']}),
      '| a revisar:', sum(d['needs_review'] == 'YES' for d in out))
for k in ['go-olimpico', 'go-accioly', 'go-serra-dourada', 'go-serrinha']:
    print(' ', k, g[k])
for d in out:
    if d['needs_review']:
        print('REV', d['rows'], repr(d['raw_venue_name']), '|', d['raw_venue_city'], '->', d['canonical_id'], '|', d['note'][:110])
