-- ============================================================================
-- Push Notifications V1 — agendamento dos Crons. Rode DEPOIS de:
-- 1. supabase/notifications.sql (tabelas);
-- 2. colar as 3 Edge Functions no dashboard (notifications-sync-and-check-access,
--    notifications-poll-live-match, notifications-dispatch) e configurar o
--    segredo FCM_SERVICE_ACCOUNT_JSON;
-- 3. Database > Extensions: habilitar "pg_cron" e "pg_net" (se ainda não
--    estiverem habilitadas nesse projeto).
--
-- ANTES DE RODAR: troque os dois placeholders abaixo pelos valores reais do
-- seu projeto — <SEU_PROJECT_REF> (Settings > General > Reference ID) e
-- <SUA_SERVICE_ROLE_KEY> (Settings > API > service_role secret). A chave só
-- fica guardada dentro do Vault do seu próprio projeto Supabase, nunca no
-- repositório.
-- ============================================================================

-- Condicional de propósito: seguro rodar o arquivo de novo (ex.: depois de
-- corrigir um erro numa execução anterior) sem criar o segredo duplicado.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notifications_service_role_key') then
    perform vault.create_secret('<SUA_SERVICE_ROLE_KEY>', 'notifications_service_role_key');
  end if;
end $$;

create schema if not exists private;

create or replace function private.notifications_service_role_key()
returns text
language sql
security definer
as $$
  select decrypted_secret from vault.decrypted_secrets
  where name = 'notifications_service_role_key';
$$;

select cron.schedule(
  'notifications-sync-and-check-access',
  '*/30 * * * *',
  $$
  select net.http_post(
    url := 'https://<SEU_PROJECT_REF>.functions.supabase.co/notifications-sync-and-check-access',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || private.notifications_service_role_key(),
      'Content-Type', 'application/json'
    )
  );
  $$
);

select cron.schedule(
  'notifications-poll-live-match',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://<SEU_PROJECT_REF>.functions.supabase.co/notifications-poll-live-match',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || private.notifications_service_role_key(),
      'Content-Type', 'application/json'
    )
  );
  $$
);

-- Rede de segurança: retoma eventos que ficaram travados em 'processing'
-- (queda no meio de um envio anterior). As outras 2 funções já chamam
-- notifications-dispatch direto quando criam um evento — este Cron só
-- existe pra cobrir falha, não é o caminho normal de disparo.
select cron.schedule(
  'notifications-dispatch-safety-net',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://<SEU_PROJECT_REF>.functions.supabase.co/notifications-dispatch',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || private.notifications_service_role_key(),
      'Content-Type', 'application/json'
    )
  );
  $$
);

-- Pra checar que os 3 jobs foram criados:
-- select jobid, jobname, schedule, active from cron.job;
