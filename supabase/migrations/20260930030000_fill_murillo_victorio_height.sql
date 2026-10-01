-- ============================================================================
-- Preenche a altura do Murillo Victorio (squad_members), única lacuna
-- biográfica restante no elenco atual do Goiás após a revalidação de
-- 2026-09-30 (migration 20260930020000).
--
-- O usuário trouxe esmeraldino.com/jogador/murillo-victorio/ citando 1,90m,
-- nascimento 07/04/2005, pé destro — mas essa página diverge de DUAS fontes
-- independentes entre si (ogol.com.br/jogador/murillo-victorio/972457 e
-- besoccer.com/jogador/murillo-3431972), que concordam exatamente em
-- nascimento (10/10/2006) e pé (canhoto, já aplicado em 20260930020000) e
-- dão 183cm de altura. Divergir nos 3 campos ao mesmo tempo sugere ficha
-- trocada/errada no esmeraldino, não um erro de digitação isolado — por
-- isso a altura aplicada aqui é 183 (BeSoccer), não 190 (esmeraldino).
do $$
begin
  if (select height_cm from public.squad_members where id = 'murillo_victorio') is not null then
    raise exception 'murillo_victorio.height_cm já não está null — aborta pra não sobrescrever.';
  end if;
end $$;

update public.squad_members set height_cm = 183 where id = 'murillo_victorio';

do $$
begin
  if (select height_cm from public.squad_members where id = 'murillo_victorio') != 183 then
    raise exception 'Pós-condição falhou: murillo_victorio.height_cm não ficou 183.';
  end if;
end $$;
