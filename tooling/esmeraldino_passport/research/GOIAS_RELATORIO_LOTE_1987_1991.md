# Relatório do lote da pesquisa externa 1987 → 1991 (notas originais, 2026-09-29/30)

Anexado sem edição para registrar o que ele já tentou. Auditoria na seção 53 de checkpoint_goias_estadios_2026-09-27.md.

# Passaporte Esmeraldino — checkpoint 1989
Data: 29/09/2026

Estado verificado: 1.989/2.102 = 94,62%. Pendentes: 113. Faltam 8 para 95%.
Dataset completo preservado: 3.840 linhas. Escopo da contagem: dataset_origin = historical_futebol80.
Base: CHECKPOINT_1987(2). Apenas duas linhas modificadas, apenas campos autorizados; venue_probable_* limpos nessas linhas.

## Confirmações desta rodada

| ID | Data canônica | Partida | Estádio | Cidade | Confiança |
|---|---|---|---|---|---|
| hist-f80-2170 | 07/07/1993 | Goiatuba 0 x 0 Goiás | Divino Garcia Rosa | Goiatuba | HIGH |
| hist-f80-2171 | 11/07/1993 | Goiás 3 x 1 Quirinópolis | Serra Dourada | Goiânia | HIGH |

Fonte primária para ambas: Diário da Manhã, 06/09/1993, Esportes p. 3, página 15 do PDF. Roberto Sampaio, “Números finais do Campeonato Goiano de 93”, Parte 4. Matéria lida integralmente e conferida visualmente.
URL: https://hemeroteca.ihgg.org/publicacoes/DIARIO_DA_MANHA/1993/09/DIARIO_DA_MANHA_1993_09_06.pdf

Trechos curtos: “Goiatuba 0 x 0 Goiás no Estádio Divino Garcia Rosa”; “Goiás 3 x 1 Quirinópolis no Estádio Serra Dourada”. A matéria atribui ambos à segunda fase.

Cruzamento independente de data, placar e fase:
https://www.rsssfbrasil.com/tablesfq/go1993.htm
SECOND STAGE / Group 2 / Round 5 [Jul 7]: Goiatuba 0-0 Goiás.
SECOND STAGE / Group 2 / Round 6 [Jul 11]: Goiás 3-1 Quirinópolis.
RSSSF usada para individualizar data/fase; a evidência de estádio é o jornal original.

## Divergência anterior de Goiatuba
O checkpoint anterior referia 04/07 em uma tabela não identificada. A RSSSF efetivamente consultada registra 07/07, coincidindo com Futebol80/CSV. O jornal de setembro não dá data, mas identifica placar, estádio e segunda fase. Na segunda fase os confrontos foram Goiás 1-1 Goiatuba e Goiatuba 0-0 Goiás. Nenhuma tolerância de 3 dias foi aplicada, nenhuma data foi alterada. A indicação anterior foi registrada em conflict_note por transparência.

## Tentativas e limites
- Firecrawl retornou 402 por falta de créditos. Pesquisa prosseguiu por busca alternativa e download direto.
- O PDF de setembro do IHGG abriu por download direto (aproximadamente 20 MB), embora o leitor web não abrisse.
- URLs do DM de 05, 08 e 12/07/1993 retornaram 404. Não insistir nessas mesmas URLs.
- Oito PDFs de O Estado (SC) baixados com sucesso e texto extraído: EST197618295, EST197618313, EST197618324, EST197618364, EST197618378, EST197618387, EST197618391, EST197618403.
- Busca textual por Goiás/Goiano/Anápolis nesses PDFs: nenhum estádio novo aceito. Extração existente tem ruído; não equivale a esgotamento visual de todas as páginas.
- EST197618391, página 8: pré-jogo Associação Jataiense x Goiás apenas em Jataí. Serra Dourada se refere a Goiânia x Goiatuba na mesma nota, NÃO ao Goiás. hist-f80-1084 continua UNKNOWN.
- BDD1976013.pdf baixado e texto extraído. Busca por Goiás/Anápolis/Incentivo não individualizou hist-f80-1105 com estádio. A ocorrência textual de Goiás é em outro contexto. Revisão visual de esportes ainda possível.

## URLs exatas dos PDFs catarinenses processados
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618295.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618313.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618324.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618364.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618378.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618387.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618391.pdf
- https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST197618403.pdf
- https://hemeroteca.ciasc.sc.gov.br/jornais/bomdiadomingo/1976/BDD1976013.pdf

## Próxima retomada
1. Trabalhar a partir do CHECKPOINT_1989 e das 113 pendências anexas. Não refazer as duas confirmações de 1993.
2. Revisar visualmente páginas esportivas dos PDFs catarinenses quando o OCR for insuficiente; procurar edições adjacentes às partidas de 1976.
3. Prosseguir na pista O Estado de Mato Grosso, fev–jun/1976, incluindo espelho do Arquivo Público de São Paulo. Ainda não investigada nesta rodada.
4. Atacar 1984–1986 (64 pendências) em jornais de outros estados. Não repetir o DM durante seu período sem circulação.
5. Preservar regras anteriores: evidência específica, sem inferência por mando/cidade; não alterar datas/placares; divergência V/E/D impede promoção; atualizar somente campos autorizados.

## Arquivos do pacote
- Dataset completo CHECKPOINT_1989.
- CSV com as 113 pendências.
- Este registro de evidências e retomada.
- Página original de esportes do DM em PDF, para auditoria visual.
- Tabela RSSSF consultada em HTML, para verificar fase e datas.


# Passaporte Esmeraldino — checkpoint 1991

Data: 30/09/2026. Pesquisa de estádios para o Fan Hub do Goiás.

## Estado auditado

- Universo da contagem: 2.102 linhas com dataset_origin = historical_futebol80.
- Estádios confirmados: **1.991/2.102 = 94,7193% (94,72%)**.
- Pendentes: 111. Meta mínima de 95%: 1.997. Faltam 6 confirmações.
- Dataset completo: 3.840 linhas, mesmas colunas e ordem da base 1989.
- Comparação campo a campo: apenas hist-f80-2308 e hist-f80-2311 mudaram; somente venue_name, venue_city, venue_confidence, source_secondary e notes. Todos os demais valores preservados.
- Os dois jogos de 1995 foram descobertos na rodada anterior e agora incorporados ao arquivo. A busca adicional desta rodada não deve ser descrita como seis novas confirmações nem como meta atingida.

## Duas confirmações incorporadas desde o arquivo 1989

| ID | Data canônica | Partida | Estádio | Cidade | Confiança |
|---|---|---|---|---|---|
| hist-f80-2308 | 27/06/1995 | Vila Nova 1 x 1 Goiás | Serra Dourada | Goiânia | HIGH |
| hist-f80-2311 | 09/07/1995 | Goiás 3 x 3 Vila Nova | Serra Dourada | Goiânia | HIGH |

Fonte primária: Diário da Manhã, 21/08/1995, p. 11, Roberto Sampaio, “Confira os números finais do Campeonato Goiano de 1995”. Página original conferida visualmente. O PDF da página está neste pacote.

https://hemeroteca.ihgg.org/publicacoes/DIARIO_DA_MANHA/1995/08/DIARIO_DA_MANHA_1995_08_21.pdf

Evidência individualizada por data, placar e adversários:
- Seção “Maiores públicos pagantes”: Vila Nova 1 x 1 Goiás, 27 de junho, Estádio Serra Dourada, primeiro turno da terceira fase.
- Seção “Maiores rendas”: Goiás 3 x 3 Vila Nova, 09 de julho, Estádio Serra Dourada, segundo turno da terceira fase.

A base também mantém as duas confirmações de 1993 documentadas no checkpoint 1989 anexado: hist-f80-2170 (Goiatuba, Divino Garcia Rosa) e hist-f80-2171 (Quirinópolis, Serra Dourada). O checkpoint 1989 é histórico; seu percentual não é o atual.

## Regras indispensáveis para continuidade

Só promover estádio com vínculo explícito ao jogo, e não por mando, cidade, estádio habitual, proximidade de outra partida ou palpite. Individualizar data/equipes/placar; se a fonte não individualiza, cruzar fonte independente. Tolerância de data de até dois dias só para jogo inequívoco, sem mudar data canônica. Conferir placar pelos campos goias_score/opponent_score. Divergência incompatível permanece pendente.

Campos autorizados: venue_name, venue_city, venue_state, venue_confidence=HIGH, source_secondary, notes e conflict_note. Limpar venue_probable_* apenas em linha confirmada. Preservar o restante. Registrar URL, edição, página e evidência lida. Snippet de busca não confirma estádio.

## Busca adicional desta rodada — evitar repetição

### Diário da Manhã

- 15/09/1995, PDF p.16, “Dois anos de vitórias sobre os visitantes”: tabela com 51 jogos de 26/09/1993 a 10/09/1995. Tabela lida visualmente e cruzada com a lista de pendências; correspondências já conhecidas. Não usar partida de abril para resolver Jataiense de maio.
- 20/03/1994: páginas esportivas, sem confirmação nova.
- Edições de 03 e 04/01/1994; 02, 03 e 04/01/1995: extração e triagem das ocorrências. Nenhuma evidência nova individualizada. 02/01/1994 retornou 404. Não repetir alegação de busca sobre retrospectiva sem localizar matéria real no PDF.
- URLs seguem https://hemeroteca.ihgg.org/publicacoes/DIARIO_DA_MANHA/AAAA/MM/DIARIO_DA_MANHA_AAAA_MM_DD.pdf . Manifesto neste pacote registra arquivos e hashes, e textos de triagem foram preservados.
- Rodadas anteriores já examinaram retrospectivas de 1993 de 16, 23 e 30/08; 06, 13 e 20/09, além de 03–05/09. Só a de 06/09 rendeu as duas confirmações documentadas.

### O Estado, Florianópolis, 1976

Fonte: https://hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/EST1976NNNNN.pdf

Novos arquivos triados nesta rodada: 18286, 18297, 18300, 18307, 18315, 18326, 18362, 18366, 18372, 18380, 18389, 18393. 18405 retornou 404. Nenhuma confirmação de estádio.

18298 foi reaberto: são 48 páginas reunindo edição de 21/02 (16 páginas) e 22/02 (32 páginas). As páginas esportivas do dia 22 foram verificadas; sem estádio de jogo pendente do Goiás. Atenção: número do arquivo não determina sozinho a data, e há PDFs com duas edições.

18300 p.13 dá Goiânia 2 x 2 Goiás em resultado de loteria, mas não estádio. 18307 corresponde a 04/03. Não transformar esses achados em confirmação.

Arquivos de rodadas anteriores: 18284, 18285, 18294, 18295, 18296, 18298, 18305, 18306, 18312, 18313, 18314, 18323, 18324, 18325, 18361, 18363, 18364, 18365, 18370, 18371, 18377, 18378, 18379, 18386, 18387, 18388, 18390, 18391, 18392, 18402, 18403 e 18404. 18299 e 18360 retornaram 404.

Armadilhas já verificadas: 18391 p.8 associa Serra Dourada a Goiânia x Goiatuba, não a Jataiense x Goiás. 18371 p.7 cita Rio Verde x Goiás sem estádio. 18404 p.44 cita Goiás 0 x 0 Itumbiara sem estádio.

### Pistas sem comprovação e acessos incompletos

- hist-f80-2169 (04/07/1993, Goiânia 2 x 0 Goiás) e hist-f80-2246 (04/09/1994, Goiás 3 x 2 Atlético): referências anteriores a Serra Dourada não vieram acompanhadas de fonte primária individualizada. Recuperação de contexto e conferência dos arquivos não validaram as alegações. Permanecem UNKNOWN/LOW. Futebol de Goyaz IDs 24946 e 25263 não trouxeram estádio nas consultas anteriores. Cinturão Brasileiro não é fonte final admitida neste checkpoint.
- Diário de Notícias, Curitiba, 24/07/1986: https://hemeroteca-pdf.bn.gov.br/325538/per325538_1986_01526.pdf . Snippet menciona Itumbiara/Goiás/loteria, potencialmente relevante ao jogo de 27/07/1986 (hist-f80-1717). Abertura via busca expirou; download retornou HTML, não PDF. Não foi lido e não confirma nada. Próximo passo: obter cópia pública legível da edição, conferir página e estádio.
- Placar no Google Books: metadados das edições localizados, mas leitor não entregou páginas e consultas internas retornaram HTTP 429. Não declarar revistas lidas. IDs: 10/08/1984 owHqHo4hPNYC; 17/08/1984 8ZrRReqxVugC; 14/09/1984 U2JT9PUuzXAC; 03/03/1986 iQJJErQrHwcC; 13/09/1985 lc4J2QtQ8agC; 07/07/1986 ReH4eOBz_dgC. Modelo de URL: https://books.google.com/books?id=ID .
- Jornal da Cidade/SE 20/11/1985: https://jornaisdesergipe.ufs.br/bitstream/123456789/44346/1/Jornal%20da%20Cidade%201985.11.20.pdf . Tentativa anterior teve erro 500/timeout; snippet não individualiza estádio pendente.
- Bom Dia Domingo/SC, 19/09/1976: https://hemeroteca.ciasc.sc.gov.br/jornais/bomdiadomingo/1976/BDD1976013.pdf . OCR anterior sem estádio vinculado ao jogo do Goiás. Inspeção visual esportiva integral não documentada.
- O Estado de Mato Grosso/APESP de 14–15/02/1976: referência antiga sem URL exata recuperada. Não declarar edição consultada nesta rodada.

## Ponto de retomada

Usar o CSV CHECKPOINT_1991 e a lista de 111 pendências anexada; não recomeçar da base 1987. Priorizar obter páginas efetivas das revistas Placar identificadas, a edição curitibana de 24/07/1986 e novas fontes primárias ainda não triadas. Os PDFs catarinenses listados e as tabelas retrospectivas acima não renderam confirmação adicional. Não elevar contagem com pistas.

O alvo continua: seis novos jogos comprovados para 1.997/2.102 = 95,0048%.

## Última fonte nova examinada

Estado do Piauí, fevereiro de 1976, acervo do Museu de História do Piauí/UFPI:
https://museudehistoriadopiaui.ufpi.edu.br/acervo/jornais/estado-do-piau%C3%AD/estado-do-piau%C3%AD-ano-de-1976
PDF público incorporado à página: https://drive.google.com/file/d/11iWJAbXPGzci47Io3sB2kYznWfQFSSIv/preview

Download realizado, 39 páginas sem camada de texto. OCR executado nas 39 páginas, 283.599 caracteres extraídos; triagem sem referência pertinente a estádio do Goiás. Não afirmar ausência absoluta em razão da qualidade do OCR. PDF e OCR incluídos no pacote para eventual inspeção visual complementar. Os demais meses do acervo não foram examinados.

O pacote inclui os textos extraídos da rodada e um manifesto dos PDFs com hashes. Os PDFs volumosos sem novas confirmações não estão todos incorporados; as URLs acima permitem recuperação. Os PDFs comprobatórios de 1993 e 1995 estão anexados.
