-- ============================================================================
-- TESTE AUTOMATIZÁVEL (sem usuário real) da correção de IDOR do Passaporte.
-- Rode DEPOIS de aplicar `passport_harden_per_user_rpcs.sql`, no SQL Editor de
-- CADA projeto (Goiás e Bragantino).
--
-- 100% LEITURA: não faz INSERT/UPDATE (portanto NÃO depende de auth.users nem
-- viola a FK de passport_attendances.user_id). A impersonação usa apenas
-- `request.jwt.claims` — auth.uid() lê o claim, sem precisar de usuário real.
-- Aborta com `FAIL#n` no primeiro problema; se tudo passar, imprime
-- `==== TODOS OS TESTES (sem usuário real) PASSARAM ====`.
--
-- Cobre: (1) introspecção prova as 5 protegidas; (2) anon/public sem EXECUTE,
-- authenticated mantém; (3) guard: A+p_user_id=B recusado (42501), A+p_user_id=A
-- ok, uid null -> not authenticated; (4) RPCs públicas intactas.
-- O teste POSITIVO A×B com dados reais (A lê A, B lê B) precisa de 2 contas de
-- TESTE — ver tooling/passport_security/authenticated_idor_test.mjs.
-- ============================================================================
begin;

do $$
declare
  fns text[] := array['passport_summary','passport_attendance_breakdown',
                       'passport_stadium_summary','passport_attended_matches',
                       'passport_memorable_match_id'];
  fn  text;
  src text;
  is_plpgsql boolean;
  r   record;
  uid_a uuid := '00000000-0000-0000-0000-0000000000aa';
  uid_b uuid := '00000000-0000-0000-0000-0000000000bb';
begin
  -- (1) INTROSPECÇÃO — cada uma das 5 usa auth.uid() e recusa p_user_id alheio
  foreach fn in array fns loop
    select p.prosrc, (p.prolang = (select oid from pg_language where lanname='plpgsql'))
      into src, is_plpgsql
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname='public' and p.proname=fn
        and pg_get_function_identity_arguments(p.oid) = 'p_user_id uuid';
    if src is null then raise exception 'FAIL#1 %(uuid) não encontrada', fn; end if;
    if not is_plpgsql then raise exception 'FAIL#1 %: esperado language plpgsql', fn; end if;
    if position('coalesce(p_user_id' in src) > 0 then
      raise exception 'FAIL#1 %: ainda confia no p_user_id do cliente (coalesce)', fn; end if;
    if position('auth.uid()' in src) = 0 then
      raise exception 'FAIL#1 %: não usa auth.uid()', fn; end if;
    if position('p_user_id <> v_uid' in src) = 0 then
      raise exception 'FAIL#1 %: falta a recusa explícita de p_user_id alheio', fn; end if;
  end loop;
  raise notice 'PASS#1 introspecção: 5 em plpgsql, auth.uid() + recusa explícita, sem coalesce(p_user_id)';

  -- (2) GRANTS — anon/public sem EXECUTE; authenticated mantém
  foreach fn in array fns loop
    if has_function_privilege('anon', format('public.%I(uuid)', fn), 'EXECUTE') then
      raise exception 'FAIL#2 %: anon AINDA tem EXECUTE', fn; end if;
    if has_function_privilege('public', format('public.%I(uuid)', fn), 'EXECUTE') then
      raise exception 'FAIL#2 %: PUBLIC AINDA tem EXECUTE', fn; end if;
    if not has_function_privilege('authenticated', format('public.%I(uuid)', fn), 'EXECUTE') then
      raise exception 'FAIL#2 %: authenticated PERDEU EXECUTE', fn; end if;
  end loop;
  raise notice 'PASS#2 grants: anon/public sem EXECUTE; authenticated mantém';

  -- (3) GUARD — impersonação por jwt.claims (sem usuário real, sem INSERT)
  --     3a) auth.uid()=A + p_user_id=B  -> 42501 (forbidden)
  reset role;
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid_a::text, 'role','authenticated')::text, true);
  set local role authenticated;
  begin
    perform public.passport_summary(uid_b);
    reset role; raise exception 'FAIL#3a passport_summary(A, p_user_id:=B) NÃO recusou';
  exception
    when insufficient_privilege then null;         -- esperado (42501)
    when others then reset role;
      raise exception 'FAIL#3a esperado 42501, veio % (%)', SQLERRM, SQLSTATE;
  end;
  --     3b) auth.uid()=A + p_user_id=A  -> permitido (sem erro)
  begin
    perform public.passport_summary(uid_a);
  exception when others then
    reset role; raise exception 'FAIL#3b A+p_user_id=A deveria passar, veio % (%)', SQLERRM, SQLSTATE;
  end;
  --     3c) uid null (sem sub) + role authenticated -> not authenticated (P0001)
  reset role;
  perform set_config('request.jwt.claims', json_build_object('role','authenticated')::text, true);
  set local role authenticated;
  begin
    perform public.passport_summary(null);
    reset role; raise exception 'FAIL#3c sem auth.uid() NÃO recusou';
  exception
    when sqlstate 'P0001' then null;               -- 'not authenticated' esperado
    when others then reset role;
      raise exception 'FAIL#3c esperado P0001 not authenticated, veio % (%)', SQLERRM, SQLSTATE;
  end;
  reset role;
  raise notice 'PASS#3 guard: A+p_user_id=B -> 42501; A+p_user_id=A -> ok; uid null -> not authenticated';

  -- (4) PÚBLICO INTACTO — anon ainda executa ranking/my_rank/catálogo
  for r in
    select p.oid, p.proname
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname in ('passport_ranking','passport_my_rank','passport_seasons','passport_matches_for_year')
  loop
    if not has_function_privilege('anon', r.oid, 'EXECUTE') then
      raise exception 'FAIL#4 % perdeu acesso público (anon sem EXECUTE)', r.proname; end if;
  end loop;
  raise notice 'PASS#4 público intacto: ranking/my_rank/seasons/matches_for_year seguem anon-executáveis';

  raise notice '==== TODOS OS TESTES (sem usuário real) PASSARAM ====';
end
$$;

rollback;
