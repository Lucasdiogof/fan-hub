-- Diagnóstico das notificações de jogo do Goiás — só leitura.
-- Rodar com tooling/multiclub/run-goias-query.ps1

-- ## 1. Partidas monitoradas nos últimos 3 dias
select match_id, kickoff, home_team_name, away_team_name, status,
       last_provider_status, last_known_score, started_at, last_polled_at, ends_at
from public.match_monitor_sessions
where kickoff > now() - interval '3 days'
order by kickoff desc
limit 10;

-- ## 2. Eventos detectados nos últimos 3 dias
select event_type, match_id, status, detected_at, completed_at,
       left(payload::text, 120) as payload
from public.notification_events
where detected_at > now() - interval '3 days'
order by detected_at desc
limit 30;

-- ## 3. Entregas por evento (status e erro do Firebase)
select e.event_type, e.detected_at, d.status, left(d.error, 160) as error,
       t.platform, d.attempted_at
from public.notification_deliveries d
join public.notification_events e on e.id = d.event_id
join public.user_notification_tokens t on t.id = d.token_id
where e.detected_at > now() - interval '3 days'
order by d.attempted_at desc nulls last
limit 40;

-- ## 4. Aparelhos cadastrados (sem mostrar o token)
select t.platform, t.is_active, t.last_seen_at, t.created_at,
       left(t.fcm_token, 12) || '…' as token_inicio, u.email
from public.user_notification_tokens t
left join auth.users u on u.id = t.user_id
order by t.last_seen_at desc
limit 20;

-- ## 5. Preferências de notificação
select u.email, p.*
from public.user_notification_preferences p
left join auth.users u on u.id = p.user_id
order by p.updated_at desc
limit 10;

-- ## 6. Crons de notificação e últimas execuções
select j.jobname, j.schedule, j.active,
       (select max(start_time) from cron.job_run_details r where r.jobid = j.jobid) as ultima_execucao,
       (select status from cron.job_run_details r where r.jobid = j.jobid order by start_time desc limit 1) as ultimo_status,
       (select left(return_message, 120) from cron.job_run_details r where r.jobid = j.jobid order by start_time desc limit 1) as ultima_msg
from cron.job j
where j.jobname ilike '%notif%'
order by j.jobname;
