-- ============================================================================
-- M2.2B-B round 1 — Retire legacy RPC execute grants.
-- NÃO aplicada ainda (arquivo local, aguardando revisão).
--
-- As 8 RPCs legacy (pré `_for_club`, todas da M3.2) continuam com EXECUTE
-- concedido a PUBLIC/anon/authenticated/service_role — nunca passaram pelo
-- hardening de ACL da M3.2 (`LEGACY_RPC_PUBLIC_EXECUTE_DEBT`, já conhecida).
-- Confirmado ao vivo nesta rodada: o HEAD atual chama 0 delas (todas têm
-- substituta `_for_club` desde a M3.2); grep em `supabase/functions/` e
-- `src/` (Worker) confirma 0 uso de `service_role` também — nenhum caminho
-- de admin/backend depende delas, por isso o REVOKE cobre as 4 roles, não
-- só PUBLIC.
--
-- REVOKE, nunca DROP FUNCTION — preserva rollback/debug e evita depender de
-- CASCADE em qualquer objeto que ainda referencie a função (não há nenhum
-- conhecido, mas DROP é desnecessariamente destrutivo pro objetivo real,
-- que é só "o cliente não consegue mais chamar"). `postgres`/owner nunca é
-- afetado por REVOKE — acesso administrativo direto continua disponível se
-- algum dia for preciso reverter.
--
-- Guard: mesmo padrão das 2 migrations anteriores.
-- ============================================================================

do $$
begin
  if (select count(*) from public.clubs) <> 1
     or not exists (
       select 1 from public.clubs
       where id = '4c16340d-300c-5ab2-903f-17519db9b146'::uuid and slug = 'goias'
     ) then
    raise exception 'M2.2B-B guard: esperava clubs=1 (Goiás) — abortando';
  end if;
end $$;

revoke execute on function public.arena_record_score(text, text, text, int, text, int, int, int, boolean, boolean)
  from public, anon, authenticated, service_role;

revoke execute on function public.arena_ranking(text, int)
  from public, anon, authenticated, service_role;

revoke execute on function public.arena_my_rank(text)
  from public, anon, authenticated, service_role;

revoke execute on function public.arena_user_detail(uuid)
  from public, anon, authenticated, service_role;

revoke execute on function public.crowd_lineup(text)
  from public, anon, authenticated, service_role;

revoke execute on function public.get_my_membership()
  from public, anon, authenticated, service_role;

revoke execute on function public.subscribe_to_plan(text)
  from public, anon, authenticated, service_role;

revoke execute on function public.create_store_order(text, text, jsonb, jsonb, jsonb, jsonb, jsonb, numeric, numeric, numeric, text, jsonb)
  from public, anon, authenticated, service_role;
