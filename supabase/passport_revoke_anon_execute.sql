-- ============================================================================
-- Passaporte: fecha EXECUTE de anon/public nas RPCs sem argumento de usuario
-- (auditoria 2026-09-27). Complementa passport_harden_per_user_rpcs.sql, que
-- so normalizou as sobrecargas "(uuid)".
--
-- Funcao em Postgres nasce com EXECUTE para PUBLIC; estes arquivos so
-- faziam "grant ... to authenticated" e nunca revogavam o padrao, entao a
-- anon key (publica, embutida no app) tambem chamava todas. Todas dependem
-- de auth.uid(), e usuario deslogado nao tem passaporte -- o app nao chama
-- nenhuma sem sessao. Idempotente; nao muda nada para quem esta logado.
-- ============================================================================
do $$
declare
  sig text;
begin
  foreach sig in array array[
    'public.passport_seasons()',
    'public.passport_matches_for_year(int)',
    'public.passport_summary()',
    'public.passport_save_attendances(jsonb)',
    'public.passport_my_attendances_for_year(int)',
    'public.passport_ranking(int, int)',
    'public.passport_my_rank(int)',
    'public.passport_set_memorable_match(text)',
    'public.passport_attended_matches()',
    'public.passport_stadium_summary()'
  ]
  loop
    if to_regprocedure(sig) is null then
      raise notice 'ignorado (nao existe neste projeto): %', sig;
      continue;
    end if;
    execute format('revoke execute on function %s from public;', sig);
    execute format('revoke execute on function %s from anon;', sig);
    execute format('grant execute on function %s to authenticated;', sig);
    execute format('grant execute on function %s to service_role;', sig);
  end loop;
end
$$;

-- Checkup (so leitura): nenhuma linha com anon_can_execute = true.
select p.oid::regprocedure as function,
       has_function_privilege('anon', p.oid, 'execute') as anon_can_execute,
       has_function_privilege('authenticated', p.oid, 'execute') as authenticated_can_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname like 'passport\_%'
order by 1;
