-- ============================================================================
-- Notícias — agendamento do refresh (PASSO SEPARADO da migration
-- 20261121010000_news_snapshots.sql, que NÃO depende disto).
--
-- Rode DEPOIS de: (1) a migration; (2) deploy da Edge Function `news-refresh`;
-- (3) o Vault com `notifications_service_role_key` e o schema `private`
-- (supabase/notifications_cron.sql, reaproveitados).
--
-- ANTES DE RODAR: troque <SEU_PROJECT_REF> pelo Reference ID do projeto.
-- PROTEGIDO: sem pg_cron/pg_net/Vault só avisa (NOTICE) e sai sem erro.
--
-- Custo: o cron acorda todo minuto, mas só chama a função quando a lista
-- venceu (`next_refresh_at <= now()`, ~10 min; falhas viram backoff 5..60 min).
-- Fora disso é um SELECT barato, zero invocação.
--
-- BANCO NOVO/VAZIO (bootstrap): sem linha, nada vence e o cron NÃO dispara
-- (evita loop por minuto se a função estiver fora). Faça UMA chamada manual:
--   curl -X POST https://<ref>.functions.supabase.co/news-refresh -H "Authorization: Bearer <service_role>"
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
    raise notice 'news cron NÃO agendado: pg_cron/pg_net/Vault/private.notifications_service_role_key ausentes. Schema de notícias segue válido.';
    return;
  end if;

  execute $f$
    create or replace function private.news_refresh_due()
    returns boolean
    language sql
    stable
    security definer
    set search_path = public, pg_temp
    as $body$
      select exists (select 1 from public.news_snapshots where next_refresh_at <= now());
    $body$
  $f$;

  perform cron.unschedule(jobid) from cron.job where jobname = 'news-refresh';

  perform cron.schedule(
    'news-refresh',
    '* * * * *',
    $job$
    select net.http_post(
      url := 'https://<SEU_PROJECT_REF>.functions.supabase.co/news-refresh',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || private.notifications_service_role_key(),
        'Content-Type', 'application/json'
      ),
      timeout_milliseconds := 60000
    ) where private.news_refresh_due();
    $job$
  );
end $$;
