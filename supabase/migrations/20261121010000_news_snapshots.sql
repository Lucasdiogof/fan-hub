-- ============================================================================
-- Notícias — snapshot da LISTA no próprio Supabase do clube.
--
--   Edge Function `news-refresh` -> site oficial -> normaliza -> ESTA tabela
--   Flutter                      -> RPC get_news_snapshot (só leitura)
--
-- Uma linha por clube (PK = club_id): a lista é SOBRESCRITA a cada refresh,
-- então a tabela não cresce. Artigo NÃO é persistido (Edge Function
-- `news-article`, sob demanda). Capas: bucket público `news-images`.
--
-- INDEPENDENTE DE SCHEDULER (pg_cron fica em supabase/news_snapshots_cron.sql).
-- Agnóstica de clube; idempotente.
--   next_refresh_at = quando buscar de novo (NULL = nada agendado)
--   expires_at      = até quando o app pode confiar na lista (RPC marca `expired`)
-- ============================================================================

create table if not exists public.news_snapshots (
  club_id              uuid        primary key references public.clubs (id) on delete cascade,
  payload              jsonb       not null,
  contract_version     integer     not null default 1,
  source               text        not null default 'official-site',
  fetched_at           timestamptz not null default now(),
  next_refresh_at      timestamptz,
  expires_at           timestamptz not null default now(),
  consecutive_failures integer     not null default 0,
  last_error           text,
  last_error_at        timestamptz,
  constraint news_snapshots_failures_check check (consecutive_failures >= 0)
);

create index if not exists news_snapshots_next_refresh_idx
  on public.news_snapshots (next_refresh_at);

-- RLS ligada e SEM policy: leitura só pela RPC; escrita só service_role.
alter table public.news_snapshots enable row level security;
revoke all on table public.news_snapshots from public, anon, authenticated;
grant all on table public.news_snapshots to service_role;

create or replace function public.get_news_snapshot(p_club_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  s     public.news_snapshots;
  v_now timestamptz := now();
begin
  select * into s from public.news_snapshots where club_id = p_club_id;
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
    -- "velho": passou do horário com folga de 2 min OU a última tentativa falhou.
    'stale',           (s.next_refresh_at is not null and v_now > s.next_refresh_at + interval '2 minutes')
                       or s.consecutive_failures > 0,
    'expired',         v_now > s.expires_at
  );
end;
$$;

revoke all on function public.get_news_snapshot(uuid) from public;
grant execute on function public.get_news_snapshot(uuid) to anon, authenticated, service_role;

-- Bucket PÚBLICO de capas (escrita só via service_role; sem policy p/ anon).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('news-images', 'news-images', true, 2097152, array['image/*'])
on conflict (id) do update
  set public = true, file_size_limit = 2097152, allowed_mime_types = array['image/*'];

do $$
begin
  if has_table_privilege('anon', 'public.news_snapshots', 'select, insert, update, delete, truncate')
     or has_table_privilege('authenticated', 'public.news_snapshots', 'select, insert, update, delete, truncate') then
    raise exception 'news_snapshots must not be directly accessible by anon/authenticated';
  end if;
  if not has_function_privilege('anon', 'public.get_news_snapshot(uuid)', 'execute') then
    raise exception 'get_news_snapshot must be executable by anon';
  end if;
end $$;
