-- ============================================================================
-- M3.2 — RPC tenant-aware ADITIVA pra Goiás Store. NUNCA substitui
-- create_store_order(...) — essa continua byte-idêntica, servindo só o app
-- já publicado (que não manda p_club_id e cai no DEFAULT Goiás da coluna).
--
-- create_store_order_for_club grava club_id EXPLICITAMENTE (nunca confia no
-- DEFAULT da M2.2A) — mesma decisão de não usar `security definer` da
-- legacy: a policy "insert own orders" (auth.uid() = user_id) já garante
-- que só é possível criar pedido pra si mesmo.
--
-- order_number continua UNIQUE GLOBAL via public.store_order_number_seq —
-- intocado nesta etapa (M2.1 já classificou KEEP_GLOBAL; prefixo "GOI-"
-- entra em pauta só na M3.3/M4).
-- ============================================================================

create or replace function public.create_store_order_for_club(
  p_club_id uuid,
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
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  insert into public.store_orders (
    user_id, club_id, status, fulfillment_method, customer, address,
    shipping_option, pickup_responsible, payment, subtotal,
    discount_amount, shipping_cost, coupon_code
  ) values (
    auth.uid(), p_club_id, p_status, p_fulfillment_method, p_customer,
    p_address, p_shipping_option, p_pickup_responsible, p_payment,
    p_subtotal, p_discount_amount, p_shipping_cost, p_coupon_code
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

-- Hardening (rodada de revisão): SECURITY INVOKER não significa que EXECUTE
-- público é desejável — a RLS ("insert own orders") protege a TABELA, mas o
-- privilégio de EXECUTE da FUNÇÃO em si deve continuar least-privilege.
-- Revoga PUBLIC explícito (mesma dívida real confirmada na legacy
-- `create_store_order`, que nunca teve um GRANT próprio — só herdava o
-- padrão do CREATE FUNCTION) antes de conceder só authenticated. Criar
-- pedido nunca faz sentido sem sessão — nunca `anon`; nenhum caller
-- server-side — nunca `service_role`.
revoke all on function public.create_store_order_for_club(
  uuid, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, numeric, numeric,
  numeric, text, jsonb
) from public;
grant execute on function public.create_store_order_for_club(
  uuid, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, numeric, numeric,
  numeric, text, jsonb
) to authenticated;
