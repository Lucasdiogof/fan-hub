-- ============================================================================
-- Assinatura de Sócio Torcedor. Rode no SQL Editor do Supabase. Substitui o
-- MockMembershipRepository (em memória, resetava a cada restart do app) por
-- uma assinatura persistente e vinculada à conta autenticada.
--
-- Validade nunca é decidida pelo app: `get_my_membership()` calcula
-- `is_active` comparando `expires_at` com o `now()` do próprio Postgres, não
-- com o relógio do aparelho — o usuário não consegue ganhar/perder status
-- mexendo na hora do celular.
--
-- Registro vencido nunca é apagado (histórico) — uma nova contratação depois
-- do vencimento simplesmente insere uma nova linha.
-- ============================================================================

create table if not exists public.supporter_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_id text not null,
  plan_name text not null,
  started_at timestamptz not null default now(),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists supporter_memberships_user_id_idx
  on public.supporter_memberships (user_id);

alter table public.supporter_memberships enable row level security;

drop policy if exists "select own memberships" on public.supporter_memberships;
create policy "select own memberships" on public.supporter_memberships
  for select using (auth.uid() = user_id);

drop policy if exists "insert own membership" on public.supporter_memberships;
create policy "insert own membership" on public.supporter_memberships
  for insert with check (auth.uid() = user_id);

-- Sem policy de update/delete pro usuário comum de propósito — o histórico é
-- imutável pelo próprio app; edição só pelo dashboard/admin se algum dia
-- precisar.

-- Sempre a assinatura mais recente do usuário (ativa ou não), com `is_active`
-- calculado pelo relógio do banco. `security definer` só pra poder ler
-- `auth.uid()` de dentro da função com o mesmo efeito de uma RLS normal —
-- ainda assim só devolve linha do próprio usuário chamando.
create or replace function public.get_my_membership()
returns table (
  id uuid,
  plan_id text,
  plan_name text,
  started_at timestamptz,
  expires_at timestamptz,
  is_active boolean
)
language sql
security definer
set search_path = public
as $$
  select
    m.id,
    m.plan_id,
    m.plan_name,
    m.started_at,
    m.expires_at,
    (m.expires_at > now()) as is_active
  from public.supporter_memberships m
  where m.user_id = auth.uid()
  order by m.created_at desc
  limit 1;
$$;
