# Roteiro de pesquisa — 5 casos-teste de estádio (Passaporte Esmeraldino / Goiás)

> Copie tudo abaixo da linha e cole na ferramenta de pesquisa, junto com o arquivo `GOIAS_PENDENCIAS_ESTADIOS_1995.csv` em anexo (107 pendências completas, pra contexto — mas o pedido agora é só sobre os 5 casos abaixo).

---

Estou pesquisando o estádio de partidas históricas do **Goiás Esporte Clube** pra um app (Passaporte Esmeraldino). Uso o CSV em anexo como referência completa das 107 pendências, mas quero que você tente resolver **só estes 5 casos** primeiro, como teste — se resolver algum, eu confiro e aplico; se não resolver nenhum, sem problema, esses já foram tentados à exaustão por várias fontes.

## Regra inegociável, sem exceção
Só aceito um estádio se a fonte citar **especificamente aquela partida** (data + os dois times + placar batendo) junto com o nome do estádio — nunca por inferência de mandante, cidade, estádio habitual do clube, ou "provavelmente foi no mesmo estádio de outro jogo próximo". Se não achar uma fonte assim, diga que não achou — não completar com achismo.

Pra cada um que resolver, me devolva: **id, nome do estádio, cidade, URL da fonte, e o trecho exato do texto que liga a partida ao estádio** (cite literalmente, não resuma).

## Os 5 casos

1. **hist-f80-1610** — 12/09/1984, **Goiás 3 x 0 Anápolis-GO**, Campeonato Goiano.
   Já tentei: Futebol de Goyaz (placar bate exato, campo de estádio vazio tanto na tabela de confronto quanto na ficha da partida); revista Placar (Google Books) — a rodada do Tabelão daquela semana pula de "2º turno 1ª rodada" (2/set) direto pra "3ª rodada" (14-16/set), esse jogo específico não apareceu em nenhuma edição.

2. **hist-f80-1604** — 12/08/1984, **Itumbiara-GO 2 x 1 Goiás**, Campeonato Goiano.
   Já tentei: o Tabelão da Placar (revista, via Google Books) TEM esse jogo (bati o placar exato: "ITUMBIARA 1 X GOIÁS 2"), mas SEM o campo "Local:" — testei em 3 edições diferentes da revista (17/08, 24/08 e 31/08/1984) e nenhuma trouxe o estádio pra esse jogo específico, mesmo outras partidas da mesma rodada tendo.

3. **hist-f80-1766** — 27/06/1987, **Goiás 1 x 0 Goiatuba-GO**, Campeonato Goiano (2º turno, 6ª rodada, sábado).
   Já tentei: Futebol de Goyaz (placar bate exato, estádio vazio na ficha da partida — `futeboldegoyaz.com.br/partidas/23421/partida`).

4. **hist-f80-0555, 0556, 0557, 0558** — 07/04/1966, **Torneio Início Goiano** (mata-mata de um dia só, provavelmente tudo no mesmo estádio): Goiás 0x0 Goiânia-GO (pênaltis), Goiás 0x0 Vila Nova-GO (pênaltis), Goiás 0x0 Ipiranga de Anápolis-GO (pênaltis), e a final Goiás 0x1 Anápolis-GO.
   Já tentei: RSSSF Brasil (`rsssfbrasil.com/tablesfq/go1966in.htm`) bate os 4 placares exatos, mas SEM campo "Local" preenchido (outras páginas da mesma seção do RSSSF têm esse campo, essa não); Futebol de Goyaz não cataloga Torneio Início nenhum ano; jornais "5 de Março" e Folha de Goiaz (IHGG) testados sem sucesso pra abril/1966.

5. **hist-f80-1105** — 19/09/1976, **Goiás 1 x 0 Anápolis-GO**, Torneio Incentivo-GO.
   Já tentei: Hemeroteca Digital Catarinense (`hemeroteca.ciasc.sc.gov.br/oestadofpolis/1976/`, jornal *O Estado* de Florianópolis-SC, que às vezes cobre o Goiano como nota nacional) — várias edições de 1976 testadas (números de arquivo entre 18279 e 18405), nenhuma com esse jogo específico.

## Dicas de onde procurar (pode ou não ajudar)
- Jornais de Goiás digitalizados no IHGG (`hemeroteca.ihgg.org`): Diário da Manhã (não cobre 1985 nem a maior parte de 1986, o jornal faliu 03/10/1984-10/10/1986), Folha de Goiaz (só até 1952), "5 de Março" (1959-1980, cobertura esportiva inconsistente).
- Diário de Notícias de Curitiba (Biblioteca Nacional, `hemeroteca-pdf.bn.gov.br/325538/per325538_<ano>_<edição 5 dígitos>.pdf`, sem CAPTCHA) — só cita clube de Goiás quando cai na grade nacional da Loteria Esportiva, não é cobertura regular.
- Se achar um jornal de OUTRO estado que cobria o Campeonato Goiano como nota nacional (foi assim que resolvemos outros jogos de 1976 antes, via jornal catarinense), isso pode valer tanto pros casos 4 e 5 quanto pra qualquer outro do CSV anexo.
