-- ============================================================================
-- Futebol — snapshots normalizados (Home, Jogos, push) no próprio Supabase do
-- clube. Substitui, aos poucos, o backend de futebol dos Workers por clube:
--
--   Edge Function `football-refresh` -> OneFootball -> normaliza -> ESTA tabela
--   Flutter / push                   -> RPC get_football_snapshot (só leitura)
--
-- Uma tabela só, `payload jsonb` = o MESMO JSON que os Workers entregavam
-- (contrato estável do Fan-Hub; mudar o formato do OneFootball nunca exige
-- release de app, só ajuste na Edge Function).
--
-- INDEPENDENTE DE SCHEDULER: esta migration NÃO usa pg_cron/pg_net/Vault e
-- aplica em qualquer projeto. O agendamento é um passo separado
-- (supabase/football_snapshots_cron.sql, protegido contra extensão ausente).
--
-- Agnóstica de clube (sem literal de clube); idempotente.
--
-- Dois conceitos distintos:
--   next_refresh_at  = QUANDO buscar de novo (decide o scheduler)
--                      (NULL = sem atualização agendada: dado histórico imutável)
--   expires_at       = até quando o APP pode confiar no snapshot (a RPC marca
--                      `expired`; o app trata como indisponível)
-- ============================================================================

create table if not exists public.football_snapshots (
  club_id              uuid        not null references public.clubs (id) on delete cascade,
  kind                 text        not null,
  -- 'default' nos singletons (team/season/competitions); id da partida
  -- (ex.: 'onef-123'), 'offset:N' (rodada) ou id da competição nos demais.
  key                  text        not null default 'default',
  payload              jsonb       not null,
  contract_version     integer     not null default 1,
  source               text        not null default 'onefootball',
  fetched_at           timestamptz not null default now(),
  next_refresh_at      timestamptz,
  expires_at           timestamptz not null default now(),
  consecutive_failures integer     not null default 0,
  last_error           text,
  last_error_at        timestamptz,
  primary key (club_id, kind, key),
  constraint football_snapshots_kind_check check (
    kind in ('team', 'fixture', 'season', 'current_round', 'standings', 'competitions')
  ),
  constraint football_snapshots_key_check check (length(key) between 1 and 200),
  constraint football_snapshots_failures_check check (consecutive_failures >= 0)
);

-- Idempotente: bancos onde a 1ª versão (NOT NULL) já rodou.
alter table public.football_snapshots alter column next_refresh_at drop not null;
alter table public.football_snapshots alter column next_refresh_at drop default;

-- Scheduler: "o que está vencido?" sem varrer a tabela.
create index if not exists football_snapshots_next_refresh_idx
  on public.football_snapshots (next_refresh_at);

-- RLS ligada e SEM policy: ninguém lê a tabela direto pelo PostgREST. Leitura
-- só pela RPC abaixo; escrita só pelo service_role (que ignora RLS).
alter table public.football_snapshots enable row level security;

revoke all on table public.football_snapshots from public, anon, authenticated;
grant all on table public.football_snapshots to service_role;

-- RPC de leitura. Dado de futebol é público, então anon e authenticated podem
-- chamar; ela só devolve linhas de football_snapshots (nunca dado privado) e
-- valida `kind`. Snapshot ausente NÃO é exceção: devolve {"found": false}.
create or replace function public.get_football_snapshot(
  p_club_id uuid,
  p_kind    text,
  p_key     text default 'default'
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_key text := coalesce(nullif(btrim(p_key), ''), 'default');
  s     public.football_snapshots;
  v_now timestamptz := now();
begin
  if p_kind is null or p_kind not in
     ('team', 'fixture', 'season', 'current_round', 'standings', 'competitions') then
    raise exception 'invalid football snapshot kind' using errcode = '22023';
  end if;
  if length(v_key) > 200 then
    raise exception 'invalid football snapshot key' using errcode = '22023';
  end if;

  select * into s
    from public.football_snapshots
   where club_id = p_club_id and kind = p_kind and key = v_key;

  if not found then
    return jsonb_build_object('found', false);
  end if;

  return jsonb_build_object(
    'found',           true,
    'payload',         s.payload,
    'contractVersion', s.contract_version,
    'source',          s.source,
    'fetchedAt',       s.fetched_at,
    'ageSeconds',      greatest(0, floor(extract(epoch from (v_now - s.fetched_at))))::int,
    -- "velho": passou do horário de atualização com folga de 2 min (o cron
    -- leva até ~1 min pra disparar) OU a última tentativa falhou.
    'stale',           (s.next_refresh_at is not null and v_now > s.next_refresh_at + interval '2 minutes')
                       or s.consecutive_failures > 0,
    'expired',         v_now > s.expires_at
  );
end;
$$;

revoke all on function public.get_football_snapshot(uuid, text, text) from public;
grant execute on function public.get_football_snapshot(uuid, text, text)
  to anon, authenticated, service_role;

-- Guarda final: a tabela não pode ficar legível por anon/authenticated.
do $$
begin
  if has_table_privilege('anon', 'public.football_snapshots', 'select, insert, update, delete, truncate')
     or has_table_privilege('authenticated', 'public.football_snapshots', 'select, insert, update, delete, truncate') then
    raise exception 'football_snapshots must not be directly accessible by anon/authenticated';
  end if;
  if not has_function_privilege('anon', 'public.get_football_snapshot(uuid,text,text)', 'execute') then
    raise exception 'get_football_snapshot must be executable by anon';
  end if;
end $$;
