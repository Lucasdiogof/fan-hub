-- Últimos 2 diffs reais entre Goiás e canonical (diff_schema_goias_bragantino.mjs
-- rodada 3): create_store_order_for_club e subscribe_to_plan_for_club tinham
-- comportamento 100% idêntico, só com a ORDEM de statements independentes
-- trocada (declare de variáveis em ordem diferente; lock advisory antes ou
-- depois da validação do plano — nenhum dos dois muda o resultado, já que a
-- validação é read-only e o lock protege o insert em supporter_memberships,
-- não a leitura do catálogo). Alinhado aqui pra bater byte-a-byte com
-- infra/supabase/canonical/supabase/migrations/20260904000000_canonical_baseline.sql,
-- fechando SCHEMA_DIFF=0 de verdade em vez de só "equivalente".

CREATE OR REPLACE FUNCTION public.create_store_order_for_club(p_club_id uuid, p_status text, p_fulfillment_method text, p_customer jsonb, p_address jsonb, p_shipping_option jsonb, p_pickup_responsible jsonb, p_payment jsonb, p_subtotal numeric, p_discount_amount numeric, p_shipping_cost numeric, p_coupon_code text, p_items jsonb)
 RETURNS store_orders
 LANGUAGE plpgsql
AS $function$
declare
  v_order public.store_orders;
  v_item jsonb;
  v_order_number text;
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  v_order_number := public.generate_store_order_number(p_club_id);

  insert into public.store_orders (
    user_id, club_id, order_number, status, fulfillment_method, customer, address,
    shipping_option, pickup_responsible, payment, subtotal,
    discount_amount, shipping_cost, coupon_code
  ) values (
    auth.uid(), p_club_id, v_order_number, p_status, p_fulfillment_method,
    p_customer, p_address, p_shipping_option, p_pickup_responsible, p_payment,
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
$function$;

CREATE OR REPLACE FUNCTION public.subscribe_to_plan_for_club(p_club_id uuid, p_plan_id text)
 RETURNS TABLE(id uuid, plan_id text, plan_name text, started_at timestamp with time zone, expires_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_plan record;
  v_active_count int;
  v_started_at timestamptz;
  v_expires_at timestamptz;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs c where c.id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  select mp.name, mp.duration_days into v_plan
  from public.membership_plans mp
  where mp.club_id = p_club_id and mp.plan_key = p_plan_id and mp.is_active;

  if v_plan is null then
    raise exception 'invalid plan_id %', p_plan_id;
  end if;

  perform pg_advisory_xact_lock(
    hashtext('subscribe_to_plan_for_club:' || v_uid::text || ':' || p_club_id::text)
  );

  select count(*) into v_active_count
  from public.supporter_memberships
  where supporter_memberships.user_id = v_uid
    and supporter_memberships.club_id = p_club_id
    and supporter_memberships.expires_at > now();

  if v_active_count > 0 then
    raise exception 'membership already active';
  end if;

  v_started_at := now();
  v_expires_at := v_started_at + (v_plan.duration_days || ' days')::interval;

  insert into public.supporter_memberships (
    user_id, club_id, plan_id, plan_name, started_at, expires_at
  )
  values (
    v_uid, p_club_id, p_plan_id, v_plan.name, v_started_at, v_expires_at
  )
  returning supporter_memberships.id into v_id;

  return query
  select v_id, p_plan_id, v_plan.name, v_started_at, v_expires_at;
end;
$function$;
