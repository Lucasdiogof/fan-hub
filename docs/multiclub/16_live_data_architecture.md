# 16 — Arquitetura de Dado Vivo vs. Snapshot (Jogadores)

> Proposta de design — nada implementado, nenhuma tabela criada além da `people` já proposta em `10_club_config.md`/migration `20260901000000_create_people.sql`. Gerado em 2026-09-01, motivado por um requisito que ficou evidente durante a reconciliação (`15_player_reconciliation_report.md`): o caso Tadeu (398×400 jogos) não era um erro de dado — era o sintoma de não existir UMA fonte viva única para estatística de jogador. Este documento resolve isso.
>
> **Revisão v3.1 (mesma data)** — firma 6 pontos que a v1 deste documento deixava como "decisão a fechar depois": `club_id` vira `uuid` (não mais texto), `player_match_appearances` ganha um status explícito de comparecimento (titular/reserva-usado/reserva-não-usado, nunca contando quem não entrou), o sync ganha uma chave de idempotência formal (§5.1), a identidade de partida ganha um namespace explícito por fonte (§1.5) em vez de um `match_id text` ambíguo, `joined_at`/`left_at` ganham precisão temporal explícita (§1.6), e posição múltipla (§2) deixa de ser "decisão futura" e vira `player_positions`, a mesma tabela já usada pra validar os 7 cenários de teste em `tooling/multiclub/test_live_data_model.mjs`/`live_data_model.mjs` (implementação de referência em memória, não o schema real — prova o desenho antes do INSERT).
>
> **Revisão v4 (Etapa E — 2026-09-02)** — a v3.1 acima ainda era um DESENHO (implementação de referência em memória, `live_data_model.mjs`). A Etapa E implementou o schema REAL (`supabase/migrations/20260902100000_create_matches.sql`, `20260902120000_create_player_match_appearances.sql`) e ele diverge da v3.1 em pontos concretos, corrigidos aqui: §1.1 (schema real de `player_match_appearances` — sem colunas de evento, isso é escopo de uma tabela futura `match_events`), §1.5 (uma tabela `matches` central FOI criada, com `id` estável via registry — não o `match_source||':'||match_external_id` texto que a v3.1 sugeria como PK), e §5.2 (baseline+delta agora usa `kickoff_at` quando disponível pra resolver fronteira de mesmo-dia). `§2`/`player_positions` já estava correto e JÁ FOI aplicado de verdade na Etapa C (`supabase/migrations/20260902060000_create_player_positions.sql` ou equivalente) — não é mais proposta futura. Ver `docs/multiclub/17_etapa_e_v2_report.md` pro relatório completo desta revisão.

## 0. O problema, exatamente como apareceu

Tadeu completou 400 jogos pelo Goiás em 28/08/2026 (Goiás 2–1 São Bernardo). `career_players` já tinha 400 (atualizado). `squad_members` tinha 398 (não atualizado — era um snapshot de antes dessa partida). **Nenhuma das duas fontes estava "errada"** — elas só foram atualizadas em momentos diferentes, porque são cópias independentes do mesmo fato. Se Tadeu jogar de novo e chegar a 401, isso precisaria ser editado manualmente em pelo menos 2 lugares hoje (e mais, se `guess_players`/`goias_players.dart`/outros também guardassem o número). Essa é exatamente a arquitetura que este documento elimina.

## 1. Camadas do modelo

```
clubs                        -- id UUID + slug (§1.0) — novo nesta revisão
  ↓
people                      -- identidade global (já proposto, migration 20260901000000)
  ↓
player_club_spells          -- passagem pessoa × clube × período (pode ter 0 jogos)
  ↓
player_club_stats           -- 1 LINHA VIVA por pessoa × clube — o número "atual"
  ↑ atualizada por
player_match_appearances    -- 1 linha por comparecimento REAL (titular ou reserva que
                                entrou — nunca reserva não usado, ver §1.1), quando
                                existir cobertura — ver §5
```

### §1.0 `clubs` — `id` é UUID, nunca o slug (JÁ APLICADO — Etapa A/B, não é mais proposta)
`10_club_config.md` (rascunho anterior) usava `clubs.id = 'goias'` (texto) como chave relacional — exatamente o padrão que causou a colisão de slug do caso Danilo em `people` (`15_player_reconciliation_report.md`). Corrigido e **aplicado de verdade** em `supabase/migrations/20260902020000_create_clubs.sql` (Etapa A/B, já rodou no Supabase) antes de qualquer FK ser escrita:
```sql
create table clubs (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,      -- 'goias', 'juventude', ... — só pra URL/config, nunca FK
  display_name text not null,
  created_at timestamptz not null default now()
);
```
Toda referência a clube nas tabelas abaixo (`player_club_spells.club_id`, `player_club_stats.club_id`, `player_match_appearances.club_id`, e qualquer tabela futura) é `uuid references clubs(id)` — o app resolve `slug='goias'` → `clubs.id` uma vez no boot (mesmo padrão de resolução já usado hoje pra `CLUB_ID=goias` em `10_club_config.md`), nunca guarda o slug como chave em outro lugar.

### `people` (já proposto — sem mudança)
Só identidade: `id uuid`, `canonical_name`, `display_name`, timestamps. Nunca jogos/gols/período.

### `player_club_spells` — passagem, não estatística
```sql
create table player_club_spells (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people(id),
  club_id uuid not null references clubs(id),
  joined_at date,               -- ver §1.6 (precisão temporal) — pode ser só o ano
  joined_at_precision text not null default 'DAY',  -- 'YEAR' | 'MONTH' | 'DAY'
  left_at date,                 -- null = passagem em andamento
  left_at_precision text,       -- idem, null enquanto left_at for null
  registration_type text,       -- 'permanent' | 'loan' | 'contract_only' (ver caso Walter/2019 abaixo)
  position_primary text,        -- ver §2, nunca posição única "eterna"
  source text,
  source_external_id text,
  verified_at timestamptz
);
```
**Achado da reconciliação que isso resolve**: o caso Walter 2019 — ele foi recontratado em 2019 mas teve a suspensão por doping ampliada antes de reestrear, então essa passagem tem `registration_type='permanent'` (ou equivalente), `joined_at` preenchido, mas **zero jogos** — porque as estatísticas vivem em OUTRA tabela (`player_club_stats`/`player_match_appearances`), nunca embutidas aqui. Uma passagem sem jogos ainda é uma passagem real — o modelo já suporta isso de graça por construção, sem caso especial. Testado em `test_live_data_model.mjs` ("Walter: passagem real com 0 jogos é válida, não um erro").

### `player_club_stats` — o número VIVO, 1 linha só
```sql
create table player_club_stats (
  person_id uuid not null references people(id),
  club_id uuid not null references clubs(id),
  appearances int not null default 0,      -- baseline + delta, nunca incrementado cego — ver §5.2
  goals int not null default 0,
  assists int not null default 0,
  as_of_date date,               -- "válido até quando" — ver §4
  as_of_match_id text,           -- referência canônica à partida mais recente — ver §1.5
  source text not null,          -- 'derived_from_appearances' | 'external_sync' | 'manual_verified'
  last_synced_at timestamptz,
  verified_at timestamptz,
  primary key (person_id, club_id)
);
```
Este é o `UPDATE player_club_stats SET appearances = 401 WHERE person_id = TADEU AND club_id = GOIAS;` que a Parte 8 do pedido pede — literal, 1 linha, 1 update, e toda feature que ler daqui enxerga o valor novo imediatamente, sem precisar tocar em `squad_members`/`career_players`/`guess_players`/nada mais, porque essas tabelas PARARAM DE GUARDAR o número (ver §3).

### §1.1 `player_match_appearances` — status de comparecimento explícito, nunca `started boolean` sozinho (SCHEMA REAL, implementado)
A v1 deste documento usava só `started boolean`, que não distinguia "reserva que entrou" de "reserva que nunca saiu do banco" — os dois ficavam `started=false`, e um `COUNT(*)` ingênuo contaria os dois como aparição, o que está errado (Parte 3 do pedido). A v3.1 (rascunho) propunha um `enum appearance_status` com colunas de evento (gols/cartões/minutos) embutidas na própria linha de appearance — a Etapa E implementou de fato uma versão mais enxuta, e é ESTA a real (`supabase/migrations/20260902120000_create_player_match_appearances.sql`):
```sql
create table player_match_appearances (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people(id),
  club_id uuid not null references clubs(id),
  canonical_match_id uuid not null references matches(id),  -- ver §1.5 (schema real)
  spell_id uuid,  -- NULL quando ambíguo/sem overlap — nunca um palpite (ver relatório, decomposição A/B/C/D)
  participation_status text not null check (participation_status in ('STARTED', 'SUBSTITUTE_USED', 'UNUSED_SUBSTITUTE')),
  position_code text check (position_code in (/* catálogo de 15 códigos da Etapa C */)),
  shirt_number integer check (shirt_number > 0),
  verification_status text not null check (verification_status in ('VERIFIED', 'PARTIAL')),
  unique (person_id, club_id, canonical_match_id)   -- idempotência — ver §5.1
);
```
Diferenças deliberadas vs. a v3.1 rascunhada: **sem** `goals`/`assists`/`yellow_cards`/`red_cards`/`minutes_played`/`came_in_minute`/`came_out_minute` embutidos na linha — evento de partida (gol, cartão, substituição com minuto) é um fato granular por natureza e tem escopo próprio (`match_events`, tabela FUTURA, fora desta etapa) que não deveria viver misturado com "esteve nesta partida". `position_code` reusa o catálogo canônico de 15 códigos já fechado na Etapa C (`player_positions`), nunca um vocabulário paralelo. Regra de contagem (Parte 3 do pedido, implementada e testada em `test_player_match_appearances.mjs`): **só `STARTED` e `SUBSTITUTE_USED` contam como aparição** — `UNUSED_SUBSTITUTE` fica registrado (é dado real: "estava no banco naquela partida"), mas nunca soma pra `player_club_stats.appearances`.

**Limitação real do provider atual (OneFootball via Worker)**: `src/football/normalize/match_lineup.ts` + `onefootball_provider.ts` entregam `matchLineup.lineup` (titulares) e eventos de substituição (`playerIn`/`playerOut`), mas **nunca** a lista completa do banco de reservas — não dá pra afirmar `UNUSED_SUBSTITUTE` de forma completa com o dado hoje disponível. O schema SUPORTA os 3 estados; nenhum sync deste provider deve inventar `UNUSED_SUBSTITUTE`. O seed histórico desta etapa (`lineup_matches.json`, só titulares confirmados por auditoria) é 100% `STARTED`, exatamente porque é a única coisa que aquela fonte distingue.

### §1.5 Identidade canônica de partida — SCHEMA REAL, implementado (`matches` + `match_source_refs`)
A v1 deste documento (e o dataset atual) usa `match_id text` que ora significa um id de `passport_matches`, ora um fixture id do OneFootball — a mesma ambiguidade de namespace que causou a colisão de slug em `people` (Danilo), só que pra partida em vez de pessoa. A v3.1 (rascunho) propunha resolver isso só com um par de colunas `match_source`/`match_external_id` concatenadas em texto (`canonicalMatchId({source, externalId}) => "source:externalId"`), sem tabela central — **essa abordagem foi descartada**: ainda amarra a identidade de partida a UMA fonte só (o mesmo problema de raiz), e não resolve o cenário multi-clube (2 clubes, 2 fontes independentes, achando a MESMA partida — a segunda nunca teria como saber que o texto que ELA geraria já existe sob outro texto gerado pela primeira).

O que foi de fato implementado (`supabase/migrations/20260902100000_create_matches.sql`, `tooling/multiclub/match_registry.mjs`):
```sql
create table matches (
  id uuid primary key,   -- LITERAL, do match registry — nunca gen_random_uuid(), nunca derivado de texto de fonte
  home_club_id uuid references clubs(id),
  away_club_id uuid references clubs(id),
  home_team_name text not null,
  away_team_name text not null,
  kickoff_year int not null,
  kickoff_month int,                 -- NULL só quando kickoff_precision='YEAR'
  kickoff_date date not null,        -- placeholder de ordenação quando a precisão é coarse — nunca fato sem checar precision
  kickoff_at timestamptz,            -- só quando kickoff_precision='DATETIME'
  kickoff_precision text not null check (kickoff_precision in ('YEAR','MONTH','DATE','DATETIME')),
  competition text, season text, home_score int, away_score int,
  verification_status text not null check (verification_status in ('VERIFIED','PARTIAL')),
  check (home_club_id is not null or away_club_id is not null),
  check (home_club_id is null or away_club_id is null or home_club_id <> away_club_id)
);

create table match_source_refs (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references matches(id) on delete cascade,
  source_type text not null check (source_type in ('LINEUP_MATCH','PASSPORT_MATCH','ONEFOOTBALL')),
  source_ref text not null,
  external_match_id text,
  source_club_id uuid references clubs(id),
  unique (source_type, source_ref)   -- a MESMA identidade de fonte nunca aponta pra 2 matches
);
```
`matches.id` **nunca** é derivado de data/horário/nome de time/placar/competição, nem de nenhum id de fonte externa — vem de um `canonicalMatchKey` sequencial e imutável (`tooling/multiclub/matches_registry.json`), exatamente como `people`/`clubs`/`player_club_spells`. Identidade de fonte (`passport_matches.id`, o slug de `lineup_matches.json`, um futuro fixture id de provider) fica em `match_source_refs`, nunca em coluna de `matches` — é isso que resolve o cenário multi-clube: quando o Juventude importar sua própria base e encontrar a MESMA partida, a fonte dele vira uma **nova linha em `match_source_refs`** apontando pro **mesmo `matches.id`**, nunca uma 2ª linha em `matches`. Um candidate cujos anchors casam com 2 entradas JÁ registradas diferentes fica `BLOCKED_AMBIGUOUS_MATCH`/`ambiguous` — nunca resolvido sozinho (`match_registry.mjs.resolveMatchAnchors`). SPLIT/MERGE (2 registros que eram a mesma partida) usa a mesma filosofia ACTIVE/SUPERSEDED de `spell_registry.mjs` (`supersedeMatch()`), pronta mas não exercitada nesta etapa (só existe 1 fonte real hoje).

Precisão temporal do **kickoff**, específica de `matches` (distinta de `joined_at`/`left_at` de spells, que são um PERÍODO — ver §1.6): `YEAR` (nem mês é confiável — caso real: `lineup_matches.match_date` com padrão `YYYY-01-01`, mês E dia fabricados), `MONTH` (mês confiável, só o dia é placeholder — `YYYY-MM-01` com MM plausível), `DATE` (dia confirmado), `DATETIME` (horário confirmado, hoje só via `passport_matches.date_precision='datetime'` + `kickoff_at`). Um link `passport_matches` único e confiável SEMPRE tem prioridade sobre a data de `lineup_matches` quando existe — nunca promovido a uma precisão maior só porque o campo tem um valor.

### §1.5.1 Identidade viva de jogador por nome — BLOQUEADA nesta etapa (regra permanente pra qualquer sync futuro)
O provider atual (OneFootball via Worker) só devolve `name` pra jogador — nenhum id. Um sync futuro que tente resolver "de quem é esse `name`" pra gravar uma `player_match_appearances` viva **nunca** pode escolher a primeira pessoa que bate pelo nome. Regra obrigatória, permanente, pra qualquer código futuro de sync ao vivo:
```
1 pessoa casa de forma inequívoca no contexto permitido (ex.: nome + elenco atual do clube)
                                                                -> vira candidate, grava
2+ pessoas casam                                               -> AMBIGUOUS, NUNCA grava sozinho
0 pessoas casam                                                -> UNRESOLVED, NUNCA grava
```
Mesmo um match único por nome continua sendo uma estratégia de BAIXA CONFIANÇA/transitória — só deixa de ser transitória quando existir `player_external_ids` (ver `player_external_ids` — deliberadamente NÃO criado nesta etapa: nenhum provider hoje fornece um id de jogador real pra persistir; quando um provider futuro fornecer `provider`+`external_player_id`, essa tabela é criada e a resolução por nome deixa de ser necessária). Esta regra NÃO se aplica ao seed histórico desta etapa (`build_player_match_appearances_seed.mjs`), que nunca resolve por nome cru — só processa `person.members` já reconciliados manualmente/por override (Etapa A/v3.1).

### §1.6 Precisão temporal — nunca inventar dia/mês que a fonte não dá
Mesmo padrão já usado na auditoria de estádios do Passaporte (`joined_at`/`left_at` de `player_club_spells`, `date_original`/`date_precision` de `passport_matches`): se a fonte só sabe o ano ("2004"), `joined_at_precision='YEAR'` e `joined_at` fica no dia 1º de janeiro só como placeholder de ordenação — a UI NUNCA deve mostrar "01/01/2004" como se fosse uma data real, sempre reformatar conforme `*_precision`. Regras (implementadas e testadas em `live_data_model.mjs.temporalValue`):
```
YEAR   -- exige só o ano
MONTH  -- exige ano + mês
DAY    -- exige ano + mês + dia (data real e completa)
```

## 2. Posição deixa de ser um campo único e eterno

**Achado da reconciliação**: Dieguinho (Jackson Diego Ibraim Fagundes) já atuou como volante, lateral-direito e meia — o script v1/v2 tratava "LD" vs "MC" como sinal de identidade diferente, quando na verdade é a mesma pessoa sendo poliv­alente. A arquitetura precisa refletir isso estruturalmente, não só como exceção no heurístico de reconciliação. **Decisão de schema fechada nesta revisão** (a v1 deste documento deixava em aberto):

```sql
create table player_positions (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people(id),
  club_id uuid not null references clubs(id),
  position_code text not null,     -- 'volante' | 'lateral-direito' | 'meia' | ...
  is_primary boolean not null default false,
  valid_from date,                 -- null = desde sempre/desconhecido
  valid_to date,                   -- null = ainda vale
  source text not null,
  unique (person_id, club_id, position_code)
);
```
Uma pessoa pode ter N linhas nesta tabela pro mesmo `(person_id, club_id)` — só UMA marcada `is_primary=true` por vez (trocar a primária não apaga as secundárias; ver `live_data_model.mjs.addPosition`/`primaryPosition`, testado em `test_live_data_model.mjs` com o próprio caso do Dieguinho: volante+lateral-direito+meia, 3 linhas, 1 primária). `player_club_spells.position_primary` (campo já citado em §1) fica como um DESNORMALIZADO de leitura rápida = a linha `is_primary=true` desta tabela pro spell mais recente, nunca a fonte de verdade em si.

- `player_positions` — todas as posições conhecidas de uma pessoa NUM clube, com a primária marcada (editorial, revisável).
- `player_match_appearances.position` — a posição REALMENTE jogada naquela partida específica, sempre a fonte de verdade mais granular, e NUNCA decide sozinha se é a mesma pessoa (ver `pairCorroborated`/conflito de posição em `reconcile_players.mjs`). `lineup_matches.lineup[].pos` (a posição por partida que já existe hoje) é conceitualmente exatamente isso, só que hoje vive solta dentro do dataset da Arena em vez de alimentar um modelo central.

## 3. O que a Arena passa a fazer: referenciar, não copiar

Hoje `career_players`, `guess_players`, `lineup_matches`, `player_identity_references` cada um guarda sua PRÓPRIA cópia de nome/posição/período/número. O alvo:

```sql
-- career_players (Adivinhe o Jogador) — conceitualmente:
create table career_game_entries (
  id text primary key,           -- mantém o id atual, é só a chave de progresso do jogo
  person_id uuid not null references people(id),
  accepted_answers jsonb,         -- fica aqui: é editorial do JOGO (variações de resposta aceitas)
  sort_order int
  -- NADA de club_career/appearances/goals — isso já está em player_club_spells/player_club_stats
);
```
A tela do jogo faz join com `people`/`player_club_spells`/`player_club_stats` pra montar a pergunta ("quantos jogos ele tem pelo Goiás?") a partir da fonte viva — nunca lê um número congelado dentro de `career_game_entries`.

**Regra de decisão** (quando algo fica na feature vs. vira referência):
| Fica na feature (editorial do jogo) | Sai da feature (vira referência a `people`/spell/stats) |
|---|---|
| `accepted_answers` do Adivinhe o Jogador | nome completo, aliases |
| `data_status`/`photo_key` do Quem Vestiu o Manto (curadoria do jogo) | posição, camisa, nascimento |
| `formation_confidence` da Escalação (confiança editorial daquela escalação específica) | jogos/gols/período agregado |
| Atributos de estilo do "Que Craque..." (são o CONTEÚDO do jogo, não fato objetivo) | — |
| Posição NAQUELA partida específica em `lineup_matches` (isso é dado de partida real, mas fica granular por natureza — vira `player_match_appearances.position` quando migrado) | — |

## 4. Dado vivo vs. snapshot — nunca confundir os dois

- **LIVE**: "quantos jogos Tadeu tem pelo Goiás" — sempre lê `player_club_stats` no momento da consulta. Muda quando ele joga de novo. Toda tela que mostra "hoje" usa isso.
- **SNAPSHOT**: uma pergunta do Quiz do tipo "quantos jogos Tadeu tinha em X data" precisa de um valor CONGELADO daquela data, nunca recalculado. Isso vira um campo explícito na PRÓPRIA pergunta (`quiz_questions.options` já é jsonb — o valor histórico correto simplesmente fica escrito ali como texto/opção da pergunta, exatamente como já é hoje) — nunca uma referência dinâmica a `player_club_stats`. Se uma pergunta editorial cita um número, esse número É a resposta certa PRA SEMPRE, independente do jogador continuar jogando.
- Regra prática: **nunca copiar o valor vivo pra dentro de uma feature "por conveniência"**. Se a feature precisa do valor atual, ela referencia `player_club_stats` toda vez. Se a feature precisa de um valor histórico fixo, esse valor é conteúdo editorial da própria feature (uma pergunta de quiz, uma pergunta do "Adivinhe"), nunca um campo que parece dinâmico mas na verdade ficou parado.

## 5. `player_match_appearances` é viável hoje? — avaliação honesta

Baseado no que `04_external_integrations.md`/`06_database_audit.md` já documentaram sobre o que o Worker/OneFootball realmente fornece:

- **Partidas AO VIVO/recentes** (via `/api/football/fixtures/{id}`): o Worker já retorna `MatchLineups` (titulares+banco por time, com número de camisa e foto) e `MatchEvent` (minuto, lado, tipo — gol/cartão/substituição —, `player?` quando a fonte identifica o jogador). **Isso É suficiente pra popular `player_match_appearances` daqui pra frente**: `started` vem da escalação, `goals`/`yellow_cards`/`red_cards` vêm dos eventos com `player` atribuído, substituições dão `came_in`/`came_out`. **Assistências normalmente NÃO vêm** de forma confiável nesse tipo de provedor (confirmado: `MatchStat` do Worker não tem um tipo "assist" documentado) — teria que ficar `null`/não coletado até termos uma fonte melhor, nunca inventado.
- **Partidas HISTÓRICAS** (`passport_matches`, 2000-2026): **não é viável hoje**. Confirmado em `07_data_coverage.md` — o schema de `passport_matches` não tem colunas de escalação/eventos, e o dataset foi importado de um JSON pronto (RSSSF/oGol), não de uma API com granularidade por jogador. O pipeline "Futebol de Goyaz" (`04_external_integrations.md`) teoricamente teria esse nível de detalhe pra competições específicas, mas está pausado, nunca chegou a alimentar o Supabase.

**Estratégia recomendada — exatamente a que a Parte 5 do pedido sugeriu**:
1. **BASELINE VERIFICADO**: popular `player_club_stats` com um número atual confirmado por fonte confiável (ex.: Tadeu=400, `as_of_date=2026-08-28`, `as_of_match_id` apontando pra a partida Goiás×São Bernardo, `source='manual_verified'` ou `'external_sync'` dependendo de como foi confirmado) — SEM tentar reconstruir as 400 linhas individuais de `player_match_appearances` retroativamente.
2. **APARIÇÕES POSTERIORES**: a partir de agora, cada partida nova sincronizada do Worker gera linhas reais em `player_match_appearances` (`source='onefootball_worker'`), e um job RECALCULA `player_club_stats` a partir delas — nunca `appearances += 1` cego (ver §5.1, correção explícita desta revisão).
3. Isso dá exatidão total do baseline em diante, sem fingir que temos granularidade histórica que não existe, e sem bloquear o projeto esperando um backfill completo que pode nunca vir.

### §5.1 Sync idempotente — nunca `appearances += 1` executado cegamente
A v1 deste documento sugeria literalmente `appearances += 1` a cada sync — **isso está errado e foi corrigido nesta revisão**: um cron/webhook pode reprocessar a mesma partida (retry, reentrega, replay manual), e um incremento cego contaria a mesma partida 2×, 3×, 10× se o job rodar de novo. A correção tem duas partes:
1. **Unicidade na origem** — `player_match_appearances` tem `unique (person_id, club_id, canonical_match_id)` (§1.1). Sincronizar a mesma partida N vezes faz um `INSERT ... ON CONFLICT (person_id, club_id, canonical_match_id) DO UPDATE SET ...` — sempre a MESMA linha, nunca uma nova. Testado em `test_live_data_model.mjs` ("Mesma partida sincronizada 10x não duplica") via `AppearanceLedger.upsert`, a implementação de referência dessa mesma regra.
2. **`player_club_stats` é RECALCULADO, nunca incrementado** — a cada sync, o job roda algo equivalente a `appearances = baseline.appearances + COUNT(*) FROM player_match_appearances WHERE person_id=... AND club_id=... AND status IN ('STARTED','SUBSTITUTE_USED') AND recorded_at > baseline.as_of_date` (ou, de forma equivalente e mais barata, um trigger `AFTER INSERT OR UPDATE` em `player_match_appearances` que recalcula a linha correspondente de `player_club_stats` via `COUNT`) — nunca um `SET appearances = appearances + 1` solto em código de aplicação. `live_data_model.mjs.resolveLiveAppearances(baseline, ledger, personId, clubId)` implementa exatamente esse recálculo (soma o baseline a um `COUNT` filtrado, não a um contador imperativo) — testado com Tadeu especificamente: baseline 400 + 1 aparição real nova = 401, e resincronizar essa MESMA próxima partida 5× ainda dá 401 (não 405).

### §5.2 Baseline + delta — sempre rastreável, nunca implícito
Já introduzido no baseline do Tadeu acima; formalizado aqui como regra geral pra qualquer pessoa×clube:
```
player_club_stats.appearances = player_club_stats (linha "baseline", congelada em as_of_date/as_of_match_id)
                                + COUNT(player_match_appearances com status contável, ESTRITAMENTE posterior ao baseline)
```
Nunca um contador solto sem essa decomposição — qualquer auditoria futura ("por que esse número é esse?") precisa conseguir responder "baseline X + Y aparições registradas depois de as_of_date", nunca só um inteiro sem histórico. Implementado e testado em `tooling/multiclub/recompute_player_club_stats.mjs` (`computeDelta`/`recomputeTotal`, exercitado em `test_player_match_appearances.mjs`).

**Fronteira do mesmo dia, usando `kickoff_at` quando existir (correção desta revisão)**: partida do candidate estritamente anterior ao `as_of_date` nunca soma (backfill não aumenta o total); o próprio match do baseline (`canonical_match_id === as_of_match_id`) nunca soma de novo; estritamente posterior sempre soma (dedup por `canonical_match_id`, garante idempotência mesmo processando a mesma partida N vezes); **mesmo dia, partida DIFERENTE** — se os DOIS lados (baseline e candidate) têm `kickoff_at` confiável (precisão `DATETIME`), compara o TIMESTAMP: só soma se o candidate for estritamente posterior; se falta horário confiável de QUALQUER um dos lados, cai em `AMBIGUOUS_BOUNDARY` — nunca resolvido silenciosamente, sempre reportado pra revisão humana. A política é deliberadamente conservadora: só aproveita horário quando ele existe E é confiável dos dois lados, nunca assume uma ordem.

## 6. Pipeline de sincronização — nunca o Flutter fazendo scraping

```
site oficial do Goiás  ─┐
CBF                     ─┤
OneFootball (via Worker)─┼──▶  backend/job/sync  ──▶  Supabase  ──▶  Flutter (só leitura)
outra fonte auditada    ─┘         (Edge Function
                                     ou cron no Worker)
```

O Flutter **nunca** deve chamar essas fontes diretamente para dado de jogador — só lê do Supabase, exatamente como já faz hoje pra squad_members/quiz_questions/etc. O trabalho de sincronizar é 100% backend (Edge Function `SECURITY DEFINER` + `pg_cron`, no mesmo padrão já usado por `notifications-sync-and-check-access`/`notifications-poll-live-match` — ver `06_database_audit.md §8` — ou uma rota nova no Worker Cloudflare que já existe).

### Qual fonte pra qual tipo de dado

| Tipo de dado | Fonte recomendada | Por quê |
|---|---|---|
| Identidade/elenco/biografia (`people`, `player_club_spells.position_primary`, foto) | Site oficial do Goiás + CBF | Fontes primárias do próprio clube/confederação, mais confiáveis pra dado biográfico que um agregador de terceiro |
| Partidas/escalações/eventos ao vivo (`player_match_appearances` daqui pra frente) | OneFootball via Worker (já em uso) | Já integrado, já teve o formato de dado auditado em `04_external_integrations.md`, cobre exatamente o que `player_match_appearances` precisa (escalação+eventos) |
| Estatísticas acumuladas (`player_club_stats`) | **Derivado de `player_match_appearances` quando a cobertura permitir** (a partir do baseline); enquanto não houver cobertura suficiente, sincronizado periodicamente de uma fonte externa confiável (site oficial/CBF costumam publicar "jogos pelo clube" em perfis de jogador) | Preferir cálculo interno sempre que possível (menos dependência externa, mais auditável) — mas não bloquear o produto esperando cobertura completa |
| Histórico pré-2026 (`passport_matches`, `player_club_spells` de passagens antigas) | Continua sendo importação manual verificada (como já é hoje) — não há fonte automática confiável pra retroagir | Sem mudança — já é assim, e está correto assim |

### Campos de proveniência (repetidos em toda tabela que sincroniza de fora)
```
source              -- de onde veio esse dado ('official_site' | 'cbf' | 'onefootball_worker' | 'manual_verified' | ...)
source_external_id  -- id do jogador/partida na fonte externa, quando existir
last_synced_at       -- quando o job rodou por último pra essa linha
verified_at           -- quando um humano confirmou esse dado manualmente (nem todo sync precisa de verificação humana, mas quando tiver, fica registrado)
```

## 7. Status de atualidade — sempre visível, nunca implícito

`player_club_stats.as_of_date`/`as_of_match_id` (já no schema do §1) existem exatamente pra responder "400 jogos até quando?" em vez de um número solto sem contexto. Recomendo que a UI (fora do escopo desta etapa de dado) eventualmente mostre isso de forma discreta (ex.: tooltip "atualizado após Goiás 2-1 São Bernardo, 28/08/2026") em vez de só o número cru — mas isso é decisão de produto pra quando a tela for revisada, não parte do schema em si.

## 8. Prova de conceito da regra fundamental (Parte 8 do pedido)

Com este desenho — e já batendo com §5.1/§5.2 (o valor à direita do `set` é sempre baseline+delta RECALCULADO por fora, nunca `appearances + 1` dentro do próprio UPDATE):
```sql
update player_club_stats
set appearances = 401, as_of_date = '2026-09-05', as_of_match_id = 'onefootball_worker:fixture_xxxxx', last_synced_at = now()
where person_id = '<uuid do Tadeu>' and club_id = (select id from clubs where slug = 'goias');
```
1 UPDATE, 1 linha. Elenco, perfil, Arena, Adivinhe o Jogador, Quem Vestiu o Manto e qualquer outra tela que precise do número atual leem dessa mesma linha — nenhuma delas guarda uma cópia própria depois da migração completa (`03_data_sources.md`/`08_multiclub_data_contract.md` documentam a duplicação atual que isso substitui). Isso só é verdade DEPOIS que `career_players`/`guess_players`/`squad_members`/etc. pararem de guardar `appearances`/`goals` próprios — a migração de schema (`player_club_stats` existir) é necessária mas não suficiente; as features precisam ser migradas pra consumi-la, item que entra no plano de implementação incremental (não nesta etapa de design).

## 9. `person_aliases` — desenho do seed futuro (tabela ainda NÃO criada)

Motivado pela reconciliação v3.1 (`15_player_reconciliation_report.md`): `canonical_aliases.json` já modela isso hoje em memória (gerado por `apply_overrides.mjs`) — este parágrafo só documenta como isso vira tabela quando for a hora, sem criar nada agora.

```sql
-- PROPOSTA — não executar ainda, nem faz parte da migration 20260901000000
create table person_aliases (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people(id),
  alias text not null,                    -- forma original (ex.: "Nicolas")
  normalized_alias text not null,         -- normalizado (ex.: "nicolas") — ver normalize() em apply_overrides.mjs, mesma função
  source text,                            -- de onde veio esse alias (ex.: 'guess_players', 'goias_players_dart')
  -- SEM unique(normalized_alias) — homônimos são reais e esperados (Danilo/
  -- Michael/Nicolas hoje, mais no futuro conforme o histórico crescer).
  unique (person_id, normalized_alias)    -- só impede a MESMA pessoa duplicar o mesmo alias
);
```

**Regra de leitura, não de schema** (a tabela sozinha não impede consulta ingênua): todo lookup de alias precisa checar se `normalized_alias` bate com **mais de um `person_id`** antes de decidir — se sim, é um alias ambíguo (equivalente a `status='AMBIGUOUS_ALIAS'` em `canonical_aliases.json` hoje) e a aplicação NUNCA deve escolher um `person_id` sozinha; precisa de contexto adicional (data da partida, camisa, posição — o mesmo tipo de evidência que resolveu Nicolas/Danilo/Michael nesta reconciliação) ou perguntar ao humano. Um `select ... where normalized_alias = 'nicolas' limit 1` é exatamente o bug que este desenho existe pra prevenir — a consulta correta é `select person_id from person_aliases where normalized_alias = 'nicolas'` (sem `limit 1`) seguida de uma decisão explícita quando vier mais de 1 linha.

Seed futuro (quando a tabela existir): 1 INSERT por linha de `canonical_aliases.json`, expandido — hoje o JSON agrupa por alias com uma lista de `refs`; a tabela inverte pra 1 linha por (person, alias), que é o formato natural de FK. Nenhuma transformação de dado, só de forma.
