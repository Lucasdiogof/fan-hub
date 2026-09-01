-- ============================================================================
-- SOMENTE LEITURA — rode no SQL Editor do Supabase e cole o resultado
-- inteiro de volta. Tudo num result set só (mesmo padrão do checkup.sql:
-- union all), porque o SQL Editor só mostra a última query quando você
-- roda várias separadas.
-- ============================================================================

select '1_columns' as section, jsonb_build_object(
  'column_name', column_name,
  'data_type', data_type,
  'is_nullable', is_nullable,
  'column_default', column_default
)::text as detail
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'

union all

select '2_constraints', jsonb_build_object(
  'conname', con.conname,
  'contype', con.contype,
  'definition', pg_get_constraintdef(con.oid)
)::text
from pg_constraint con
where con.conrelid = 'public.profiles'::regclass

union all

select '3_indexes', jsonb_build_object(
  'indexname', indexname,
  'indexdef', indexdef
)::text
from pg_indexes
where schemaname = 'public' and tablename = 'profiles'

union all

select '4_trigger_on_auth_users', jsonb_build_object(
  'trigger_name', t.tgname,
  'function_name', p.proname,
  'function_body', pg_get_functiondef(p.oid)
)::text
from pg_trigger t
join pg_proc p on p.oid = t.tgfoid
where t.tgrelid = 'auth.users'::regclass and not t.tgisinternal

union all

select '5_rls_policies_profiles', jsonb_build_object(
  'policyname', policyname,
  'cmd', cmd,
  'permissive', permissive,
  'roles', roles::text,
  'qual', qual,
  'with_check', with_check
)::text
from pg_policies
where schemaname = 'public' and tablename = 'profiles'

union all

select '6_rls_enabled_profiles', jsonb_build_object(
  'relrowsecurity', relrowsecurity,
  'relforcerowsecurity', relforcerowsecurity
)::text
from pg_class
where oid = 'public.profiles'::regclass

union all

select '7_cron_jobs', jsonb_build_object(
  'jobid', jobid,
  'jobname', jobname,
  'schedule', schedule,
  'active', active
)::text
from cron.job

union all

select '8_vault_secret_names', jsonb_build_object('name', name)::text
from vault.secrets

union all

select '9_extensions', jsonb_build_object('extname', extname)::text
from pg_extension
where extname in ('pg_cron', 'pg_net')

order by 1;
