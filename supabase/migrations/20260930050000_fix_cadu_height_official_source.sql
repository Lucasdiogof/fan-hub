-- ============================================================================
-- Corrige a altura do Cadu (squad_members, Goiás): estava 188cm. Usuário
-- pediu pra seguir a regra "na dúvida, usa a fonte do Goiás" — o site
-- OFICIAL (goiasec.com.br/elenco/atleta/cadu) lista 1,82m. Wikipédia diz
-- 1,79, esmeraldino diz 1,82 (bate com o oficial); só o ogol.com.br (de
-- onde o 188 provavelmente veio) diverge bastante dos outros três.
do $$
begin
  if (select height_cm from public.squad_members where id = 'cadu') != 188 then
    raise exception 'squad_members.cadu.height_cm não está em 188 — aborta pra não sobrescrever um valor que não é o documentado.';
  end if;
end $$;

update public.squad_members set height_cm = 182 where id = 'cadu';

do $$
begin
  if (select height_cm from public.squad_members where id = 'cadu') != 182 then
    raise exception 'Pós-condição falhou: cadu.height_cm não ficou 182.';
  end if;
end $$;
