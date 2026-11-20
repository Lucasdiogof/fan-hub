-- ============================================================================
-- Futebol — agendamento do refresh (PASSO SEPARADO da migration
-- 20261120010000_football_snapshots.sql, que NÃO depende disto).
--
-- Rode DEPOIS de: (1) a migration; (2) deploy da Edge Function `football-refresh`
-- (+ segredo/caller de serviço, igual às funções de push); (3) o Vault com
-- `notifications_service_role_key` e o schema `private` criados por
-- supabase/notifications_cron.sql (reaproveitados aqui).
--
-- ANTES DE RODAR: troque <SEU_PROJECT_REF> pelo Reference ID do projeto.
--
-- PROTEGIDO: se pg_cron/pg_net/Vault não estiverem disponíveis, só avisa
-- (NOTICE) e sai sem erro — o schema de futebol continua válido e o refresh
-- pode ser disparado por outro mecanismo.
--
-- Custo: o cron acorda todo minuto, mas SÓ dispara a Edge Function quando algum
-- snapshot venceu (`next_refresh_at <= now()`); fora disso é um SELECT
-- barato, zero invocação. Várias linhas vencidas = UMA chamada (a função
-- refresca tudo que venceu do clube). Ao vivo a cadência é 60s (policy.ts).
-- shortcut: sem trava de sobreposição; se a função passar de ~60s uma 2ª
-- chamada pode refazer o mesmo vencido. Hoje ~30-40s; travar se crescer.
--
-- BANCO NOVO/VAZIO (bootstrap): não há linha vencida, então o cron NÃO dispara
-- sozinho (de propósito: evita loop por minuto se a função estiver fora). Faça
-- UMA chamada manual com a service role:
--   curl -X POST https://<ref>.functions.supabase.co/football-refresh --     -H "Authorization: Bearer <service_role>"
-- Depois disso as linhas existem e o cron assume.
-- ============================================================================

do $$
declare
  v_ok boolean;
begin
  select
    exists (select 1 from pg_extension where extname = 'pg_cron')
    and exists (select 1 from pg_extension where extname = 'pg_net')
    and to_regclass('vault.decrypted_secrets') is not null
    and to_regprocedure('private.notifications_service_role_key()') is not null
  into v_ok;

  if not v_ok then
    raise notice 'football cron NÃO agendado: pg_cron/pg_net/Vault/private.notifications_service_role_key ausentes. Schema de futebol segue válido.';
    return;
  end if;

  execute $f$
    create or replace function private.football_refresh_due()
    returns boolean
    language sql
    stable
    security definer
    set search_path = public, pg_temp
    as $body$
      -- NULL (`next_refresh_at`) = nada agendado -> nunca vence. Falhas já viram
      -- backoff em `next_refresh_at` (5/10/20/40/60 min), então respeitam o cron.
      select exists (select 1 from public.football_snapshots where next_refresh_at <= now());
    $body$
  $f$;

  perform cron.unschedule(jobid) from cron.job where jobname = 'football-refresh';

  perform cron.schedule(
    'football-refresh',
    '* * * * *',
    $job$
    select net.http_post(
      url := 'https://<SEU_PROJECT_REF>.functions.supabase.co/football-refresh',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || private.notifications_service_role_key(),
        'Content-Type', 'application/json'
      ),
      -- pg_net corta em 5s por padrão e registraria timeout falso; a função leva ~30s.
      timeout_milliseconds := 120000
    ) where private.football_refresh_due();
    $job$
  );
end $$;
