-- ============================================================================
-- Quem Vestiu o Manto (guess_players, Goiás) — fase 2 da auditoria, parte
-- segura: só PREENCHE campos que estavam null e promove a `verified` quem
-- teve TODOS os campos conferidos. Nenhum valor existente é trocado aqui
-- (as divergências ficaram para decisão do usuário).
--
-- Fonte: ogol.com.br, conferido em 2026-10-01 —
--   * elenco do Goiás por temporada (/equipe/goias/2244/plantel?epoca_id=…),
--     que dá a identidade (quem esteve no elenco em cada ano) e a camisa
--     por temporada (só existe de ~2008 em diante);
--   * perfil de cada jogador (/jogador/<slug>/<id>): nome completo, posição,
--     jogos por temporada e clubes de base.
-- Regras usadas:
--   * camisa: só quando o ogol registra UMA única camisa no Goiás;
--   * estreia: 1ª temporada com jogos registrados pelo Goiás (não só a
--     presença no elenco) — é a mesma definição que os valores atuais seguem;
--   * clube formador: só quando o ogol mostra categoria de base ([S17] etc.).
-- Dill fica sem camisa: o catálogo já documenta fontes divergentes (7 × 9).
-- ============================================================================

do $$
declare v text;
begin
  select string_agg(e.id, ', ') into v
  from (values
    ('arthur_caike', 'shirt'), ('bruno_henrique', 'shirt'), ('caique_sa', 'shirt'),
    ('madison', 'shirt'), ('evair', 'shirt'),
    ('dalton', 'debut'), ('eduardo_heuser', 'debut'), ('luiz_felipe_clemente_de_almeida', 'debut'),
    ('maranhao', 'academy'), ('reidner', 'academy'), ('brayann_brito_batista', 'academy'),
    ('marcelo_costa', 'academy')
  ) as e(id, field)
  left join public.guess_players g on g.id = e.id
  where g.id is null
     or (e.field = 'shirt' and g.shirt_number is not null)
     or (e.field = 'debut' and g.club_debut_year is not null)
     or (e.field = 'academy' and g.academy_club is not null);
  if v is not null then
    raise exception 'campos que deveriam estar null já têm valor: % — aborta.', v;
  end if;

  if (select count(*) from public.guess_players where id in (
        'arthur_caike','brayann_brito_batista','carlos_eduardo_de_sousa_leopoldino','douglas',
        'esli_samuel_garcia_cordero','gonzalo_freitas','halerrandrio_dos_santos_feitosa',
        'luiz_felipe_clemente_de_almeida','marcelo_costa','paulo_baier',
        'pedro_junqueira_de_oliveira','rodrigo','sander')
      and data_status in ('review', 'incomplete')) <> 13 then
    raise exception 'status de algum jogador a promover não é review/incomplete — aborta.';
  end if;
end $$;

-- camisa (única registrada no Goiás)
update public.guess_players set shirt_number = 45 where id = 'arthur_caike';   -- 2025
update public.guess_players set shirt_number = 7  where id = 'bruno_henrique'; -- 2015 (Bruno Henrique Pinto)
update public.guess_players set shirt_number = 70 where id = 'caique_sa';      -- 2019
update public.guess_players set shirt_number = 40 where id = 'madison';        -- 2019 e 2020
update public.guess_players set shirt_number = 9  where id = 'evair';          -- 2000

-- estreia (1ª temporada com jogos registrados)
update public.guess_players set club_debut_year = 1989 where id = 'dalton';
update public.guess_players set club_debut_year = 1986 where id = 'eduardo_heuser';
update public.guess_players set club_debut_year = 2026 where id = 'luiz_felipe_clemente_de_almeida';

-- clube formador (categoria de base registrada)
update public.guess_players set academy_club = 'Itaúna'            where id = 'maranhao';
update public.guess_players set academy_club = 'Goiás'             where id = 'reidner';
update public.guess_players set academy_club = 'Guarany de Sobral' where id = 'brayann_brito_batista';
update public.guess_players set academy_club = 'Juventude'         where id = 'marcelo_costa';

-- todos os campos conferidos no ogol (posição, camisa, base, estreia)
update public.guess_players set data_status = 'verified' where id in (
  'arthur_caike','brayann_brito_batista','carlos_eduardo_de_sousa_leopoldino','douglas',
  'esli_samuel_garcia_cordero','gonzalo_freitas','halerrandrio_dos_santos_feitosa',
  'luiz_felipe_clemente_de_almeida','marcelo_costa','paulo_baier',
  'pedro_junqueira_de_oliveira','rodrigo','sander');

do $$
begin
  if (select count(*) from public.guess_players where
        (id = 'arthur_caike' and shirt_number = 45)
     or (id = 'bruno_henrique' and shirt_number = 7)
     or (id = 'caique_sa' and shirt_number = 70)
     or (id = 'madison' and shirt_number = 40)
     or (id = 'evair' and shirt_number = 9)
     or (id = 'dalton' and club_debut_year = 1989)
     or (id = 'eduardo_heuser' and club_debut_year = 1986)
     or (id = 'luiz_felipe_clemente_de_almeida' and club_debut_year = 2026)
     or (id = 'maranhao' and academy_club = 'Itaúna')
     or (id = 'reidner' and academy_club = 'Goiás')
     or (id = 'brayann_brito_batista' and academy_club = 'Guarany de Sobral')
     or (id = 'marcelo_costa' and academy_club = 'Juventude')) <> 12 then
    raise exception 'Pós-condição falhou: preenchimentos.';
  end if;
  if (select count(*) from public.guess_players where data_status = 'verified') <> 66 + 13 then
    raise exception 'Pós-condição falhou: total de verified deveria ser 79.';
  end if;
end $$;
