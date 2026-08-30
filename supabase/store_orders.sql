-- ============================================================================
-- Pedidos da Goiás Store. Rode no SQL Editor do Supabase. Substitui o
-- histórico salvo em `SharedPreferences` (local ao aparelho, sem dono) por
-- pedidos persistentes e vinculados à conta autenticada.
--
-- A COMPRA continua simulada (nunca existe pagamento/transportadora real).
-- O que muda é que o HISTÓRICO passa a ser real: sobrevive logout/login e
-- reinstalação, e nunca vaza entre contas diferentes no mesmo aparelho.
--
-- Cada item guarda um SNAPSHOT do produto no momento da compra
-- (nome/imagem/tamanho/preço) — nunca lê o catálogo atual, então um pedido
-- antigo continua mostrando exatamente o que foi comprado mesmo que o
-- produto mude de preço/nome ou saia da loja depois.
--
-- Pedido/itens nunca são apagados nem editados pelo app (histórico
-- imutável) — só INSERT e SELECT do próprio dono.
-- ============================================================================

create sequence if not exists public.store_order_number_seq;

create or replace function public.generate_store_order_number()
returns text
language sql
as $$
  select 'GOI-' || extract(year from now())::text || '-' ||
    lpad(nextval('public.store_order_number_seq')::text, 6, '0');
$$;

create table if not exists public.store_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_number text not null unique default public.generate_store_order_number(),
  created_at timestamptz not null default now(),
  status text not null,
  fulfillment_method text not null,
  -- Snapshots de objetos aninhados — nunca referenciam cadastro vivo
  -- (endereço/pagamento atuais do usuário), só o que valeu NESTE pedido.
  customer jsonb not null,
  address jsonb,
  shipping_option jsonb,
  pickup_responsible jsonb,
  payment jsonb not null,
  subtotal numeric not null,
  discount_amount numeric not null default 0,
  shipping_cost numeric not null default 0,
  coupon_code text
);

create index if not exists store_orders_user_id_idx
  on public.store_orders (user_id, created_at desc);

create table if not exists public.store_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.store_orders(id) on delete cascade,
  product_id text not null,
  product_name text not null,
  product_image text not null,
  size text not null,
  quantity integer not null,
  unit_price numeric not null,
  personalization_surcharge numeric not null default 0,
  personalized_name text,
  personalized_number integer,
  total_price numeric not null
);

create index if not exists store_order_items_order_id_idx
  on public.store_order_items (order_id);

alter table public.store_orders enable row level security;
alter table public.store_order_items enable row level security;

drop policy if exists "select own orders" on public.store_orders;
create policy "select own orders" on public.store_orders
  for select using (auth.uid() = user_id);

drop policy if exists "insert own orders" on public.store_orders;
create policy "insert own orders" on public.store_orders
  for insert with check (auth.uid() = user_id);

drop policy if exists "select own order items" on public.store_order_items;
create policy "select own order items" on public.store_order_items
  for select using (
    exists (
      select 1 from public.store_orders o
      where o.id = order_id and o.user_id = auth.uid()
    )
  );

drop policy if exists "insert own order items" on public.store_order_items;
create policy "insert own order items" on public.store_order_items
  for insert with check (
    exists (
      select 1 from public.store_orders o
      where o.id = order_id and o.user_id = auth.uid()
    )
  );

-- Sem policy de update/delete pro usuário comum de propósito — histórico
-- imutável pelo próprio app.

-- Cria o pedido e todos os seus itens numa única operação atômica — nunca
-- dois inserts separados que pudessem deixar um pedido "órfão" sem itens se
-- o segundo falhasse no meio do caminho. Roda como o usuário chamador (sem
-- `security definer`): a policy de insert acima já garante que só é
-- possível criar pedido pra si mesmo, então não precisa de privilégio
-- elevado aqui.
create or replace function public.create_store_order(
  p_status text,
  p_fulfillment_method text,
  p_customer jsonb,
  p_address jsonb,
  p_shipping_option jsonb,
  p_pickup_responsible jsonb,
  p_payment jsonb,
  p_subtotal numeric,
  p_discount_amount numeric,
  p_shipping_cost numeric,
  p_coupon_code text,
  p_items jsonb
)
returns public.store_orders
language plpgsql
as $$
declare
  v_order public.store_orders;
  v_item jsonb;
begin
  insert into public.store_orders (
    user_id, status, fulfillment_method, customer, address,
    shipping_option, pickup_responsible, payment, subtotal,
    discount_amount, shipping_cost, coupon_code
  ) values (
    auth.uid(), p_status, p_fulfillment_method, p_customer, p_address,
    p_shipping_option, p_pickup_responsible, p_payment, p_subtotal,
    p_discount_amount, p_shipping_cost, p_coupon_code
  )
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.store_order_items (
      order_id, product_id, product_name, product_image, size,
      quantity, unit_price, personalization_surcharge,
      personalized_name, personalized_number, total_price
    ) values (
      v_order.id,
      v_item->>'productId',
      v_item->>'productName',
      v_item->>'thumbnail',
      v_item->>'size',
      (v_item->>'quantity')::integer,
      (v_item->>'unitPrice')::numeric,
      coalesce((v_item->>'personalizationSurcharge')::numeric, 0),
      v_item->>'personalizedName',
      (v_item->>'personalizedNumber')::integer,
      (coalesce((v_item->>'unitPrice')::numeric, 0) +
        coalesce((v_item->>'personalizationSurcharge')::numeric, 0)) *
        (v_item->>'quantity')::integer
    );
  end loop;

  return v_order;
end;
$$;
