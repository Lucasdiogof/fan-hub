-- ============================================================================
-- Preenche pé preferencial / altura do elenco atual do Goiás (squad_members)
-- que estavam null — pesquisado no ogol.com.br (2026-09-30), confirmado
-- contra o elenco oficial em goiasec.com.br/elenco/futebol-profissional
-- (31/31 jogadores batem exatamente, nenhum jogador faltando ou sobrando).
-- murillo_victorio continua sem altura: não publicada em nenhuma fonte
-- consultada, não é lacuna de pesquisa.
--
-- PRÉ: cada linha precisa estar com o campo exatamente null antes do update
-- (aborta se alguém já tiver preenchido por outro caminho).
do $$
declare
  v_bad text[] := array[]::text[];
begin
  if (select foot from public.squad_members where id = 'murillo_victorio') is not null then v_bad := array_append(v_bad, 'murillo_victorio.foot'); end if;
  if (select foot from public.squad_members where id = 'thiago_rodrigues') is not null then v_bad := array_append(v_bad, 'thiago_rodrigues.foot'); end if;
  if (select foot from public.squad_members where id = 'marcos_vinicius') is not null then v_bad := array_append(v_bad, 'marcos_vinicius.foot'); end if;
  if (select foot from public.squad_members where id = 'djalma') is not null then v_bad := array_append(v_bad, 'djalma.foot'); end if;
  if (select foot from public.squad_members where id = 'filipe_machado') is not null then v_bad := array_append(v_bad, 'filipe_machado.foot'); end if;
  if (select foot from public.squad_members where id = 'lucas_rodrigues') is not null then v_bad := array_append(v_bad, 'lucas_rodrigues.foot'); end if;
  if (select foot from public.squad_members where id = 'wellington_rato') is not null then v_bad := array_append(v_bad, 'wellington_rato.foot'); end if;
  if (select foot from public.squad_members where id = 'jean_carlos') is not null then v_bad := array_append(v_bad, 'jean_carlos.foot'); end if;
  if (select height_cm from public.squad_members where id = 'jean_carlos') is not null then v_bad := array_append(v_bad, 'jean_carlos.height_cm'); end if;
  if (select foot from public.squad_members where id = 'halerrandrio') is not null then v_bad := array_append(v_bad, 'halerrandrio.foot'); end if;
  if (select foot from public.squad_members where id = 'esli_garcia') is not null then v_bad := array_append(v_bad, 'esli_garcia.foot'); end if;
  if (select foot from public.squad_members where id = 'kadu_sousa') is not null then v_bad := array_append(v_bad, 'kadu_sousa.foot'); end if;

  if array_length(v_bad, 1) > 0 then
    raise exception 'Campos já preenchidos (não deveriam estar): %. Aborta pra não sobrescrever.', v_bad;
  end if;
end $$;

update public.squad_members set foot = 'Canhoto' where id = 'murillo_victorio';
update public.squad_members set foot = 'Destro' where id = 'thiago_rodrigues';
update public.squad_members set foot = 'Destro' where id = 'marcos_vinicius';
update public.squad_members set foot = 'Canhoto' where id = 'djalma';
update public.squad_members set foot = 'Destro' where id = 'filipe_machado';
update public.squad_members set foot = 'Destro' where id = 'lucas_rodrigues';
update public.squad_members set foot = 'Canhoto' where id = 'wellington_rato';
update public.squad_members set foot = 'Canhoto', height_cm = 173 where id = 'jean_carlos';
update public.squad_members set foot = 'Destro' where id = 'halerrandrio';
update public.squad_members set foot = 'Destro' where id = 'esli_garcia';
update public.squad_members set foot = 'Destro' where id = 'kadu_sousa';

-- PÓS: confirma que só restam murillo_victorio e kadu_sousa sem altura, e
-- ninguém mais sem pé preferencial.
do $$
declare
  v_no_foot int;
  v_no_height int;
begin
  select count(*) into v_no_foot from public.squad_members where foot is null;
  if v_no_foot > 0 then
    raise exception 'Ainda há % jogador(es) sem pé preferencial — esperado 0.', v_no_foot;
  end if;

  select count(*) into v_no_height from public.squad_members where height_cm is null;
  if v_no_height != 1 then
    raise exception 'Esperado exatamente 1 jogador sem altura (murillo_victorio), achou %.', v_no_height;
  end if;
end $$;
