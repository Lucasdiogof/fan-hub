-- ============================================================================
-- Limpeza de cadastros pendentes há mais de 48h — rode DEPOIS de colar a
-- Edge Function `cleanup-unconfirmed-signups` no dashboard (Edge Functions >
-- Create a new function, cole supabase/functions/cleanup-unconfirmed-signups/
-- index.ts). Reaproveita a MESMA secret já guardada no Vault pros crons de
-- notificações (`notifications_service_role_key`) — não cria uma nova, é a
-- mesma service_role key do projeto de qualquer forma.
-- ============================================================================

-- Função que a Edge Function chama pra saber QUEM apagar — fica em `public`
-- de propósito (só schema exposto por padrão via PostgREST/RPC), mas o
-- `grant` abaixo restringe a execução só pro `service_role`; `anon`/
-- `authenticated` nunca conseguem chamar isso. `security definer` porque
-- `auth.users` não é legível pelo dono normal da conexão.
create or replace function public.list_unconfirmed_signups_for_cleanup()
returns table (id uuid, email text)
language sql
security definer
set search_path = public, auth
as $$
  select id, email
  from auth.users
  where email_confirmed_at is null
    and created_at < now() - interval '48 hours';
$$;

revoke all on function public.list_unconfirmed_signups_for_cleanup() from public;
revoke all on function public.list_unconfirmed_signups_for_cleanup() from anon, authenticated;
grant execute on function public.list_unconfirmed_signups_for_cleanup() to service_role;

select cron.schedule(
  'cleanup-unconfirmed-signups',
  '0 * * * *', -- a cada hora, no minuto 0
  $$
  select net.http_post(
    url := 'https://yonozsdgyrhgqrvydbnr.functions.supabase.co/cleanup-unconfirmed-signups',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || private.notifications_service_role_key(),
      'Content-Type', 'application/json'
    )
  );
  $$
);

-- Pra conferir que o job foi criado:
-- select jobid, jobname, schedule, active from cron.job where jobname = 'cleanup-unconfirmed-signups';
