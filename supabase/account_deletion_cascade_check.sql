-- ============================================================================
-- Exclusão de conta — garante que `profiles` e `user_addresses` (as duas
-- tabelas que não têm SQL de criação neste repo, criadas direto no
-- dashboard em algum momento) cascam quando `auth.users` é apagado. As
-- demais tabelas de progresso (quiz, escalação, jogador, votos, scores)
-- já têm `on delete cascade` desde que foram criadas. Rode no SQL Editor
-- do Supabase. Idempotente: só recria a FK se ela ainda não for CASCADE.
-- ============================================================================

do $$
declare
  v_conname text;
  v_delete_rule text;
begin
  select con.conname, rc.delete_rule
    into v_conname, v_delete_rule
  from pg_constraint con
  join information_schema.referential_constraints rc
    on rc.constraint_name = con.conname
  where con.conrelid = 'public.profiles'::regclass
    and con.contype = 'f'
    and con.confrelid = 'auth.users'::regclass
  limit 1;

  if v_conname is null then
    raise notice 'profiles: nenhuma FK pra auth.users encontrada — confira manualmente.';
  elsif v_delete_rule = 'CASCADE' then
    raise notice 'profiles: FK já é ON DELETE CASCADE, nada a fazer.';
  else
    execute format('alter table public.profiles drop constraint %I', v_conname);
    execute 'alter table public.profiles add constraint profiles_id_fkey foreign key (id) references auth.users(id) on delete cascade';
    raise notice 'profiles: FK recriada com ON DELETE CASCADE.';
  end if;
end $$;

do $$
declare
  v_conname text;
  v_delete_rule text;
begin
  select con.conname, rc.delete_rule
    into v_conname, v_delete_rule
  from pg_constraint con
  join information_schema.referential_constraints rc
    on rc.constraint_name = con.conname
  where con.conrelid = 'public.user_addresses'::regclass
    and con.contype = 'f'
    and con.confrelid = 'auth.users'::regclass
  limit 1;

  if v_conname is null then
    raise notice 'user_addresses: nenhuma FK pra auth.users encontrada — confira manualmente.';
  elsif v_delete_rule = 'CASCADE' then
    raise notice 'user_addresses: FK já é ON DELETE CASCADE, nada a fazer.';
  else
    execute format('alter table public.user_addresses drop constraint %I', v_conname);
    execute 'alter table public.user_addresses add constraint user_addresses_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade';
    raise notice 'user_addresses: FK recriada com ON DELETE CASCADE.';
  end if;
end $$;
