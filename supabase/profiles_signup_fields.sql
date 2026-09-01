-- ============================================================================
-- Suporte ao novo cadastro em 3 passos — rode no SQL Editor do Supabase.
-- Idempotente (seguro rodar de novo). Não mexe na trigger `handle_new_user`
-- nem na RLS existente de `profiles` — ambas continuam como estão hoje
-- (decisão deliberada: o profile nasce incompleto no INSERT de auth.users,
-- e só é completado depois da confirmação do OTP, do lado do Flutter).
-- ============================================================================

-- 1) Novo campo — opt-in de marketing, nunca existiu antes.
alter table public.profiles
  add column if not exists marketing_opt_in boolean not null default false;

-- 2) Unicidade de CPF — autoridade final no Postgres, nunca só no Flutter
-- (uma consulta no cliente antes de gravar tem race condition; duas
-- requisições simultâneas com o mesmo CPF podem passar as duas). Parcial
-- (`where cpf is not null`) porque a coluna é nullable e vários profiles
-- antigos não têm CPF preenchido ainda.
--
-- Já confirmado (introspecção prévia) que não há CPF duplicado não nulo
-- hoje — se esse `create unique index` falhar, alguém inseriu um duplicado
-- entre a checagem e agora; rode
--   select cpf, count(*) from public.profiles where cpf is not null
--   group by cpf having count(*) > 1;
-- pra achar antes de tentar de novo.
create unique index if not exists profiles_cpf_unique_idx
  on public.profiles (cpf)
  where cpf is not null;

-- 3) RPC pública pra checar unicidade de CPF ANTES do usuário terminar o
-- cadastro (Passo 1, UX) — nunca a autoridade final (essa é o índice acima),
-- só evita o usuário preencher os 3 passos pra descobrir o conflito no
-- fim. `security definer` porque quem chama isso é ANÔNIMO (ainda não tem
-- conta) — a RLS de `profiles` bloquearia um select direto. Só devolve
-- true/false, nunca nenhum outro dado da linha.
create or replace function public.cpf_is_taken(p_cpf text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where cpf = p_cpf
  );
$$;

revoke all on function public.cpf_is_taken(text) from public;
grant execute on function public.cpf_is_taken(text) to anon, authenticated;
