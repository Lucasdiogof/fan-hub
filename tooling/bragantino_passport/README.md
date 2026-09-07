# Passaporte do Bragantino — pipeline por lote

Reconstrução, lote a lote, do histórico de partidas oficiais do Red Bull
Bragantino / Clube Atlético Bragantino (uma única história de clube). Nunca
copia dado do Goiás; nunca infere estádio pelo mandante; nunca publica
horário/estádio sem fonte específica da partida.

## Estratégia

Começa do período mais recente (2026) e retrocede ano a ano. Cada lote vira
um arquivo `source/bragantino_passport_<ano>.json` + uma SQL de seed
`supabase/bragantino_passport_matches_<ano>_seed.sql`, sempre idempotente
(`ON CONFLICT (id) DO UPDATE`).

## Lotes

| Lote | Ano | Status | Partidas | Fonte primária |
|---|---|---|---|---|
| 1 | 2026 | CLOSED | 59 | OneFootball (`api.onefootball.com/web-experience`) |
| 2 | 2025 | CLOSED | 57 | oGol (`ogol.com.br/equipe/red-bull-bragantino`) |
| 3 | 2024 | CLOSED | 70 | oGol |
| 4 | 2023 | BLOQUEADO — oGol respondeu 403 na última checagem (2026-09-07), não é mais o 503 de rate-limit original; não ficar reprovando "só pra ver" | — | oGol |

## Controle de cobertura 2000-2026 (`source/bragantino_passport_audit_manifest_v4.json`)

Adicionado em 2026-09-07 (pacote `docs/bragantino_data`): contagem oficial
de partidas por ano-calendário 2000-2026 + `epoca_id`/URL do oGol pra cada
um — confirma exatamente os números já derivados abaixo (nenhuma
divergência encontrada) e já traz pronta a URL de cada ano ainda não
raspado (2000-2023). **Só controle/auditoria — nenhuma das 1.251 partidas
individuais de 2000-2023 está materializada aqui; não gerar nenhuma até
raspar de verdade.** Reconciliações por competição/ano (ex.: 2020 vs 2021
por causa do Brasileirão que virou o ano) também vêm documentadas no
manifesto — usar como checklist ao fechar cada lote futuro.

## Por que 2026 usa OneFootball e temporadas passadas usam oGol

A página de TIME do OneFootball (`/time/<slug>/resultados` e `/jogos`) só
mostra uma janela rolante (resultados recentes + próximos jogos) — funciona
perfeitamente pra a temporada corrente, mas não tem histórico de anos
anteriores. Temporadas fechadas usam oGol como backbone: a tabela "todos os
jogos" (`equipe/red-bull-bragantino/3156/todos-os-jogos?epoca_id=<id>&compet_id_jogos=<id>`)
tem histórico completo por competição, e cada ficha individual de partida
(`jogo/<slug>/<id>`) embute um bloco JSON-LD (`schema.org/SportsEvent`) com
`location.name` (estádio) e `startDate` (UTC real) — muito mais confiável
que tentar ler a tabela "a olho".

`epoca_id` não é o ano diretamente: 2026→155, 2025→154, 2024→153 (sempre
decrescente 1 a 1 pra trás, confirmado por probe direto de cada um antes de
assumir). `compet_id_jogos` (Paulista=555, Brasileirão=51, Copa do
Brasil=260, Sudamericana=269) é estável entre temporadas; Libertadores=58
só aparece no dropdown dos anos em que o time participou dela.

## Dois bugs de parser encontrados durante os lotes 2025/2024 (lição pra futuros lotes)

1. **Placar invertido em jogos fora de casa** — o parser assumia que o
   texto do placar vinha "time da página primeiro", quando na verdade o
   oGol sempre mostra `<mandante>-<visitante>`, igual à ordem do slug da
   URL. Descoberto cruzando um resultado com a imprensa (Botafogo 2-0
   Bragantino apareceu como Bragantino 2-0 Botafogo). Corrigido; **todo
   lote gerado antes dessa correção deve ser re-verificado** se for
   reaberto.
2. **Linhas de pênaltis/prorrogação invisíveis pro parser** — jogos
   decididos assim têm `<a class="prol" href="...">` (atributo extra antes
   do `href`) e um `<span>` com o placar da disputa depois do placar normal
   — o regex original só casava `<a href="...">` puro e descartava a linha
   inteira, **sem erro nem aviso**. Isso escondeu partidas decisivas
   inteiras: 2 rodadas completas da Copa do Brasil 2025 (Sousa,
   São José-RS) e a volta de 2 mata-matas de 2024 (Rionegro Águilas na
   Libertadores, Corinthians na Sul-Americana — a própria eliminação da
   campanha!). **Nunca aceitar a contagem de jogos de um lote como
   "fechada" sem cruzar com uma fonte de reconciliação por competição** —
   foi exatamente isso que expôs o bug, não uma inspeção da tabela.

Ambos corrigidos em `parse_ogol_matches.mjs`; `penalty_home_score`/
`penalty_away_score` agora saem no JSON de cada partida decidida assim
(vira texto em `data_notes` no SQL final, não é coluna própria ainda).

## oGol e rate limiting

O oGol usa Cloudflare e bloqueia (HTTP 503, `Retry-After`) depois de um
volume alto de requisições na mesma sessão/IP — aconteceu no fim do lote
2024, logo depois de corrigir o bug de pênaltis (justo quando 2 fichas
novas precisavam ser buscadas). Nesses casos, com o placar/data/competição
já confirmados pela própria tabela (fonte estruturada), o estádio das
poucas partidas afetadas foi confirmado por imprensa externa em vez do
JSON-LD — sempre com fonte específica registrada em `data_notes`, nunca
como padrão aplicado a partidas futuras. Ao reabrir o pipeline (lote 2023
em diante), espaçar as requisições e considerar retomar de onde parou em
vez de rebaixar tudo pra imprensa.

## Descoberta relevante: transição de estádio em 2025

O estádio histórico do clube (Nabi Abi Chedid, em Bragança Paulista) foi
demolido em 2025 pra construção da "Arena Red Bull" — o time jogou toda a
2ª metade de 2025 e toda a 2026 (até o corte desta pesquisa) no Estádio
Municipal Cícero de Souza Marques, mandado também em Bragança Paulista.
Confirmado partida a partida (nunca assumido): último mando no Nabi Abi
Chedid foi 2025-04-20 (Brasileirão vs Cruzeiro, 1-0); a partir de
2025-05-05 os mandos já são no Cícero de Souza Marques — com uma única
exceção isolada (2025-08-06, volta das oitavas da Copa do Brasil vs
Botafogo), onde o JSON-LD do oGol trazia "Nabi Abi Chedid" mas a imprensa
confirma Cícero de Souza Marques (o Nabi Abi Chedid já estava interditado
por obras nessa data) — corrigido com fonte registrada, não por "padrão
dos jogos ao redor". Esse é exatamente o tipo de caso que justifica a regra
"nunca inferir estádio pelo mandante": mesmo com um padrão de 20+ jogos
seguidos, uma exceção real aconteceu.

## Scripts

- `parse_ogol_matches.mjs <arquivo.html> [teamSlug]` — parser reproduzível
  da tabela "todos os jogos" do oGol (regex sobre o HTML bruto, sem
  DOM/browser). Exporta `parseOgolTeamMatches(html, { teamSlug })`.
- `generate_seed_sql.mjs <ano>` — gera a SQL de seed a partir do JSON fonte
  já validado (nunca refaz pesquisa). Uso: `node generate_seed_sql.mjs 2025`.
- `validate_batch.mjs <ano>` — valida um lote já gerado (IDs únicos, datas,
  placares, consistência mandante/visitante, regra crítica de estádio,
  SQL bem formada, contagem de linhas batendo com o JSON). Uso:
  `node validate_batch.mjs 2025`.
- `parse_ogol_lineup.mjs <arquivo.html>` — extrai a escalação (titulares,
  reservas usados, banco não usado, capitão) da mesma ficha de partida já
  baixada pro Passaporte (`id="game_report"`) — ver seção
  "LINEUP_SHORTLIST_V2" abaixo. Exporta `parseOgolLineup(html)`.
- `validate_lineup_shortlist.mjs` — valida `source/lineup_shortlist_v2.json`
  (onze completo, camisas sem duplicata/fora de faixa, fonte rastreável).

## LINEUP_SHORTLIST_V2 (candidatos pro "Adivinhe a Escalação")

Reconstrução NOVA — a lista de 24 partidas referenciada em pesquisa
anterior nunca foi encontrada no repositório (procurada e confirmada
ausente); esta lista não reivindica nenhuma continuidade com aquela.

A ficha de partida do oGol (a mesma já baixada pra extrair estádio/data via
JSON-LD, ver acima) embute a escalação completa numa seção
`id="game_report"` — **sem nenhuma request nova**. A seção lista, por time,
quem entrou em campo (titulares + reservas usados), então titular de
verdade é só quem NUNCA tem um evento `title="Entrou"` (reserva que jogou);
reservas que ficaram no banco o jogo inteiro vêm numa linha separada
("Reservas", classe `inactive`). Sem checar isso, todo mundo que jogou
(18+ por time) apareceria como "titular".

### Duas categorias — nunca misturar sem critério

`source/lineup_shortlist_v2.json` tem `recent_lineups.matches` e
`historical_lineups.matches` separados de propósito:

- **RECENT_LINEUPS** — 123 partidas de 2024/2025, extraídas automaticamente
  das 125 fichas já em cache dos lotes do Passaporte (as 2 exceções
  ficaram com conteúdo incompleto por causa do rate limit do oGol, ver
  seção acima). Fácil de obter porque já é reaproveitamento de dado
  baixado por outro motivo — **isso não significa que deva dominar o jogo
  final**.
- **HISTORICAL_LINEUPS** — partidas historicamente relevantes (Série B
  1989, Paulista 1990, campanhas antigas importantes, partidas marcantes,
  jogos decisivos). **Ainda vazio, `research_status: "PENDING_RESEARCH"`**
  — nunca preenchido com dado inventado só pra balancear a proporção com
  RECENT_LINEUPS. `historical_lineups.research_targets` documenta as 5
  frentes prioritárias a pesquisar; o oGol provavelmente não tem esse
  nível de detalhe de escalação pra jogos tão antigos (a confirmar quando
  essa frente for aberta — pode exigir CBF/imprensa de época/RSSSF).

Cada registro (recente ou histórico) preserva: `source`, `source_match_id`,
`source_url`, `date`, `competition`, `competition_edition`, `opponent`,
`club_is_home`, `score_display`, `outcome`, `stadium`, `starting_xi`
(camisa+nome+capitão), `used_substitutes`, `manual_corrections` (motivo
registrado quando uma camisa/dado precisou de correção pontual, `null`
quando não houve nenhuma). A seleção final de partidas pro app (misturando
as duas categorias) é uma decisão futura, feita só depois que
HISTORICAL_LINEUPS tiver conteúdo de verdade — nenhuma interface criada
ainda, é só o dataset base.

## Tabela

`supabase/bragantino_passport_matches.sql` cria `public.passport_matches`
— **mesmo nome** da tabela do Goiás, só que no projeto Supabase SEPARADO do
Bragantino (o isolamento vem do projeto, não de um `club_id`/nome
prefixado). Colunas alinhadas ao contrato do Goiás onde fazem sentido;
campos exclusivos do Bragantino (`competition_edition`, `phase_status`,
`weekday`, `day_type`, `day_period`, `stadium_status`, `venue_city/state/
country` etc) só existem no schema dele. Ver comentário no topo do arquivo
SQL pra mais detalhes, incluindo um bug pré-existente encontrado (não
corrigido, fora de escopo) na RPC `passport_matches_for_year` do Goiás.

## Importar no Supabase do Bragantino — runbook

Nenhum destes arquivos é aplicado por aqui: rode você mesmo no SQL Editor do
projeto do **Bragantino** (`yrgyzkaaudyzmsqwzecj`), nesta ordem. Todos são
idempotentes e nenhum apaga presença de usuário.

1. `supabase/bragantino_passport_infra.sql`
2. `supabase/bragantino_passport_venues_seed.sql`
3. `supabase/bragantino_passport_matches_2024_seed.sql`
4. `supabase/bragantino_passport_matches_2025_seed.sql`
5. `supabase/bragantino_passport_matches_2026_seed.sql`

Antes de rodar qualquer coisa: `node tooling/bragantino_passport/validate_import.mjs`
(as 186 partidas de uma vez) — se não passar, não aplique nada.

### O que já existia no banco (verificado ao vivo, 2026-09-07)

Ao contrário do que a auditoria estática dos `.sql` deste repositório dizia,
o projeto do Bragantino **já tinha** `passport_matches`, `venues`,
`passport_attendances`, `passport_memorable_matches` e as 11 RPCs, todas
devolvendo os nomes genéricos que o Flutter espera (`club_is_home`,
`club_score`, `venue_name`, `venue_city`). Só faltava dado e as colunas de
enriquecimento — que é tudo o que o passo 1 adiciona.

Lição que vale pro resto do projeto: **arquivo `.sql` versionado não é fonte de
verdade sobre o que está rodando.** Chame a RPC / consulte o REST antes de
concluir que algo falta ou está quebrado.

### Estádios

`build_venues.mjs` transforma as 62 grafias da fonte em 49 estádios. Ele só
agrupa grafias que estão escritas explicitamente em `MERGE_GROUPS` — nunca por
semelhança de string, porque "Estadio Monumental Banco Pichincha" (Guayaquil) e
"Estadio Monumental" (Buenos Aires) são casas diferentes. Regenerar:

```
node tooling/bragantino_passport/build_venues.mjs
node tooling/bragantino_passport/generate_seed_sql.mjs 2024   # e 2025, 2026
```

O seed de partidas grava `venue_id` direto e termina com um bloco que estoura
se sobrar partida com estádio e sem `venue_id` — falha alta em vez de partida
aparecendo sem estádio no app.
