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
| 4 | 2023 | não iniciado (oGol rate-limitou a sessão no fim do lote 3 — ver abaixo) | — | oGol |

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
