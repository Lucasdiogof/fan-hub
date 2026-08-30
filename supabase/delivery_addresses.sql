-- ============================================================================
-- Endereços de entrega da Goiás Store. Rode no SQL Editor do Supabase.
--
-- Conceitualmente separado do endereço RESIDENCIAL (tabela `profiles`, um só
-- por conta, editado em "Endereço residencial" no Perfil): aqui é uma lista,
-- zero ou vários endereços por conta, usada só pra escolher onde receber uma
-- compra da Loja. Ao contrário de `store_orders` (histórico imutável), este
-- é editável pelo dono — endereço de entrega pode ser corrigido/removido a
-- qualquer momento; o que NUNCA muda depois de criado é o snapshot já salvo
-- dentro de um pedido (`store_orders.address`, uma cópia congelada, não uma
-- referência a esta tabela).
-- ============================================================================

create table if not exists public.delivery_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text,
  zip_code text not null,
  street text not null,
  number text not null,
  complement text,
  neighborhood text not null,
  city text not null,
  state text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists delivery_addresses_user_id_idx
  on public.delivery_addresses (user_id, created_at asc);

alter table public.delivery_addresses enable row level security;

drop policy if exists "select own delivery addresses" on public.delivery_addresses;
create policy "select own delivery addresses" on public.delivery_addresses
  for select using (auth.uid() = user_id);

drop policy if exists "insert own delivery addresses" on public.delivery_addresses;
create policy "insert own delivery addresses" on public.delivery_addresses
  for insert with check (auth.uid() = user_id);

drop policy if exists "update own delivery addresses" on public.delivery_addresses;
create policy "update own delivery addresses" on public.delivery_addresses
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "delete own delivery addresses" on public.delivery_addresses;
create policy "delete own delivery addresses" on public.delivery_addresses
  for delete using (auth.uid() = user_id);

-- Garante as duas regras de negócio direto no banco (nunca em múltiplos
-- passos no app, que poderiam deixar dois endereços padrão momentaneamente
-- inconsistentes):
--   1. o primeiro endereço de uma conta já nasce padrão;
--   2. marcar um endereço como padrão automaticamente desmarca os outros.
create or replace function public.delivery_address_ensure_default()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.delivery_addresses
    where user_id = new.user_id and id <> new.id
  ) then
    new.is_default := true;
  end if;
  return new;
end;
$$;

drop trigger if exists delivery_addresses_ensure_default on public.delivery_addresses;
create trigger delivery_addresses_ensure_default
  before insert on public.delivery_addresses
  for each row execute function public.delivery_address_ensure_default();

create or replace function public.delivery_address_enforce_single_default()
returns trigger
language plpgsql
as $$
begin
  if new.is_default then
    update public.delivery_addresses
      set is_default = false
      where user_id = new.user_id and id <> new.id and is_default = true;
  end if;
  return new;
end;
$$;

drop trigger if exists delivery_addresses_single_default on public.delivery_addresses;
create trigger delivery_addresses_single_default
  before insert or update on public.delivery_addresses
  for each row execute function public.delivery_address_enforce_single_default();
