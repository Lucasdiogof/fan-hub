# Etapa M3.2 — Tenant-Aware User State + RPC Compatibility

Data: 2026-09-02 (1ª rodada e rodada de hardening de segurança, ver §51-60 — mesmo dia, sem convenção de timestamp que justifique data futura)
Status: **M3.2 APPLIED (2026-09-02). 5 migrations da M3.2 aplicadas (46/46 local=remote, 0 mismatch). 8 RPCs tenant-aware ativas. ACL hardened authenticated-only (validado via `has_function_privilege` + `proacl`, 8/8). Commit ainda pendente de autorização separada — ver §65+.**

Roadmap: `M2.2A ✅ → M3.1 ✅ → M3.2 ← AGORA → M3.3 → M2.2B → M4`. `SECOND_CLUB_BLOCKED = true` (inalterado).

---

## 0. Confirmação de Git (antes de qualquer alteração)

```
git rev-parse HEAD  →  ce23d5bb30ba05cab5bf3016658aff4b1bc7c075
git log -4 --oneline:
  ce23d5b docs(multiclub): record M3.1 commit hash and final test totals
  f69b4b1 feat(multiclub): scope content runtime by club
  bd18226 docs(multiclub): record M2.2A commit hash and post-push validation
  0d5db94 feat(multiclub): add additive tenant schema
git status: limpo — só as exclusões-padrão (store_entry_card.dart modificado
  não-staged, multiclub_hardcode_audit_stats.json idem, _competitions_pkg/,
  migration_dump.txt, docs/multiclub/19_etapa_e_v4_applied_report.md
  untracked, todos pré-existentes)
```

`ce23d5b` confere exatamente com o que o relatório da M3.1 registrou como commit docs-only posterior ao `f69b4b1` — nada assumido, conferido ao vivo. **0 `git push`.**

## 1. Escopo da M3.2 — reauditado antes de editar

A lista do pedido foi tratada como ponto de partida, não como verdade cega — reaudite cada tabela/RPC contra o código real (`lib/` + `supabase/`) antes de tocar em qualquer arquivo. Achados relevantes vs. a lista original:

- **`create_store_order` É uma RPC de verdade** (não um insert direto) — confirmado lendo `supabase/store_orders.sql`. `subscribe_to_plan` também é uma RPC real e é chamada pelo Flutter (`submitRegistration`) — não estava na lista original do pedido (só `get_my_membership_for_club` estava nomeada), mas grava em `supporter_memberships` (tabela CRÍTICA explicitamente no escopo) sem `club_id`; deixá-la de fora deixaria o WRITE de assinatura permanentemente preso ao Goiás mesmo com a leitura corrigida — decisão registrada explicitamente aqui (item 15 abaixo), não escondida.
- **`ticket_checkin_decisions`/`ticket_orders`/`tickets` não têm RPC nenhuma** — confirmado: são `.upsert()`/`.insert()`/`.update()` diretos em `MockTicketRepository`, protegidos só por RLS. Não existe "RPC de check-in" pra criar — o pedido já cobria essa possibilidade condicionalmente (item 19), e a resposta é: não existe.
- **`match_monitor_sessions`/`notification_events`/`notification_deliveries` são 100% Edge Function (Deno)** — zero owner Dart. Confirmado via grep no repo inteiro (não só `lib/`) e leitura de `supabase/functions/notifications-{sync-and-check-access,poll-live-match,dispatch}/index.ts`. Essas 3 funções já usam `GOIAS_TEAM_ID = 1863` hardcoded (`notifications-poll-live-match/index.ts`) — não existe hoje nenhum equivalente de `ClubConfig` do lado do servidor. Ver §44 (fora de escopo, M3.3).

Full audit (read-only) cobriu as 19 tabelas + 8 alvos de RPC listados no pedido, com file:line de cada `.from()`/`.rpc()` real, PK/UNIQUE de cada uma, e SQL exato de cada função — usado como base de todo o resto deste relatório.

## 2. Fora de escopo — confirmado intocado

`passport_matches`/`passport_attendances`/`passport_memorable_matches`: `supabase_passport_repository.dart` sem `_clubConfig`/`club_id` (testado). PK composta definitiva, `UNIQUE(club_id,...)`, remoção do `DEFAULT` Goiás, RLS tenant enforcement estrito, flavors, 2º clube real: nenhum tocado — tudo isso é M2.2B/M4.

## 3-4. Regra central — `clubConfig.identity.canonicalClubId` explícito, nunca `DEFAULT`

Todas as 14 tabelas com leitura/escrita direta e todas as 8 RPCs novas recebem o UUID via `ClubConfig` — nunca dependem do `DEFAULT` Goiás da M2.2A (que continua existindo só pra compatibilidade do app antigo). Confirmado por teste estático (`hasClubIdInReads`/`hasClubIdInWrites`/`hasClubIdParam` — ver §39 da tooling).

## 5. Reads diretos — `.eq('club_id', ...)`, auditado inclusive `.maybeSingle()`/`.single()`/`.order()`/`.limit()`

Todas as 14 tabelas com leitura direta ganharam `.eq('club_id', _clubConfig.identity.canonicalClubId)` — sempre ANTES de `.maybeSingle()`/`.limit()`/`.order()` na cadeia (nunca depois, o que mudaria a semântica). Auditado manualmente arquivo por arquivo, não só via regex.

## 6. Writes diretos — `club_id` explícito, nunca confia no `DEFAULT`

Diferente da M3.1 (só leitura), toda tabela tenant-scoped com INSERT/UPSERT direto ganhou `'club_id': _clubConfig.identity.canonicalClubId` no payload: `quiz_question_progress`, `quiz_active_session`, `career_path_progress`, `lineup_match_progress`, `arena_selected_content` (2 owners), `arena_achievements`, `player_identity_results`, `tactical_identity_results`, `match_lineup_votes`, `ticket_checkin_decisions`, `tickets`, `ticket_orders`, `user_notification_preferences`. `store_orders` grava via RPC (`create_store_order_for_club`), não via insert direto — `p_club_id` explícito lá.

## 7. Update/Delete — tenant filter completo, nunca só `club_id` isolado

`MockTicketRepository.undoCheckIn`/`clearCheckInDecision`/`requestRefund`: todo `update()`/`delete()` ganhou `.eq('club_id', ...)` **junto** com `.eq('user_id', _uid)` e as demais chaves já existentes (`match_id`/`origin`/`status`) — nunca um update de uma conta alcançando a linha de outro clube da MESMA conta, porque a query em si já exige as duas condições simultaneamente (AND implícito do builder), nunca `club_id` sozinho decidindo o alvo.

## 8. Arena — cadeia content → progress → score → ranking fechada

Auditado cada elo: `career_players`/`guess_players`/`lineup_matches`/`quiz_questions` (já `club_id` desde a M3.1) → `quiz_question_progress`/`career_path_progress`/`lineup_match_progress`/`arena_selected_content` (ganharam `club_id` agora) → `user_game_item_progress`/`score_events` (ganham `club_id` só dentro da RPC `arena_record_score_for_club`, nunca via write direto do Flutter — essas 2 tabelas nunca tiveram owner Dart, sempre foram RPC-only) → `arena_ranking_for_club`/`arena_my_rank_for_club`/`arena_user_detail_for_club` (filtram por `club_id` nas 3). Cada elo novo carrega o MESMO `club_id` do `ClubConfig` ativo — nenhum elo intermediário fica sem filtro (o que deixaria a cadeia "vazar" no meio mesmo com as pontas corretas).

## 9-14. `arena_record_score_for_club` — nova, aditiva, com validação e segurança

`supabase/migrations/20260903000000_add_arena_tenant_aware_rpcs.sql`. Recebe `p_club_id uuid` como 1º parâmetro (nunca opcional, nunca com `default`). Valida:
```sql
if p_club_id is null then raise exception 'p_club_id is required'; end if;
if not exists (select 1 from public.clubs where id = p_club_id) then
  raise exception 'unknown club_id %', p_club_id;
end if;
```
— rejeita `NULL` e clube inexistente, nunca aceita silenciosamente Goiás. A validação de `item_id` (já existia na legacy) agora TAMBÉM exige `club_id = p_club_id` na tabela de conteúdo (`quiz_questions`/`career_players`/`guess_players`/`lineup_matches`), então um `item_id` real de OUTRO clube é rejeitado igual a um `item_id` inventado.

**Segurança do usuário preservada**: `v_uid uuid := auth.uid();` continua sendo a ÚNICA fonte de identidade — a função nunca aceita `p_user_id` do cliente (mesma decisão de design da legacy, nunca enfraquecida pra adicionar tenancy).

**Legacy `arena_record_score` — intacta**: `create or replace function public.arena_record_score(...)` continua existindo, com a MESMA assinatura, no MESMO arquivo-fonte (`supabase/arena_ranking.sql`) e na migration histórica que a registrou (`20260830220001_arena_record_score_item_validation.sql`) — não editada nesta rodada. Confirmado via teste estático que nenhum caractere dela mudou (`legacySqlStillDefined`).

**KEY_SCOPE — achado crítico, resolvido com uma trava, não com corrupção silenciosa**: `user_game_item_progress` tem `PRIMARY KEY (user_id, game_id, item_id)` **sem `club_id` na chave** (KEY_SCOPE ainda bloqueado, M2.2B resolve). Isso significa que, com um 2º clube real, a MESMA tripla `(user_id, game_id, item_id)` poderia existir sob 2 clubes diferentes e colidir no `on conflict`. `arena_record_score_for_club` fecha isso com uma trava explícita:
```sql
if v_prev.user_id is not null and v_prev.club_id is distinct from p_club_id then
  raise exception 'key_scope_collision: item % (game %) already has progress under a different club_id (KEY_SCOPE not yet resolved, see M2.2B)', ...;
end if;
```
— uma colisão vira **erro alto e explícito**, nunca uma sobrescrita silenciosa que trocaria a "dona" da linha de um clube pro outro. Hoje isso é puramente teórico (`clubRegistry` só tem `'goias'`), mas a função já nasce correta pro dia em que deixar de ser — sem precisar de outra correção depois.

Totais (`total_score`/`game_score`) retornados pela função também filtram por `club_id = p_club_id` — nunca soma cross-club, mesma regra das RPCs de ranking (§13).

## 13-14. Ranking — 3 RPCs novas, legacy preservada

`arena_ranking_for_club(p_club_id, p_period, p_limit)`, `arena_my_rank_for_club(p_club_id, p_period)`, `arena_user_detail_for_club(p_club_id, p_user_id)` — as 3 filtram `score_events`/`user_game_item_progress` por `club_id = p_club_id`, nunca cross-club. `arena_ranking`/`arena_my_rank`/`arena_user_detail` legacy continuam byte-idênticas (mesmo arquivo-fonte, nenhuma linha alterada) — servem só o app antigo. `arena_user_detail_for_club` preserva a mesma decisão de design da legacy (confia em `p_user_id`, não em `auth.uid()` — é o bottom sheet ao tocar em qualquer um no ranking, não "meus dados").

## 15-16. Membership — CRITICAL, corrigido de verdade

`supabase/migrations/20260903010000_add_membership_tenant_aware_rpcs.sql`. `get_my_membership_for_club(p_club_id)`:
```sql
where m.user_id = auth.uid() and m.club_id = p_club_id
order by m.created_at desc
limit 1;
```
— nunca mais `order by created_at desc limit 1` GLOBAL (o achado crítico documentado desde a M1: numa base multi-clube real, isso vazaria a assinatura mais recente de QUALQUER clube pro usuário). `get_my_membership()` legacy continua intacta.

**Extensão justificada além da lista original** (registrada explicitamente, não escondida — ver §1): `subscribe_to_plan_for_club(p_club_id, p_plan_id)` foi criada porque `subscribe_to_plan` é o ÚNICO write real em `supporter_memberships`, chamado por `submitRegistration` no Flutter. Sem essa 2ª RPC, a leitura ficaria corrigida mas toda NOVA assinatura continuaria caindo no `DEFAULT` Goiás pra sempre. Mesma trava de concorrência da legacy (`pg_advisory_xact_lock`), agora escopada por `(user_id, club_id)` — permite assinaturas ativas simultâneas em clubes diferentes (mesmo padrão já adotado em `user_notification_preferences`), nunca 2 ativas no MESMO clube.

**Teste obrigatório (mesmo user, clubA/clubB, ativo A nunca lê B)**: coberto no grupo "Membership" de `club_scoped_user_state_test.dart` — `getMyMembership`/`submitRegistration` testados com `goiasClubConfig` E `syntheticClubBConfig` (fixture sintética, nunca cadastrada em `clubRegistry`, nunca um clube real nomeado), provando por captura de payload real que `p_club_id` muda com o clube ativo e nunca é o UUID do Goiás quando o clube ativo é o sintético.

## 17-18. Crowd Lineup — write direto + RPC nova, `match_id` tratado com `club_id` junto

`match_lineup_votes` já tinha `club_id` (M2.2A) — `submitVote`/`getMyVote` agora gravam/filtram por ele. Nova `crowd_lineup_for_club(p_club_id, p_match_id)` (`20260903020000_add_crowd_lineup_tenant_aware_rpc.sql`) filtra a CTE base por `match_id = p_match_id and club_id = p_club_id` — sem isso, 2 clubes votando numa partida com o MESMO `match_id` (sem namespace global comprovado, ver §18 do pedido) misturariam votos. `crowd_lineup(p_match_id)` legacy intacta. Toda query nova (inclusive dentro da RPC) já trata `club_id + match_id` como a identidade runtime da partida — nenhuma PK trocada ainda, mas nenhuma query nova confia só em `match_id`.

## 19. Ticket check-in — sem RPC, filtros diretos completos

`ticket_checkin_decisions`/`ticket_orders`/`tickets`: reads com `club_id` filter, writes com `club_id` explícito, updates/deletes com `club_id` filter OBRIGATÓRIO junto de `user_id` (nunca `club_id` sozinho) — confirmado item por item em `mock_ticket_repository.dart` (8 pontos de leitura/escrita, todos ajustados). PK/UNIQUE não alterada (`ticket_checkin_decisions` PK composta `(user_id, match_id)`, `tickets` índice parcial `(user_id, match_id) WHERE origin='membership_check_in'` — ambos KEY_SCOPE_BLOCKED, registrado na tooling; `ticket_orders` não tem UNIQUE nenhuma em `number`, então não há chave física pra colidir).

## 20-21. Store — `create_store_order_for_club`, `order_number` preservado

Novo write via RPC (`20260903030000_add_store_tenant_aware_rpc.sql`): `create_store_order_for_club(p_club_id, ...)` — mesma lógica da legacy (insere o pedido + itens numa transação `plpgsql`, sem `security definer`, confiando na policy `insert own orders` já existente), só que grava `club_id` explícito em vez de depender do `DEFAULT`. `create_store_order` legacy intacta. `UNIQUE(order_number)`/sequence global/prefixo `"GOI-"` **preservados exatamente como estavam** — `generate_store_order_number()` continua hardcoded, nada de `ClubIntegrations.orderPrefix` (que já existia como campo documentado-mas-inerte desde a M1) foi ligado a nada. Prefixo/branding fica pra M3.3/M4, conforme o pedido explícito.

## 22. Notification preferences — ROW_SCOPE pronto, KEY_SCOPE explicitamente bloqueado

`user_notification_preferences`: `getPreferences`/`updatePreferences` agora leem/escrevem por `user_id` + `club_id`. PK continua só `user_id` — `onConflict: 'user_id'` inalterado. **Nenhuma tentativa de criar uma 2ª linha de preferências de um clube sintético em produção/real** — a única prova de comportamento sob 2 clubes é via `CapturingHttpClient` + `syntheticClubBConfig` (mock/fake), nunca uma chamada de rede de verdade. `ROW_SCOPE_READY=true`/`KEY_SCOPE_BLOCKED=true` registrados explicitamente na tooling.

## 23-24. Notification events / match monitor sessions — fora do Dart, documentado

**Decisão explícita, não uma omissão**: `notification_events` e `match_monitor_sessions` são escritos e lidos EXCLUSIVAMENTE por 3 Supabase Edge Functions (Deno, `supabase/functions/`), nunca pelo Flutter — confirmado por auditoria completa do repositório (não só `lib/`). Essas funções hoje são 100% hardcoded pro Goiás (`GOIAS_TEAM_ID = 1863` em `notifications-poll-live-match/index.ts`, URL do Worker fixa) — não existe um `ClubConfig` equivalente do lado do servidor, e criar um agora seria escopo da M3.3 (generalização do Worker/pipeline), não da M3.2 (que o próprio pedido restringe a Flutter + RPCs Postgres). As 2 tabelas continuam com `club_id` (herdado do `DEFAULT` Goiás da M2.2A, nunca explícito) e `KEY_SCOPE_BLOCKED`/`ROW_SCOPE` (server-side) registrados como pendentes até M2.2B/M3.3, exatamente como o pedido antecipou pra essas 2. Nenhum arquivo Deno foi tocado nesta etapa.

## 25. FCM token — continua global, confirmado

`user_notification_tokens`: **nenhum `club_id` adicionado** — `registerToken`/`deactivateToken` intocados quanto a tenancy, testado explicitamente (`registerToken` não manda `club_id` no payload).

## 26. Notification deliveries — continua herdando via `event_id`

Nenhuma coluna `club_id` adicionada (a M2.2A já decidiu isso explicitamente); nenhum código novo referencia a tabela.

## 27-28. `player_identity_results`/`tactical_identity_results` — ROW_SCOPE pronto, KEY_SCOPE bloqueado

Ambas: PK é só `user_id` (1 resultado por usuário NO TOTAL, não por clube) — `onConflict: 'user_id'` inalterado. `saveResult` agora grava `club_id`; `loadLatestResult` agora filtra por `club_id`. Nenhuma troca de PK.

## 29. `arena_selected_content` — o caso mais frágil, tratado com o mesmo cuidado

`PRIMARY KEY (user_id, game_id)`, sem `item_id`/`club_id` na chave — confirmado lendo o `CREATE TABLE` real. Os 2 owners (`SupabaseCareerPathStorage`/`SupabaseLineupStorage`) agora filtram/gravam `club_id`, mas `onConflict: 'user_id,game_id'` continua igual — um 2º clube real ainda sobrescreveria a seleção do 1º sob a MESMA chave até a M2.2B trocar a PK. Comentário explícito no código nos 2 arquivos, e `keyScopeBlocked: true` registrado na tooling — nunca uma corrupção silenciosa disfarçada de "resolvido".

## 30-33. Migrations — só aditivas, agrupadas por dependência

4 migrations novas (`20260903000000`-`030000`), cada uma só com `CREATE OR REPLACE FUNCTION` + `GRANT EXECUTE` — **nenhum** `DROP FUNCTION` de legacy, `DROP`/`ALTER` de PK/UNIQUE/DEFAULT. Agrupadas por domínio (confirmado nunca misturar):
1. `20260903000000_add_arena_tenant_aware_rpcs.sql` — as 4 RPCs de Arena (score+ranking).
2. `20260903010000_add_membership_tenant_aware_rpcs.sql` — as 2 RPCs de Sócio.
3. `20260903020000_add_crowd_lineup_tenant_aware_rpc.sql` — a RPC da Escalação da Torcida.
4. `20260903030000_add_store_tenant_aware_rpc.sql` — a RPC da Loja.

**`SECURITY DEFINER` auditado em cada uma das 7 novas que usam** (`arena_record_score_for_club`/`arena_ranking_for_club`/`arena_my_rank_for_club`/`arena_user_detail_for_club`/`get_my_membership_for_club`/`subscribe_to_plan_for_club`/`crowd_lineup_for_club`): todas usam `auth.uid()` onde a legacy usava (nunca aceitam um `p_user_id` arbitrário substituindo `auth.uid()` — exceção deliberada e preservada: `arena_user_detail_for_club`, que já confiava em `p_user_id` na legacy, pelo mesmo motivo de design). `create_store_order_for_club` reusa a MESMA decisão da legacy de não usar `security definer` (roda como o chamador; a RLS `insert own orders` já garante `auth.uid() = user_id`, então privilégio elevado nunca foi necessário — copiado, não reinventado).

> ⚠️ **CORRIGIDO na rodada de hardening (§51-60)**: o `set search_path = public` desta 1ª rodada e a alegação de grants abaixo ("exatamente o mesmo conjunto da legacy") estavam **erradas/incompletas** — ver §51-60 pra tratamento completo e correto. Texto original preservado aqui só por histórico, nunca aplicado ao banco nesta forma.

**Grants (texto original, SUPERADO — ver §55)**: ~~cada RPC nova recebe exatamente o mesmo conjunto de grants da sua legacy correspondente — `arena_ranking_for_club`/`crowd_lineup_for_club` também liberadas pra `anon` (igual `arena_ranking`/`crowd_lineup` legacy, ambas de leitura pública); as demais só `authenticated` (igual as legacy). Nenhuma função nova ficou mais permissiva que sua correspondente antiga.~~

## 34-35. Compatibilidade — só validado estruturalmente, NÃO aplicado

`old app + DB M3.2 transitional`: as legacy continuam byte-idênticas — nenhuma quebra possível pro app já publicado. `new app M3.2 + DB M3.2`: o Flutter novo só chama as variantes `_for_club` — confirmado por teste estático que NENHUMA das 8 RPCs legacy é mais chamada de lugar nenhum em `lib/` (regex que distingue `'arena_ranking'` de `'arena_ranking_for_club'`, nunca um falso-negativo por substring). **Essa invariante só foi validada estaticamente + com os testes locais** — a prova ao vivo (rodar contra o banco real com as 2 gerações do app) só é possível DEPOIS do `db push`, que não aconteceu nesta rodada (§48).

## 36. Flutter novo não depende mais de legacy (onde existe variante nova)

Confirmado: `arena_record_score`/`arena_ranking`/`arena_my_rank`/`arena_user_detail`/`get_my_membership`/`crowd_lineup`/`create_store_order` — nenhuma chamada em `lib/` além da variante `_for_club`. `subscribe_to_plan` idem (não estava na lista original, mas segue a mesma regra por consistência — ver §15).

## 37. Teste de payload real de RPC — 8/8 RPCs, prova por captura, nunca só estático

`test/core/club/club_scoped_user_state_test.dart` — `CapturingHttpClient` estendido (`test/core/club/capturing_http_client.dart`) pra capturar não só a URL, mas o **corpo** de cada requisição real (`lastRequestBody`/`lastRequestBodyJson`), decodificando `Map` (RPC/upsert de 1 linha) ou `List` (insert em lote). Pra cada uma das 8 RPCs novas, testado com Goiás E com `syntheticClubBConfig`: o JSON body de verdade que o `postgrest` monta contém `{"p_club_id": "<uuid do clube ativo>"}` — nunca inferido, sempre lido do corpo real capturado antes de qualquer resposta chegar. Total: 16 testes (8 RPCs × 2 clubes) + 1 teste extra confirmando que club-b nunca manda o UUID do Goiás em nenhuma das 4 RPCs de Arena.

**Gotcha resolvido pra viabilizar isso**: os repositories usam `_uid = _client.auth.currentUser!.id`, que lançaria `Null check operator used on a null value` sem uma sessão autenticada. Resolvido com `SupabaseClient.auth.recoverSession(...)` usando um `access_token` que NÃO é um JWT válido de propósito — o pacote `gotrue` tenta decodificar o payload JWT pra achar `exp`, falha (capturado em try/catch dentro do próprio pacote), `expiresAt` vira `null`, `isExpired` vira `false`, e a sessão é só salva em memória (`_saveSession`, 0 I/O) — login "de mentira" sem nenhuma chamada de rede real, mesmo espírito do `CapturingHttpClient` (nunca um framework de mock, só o comportamento real do pacote usado a favor do teste).

## 38. Teste de payload real de write direto — 13 superfícies, Goiás + club-b

Mesma técnica, pros writes diretos (não-RPC): `quiz_question_progress` (`recordAnswer`), `career_path_progress`+`arena_selected_content` (`save`/`saveSelectedPlayerId`), `lineup_match_progress`+`arena_selected_content` (`save`/`saveSelectedMatchId`), `match_lineup_votes` (`submitVote`), `player_identity_results`/`tactical_identity_results` (`saveResult`), `user_notification_preferences` (`updatePreferences`), `ticket_checkin_decisions`+`tickets` (`checkIn`), `ticket_orders`+`tickets` (`purchase`). Total: 24 testes (12 superfícies × 2 clubes, `checkIn`/`purchase` cada um provando 2 tabelas de uma vez). `arena_achievements` (`_tryUnlockAchievement`) **não** ganhou um teste de captura de rede dedicado — é privado, só alcançável via `loadSnapshot()` completo, que exigiria montar as 5 dependências reais de `ArenaProgressRepository` até fechar "100% completo" nos 3 jogos; decisão explícita de escopo (não uma omissão silenciosa): a prova de que o MESMO padrão de código (`'club_id': _clubId` no upsert) está presente é feita estaticamente pela tooling (`hasClubIdInWrites`), e o padrão em si já foi provado dinamicamente 12+ vezes nas outras superfícies com código estruturalmente idêntico.

## 39. Synthetic club-b — usado em toda a bateria, nunca no registry real

`syntheticClubBConfig` (já existente desde a M3.1, `test/core/club/synthetic_club_config.dart`) reusado, nunca um clube real nomeado. Confirmado: `p_club_id`/`club_id` capturado no payload real, pra CADA uma das 24+16 = 40 provas com club-b, é sempre `syntheticClubBConfig.identity.canonicalClubId` — nunca o UUID do Goiás (checado explicitamente num teste dedicado pras 4 RPCs de Arena, e implicitamente em todos os outros 39 pela própria asserção `expect(..., config.identity.canonicalClubId)`).

## 40. Goiás — comportamento idêntico, nada mudou

Todos os 40 testes rodados com `goiasClubConfig` continuam batendo — nenhuma mudança visual/de gameplay, mesma progressão, ranking, sócio, votos, ingressos, preferências. O `DEFAULT` da M2.2A continua ali como rede de segurança pro app antigo; o app novo nunca precisa dele porque manda `club_id` explícito sempre.

## 41. Banco M2.2A — 24 colunas/defaults inalterados

`DEFAULT` Goiás continua em todas as 24 colunas da M2.2A — nenhuma removida, nenhuma alterada.

## 42. KEY_SCOPE — não resolvido, cada bloqueio registrado explicitamente

Continuam pra M2.2B: PKs de progresso (`quiz_question_progress`/`quiz_active_session`/`career_path_progress`/`lineup_match_progress`/`arena_selected_content`/`arena_achievements`), `UNIQUE(person_id)` (career/guess/squad, herdado do F-series), `notification dedupe` (`UNIQUE(event_type,dedupe_key)`), `match ids` (sem namespace global comprovado), `preferences PK` (`user_notification_preferences`, só `user_id`). Cada uma dessas tabelas tem `keyScopeBlocked: true` registrado na tooling nova (§45) — nunca um "resolvido" fingido.

## 43. M3.3 — fora, confirmado intocado

`Team.isGoias`/`_isGoiasHome`/`getGoiasSnapshot`/`Team.goiasId`, `AppColors`/`AppAssets`, Arena capabilities, Worker routes, `GOIAS_TEAM_ID`, `"GOI-"` — nenhum tocado. Testado estaticamente que `team.dart` não referencia `ClubConfig`.

## 44. Passaporte — fora, confirmado intocado

`supabase_passport_repository.dart` sem `_clubConfig`/`club_id` (testado).

## 45. Tooling

`tooling/multiclub/audit_multiclub_runtime_user_state_scope.mjs` (NOVO) — lê os repositories/DI/migrations REAIS (nunca lista assumida), escreve `data_export/goias/player_reconciliation/multiclub_runtime_user_state_scope_audit.json`. Métricas emitidas:
```
allDirectTablesRowScopeReady: true   (14/14 tabelas de leitura/escrita direta)
allRpcsTenantAwareReady: true        (8/8 RPCs novas)
goiasUuidHardcodedInTouchedFiles: [] (0 UUID hardcoded em qualquer arquivo tocado)
edgeFunctionOnlyTables: 3            (match_monitor_sessions, notification_events,
                                       notification_deliveries — cada uma com motivo
                                       documentado)
globalTables: 1                      (user_notification_tokens — CORRIGIDO na rodada
                                       de hardening: tinha owner Dart real, nunca deveria
                                       estar classificada como edge-function-only, ver §54)
```
Por tabela: `hasClubIdInReads`/`hasClubIdInWrites`/`hasClubConfigCtorParam`/`keyScopeBlocked`. Por RPC: `newRpcCallSitePresent`/`hasClubIdParam`/`legacyStillCalledInFlutter`/`legacySqlStillDefined`/`migrationValidatesClubId`/`migrationIsAdditiveOnly`/`revokePublicPresent`/`grantAllowlistMatches`/`safeSearchPath`/`schemaQualified` (últimos 4 adicionados na rodada de hardening, §51-60). `tooling/multiclub/test_multiclub_runtime_user_state_scope.mjs` (31 testes — 19 da 1ª rodada + 12 da rodada de hardening) prova cada uma dessas métricas. `tooling/multiclub/test_multiclub_runtime_content_scope.mjs` (EXISTENTE, da M3.1) precisou de um ajuste — ver §46.

## 46. Regressão auto-detectada e corrigida — mesmo padrão do M2.2A

Rodar a suíte completa revelou que `test_multiclub_runtime_content_scope.mjs` (M3.1) tinha 2 asserções que **só faziam sentido enquanto a M3.2 não existia**: "`arena_progress_repository.dart`/`supabase_membership_repository.dart`/etc. NUNCA tocados" e "exatamente 41 migrations". Mesmo padrão de regressão auto-referencial já documentado desde a M2.2A (6 testes antigos que hardcoded "35 migrations" quebraram quando a M2.2A adicionou as suas). Corrigido: a asserção de "arquivos nunca tocados" foi substituída por uma nota de supersessão (a prova de que a M3.2 tocou esses arquivos CORRETAMENTE mora no arquivo de teste novo, §45); a contagem de migrations passou a filtrar pela janela de tempo da PRÓPRIA M3.1 (`f <= '20260902270000_z'`) em vez do total bruto atual — nunca mais quebra quando uma etapa futura legítima adicionar migration. `test_multiclub_runtime_content_scope.mjs`: 25→24 testes (2 velhos viraram 1 mais preciso), 0 falhando.

## 47. JS — total real (pós-hardening)

```
tooling/multiclub/test_*.mjs: 632 passando, 0 falhando
  (620 no fim da 1ª rodada + 12 novos em test_multiclub_runtime_user_state_scope.mjs
   na rodada de hardening — seção 8, §51-60 — 0 de qualquer outro arquivo)
```

## 48. `flutter analyze`

**0 issues.** (rodada de hardening é Supabase-SQL + tooling JS apenas — 0 arquivo `.dart` de produção tocado, `flutter analyze` roda idêntico à 1ª rodada)

## 49. `flutter test`

**841 passed, 1 skip, 0 failed** (era 800/1 no fim da M3.1 — **+41 novos** na 1ª rodada da M3.2, todos em `test/core/club/club_scoped_user_state_test.dart`; inalterado na rodada de hardening, que não tocou nenhum `.dart`).

## 50. Migrations — estado real

```
npx supabase migration list → 45 migrations locais, 41 local=remote (as
  originais, inalteradas), 4 SÓ LOCAIS (as 4 novas desta etapa, ainda não
  aplicadas)
npx supabase db push --dry-run → confirma EXATAMENTE as 4 migrations novas
  a aplicar, nada mais:
    20260903000000_add_arena_tenant_aware_rpcs.sql
    20260903010000_add_membership_tenant_aware_rpcs.sql
    20260903020000_add_crowd_lineup_tenant_aware_rpc.sql
    20260903030000_add_store_tenant_aware_rpc.sql
```
**Nenhum `db push` real executado.**

---

# Rodada de hardening de segurança (2026-09-02)

Motivada por revisão explícita do usuário sobre a 1ª rodada: as alegações de grant "idêntico à legacy" e `set search_path = public` (§30-33 acima, agora riscadas) não eram seguras o suficiente — corrigidas de verdade abaixo, com achados live no banco, nunca assumidos.

## 51. Achado real confirmado ao vivo — `LEGACY_RPC_PUBLIC_EXECUTE_DEBT`

`CREATE FUNCTION` concede `EXECUTE` a `PUBLIC` por padrão a menos que seja revogado explicitamente. Consultado ao vivo (`npx supabase db query --linked`) o `pg_proc.proacl` das 8 RPCs legacy:

```sql
select p.proname, p.prosecdef, p.proacl from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname in (
  'arena_record_score','arena_ranking','arena_my_rank','arena_user_detail',
  'get_my_membership','subscribe_to_plan','crowd_lineup','create_store_order'
);
```

Resultado: **as 8 têm `=X/postgres` no `proacl`** (PUBLIC com EXECUTE), além dos grants explícitos já esperados (`anon=X`, `authenticated=X`, `service_role=X`, todas dono `postgres`). Ou seja, mesmo as legacy que "só" deveriam estar acessíveis a `authenticated` (ex.: `arena_record_score`, `get_my_membership`, `subscribe_to_plan`, `create_store_order`) hoje também têm EXECUTE aberto a PUBLIC (e, nessas 4, também a `anon`/`service_role` — grants antigos nunca auditados dessa forma antes).

**Decisão explícita desta rodada**: as 8 legacy **NÃO são tocadas** (risco de quebrar o app já publicado, fora do escopo autorizado). O achado é registrado como dívida nomeada:

> **`LEGACY_RPC_PUBLIC_EXECUTE_DEBT`** — as 8 RPCs legacy (`arena_record_score`, `arena_ranking`, `arena_my_rank`, `arena_user_detail`, `get_my_membership`, `subscribe_to_plan`, `crowd_lineup`, `create_store_order`) têm EXECUTE aberto a PUBLIC (e, em 4 delas, a `anon`/`service_role` além do esperado) por nunca terem recebido um `REVOKE ALL FROM PUBLIC` explícito desde a criação. Endereçar exige checar compatibilidade com o app já publicado (nenhum cliente deveria estar chamando essas RPCs sem sessão hoje, mas isso nunca foi provado ao vivo) — tratamento explícito fica pra depois da M3.2/M3.3, nunca nesta rodada.

## 52. As 8 RPCs novas — REVOKE PUBLIC explícito + grant allowlist real, nunca copiado cego

Cada uma das 8 `_for_club` recebe, logo após o `CREATE OR REPLACE FUNCTION`:
```sql
revoke all on function public.<nome>(<assinatura exata>) from public;
grant execute on function public.<nome>(<assinatura exata>) to <roles>;
```
Assinatura sempre com os tipos completos na ordem exata (nunca `(...)`) — testado (`grantAllowlistMatches`, verifica `revoke`/`grant` casam com a assinatura real da função no mesmo arquivo).

**Classificação por role real (nunca copiado da legacy)** — baseada em auditoria dos call sites Flutter reais + guard de rota (`app_router.dart`):

| RPC nova | Role concedido | Por quê (evidência real) |
|---|---|---|
| `arena_record_score_for_club` | `authenticated` | escrita exige `auth.uid()` — nunca `anon`; nenhum caller server-side — nunca `service_role` |
| `arena_ranking_for_club` | `authenticated` | tela Ranking da Arena 100% atrás do redirect global de login (`_publicRoutes = {'/profile/terms','/profile/privacy'}` em `app_router.dart:125` — nenhuma rota de Arena está lá); a legacy concede `anon` mas nenhum caller anônimo alcança de fato hoje |
| `arena_my_rank_for_club` | `authenticated` | mesma tela/guard da anterior |
| `arena_user_detail_for_club` | `authenticated` | mesma tela/guard, bottom sheet dentro do Ranking |
| `get_my_membership_for_club` | `authenticated` | ler status de sócio não faz sentido sem sessão |
| `subscribe_to_plan_for_club` | `authenticated` | escrita exige `auth.uid()` |
| `crowd_lineup_for_club` | `authenticated` | rota `/crowd-lineup` também fora de `_publicRoutes` — mesmo raciocínio de `arena_ranking_for_club`; legacy concede `anon` mas nenhum caller anônimo alcança hoje |
| `create_store_order_for_club` | `authenticated` | criar pedido exige sessão (RLS `insert own orders` já assume `auth.uid()`) |

Nenhuma das 8 recebe `anon` nem `service_role` — verificado ao vivo (route guard) que nenhum caller anônimo real alcança `arena_ranking_for_club`/`crowd_lineup_for_club` hoje, mesmo a legacy concedendo `anon` por decisão antiga (possivelmente antecipando um uso público que nunca existiu). **Revisitar se um uso público real (embed/web) for decidido no futuro** — comentário deixado no SQL nos 2 pontos.

## 53. `SECURITY DEFINER` — 7 (não 6) + 1 `SECURITY INVOKER`, contagem corrigida

Miscontagem do relatório original corrigida: **7 SECURITY DEFINER** (`arena_record_score_for_club`, `arena_ranking_for_club`, `arena_my_rank_for_club`, `arena_user_detail_for_club`, `get_my_membership_for_club`, `subscribe_to_plan_for_club`, `crowd_lineup_for_club`) **+ 1 SECURITY INVOKER** (`create_store_order_for_club`, mesma decisão da legacy) **= 8 novas RPCs**, nunca 6+1=7. Testado (`securityDefinerCount === 7`, `securityInvokerCount === 1`, mais `securityDefinerMatchesExpected` por RPC).

## 54. `search_path` — upgrade de `public` pra `pg_catalog, public, pg_temp` + qualificação de schema total

Confirmado ao vivo que `anon`/`authenticated`/`service_role` **não têm `CREATE` no schema `public`** (bom — ninguém externo cria uma tabela/função disfarçada lá), mas **as 3 TÊM privilégio `TEMP` no banco** (`has_database_privilege(rolname, current_database(), 'TEMP')`):
```sql
select rolname,
  has_schema_privilege(rolname, 'public', 'CREATE') as can_create_public,
  has_database_privilege(rolname, current_database(), 'TEMP') as has_temp
from pg_roles where rolname in ('anon','authenticated','service_role');
-- resultado: as 3 → can_create_public=false, has_temp=true
```
Ou seja: `set search_path = public` sozinho **não é prova suficiente** de segurança — qualquer sessão pode criar objetos em `pg_temp` (schema temporário próprio da sessão), e se `pg_temp` pudesse preceder `public` na resolução, um objeto malicioso lá poderia sombrear uma tabela real referenciada sem qualificação.

**Correção aplicada nas 7 SECURITY DEFINER**: `set search_path = pg_catalog, public, pg_temp` (nunca só `public`) — `pg_temp` explicitamente por ÚLTIMO, nunca implícito/primeiro. **Toda relação de aplicação referenciada no corpo das 7 (+ a 1 invoker) está schema-qualificada** (`public.clubs`, `public.score_events`, `public.user_game_item_progress`, `public.supporter_memberships`, `public.match_lineup_votes`, `public.profiles`, `public.quiz_questions`, `public.career_players`, `public.guess_players`, `public.lineup_matches`, `public.store_orders`, `public.store_order_items` — nunca uma referência bare); `auth.uid()` já nasceu qualificado (schema `auth`) e continua assim. Funções built-in usadas sem prefixo (`now()`, `least()`, `greatest()`, `date_trunc()`, `row_number()`, `pg_advisory_xact_lock()`, `hashtext()`) são seguras mesmo sem qualificação explícita porque `pg_catalog` vem PRIMEIRO no novo `search_path` — resolvem pro catálogo real antes de qualquer `pg_temp`.

**Prova, não só grep**: o teste "detecção de qualificação funciona de verdade" (`test_multiclub_runtime_user_state_scope.mjs`, seção 8) fabrica uma referência bare (`from supporter_memberships` em vez de `from public.supporter_memberships`) dentro de uma cópia em memória do SQL real e prova que o detector a sinaliza — nunca um teste que só verifica a presença da string `set search_path`.

## 55. `user_notification_tokens` — reclassificado, nunca ganha `club_id`

O relatório original (§45 supersedido) classificava `user_notification_tokens` dentro de `edgeFunctionOnlyTables` (junto de `match_monitor_sessions`/`notification_events`/`notification_deliveries`) — **contradizia o próprio corpo do relatório**, que já confirmava (§25) que `registerToken`/`deactivateToken` em `supabase_notification_repository.dart` são owner Dart real. Corrigido: `user_notification_tokens` saiu de `edgeFunctionOnlyTables` (que agora tem só as 3 realmente Edge-Function-only) e entrou numa categoria nova, `globalTables` — owner Dart real, mas **deliberadamente fora de tenant-scope** (token FCM é do APARELHO, nunca do clube ativo). **A decisão de produto não mudou** (nunca ganha `club_id`) — só a classificação/motivo estava errada, corrigido só no JSON/tooling/relatório, **0 mudança de runtime**.

## 56. Matriz de compatibilidade App × DB — 4 estados, prova de por que o release precisa ser DB-first

| | DB-41 (sem as 4 RPCs novas) | DB-45-M3.2 (com as 4 RPCs novas) |
|---|---|---|
| **App atual (publicado)** | ✅ chama só as 8 RPCs legacy, que continuam byte-idênticas | ✅ idem — as 4 migrations são só aditivas, nada que o app atual chama muda |
| **App novo (M3.2, chama `*_for_club`)** | ❌ **FALHA** — o app chamaria `arena_record_score_for_club`/etc., que não existem ainda no banco (`PGRST202`/função inexistente) | ✅ único estado onde o app novo funciona de verdade |

**Conclusão obrigatória**: o único quadrante que quebra é "app novo + DB-41" — nunca pode acontecer em produção. Isso prova que a ordem de deploy real precisa ser banco-primeiro.

## 57. `DEPLOY_ORDER = DB_FIRST` — registrado como restrição formal

> **`DEPLOY_ORDER = DB_FIRST`**: (1) `db push` das 4 migrations novas → (2) validar ao vivo que as 8 `_for_club` existem e respondem (`select proname from pg_proc where proname like '%_for_club'`, mínimo) → só então (3) publicar um build novo do app que chama `_for_club`. Commit em git pode acontecer antes ou depois do `db push` (git e Supabase são sistemas independentes) — mas um build real, distribuído a usuários, nunca pode chamar `_for_club` antes do passo (1)+(2) terem acontecido de verdade no projeto Supabase linkado.

## 58. `create_store_order_for_club` — REVOKE+GRANT mesmo sendo `SECURITY INVOKER`

`SECURITY INVOKER` não significa que EXECUTE público é desejável — a RLS (`insert own orders`, `auth.uid() = user_id`) protege a TABELA, mas o privilégio de EXECUTE da FUNÇÃO em si precisa continuar least-privilege independentemente. `create_store_order_for_club` recebeu o mesmo tratamento das 7 DEFINER: `revoke all ... from public` + `grant execute ... to authenticated` (nunca `anon`/`service_role`) — testado explicitamente (`isSecurityDefiner === false && revokePublicPresent === true && grantAllowlistMatches === true`).

## 59. Assinaturas exatas em todo REVOKE/GRANT

Todo `revoke`/`grant` usa a assinatura completa (tipos na ordem exata dos parâmetros, ex. `arena_record_score_for_club(uuid, text, text, text, int, text, int, int, int, boolean, boolean)`) — nunca `(...)` genérico, prevenindo ambiguidade se um overload for adicionado no futuro. Verificado por regex que casa a assinatura literal no mesmo bloco `REVOKE`/`GRANT`.

## 60. Legado — 0 alterado, verificado por 2 vias independentes

(a) `legacySqlStillDefined = true` pras 8 (o texto `create or replace function public.<legacy>(` continua presente no arquivo-fonte original); (b) **novo nesta rodada**: teste que roda `git diff --name-only` e confirma que nenhum dos arquivos-fonte legacy (`arena_ranking.sql`, `supporter_memberships.sql`, `crowd_lineup.sql`, `store_orders.sql`) aparece no diff — não só "a string ainda existe", mas "o arquivo nem foi tocado". As 4 migrations novas continuam só-aditivas (`migrationIsAdditiveOnly`, nunca `DROP FUNCTION`/`ALTER`/`DROP` de PK/UNIQUE/DEFAULT).

## Reexecução completa pós-hardening

```
node tooling/multiclub/audit_multiclub_runtime_user_state_scope.mjs
  → allDirectTablesRowScopeReady=true, allRpcsTenantAwareReady=true,
    allRpcsSecurityHardeningReady=true, securityDefinerCount=7, securityInvokerCount=1

node tooling/multiclub/test_multiclub_runtime_user_state_scope.mjs
  → 31 passaram, 0 falharam (19 da 1ª rodada + 12 novos da seção 8 de hardening)

tooling/multiclub/test_*.mjs (todos os 20 arquivos)
  → 632 passando, 0 falhando

flutter analyze → 0 issues
flutter test → 841 passed, 1 skip, 0 failed

npx supabase migration list → 45 locais, 41 local=remote, 4 só-locais (inalterado)
npx supabase db push --dry-run → confirma EXATAMENTE as mesmas 4 migrations,
  nada mais/menos:
    20260903000000_add_arena_tenant_aware_rpcs.sql
    20260903010000_add_membership_tenant_aware_rpcs.sql
    20260903020000_add_crowd_lineup_tenant_aware_rpc.sql
    20260903030000_add_store_tenant_aware_rpc.sql

git diff --stat / git status → idênticos à 1ª rodada (as 4 migrations, a tooling
  nova e este relatório continuam untracked — REVOKE/GRANT/search_path/
  qualificação foram editados DENTRO dos arquivos untracked já existentes,
  nunca criaram diff em arquivo tracked novo)
```

**0 commit. 0 `db push`. 0 `git push` nesta rodada de hardening.**

---

# Aplicação (2026-09-02) e achado pós-push — migration de correção

Hardening aprovado, preflight (`migration list` + `db push --dry-run`) confirmou exatamente as 4 migrations esperadas, `select count(*) from pg_proc where proname like '%_for_club'` confirmou **0** remotamente antes do push. **`npx supabase db push` executado — as 4 migrations aplicaram com 0 erro.**

## 61. Achado real pós-push — `anon`/`service_role` com EXECUTE apesar do REVOKE

Verificação ao vivo imediatamente após o push (`pg_proc.proacl` das 8 `_for_club`) mostrou:
```
{postgres=X/postgres, anon=X/postgres, authenticated=X/postgres, service_role=X/postgres}
```
`PUBLIC` ausente (o `revoke all ... from public` das 4 migrations originais funcionou) — mas **`anon` e `service_role` continuavam com EXECUTE**, falhando o requisito explícito (PUBLIC=NÃO, anon=NÃO, service_role=NÃO, authenticated=SIM).

**Causa raiz** (`pg_default_acl`, consultada ao vivo):
```sql
select n.nspname, d.defaclrole::regrole as role, d.defaclobjtype, d.defaclacl
from pg_default_acl d join pg_namespace n on n.oid = d.defaclnamespace
where n.nspname = 'public';
-- defaclobjtype='f' (functions), role=postgres:
-- {postgres=X/postgres, anon=X/postgres, authenticated=X/postgres, service_role=X/postgres}
```
O projeto Supabase tem `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO postgres, anon, authenticated, service_role` configurado no nível do PROJETO (padrão de todo projeto Supabase — não uma decisão deste código). Toda `CREATE FUNCTION` nova em `public` já nasce com EXECUTE concedido a `anon`/`authenticated`/`service_role` automaticamente, via mecanismo **separado e anterior** ao grant implícito a `PUBLIC` que `REVOKE ALL FROM PUBLIC` resolve — a 1ª rodada de hardening só tratou o 2º mecanismo, nunca validou o ACL real pós-aplicação (só o texto da migration), e por isso não capturou o 1º.

**Nunca usar "RLS protege" como justificativa** pra deixar `service_role` com EXECUTE: `service_role` bypassa RLS por definição (chave de confiança total server-side) — least-privilege na função continua obrigatório independente de RLS.

## 62. Correção — migration aditiva nova, legacy e as 4 originais intocadas

`supabase/migrations/20260903040000_harden_tenant_rpc_execute_grants.sql` (NOVA, não aplicada ainda) — pra cada uma das 8 `_for_club`, com assinatura exata:
```sql
revoke execute on function public.<nome>(<tipos exatos>) from public, anon, service_role;
grant execute on function public.<nome>(<tipos exatos>) to authenticated;
```
Não recria nenhuma função (`0` `CREATE FUNCTION`), não altera `ALTER DEFAULT PRIVILEGES` global (escopo maior, decisão separada — revisitar seria afetar toda função futura em `public`, não só estas 8), não toca nas 4 migrations já aplicadas nem em nenhuma RPC legacy — confirmado por 3 testes novos.

## 63. Tooling — ACL EFETIVO simulado, nunca só 1 migration isolada

`audit_multiclub_runtime_user_state_scope.mjs`: nova função `computeEffectiveGrants(rpc, cfg)` simula o ACL somando, em ordem, TODAS as migrations que tocam uma RPC (`migration` + `hardeningMigration`), partindo do estado REAL confirmado ao vivo no momento da criação (`DEFAULT_ACL_ROLES_ON_CREATE = ['public','anon','authenticated','service_role']` — documentado, nunca assumido). `allRpcsSecurityHardeningReady`/`allRpcsTenantAwareReady` agora dependem de `effectiveGrantAllowlistMatches` (a prova real), não mais só de `grantAllowlistMatches` isolado da migration original (que se provou insuficiente — ver §61). `test_multiclub_runtime_user_state_scope.mjs` ganhou uma seção 9 (5 testes novos): ACL efetivo das 8 = exatamente `['authenticated']`, hardening migration existe e está registrada, a migration de correção não recria função nem mexe em `ALTER DEFAULT PRIVILEGES`, simulação parte do default real. **Suíte: 31→36 testes.**

## 64. `20260903040000` — aplicada, 46/46 local=remote, 0 mismatch

`npx supabase db push` executado — a migration de correção aplicou com **0 erro**. `npx supabase migration list` pós-push: **46 locais, 46 local=remote, 0 mismatch**.

## 65. Prova efetiva — `has_function_privilege`, não só `proacl`

Por instrução explícita ("não considerar a etapa concluída apenas porque `proacl` parece certo"), a prova principal foi via `has_function_privilege(<role>, <oid>, 'EXECUTE')`, role por role, nas 8:

```sql
select p.proname,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_exec,
  has_function_privilege('anon', p.oid, 'EXECUTE') as anon_exec,
  has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_exec,
  has_function_privilege('postgres', p.oid, 'EXECUTE') as postgres_exec
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname like '%_for_club';
```

Resultado, **8/8**: `authenticated_exec=true`, `anon_exec=false`, `service_role_exec=false`, `postgres_exec=true` (owner administrativo, nunca revogado — por instrução explícita, não fazia parte do objetivo desta allowlist). `has_function_privilege('public', p.oid, 'EXECUTE')` também **false** nas 8. `proacl` final, limpo, confirma a mesma coisa por outra via: `{postgres=X/postgres, authenticated=X/postgres}` — só o owner e `authenticated`, nada mais, nas 8.

## 66. Regra permanente registrada — vale pra toda migration futura que criar função

Por instrução explícita, esta regra fica registrada como padrão obrigatório daqui pra frente neste projeto, não só pra M3.2:

> Toda `CREATE FUNCTION` nova em `public` neste projeto Supabase nasce com EXECUTE concedido a `anon`/`authenticated`/`service_role` automaticamente, via `ALTER DEFAULT PRIVILEGES` configurado no nível do projeto (achado real, `pg_default_acl`, §61) — nunca confiar que `REVOKE ALL FROM PUBLIC` sozinho resolve isso. Toda migration futura que criar uma função em `public` deve, na MESMA migration:
> 1. `CREATE FUNCTION` com a lógica real;
> 2. `REVOKE EXECUTE ... FROM PUBLIC, anon, service_role` explícito (nunca só `PUBLIC`);
> 3. `GRANT EXECUTE ... TO <allowlist real>` explícito (nunca herdar da legacy sem checar call sites reais);
> 4. validar o ACL EFETIVO ao vivo pós-push via `has_function_privilege` (nunca só ler o texto da migration).
>
> `ALTER DEFAULT PRIVILEGES` global do projeto **não foi alterado** nesta etapa (decisão explícita, escopo maior — afetaria toda função futura, não só as 8 de M3.2) — revisitar isso é uma decisão separada, se algum dia fizer sentido.

## Reexecução completa pós-aplicação (5/5 migrations da M3.2)

```
npx supabase migration list → 46 locais, 46 local=remote, 0 mismatch

has_function_privilege nas 8 _for_club → authenticated=true (8/8),
  anon=false (8/8), service_role=false (8/8), public=false (8/8)
proacl final das 8 → {postgres=X/postgres, authenticated=X/postgres} (limpo)

7 SECURITY DEFINER (search_path=pg_catalog, public, pg_temp) +
  1 SECURITY INVOKER (create_store_order_for_club) — reconfirmado ao vivo,
  inalterado por esta migration (que só mexeu em grants)

legacy (8 RPCs): proacl idêntico ao pré-M3.2, incluindo o próprio PUBLIC
  delas — LEGACY_RPC_PUBLIC_EXECUTE_DEBT preservada, intocada

node tooling/multiclub/test_multiclub_runtime_user_state_scope.mjs
  → 36 passaram, 0 falharam

tooling/multiclub/test_*.mjs (todos os 21 arquivos)
  → 637 passando, 0 falhando

flutter analyze → 0 issues
flutter test → 841 passed, 1 skip, 0 failed
```

**`SECOND_CLUB_BLOCKED=true`** reconfirmado (`clubRegistry` só `'goias'`, 0 PK/UNIQUE/DEFAULT alterado). Edge Functions: 0 mudança. **`DB_HAS_M3_2_RPCS=true`, `M3_2_RPC_ACL_HARDENED=true`, `DEPLOY_ORDER=DB_FIRST ✅`** — só agora, com o ACL remoto correto, o app M3.2 está apto a ser distribuído (não distribuído nesta etapa).

**5 migrations da M3.2 aplicadas. 0 commit ainda (autorização separada — ver AUTORIZADO commit abaixo). 0 `git push`.**

---

## Git diff --stat

```
 .../multiclub_hardcode_audit_stats.json            |  2 ++  (side-effect legítimo, mesma razão da M3.1 — recatalogação automática de lib/core/club/ não mudou, o diff é só timestamp/contagem)
 lib/core/di/injection_container.dart               | 23 +++++++-------
 lib/features/arena/data/arena_progress_repository.dart      | 13 +++++++-
 .../career_path/data/supabase_career_path_storage.dart      | 16 +++++++++-
 .../games/lineup/data/supabase_lineup_storage.dart           | 14 +++++++-
 .../player_identity/data/supabase_player_identity_repository.dart | 9 +++++-
 .../games/quiz/data/quiz_progress_repository.dart             | 21 ++++++++++--
 .../tactical_identity/data/supabase_tactical_identity_repository.dart | 9 +++++-
 .../ranking/data/supabase_arena_ranking_repository.dart       | 27 +++++++++++-----
 .../crowd_lineup/data/supabase_crowd_lineup_repository.dart   | 15 +++++++--
 .../membership/data/supabase_membership_repository.dart       | 22 ++++++++++---
 .../notifications/data/supabase_notification_repository.dart  | 14 +++++++-
 .../store/data/supabase_store_orders_repository.dart           | 13 ++++++--
 .../store/presentation/widgets/store_entry_card.dart (pré-existente) | 2 +-
 .../ticket/data/mock_ticket_repository.dart                    | 24 +++++++++++++-
 test/core/club/capturing_http_client.dart                      | 30 +++++++++++++++---
 test/features/arena/deep_link_content_scope_test.dart          |  4 +--
 test/features/arena/games/quiz/cubit/quiz_cubit_test.dart      |  2 +-
 test/features/arena/lineup/lineup_page_test.dart               |  1 +
 test/features/store/supabase_store_orders_repository_test.dart |  2 ++
 tooling/multiclub/test_multiclub_runtime_content_scope.mjs     | 37 ++++++++------------
 21 files changed, 234 insertions(+), 66 deletions(-)
```

## `git status` (arquivos novos, untracked)

```
?? data_export/goias/player_reconciliation/multiclub_runtime_user_state_scope_audit.json
?? supabase/migrations/20260903000000_add_arena_tenant_aware_rpcs.sql
?? supabase/migrations/20260903010000_add_membership_tenant_aware_rpcs.sql
?? supabase/migrations/20260903020000_add_crowd_lineup_tenant_aware_rpc.sql
?? supabase/migrations/20260903030000_add_store_tenant_aware_rpc.sql
?? supabase/migrations/20260903040000_harden_tenant_rpc_execute_grants.sql
?? docs/multiclub/32_etapa_m3_2_report.md
?? test/core/club/club_scoped_user_state_test.dart
?? tooling/multiclub/audit_multiclub_runtime_user_state_scope.mjs
?? tooling/multiclub/test_multiclub_runtime_user_state_scope.mjs
```
Untracked não relacionados a esta etapa (pré-existentes, confirmados intocados): `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`.

## `SECOND_CLUB_BLOCKED = true`

Confirmado — nenhuma PK/UNIQUE tocada, nenhum clube real cadastrado, `clubRegistry` continua com exatamente 1 entrada (`'goias'`).

---

**M3.2 APPLIED. 5 migrations aplicadas ao banco remoto (46/46 local=remote). 8 RPCs tenant-aware ativas, ACL hardened authenticated-only. Legacy intacta. `DEPLOY_ORDER=DB_FIRST` satisfeito. Commit autorizado (ver instrução do usuário) — ainda não executado nesta etapa do relatório; ver confirmação abaixo. 0 `git push`.**
