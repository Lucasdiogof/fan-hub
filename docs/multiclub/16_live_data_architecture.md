# 16 — Arquitetura de Dado Vivo vs. Snapshot (Jogadores)

> Proposta de design — nada implementado, nenhuma tabela criada além da `people` já proposta em `10_club_config.md`/migration `20260901000000_create_people.sql`. Gerado em 2026-09-01, motivado por um requisito que ficou evidente durante a reconciliação (`15_player_reconciliation_report.md`): o caso Tadeu (398×400 jogos) não era um erro de dado — era o sintoma de não existir UMA fonte viva única para estatística de jogador. Este documento resolve isso.
>
> **Revisão v3.1 (mesma data)** — firma 6 pontos que a v1 deste documento deixava como "decisão a fechar depois": `club_id` vira `uuid` (não mais texto), `player_match_appearances` ganha um status explícito de comparecimento (titular/reserva-usado/reserva-não-usado, nunca contando quem não entrou), o sync ganha uma chave de idempotência formal (§5.1), a identidade de partida ganha um namespace explícito por fonte (§1.5) em vez de um `match_id text` ambíguo, `joined_at`/`left_at` ganham precisão temporal explícita (§1.6), e posição múltipla (§2) deixa de ser "decisão futura" e vira `player_positions`, a mesma tabela já usada pra validar os 7 cenários de teste em `tooling/multiclub/test_live_data_model.mjs`/`live_data_model.mjs` (implementação de referência em memória, não o schema real — prova o desenho antes do INSERT).

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

### §1.0 `clubs` — `id` é UUID, nunca o slug (NOVO nesta revisão)
`10_club_config.md` (rascunho anterior) usava `clubs.id = 'goias'` (texto) como chave relacional — exatamente o padrão que causou a colisão de slug do caso Danilo em `people` (`15_player_reconciliation_report.md`). Corrigido aqui antes de qualquer FK ser escrita:
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

### §1.1 `player_match_appearances` — status de comparecimento explícito, nunca `started boolean` sozinho
A v1 deste documento usava só `started boolean`, que não distinguia "reserva que entrou" de "reserva que nunca saiu do banco" — os dois ficavam `started=false`, e um `COUNT(*)` ingênuo contaria os dois como aparição, o que está errado (Parte 3 do pedido). Corrigido:
```sql
create type appearance_status as enum ('STARTED', 'SUBSTITUTE_USED', 'UNUSED_SUBSTITUTE');

create table player_match_appearances (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people(id),
  club_id uuid not null references clubs(id),
  match_source text not null,     -- ver §1.5 — nunca um match_id ambíguo sozinho
  match_external_id text not null,
  canonical_match_id text generated always as (match_source || ':' || match_external_id) stored,
  status appearance_status not null,
  came_in_minute int,             -- só quando status = SUBSTITUTE_USED
  came_out_minute int,
  shirt_number int,
  position text,                  -- posição NAQUELA partida, nunca a "posição da pessoa"
  goals int default 0,
  assists int default 0,
  yellow_cards int default 0,
  red_cards int default 0,
  minutes_played int,
  source text not null,
  source_external_id text,
  recorded_at timestamptz not null default now(),
  unique (person_id, club_id, canonical_match_id)   -- idempotência — ver §5.1
);
```
Regra de contagem (Parte 3 do pedido, implementada e testada em `live_data_model.mjs`/`countsAsAppearance`): **só `STARTED` e `SUBSTITUTE_USED` contam como aparição** — `UNUSED_SUBSTITUTE` fica registrado (é dado real: "estava no banco naquela partida"), mas nunca soma pra `player_club_stats.appearances`. `player_club_stats.appearances/goals/assists` idealmente é `COUNT`/`SUM` filtrado por `status IN ('STARTED','SUBSTITUTE_USED')` desta tabela — mas só quando a cobertura permitir (ver §5, é exatamente por isso que as duas tabelas são separadas: uma é o agregado vivo consultável rápido, a outra é o detalhe que idealmente a alimenta).

### §1.5 Identidade canônica de partida — nunca um `match_id text` ambíguo
A v1 deste documento (e o dataset atual) usa `match_id text` que ora significa um id de `passport_matches`, ora um fixture id do OneFootball — a mesma ambiguidade de namespace que causou a colisão de slug em `people` (Danilo), só que pra partida em vez de pessoa. Resolvido com namespace explícito, sem precisar criar uma tabela `matches` central nesta etapa (fica como evolução futura se o número de fontes crescer):
```
match_source        -- 'passport_matches' | 'onefootball_worker' | ... — de onde veio o id
match_external_id   -- o id NAQUELA fonte (ex.: 'pe_cb52680435343cc4' pra passport_matches)
canonical_match_id  -- match_source || ':' || match_external_id — SEMPRE usado como chave,
                        nunca match_external_id sozinho
```
`live_data_model.mjs.canonicalMatchId({source, externalId})` implementa isso — usado tanto no baseline do Tadeu (`as_of_match_id = 'passport_matches:pe_cb52680435343cc4'`, atualizando a nomenclatura livre "pe_..." que os overrides de reconciliação usaram) quanto em cada linha nova de `player_match_appearances`. Se/quando uma tabela `matches` central for criada, `canonical_match_id` vira sua PK e as duas colunas (`match_source`/`match_external_id`) continuam existindo como o jeito de POPULAR essa PK — não é trabalho perdido.

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
                                + COUNT(player_match_appearances com status contável, recorded_at > as_of_date)
```
Nunca um contador solto sem essa decomposição — qualquer auditoria futura ("por que esse número é esse?") precisa conseguir responder "baseline X + Y aparições registradas depois de as_of_date", nunca só um inteiro sem histórico.

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
