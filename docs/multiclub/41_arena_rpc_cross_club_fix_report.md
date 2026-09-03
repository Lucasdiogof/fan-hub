# Micro-etapa pré-M4 — corrigir `arena_record_score_for_club`

Data: 2026-09-03
Status: design + testes prontos, aplicação autorizada nesta rodada. `0 git push`.

Autorizada pelo dono logo após o fechamento da M2.2B-B (`280e1ae`, `HEAD==origin/main`), como pré-condição registrada para desbloquear M4 no futuro (`M4_BLOCKED_BY_ARENA_RPC_FIX`).

---

## 1. Preflight

`HEAD == origin/main == 280e1ae`. `git status` limpo (só exclusões-padrão + leftovers legítimos de rodadas anteriores). `npx supabase migration list`: **56 local = 56 remote, 0 pending** antes de criar a migration desta rodada.

## 2. Leitura da função LIVE (não a migration histórica)

Assinatura exata, via `pg_proc`:

```
arena_record_score_for_club(
  p_club_id uuid, p_game_id text, p_item_id text, p_event_type text,
  p_attempt_number integer, p_difficulty text, p_wrong_count integer,
  p_found_count integer, p_total_count integer, p_was_revealed boolean,
  p_was_abandoned boolean
) returns table(points_delta integer, item_score integer, total_score integer, game_score integer)
security definer, search_path = pg_catalog, public, pg_temp
```

Corpo completo extraído via `pg_proc.prosrc` (não a migration `20260903090000` que originalmente criou a função) e lido linha a linha.

## 3. Auditoria completa do corpo — divergência real encontrada

Classificação de **todo** acesso a tabela tenant-scoped na função:

| Query | Filtro ao vivo | Classificação |
|---|---|---|
| `public.clubs` (valida `p_club_id`) | `where id = p_club_id` | `GLOBAL_INTENTIONAL` |
| `quiz_questions`/`career_players`/`guess_players`/`lineup_matches` (valida `item_id`) | `where id = p_item_id and club_id = p_club_id` | `CLUB_SCOPED_CORRECT` (4/4) |
| **`v_prev` SELECT** (`user_game_item_progress`, antes do `for update`) | `where user_id = v_uid and game_id = p_game_id and item_id = p_item_id` — **sem `club_id`** | **`MISSING_CLUB_FILTER`** |
| INSERT `user_game_item_progress` | `club_id` na lista de colunas + `on conflict (club_id, user_id, game_id, item_id)` | `CLUB_SCOPED_CORRECT` |
| INSERT `score_events` | `club_id` na lista de colunas | `CLUB_SCOPED_CORRECT` |
| soma `total_score` (retorno) | `where user_id = v_uid and club_id = p_club_id` | `CLUB_SCOPED_CORRECT` |
| soma `game_score` (retorno) | `where user_id = v_uid and club_id = p_club_id and game_id = p_game_id` | `CLUB_SCOPED_CORRECT` |

**Achado real diverge da premissa original registrada em M2.2B-B round 1** (relatório 40 / memória do projeto), que listava 3 leituras problemáticas (`v_prev`, `total_score`, `game_score`). A auditoria ao vivo desta rodada confirmou que **só `v_prev` estava de fato sem `club_id = p_club_id`** — as duas somas já filtravam corretamente. Reportado ao dono antes de qualquer edição; dono confirmou reduzir o escopo ao defeito real, sem tocar no que já estava certo.

```
ARENA_RPC_MISSING_CLUB_FILTER_COUNT_BEFORE=1
ARENA_RPC_MISSING_CLUB_FILTER_COUNT_AFTER=0
```

Nenhum quarto problema (leitura/escrita tenant-scoped sem `club_id`) foi encontrado na varredura completa do corpo.

## 4. Decisão sobre o guard `key_scope_collision`

```sql
if v_prev.user_id is not null and v_prev.club_id is distinct from p_club_id then
  raise exception 'key_scope_collision: ...';
end if;
```

Com `v_prev` agora filtrado por `club_id = p_club_id`, a condição `v_prev.club_id is distinct from p_club_id` nunca mais pode ser verdadeira — o guard fica estruturalmente inalcançável. Decisão: **`KEEP_DEFENSIVELY`** (preferência explícita do dono, sem motivo técnico forte para remover) — código morto inofensivo, mantido como documentação histórica do porquê o guard existia (proteção contra colidir com a PK legada, já removida desde `KEY_SCOPE_FINAL=true`).

## 5. Migration

`supabase/migrations/20260903150000_fix_arena_score_cross_club_reads.sql` — `CREATE OR REPLACE FUNCTION`, única mudança real no corpo: adiciona `and club_id = p_club_id` ao SELECT de `v_prev`. `total_score`/`game_score` permanecem **byte-idênticos** (nenhuma reescrita cosmética). Preservados integralmente: assinatura, tipo de retorno, `SECURITY DEFINER`, `search_path`, semântica de pontuação, `ON CONFLICT (club_id, user_id, game_id, item_id)`, guards existentes, mensagens de erro. Guard `clubs=1+goias` no início do arquivo, mesmo padrão de toda migration desta etapa. 0 `DROP TABLE`/`CASCADE`/`TRUNCATE`.

## 6. ACL

`CREATE OR REPLACE FUNCTION` preserva o ACL existente no Postgres (mesmo OID), mas a migration declara explicitamente por segurança e auditabilidade, seguindo a regra permanente do projeto:

```sql
revoke all on function public.arena_record_score_for_club(
  uuid, text, text, text, integer, text, integer, integer, integer, boolean, boolean
) from public, anon, service_role;

grant execute on function public.arena_record_score_for_club(
  uuid, text, text, text, integer, text, integer, integer, integer, boolean, boolean
) to authenticated;
```

Assinatura do `REVOKE`/`GRANT` conferida termo a termo contra a `CREATE FUNCTION` (mesma classe de bug do M3.4 round 1, agora coberta por tooling — ver §8).

## 7. Testes SQL funcionais

Optou-se por prova **estrutural** (via `prosrc`/texto da migration, com extração de bloco por âncora — nunca grep genérico) em vez de dados fabricados em transação, já que a semântica de isolamento (soma só do `club_id` ativo, `v_prev` só enxerga linha do próprio clube) é inteiramente demonstrável estaticamente a partir do SQL que será executado — sem necessidade de inserir linhas sintéticas mesmo dentro de `BEGIN/ROLLBACK`. Nenhum dado fabricado, nenhum segundo clube.

## 8. Tooling

Novo `tooling/multiclub/audit_arena_rpc_cross_club_fix.mjs` + `test_arena_rpc_cross_club_fix.mjs` (18 testes). Cada query é extraída do corpo por âncora textual e validada **individualmente** (nunca uma busca genérica pela string `club_id` em qualquer lugar do arquivo):

- `arenaScorePrevReadClubScoped` — bloco do SELECT de `v_prev` isolado, checa `club_id`+`user_id`+`game_id`+`item_id` juntos
- `arenaScoreTotalScoreClubScoped` — bloco da soma `total_score` isolado
- `arenaScoreGameScoreClubScoped` — bloco da soma `game_score` isolado
- `arenaScoreConflictTargetTenantAware` — bloco do INSERT/ON CONFLICT isolado
- `arenaScoreAclCorrect` — REVOKE/GRANT com assinatura exata, roles corretos
- `arenaScoreCrossClubReady` — agregado

6 testes fabricados provam que cada check derruba **só o seu próprio check** quando o filtro correspondente é removido (v_prev quebrado não derruba total_score/game_score, e vice-versa) — prova de que a validação é por-query, não superficial. Mais 2 fabricados reproduzindo a classe de bug real do M3.4 (ON CONFLICT voltando à chave legada; GRANT vazando pra `anon`; assinatura do REVOKE divergindo da CREATE FUNCTION).

## 9. Gates

- JS `tooling/**/test_*.mjs`: **795 passando, 0 falhando** (777 baseline + 18 novos)
- `flutter analyze`: **0 issues**
- `flutter test`: **896 passed / 1 skip** (0 `.dart` alterado — reconfirmação, não trabalho novo)
- `npx supabase migration list`: **57 local / 56 remote / 1 pending**, dry-run lista exatamente `20260903150000_fix_arena_score_cross_club_reads.sql`

## 10-19. Aplicação

Ver seção **APLICAÇÃO** abaixo (preenchida após o `db push` real).

---

## Estados após esta micro-etapa

`ARENA_RPC_CROSS_CLUB_READ_FIX_PENDING=false` · `M4_BLOCKED_BY_ARENA_RPC_FIX=false` · `KEY_SCOPE_FINAL=true` (inalterado) · `KEY_SCOPE_SECOND_CLUB_BLOCKER=false` (inalterado) · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` (inalterado) · `PASSPORT_TENANCY_DEFERRED=true` (inalterado) · **`SECOND_CLUB_PRODUCT_READY=false`** (este fix remove só este blocker específico — NÃO significa pronto para um 2º clube real).

---

**PARE.** Não iniciar M4. Não cadastrar segundo clube. `0 git push` nesta rodada.
