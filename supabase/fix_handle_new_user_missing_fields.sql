-- BUG REAL (afeta Goiás E Bragantino, mesma trigger canônica nos dois
-- projetos): `handle_new_user()` só copiava `full_name` do
-- `raw_user_meta_data` pro novo `profiles`, mesmo o cadastro
-- (`register_step_personal.dart`/`auth_remote_data_source.dart`) já
-- enviando cpf/birth_date/phone/marketing_opt_in no metadata do signup.
-- Resultado: CPF/data de nascimento/celular preenchidos no cadastro nunca
-- chegavam no `profiles` — ficavam sempre null até o usuário reentrar tudo
-- manualmente em "Dados Pessoais", uma etapa redundante que ninguém pedia.
--
-- Idempotente (create or replace function). Rodar no SQL editor de CADA
-- projeto Supabase (Goiás e Bragantino, cada um o seu) — é a mesma trigger
-- canônica nos dois, o bug é idêntico nos dois.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, full_name, cpf, birth_date, phone, marketing_opt_in)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'cpf',
    nullif(new.raw_user_meta_data->>'birth_date', '')::date,
    new.raw_user_meta_data->>'phone',
    coalesce((new.raw_user_meta_data->>'marketing_opt_in')::boolean, false)
  );
  return new;
end;
$function$;

-- BACKFILL opcional, uma vez só: contas já criadas antes deste fix também
-- perderam os dados — mas eles continuam intactos em `auth.users.
-- raw_user_meta_data` (a trigger só falhou em COPIAR, nunca em GRAVAR).
-- Preenche só o que hoje está null em `profiles`, nunca sobrescreve um dado
-- que o usuário já corrigiu manualmente em "Dados Pessoais" depois.
update public.profiles as p
set
  cpf = coalesce(p.cpf, u.raw_user_meta_data->>'cpf'),
  birth_date = coalesce(p.birth_date, nullif(u.raw_user_meta_data->>'birth_date', '')::date),
  phone = coalesce(p.phone, u.raw_user_meta_data->>'phone')
from auth.users as u
where p.id = u.id
  and (p.cpf is null or p.birth_date is null or p.phone is null);
