-- ============================================================================
-- M3.2 — correção de hardening, pós-push das 4 migrations
-- (20260903000000-030000). NÃO edita nenhuma das 4 (já aplicadas), NÃO toca
-- em nenhuma RPC legacy.
--
-- Causa raiz (achado real, confirmado ao vivo via pg_default_acl):
-- ```sql
-- select n.nspname, d.defaclrole::regrole as role, d.defaclobjtype, d.defaclacl
-- from pg_default_acl d join pg_namespace n on n.oid = d.defaclnamespace
-- where n.nspname = 'public';
-- ```
-- retorna, pra defaclobjtype='f' (functions), role=postgres:
-- `{postgres=X/postgres, anon=X/postgres, authenticated=X/postgres, service_role=X/postgres}`
-- — ou seja, este projeto Supabase tem
-- `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT EXECUTE ON
-- FUNCTIONS TO postgres, anon, authenticated, service_role` configurado no
-- nível do PROJETO (padrão de todo projeto Supabase, não uma decisão deste
-- código) — isso significa que TODA `CREATE FUNCTION` nova em `public`
-- criada pela role `postgres` já nasce com EXECUTE concedido a
-- `anon`/`authenticated`/`service_role` automaticamente, via um mecanismo
-- SEPARADO e ANTERIOR ao grant implícito a PUBLIC que `REVOKE ALL FROM
-- PUBLIC` resolve. As migrations 20260903000000-030000 só revogaram de
-- PUBLIC — nunca de `anon`/`service_role` explicitamente — porque a 1ª
-- rodada de hardening nunca validou o ACL real pós-aplicação, só o texto da
-- própria migration. Confirmado ao vivo (`pg_proc.proacl`) logo após o push:
-- as 8 novas tinham `{postgres=X, anon=X, authenticated=X, service_role=X}`
-- — PUBLIC ausente (bom, a 1ª rodada funcionou nisso), mas `anon`/
-- `service_role` presentes (ruim — nunca deveriam estar, nenhuma das 8 tem
-- caller anônimo ou server-side real).
--
-- IMPORTANTE — nunca usar "RLS protege" como justificativa pra deixar
-- service_role com EXECUTE: `service_role` tem privilégio elevado que
-- BYPASSA RLS por definição (é a chave usada por processos server-side de
-- confiança total) — least-privilege na função continua obrigatório
-- independente de RLS, mesmo raciocínio já registrado pra
-- `create_store_order_for_club` (SECURITY INVOKER) na rodada anterior.
--
-- Esta migration NÃO altera `ALTER DEFAULT PRIVILEGES` global — resolve só
-- as 8 RPCs já criadas, explicitamente, uma por uma. Revisitar o default
-- privilege do projeto fica pra uma decisão separada e explícita (afetaria
-- toda função futura em `public`, escopo maior que esta correção).
-- ============================================================================

revoke execute on function public.arena_record_score_for_club(
  uuid, text, text, text, int, text, int, int, int, boolean, boolean
) from public, anon, service_role;
grant execute on function public.arena_record_score_for_club(
  uuid, text, text, text, int, text, int, int, int, boolean, boolean
) to authenticated;

revoke execute on function public.arena_ranking_for_club(uuid, text, int)
  from public, anon, service_role;
grant execute on function public.arena_ranking_for_club(uuid, text, int)
  to authenticated;

revoke execute on function public.arena_my_rank_for_club(uuid, text)
  from public, anon, service_role;
grant execute on function public.arena_my_rank_for_club(uuid, text)
  to authenticated;

revoke execute on function public.arena_user_detail_for_club(uuid, uuid)
  from public, anon, service_role;
grant execute on function public.arena_user_detail_for_club(uuid, uuid)
  to authenticated;

revoke execute on function public.get_my_membership_for_club(uuid)
  from public, anon, service_role;
grant execute on function public.get_my_membership_for_club(uuid)
  to authenticated;

revoke execute on function public.subscribe_to_plan_for_club(uuid, text)
  from public, anon, service_role;
grant execute on function public.subscribe_to_plan_for_club(uuid, text)
  to authenticated;

revoke execute on function public.crowd_lineup_for_club(uuid, text)
  from public, anon, service_role;
grant execute on function public.crowd_lineup_for_club(uuid, text)
  to authenticated;

revoke execute on function public.create_store_order_for_club(
  uuid, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, numeric, numeric,
  numeric, text, jsonb
) from public, anon, service_role;
grant execute on function public.create_store_order_for_club(
  uuid, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, numeric, numeric,
  numeric, text, jsonb
) to authenticated;
