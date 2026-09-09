-- ============================================================================
-- Auditoria de migrations — projeto GOIÁS. Rode no SQL Editor deste projeto.
-- Cada linha retornada = uma migration/SQL que parece não ter rodado (ou
-- rodou incompleto). Se só aparecer a linha de RESUMO, está tudo certo.
--
-- Isto NÃO substitui `checkup.sql` (duplicatas/órfãos nos dados) — rode os
-- dois. Este aqui olha "existe a coluna/função/bucket que a migration
-- deveria ter criado", não "os dados estão consistentes".
--
-- Idempotência: toda migration deste repo usa IF NOT EXISTS/ON CONFLICT/
-- CREATE OR REPLACE — rodar de novo por engano nunca duplica nada. Se algo
-- aparecer aqui como faltando, o problema é NÃO ter rodado, não ter rodado
-- 2x.
-- ============================================================================

-- ── MIGRATION 20260904210000_add_delivery_address_triggers ──
select '❌ 20260904210000: trigger delivery_addresses_ensure_default ausente' as check, '' as detail
where not exists (select 1 from pg_trigger where tgname = 'delivery_addresses_ensure_default')

union all

select '❌ 20260904210000: trigger delivery_addresses_single_default ausente', ''
where not exists (select 1 from pg_trigger where tgname = 'delivery_addresses_single_default')

-- ── MIGRATION 20260908000000_squad_members_add_lifecycle_columns ──

union all

select '❌ 20260908000000: coluna squad_members.active ausente', ''
where not exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'squad_members' and column_name = 'active'
)

union all

select '❌ 20260908000000: coluna squad_members.departed_at ausente', ''
where not exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'squad_members' and column_name = 'departed_at'
)

union all

select '❌ 20260908000000: coluna squad_members.departed_to ausente', ''
where not exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'squad_members' and column_name = 'departed_to'
)

-- ── MIGRATION 20260909000000_arena_record_score_identity_games ──

union all

select '❌ 20260909000000: função arena_record_score ausente', ''
where not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'arena_record_score'
)

union all

select '❌ 20260909000000: arena_record_score sem branch pra tactical_identity', ''
where not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'arena_record_score'
    and pg_get_functiondef(p.oid) like '%tactical_identity%'
)

union all

select '❌ 20260909000000: arena_record_score sem branch pra player_identity', ''
where not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'arena_record_score'
    and pg_get_functiondef(p.oid) like '%player_identity%'
)

-- ── MIGRATION 20260909120000_half_price_proof ──

union all

select '❌ 20260909120000: coluna tickets.half_price_type ausente', ''
where not exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'tickets' and column_name = 'half_price_type'
)

union all

select '❌ 20260909120000: coluna tickets.half_price_proof_path ausente', ''
where not exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'tickets' and column_name = 'half_price_proof_path'
)

union all

select '❌ 20260909120000: bucket half_price_proofs ausente', ''
where not exists (select 1 from storage.buckets where id = 'half_price_proofs')

union all

select '❌ 20260909120000: bucket half_price_proofs está PÚBLICO (deveria ser privado)', ''
where exists (select 1 from storage.buckets where id = 'half_price_proofs' and public = true)

union all

select '❌ 20260909120000: policy half_price_proofs_write_own ausente', ''
where not exists (
  select 1 from pg_policies
  where schemaname = 'storage' and tablename = 'objects' and policyname = 'half_price_proofs_write_own'
)

union all

select '❌ 20260909120000: policy half_price_proofs_read_own ausente', ''
where not exists (
  select 1 from pg_policies
  where schemaname = 'storage' and tablename = 'objects' and policyname = 'half_price_proofs_read_own'
)

union all

select '❌ 20260909120000: policy half_price_proofs_delete_own ausente', ''
where not exists (
  select 1 from pg_policies
  where schemaname = 'storage' and tablename = 'objects' and policyname = 'half_price_proofs_delete_own'
)

-- ── fix_handle_new_user_missing_fields.sql (arquivo solto, roda nos 2 projetos) ──

union all

select '❌ fix_handle_new_user_missing_fields.sql: handle_new_user ainda não copia cpf/birth_date/phone do metadata', ''
where not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'handle_new_user'
    and pg_get_functiondef(p.oid) like '%cpf%'
    and pg_get_functiondef(p.oid) like '%birth_date%'
    and pg_get_functiondef(p.oid) like '%marketing_opt_in%'
)

union all

select '❌ fix_handle_new_user_missing_fields.sql: backfill não rodou — ' || count(*)::text || ' perfil(is) com cpf/birth_date/phone NULL apesar do metadata do cadastro ter o dado', ''
from public.profiles p
join auth.users u on u.id = p.id
where (p.cpf is null and coalesce(u.raw_user_meta_data->>'cpf', '') <> '')
   or (p.birth_date is null and coalesce(u.raw_user_meta_data->>'birth_date', '') <> '')
   or (p.phone is null and coalesce(u.raw_user_meta_data->>'phone', '') <> '')
having count(*) > 0

-- ── RESUMO ──

union all

select '✅ Fim da auditoria — nenhuma ❌ acima = tudo rodado certinho', 'Lembre de rodar checkup.sql também, pra duplicatas/órfãos nos dados';
