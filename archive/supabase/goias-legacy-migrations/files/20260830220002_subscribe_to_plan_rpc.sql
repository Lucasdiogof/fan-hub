-- ============================================================================
-- Fecha o vetor descrito no Lote 2 do hardening: ate aqui, o Flutter
-- calculava e enviava started_at/expires_at/plan_id/plan_name direto num
-- insert em supporter_memberships, e a policy so garantia
-- `auth.uid() = user_id` -- um usuario autenticado podia chamar o Supabase
-- direto e mandar expires_at no futuro distante.
--
-- A partir daqui, o Flutter nao decide mais validade nenhuma. Toda
-- contratacao passa pela RPC abaixo, que:
--   1. identifica o usuario so por auth.uid() (nem recebe user_id como
--      parametro -- estruturalmente impossivel escolher outra conta);
--   2. valida que plan_id e um dos planos reais (mesmo padrao de
--      arena_record_score: mapeamento hardcoded, sem tabela nova);
--   3/4/5. usa o horario do proprio Postgres pra started_at/expires_at,
--      sempre 30 dias, nunca um valor vindo do cliente;
--   6. bloqueia se ja existe uma assinatura ativa (expires_at > now()).
--
-- pg_advisory_xact_lock trava por user_id dentro da transacao (libera
-- sozinho no commit/rollback) -- fecha a corrida de duas chamadas
-- concorrentes criarem duas assinaturas ativas, sem precisar de constraint
-- nova (um indice parcial com `where expires_at > now()` nao e possivel:
-- predicado de indice em Postgres precisa ser imutavel, e now() nao e).
--
-- IMPORTANTE: pagamento continua nao existindo. Isto so protege a regra de
-- validade da simulacao -- nenhum gateway/checkout real foi adicionado.
-- ============================================================================

create or replace function public.subscribe_to_plan(p_plan_id text)
returns table (
  id uuid,
  plan_id text,
  plan_name text,
  started_at timestamptz,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_plan_name text;
  v_active_count int;
  v_started_at timestamptz;
  v_expires_at timestamptz;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  perform pg_advisory_xact_lock(hashtext('subscribe_to_plan:' || v_uid::text));

  -- Mesmo catalogo de MembershipPlansCatalog.plans (lib/features/membership/
  -- data/membership_plans_catalog.dart) -- se um plano for adicionado/
  -- renomeado la, precisa ser espelhado aqui tambem. Nao existe uma tabela
  -- de planos no banco de proposito (planos continuam vindo do catalogo
  -- local no Flutter; so a CONTRATACAO precisava virar real).
  v_plan_name := case p_plan_id
    when 'nossa-gente' then 'NOSSA GENTE'
    when 'nossa-historia' then 'NOSSA HISTORIA'
    when 'nossa-garra' then 'NOSSA GARRA'
    when 'nossa-gloria' then 'NOSSA GLORIA'
    when 'nossa-familia' then 'NOSSA FAMILIA'
    when 'plano-vip' then 'PLANO VIP'
    else null
  end;

  if v_plan_name is null then
    raise exception 'invalid plan_id %', p_plan_id;
  end if;

  -- Qualificado com o nome da tabela de proposito: `returns table (...,
  -- expires_at timestamptz)` faz o Postgres enxergar `expires_at` tambem
  -- como variavel de saida da propria funcao, colidindo com a coluna da
  -- tabela e virando "column reference is ambiguous" sem essa qualificacao.
  select count(*) into v_active_count
  from public.supporter_memberships
  where supporter_memberships.user_id = v_uid
    and supporter_memberships.expires_at > now();

  if v_active_count > 0 then
    raise exception 'membership already active';
  end if;

  v_started_at := now();
  v_expires_at := v_started_at + interval '30 days';

  insert into public.supporter_memberships (
    user_id, plan_id, plan_name, started_at, expires_at
  )
  values (
    v_uid, p_plan_id, v_plan_name, v_started_at, v_expires_at
  )
  returning supporter_memberships.id into v_id;

  return query
  select v_id, p_plan_id, v_plan_name, v_started_at, v_expires_at;
end;
$$;

grant execute on function public.subscribe_to_plan(text) to authenticated;

-- Fecha o vetor de verdade: sem policy de insert, RLS bloqueia qualquer
-- insert direto do cliente em supporter_memberships. So a RPC acima
-- (security definer, roda como dono da tabela) consegue escrever. Select
-- continua igual -- leitura nao muda neste lote.
drop policy if exists "insert own membership" on public.supporter_memberships;
