-- M-live: 6 eventos canônicos de partida ao vivo (kickoff, gol a favor, gol
-- contra, intervalo, início do 2º tempo, fim de jogo) + preferências
-- granulares atrás de um master toggle ("Jogos ao vivo").
--
-- `goal`/`full_time` já existiam (nomes mantidos, nunca renomeados — nenhum
-- motivo pra quebrar dado histórico/compat). Novos: `kickoff`, `goal_against`,
-- `half_time`, `second_half_started`.

alter table public.notification_events drop constraint notification_events_event_type_check;
alter table public.notification_events add constraint notification_events_event_type_check
  check (event_type = any (array[
    'match_access_open'::text,
    'kickoff'::text,
    'goal'::text,
    'goal_against'::text,
    'half_time'::text,
    'second_half_started'::text,
    'full_time'::text
  ]));

-- Último status normalizado do provider visto nesta sessão (`scheduled` |
-- `live` | `halftime` | `finished` | ...) — usado só pra detectar TRANSIÇÃO
-- real (kickoff/half_time/second_half_started), nunca por horário ou
-- minuto. `null` até o 1º poll depois do kickoff.
alter table public.match_monitor_sessions add column last_provider_status text;

-- Master toggle "Jogos ao vivo" — era `matches_enabled` (cobria só gol +
-- fim de jogo); agora gate único dos 6 eventos de partida. Rename preserva
-- o valor já escolhido por usuários existentes (quem tinha desativado
-- "Partidas" continua com o master OFF, nunca reativado silenciosamente).
alter table public.user_notification_preferences rename column matches_enabled to live_matches_enabled;

-- Sub-preferências por tipo de evento, todas default true (comportamento
-- pra usuários existentes: só dependiam do master antes, então o default
-- aqui preserva "recebia goal+full_time" e ainda liga os 4 eventos novos —
-- nunca um usuário que nunca configurou nada passa a receber MENOS do que
-- recebia, mas quem quiser pode desligar cada um individualmente).
alter table public.user_notification_preferences add column kickoff_enabled boolean not null default true;
alter table public.user_notification_preferences add column goal_for_enabled boolean not null default true;
alter table public.user_notification_preferences add column goal_against_enabled boolean not null default true;
alter table public.user_notification_preferences add column half_time_enabled boolean not null default true;
alter table public.user_notification_preferences add column second_half_started_enabled boolean not null default true;
alter table public.user_notification_preferences add column full_time_enabled boolean not null default true;
