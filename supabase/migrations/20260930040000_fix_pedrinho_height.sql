-- ============================================================================
-- Corrige a altura do Pedrinho (squad_members, Goiás): estava 182cm,
-- usuário confirmou pessoalmente que está errado. TRÊS fontes
-- independentes concordam em 175cm: o site OFICIAL do Goiás
-- (goiasec.com.br/elenco/atleta/pedrinho117), a Wikipédia
-- (en.wikipedia.org/wiki/Pedro_Junqueira) e esmeraldino.com — só o
-- ogol.com.br (de onde o 182 provavelmente veio) diverge.
do $$
begin
  if (select height_cm from public.squad_members where id = 'pedrinho') != 182 then
    raise exception 'squad_members.pedrinho.height_cm não está em 182 — aborta pra não sobrescrever um valor que não é o documentado.';
  end if;
end $$;

update public.squad_members set height_cm = 175 where id = 'pedrinho';

do $$
begin
  if (select height_cm from public.squad_members where id = 'pedrinho') != 175 then
    raise exception 'Pós-condição falhou: pedrinho.height_cm não ficou 175.';
  end if;
end $$;
