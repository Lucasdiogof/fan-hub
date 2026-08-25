-- Seed/upsert do elenco profissional atual do Goiás Esporte Clube.
-- Dados biográficos (idade, nacionalidade, altura, pé): pesquisa web inicial.
-- Histórico de clubes (club_history): goias_current_squad_careers.json/csv,
-- fornecido pelo usuário como fonte de verdade (fotmob/ogol/365scores/site
-- oficial, atualizado em 2026-08-24). data_quality e notes preservados
-- exatamente como na fonte — 'partial'/'review' NÃO foram completados
-- automaticamente. Rodar manualmente no SQL editor do Supabase.

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('tadeu', 'Tadeu', 'Tadeu Antônio Ferreira', 23, 'Goleiro', 'Goleiros', '1992-02-04', 'Brasil', 184, 'Destro',
  '[{"period":"abr/2012–jan/2013","team":"Coritiba","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem identificada; totais não exibidos na tabela consultada."},
    {"period":"fev/2013–dez/2013","team":"Tupi","appearances":5,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2014–jul/2014","team":"Coritiba","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem identificada; totais não exibidos."},
    {"period":"jan/2015–jan/2016","team":"Maringá FC","appearances":10,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2016–jul/2016","team":"Ceará","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem identificada; totais não exibidos."},
    {"period":"jul/2016–abr/2018","team":"Ferroviária","appearances":47,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2018–dez/2018","team":"Osasco Sporting","appearances":37,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2019–mar/2019","team":"Ferroviária","appearances":13,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2019–dez/2019","team":"Goiás","appearances":38,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":null},
    {"period":"jan/2020–atual","team":"Goiás","appearances":360,"goals":13,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 0)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('ezequiel', 'Ezequiel', 'Ezequiel Alves de Oliveira Vieira', 12, 'Goleiro', 'Goleiros', '2003-06-13', 'Brasil', 185, 'Canhoto',
  '[{"period":"fev/2022–dez/2022","team":"Cruzeiro","appearances":1,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2023–atual","team":"Goiás","appearances":null,"goals":null,"loan":false,"is_goias":true,"data_quality":"partial","notes":"Carreira no Goiás confirmada; agregador não exibiu total consolidado de jogos/gols nesta passagem."}]'::jsonb, 1)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('murillo_victorio', 'Murillo Victorio', 'Murillo Carvalho Victorio', 32, 'Goleiro', 'Goleiros', '2006-10-10', 'Brasil', null, null,
  '[{"period":"jun/2025–atual","team":"Goiás","appearances":null,"goals":null,"loan":false,"is_goias":true,"data_quality":"partial","notes":"Único clube profissional encontrado; total consolidado não exibido na fonte."}]'::jsonb, 2)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('thiago_rodrigues', 'Thiago Rodrigues', 'Thiago Rodrigues de Oliveira Nogueira', 1, 'Goleiro', 'Goleiros', '1988-10-20', 'Brasil', 189, null,
  '[{"period":"mai/2008–dez/2013","team":"Paraná Clube","appearances":33,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2014–jan/2015","team":"Rio Branco SC","appearances":14,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2015–jan/2016","team":"Caxias","appearances":16,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2016–mai/2016","team":"Guarani de Palhoça","appearances":16,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2016–dez/2017","team":"Figueirense","appearances":43,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2018","team":"Itumbiara EC","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem identificada; totais não exibidos."},
    {"period":"jan/2018–fev/2020","team":"Paraná Clube","appearances":62,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2020–dez/2021","team":"CSA","appearances":59,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–mar/2023","team":"Vasco da Gama","appearances":50,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2023–dez/2023","team":"Vitória","appearances":2,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2024–atual","team":"Goiás","appearances":10,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 3)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('luisao', 'Luisão', 'Luis Fellipe Campos Doria', 25, 'Zagueiro', 'Zagueiros', '2003-09-09', 'Brasil', 192, 'Destro',
  '[{"period":"jan/2023–jan/2025","team":"Novorizontino","appearances":49,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–dez/2025","team":"Santos","appearances":9,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–dez/2026","team":"Goiás","appearances":26,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 4)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('lucas_ribeiro', 'Lucas Ribeiro', 'Lucas Ribeiro dos Santos', 14, 'Zagueiro', 'Zagueiros', '1999-01-19', 'Brasil', 190, 'Destro',
  '[{"period":"jul/2018–dez/2018","team":"Vitória","appearances":16,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2019–ago/2020","team":"Hoffenheim","appearances":3,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2020–dez/2021","team":"Internacional","appearances":33,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–abr/2024","team":"Ceará","appearances":32,"goals":1,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2024–atual","team":"Goiás","appearances":104,"goals":3,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 5)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('luiz_felipe', 'Luiz Felipe', 'Luiz Felipe do Nascimento dos Santos', 3, 'Zagueiro', 'Zagueiros', '1993-09-09', 'Brasil', 189, 'Destro',
  '[{"period":"jan/2012–jan/2014","team":"Caxias","appearances":19,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2014–jan/2015","team":"Duque de Caxias","appearances":6,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2015–fev/2016","team":"Paraná Clube","appearances":43,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2016–jul/2023","team":"Santos","appearances":169,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2023–dez/2024","team":"Atlético-GO","appearances":35,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–nov/2025","team":"Goiás","appearances":19,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null},
    {"period":"jan/2026–atual","team":"Goiás","appearances":26,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 6)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('ramon_menezes', 'Ramon Menezes', 'Ramon Menezes Roma', 4, 'Zagueiro', 'Zagueiros', '1995-05-03', 'Brasil', 186, 'Destro',
  '[{"period":"fev/2013–fev/2015","team":"Bahia de Feira","appearances":17,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2015–jan/2017","team":"Vitória","appearances":90,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2017–mai/2017","team":"Maccabi Tel Aviv","appearances":3,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jun/2017–dez/2019","team":"Vitória","appearances":115,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2020–dez/2021","team":"Cruzeiro","appearances":73,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–jul/2023","team":"Atlético-GO","appearances":52,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2023–dez/2023","team":"CRB","appearances":15,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2024–jul/2025","team":"Ceará","appearances":36,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2025–mar/2026","team":"Sport Recife","appearances":33,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2026–dez/2026","team":"Goiás","appearances":13,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":"Total é snapshot da tabela de carreira; pode variar conforme atualização da fonte."}]'::jsonb, 7)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('murilo_camara', 'Murilo Câmara', 'Murilo Camara Saquetti Chimelo Pereira', 29, 'Zagueiro', 'Zagueiros', '2006-11-04', 'Brasil', 193, 'Canhoto',
  '[{"period":"jun/2024–dez/2024","team":"Rio Branco EC","appearances":4,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2025–dez/2025","team":"Goiás","appearances":2,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null},
    {"period":"mar/2026–atual","team":"Goiás","appearances":1,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 8)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('rodrigo_soares', 'Rodrigo Soares', 'Rodrigo Alves Soares', 2, 'Lateral-direito', 'Laterais-direitos', '1992-12-26', 'Brasil', 176, 'Destro',
  '[{"period":"jan/2012–dez/2012","team":"União São João","appearances":14,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2013–dez/2013","team":"Santo André","appearances":1,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2013","team":"Atlético Sorocaba","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem identificada; totais não exibidos."},
    {"period":"jan/2014–jun/2015","team":"Grêmio Anápolis","appearances":14,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2015–jun/2016","team":"FC Porto","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem no elenco principal identificada; totais não exibidos."},
    {"period":"jul/2015–fev/2017","team":"FC Porto B","appearances":25,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2017–jun/2017","team":"Chaves","appearances":8,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2017–jun/2019","team":"Aves","appearances":73,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2019–jan/2022","team":"PAOK","appearances":64,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–nov/2022","team":"Juventude","appearances":48,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2023–nov/2023","team":"Atlético-GO","appearances":38,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2024–nov/2025","team":"Novorizontino","appearances":82,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–atual","team":"Goiás","appearances":37,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 9)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('marcos_vinicius', 'Marcos Vinicius', 'Marcos Vinicius da Silva Santos', 63, 'Lateral-direito', 'Laterais-direitos', '1997-03-25', 'Brasil', 178, null,
  '[{"period":"jan/2017–mai/2017","team":"CA Tubarão","appearances":12,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2017–set/2017","team":"Brusque","appearances":6,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"set/2017–abr/2018","team":"CA Tubarão","appearances":15,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2018–mar/2019","team":"Chapecoense","appearances":7,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2019–dez/2019","team":"Criciúma","appearances":11,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2020–jul/2020","team":"Chapecoense","appearances":4,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2020–jun/2021","team":"UD Vilafranquense","appearances":25,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2021–abr/2022","team":"Maringá","appearances":17,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2022–out/2022","team":"ABC","appearances":22,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"nov/2022–abr/2023","team":"Maringá","appearances":16,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2023–jul/2023","team":"Coritiba","appearances":5,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2023–abr/2024","team":"Maringá","appearances":22,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2024–nov/2024","team":"Avaí","appearances":35,"goals":1,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–dez/2025","team":"Avaí","appearances":47,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–ago/2026","team":"Chapecoense","appearances":25,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2026–atual","team":"Goiás","appearances":4,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 10)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('nicolas', 'Nicolas', 'Nicolas Vichiatto da Silva', 6, 'Lateral-esquerdo', 'Laterais-esquerdos', '1997-02-24', 'Brasil', 181, 'Canhoto',
  '[{"period":"mar/2016–ago/2018","team":"Athletico Paranaense","appearances":41,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2018–dez/2018","team":"Ponte Preta","appearances":7,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2019–fev/2019","team":"Athletico Paranaense","appearances":6,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2019–mar/2021","team":"Atlético-GO","appearances":92,"goals":4,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2021–dez/2021","team":"Athletico Paranaense","appearances":34,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–dez/2022","team":"Grêmio","appearances":36,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2023–dez/2024","team":"América-MG","appearances":52,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–dez/2025","team":"Ceará","appearances":24,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–atual","team":"Goiás","appearances":38,"goals":2,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 11)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('danilo', 'Danilo', 'Danilo Cunha da Silva', 66, 'Lateral-esquerdo', 'Laterais-esquerdos', '2007-05-12', 'Brasil', 176, 'Canhoto',
  '[{"period":"jan/2025–atual","team":"Goiás","appearances":8,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 12)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('djalma', 'Djalma', 'Djalma Antônio da Silva Filho', 54, 'Lateral-esquerdo', 'Laterais-esquerdos', '1994-09-19', 'Brasil', 180, null,
  '[{"period":"jun/2012–ago/2017","team":"Atlético Pernambucano","appearances":44,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2017–out/2017","team":"Nacional AC (Patos)","appearances":null,"goals":null,"loan":true,"is_goias":false,"data_quality":"partial","notes":"Empréstimo identificado; totais não exibidos."},
    {"period":"out/2017–jan/2018","team":"Decisão","appearances":null,"goals":null,"loan":true,"is_goias":false,"data_quality":"partial","notes":"Empréstimo identificado; totais não exibidos."},
    {"period":"jan/2018–abr/2018","team":"Nacional AC (Patos)","appearances":null,"goals":4,"loan":true,"is_goias":false,"data_quality":"review","notes":"A fonte retornou 0 jogos/4 gols, combinação impossível; jogos deixados como null para revisão."},
    {"period":"abr/2018–ago/2018","team":"Treze","appearances":13,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2019–abr/2019","team":"URT","appearances":13,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2019–out/2019","team":"Treze","appearances":17,"goals":1,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2019–jan/2021","team":"Confiança","appearances":48,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2021–dez/2021","team":"Operário-PR","appearances":42,"goals":4,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–ago/2022","team":"Bahia","appearances":21,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2022–mai/2024","team":"AEL Limassol","appearances":75,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jun/2024–jun/2025","team":"Göztepe","appearances":25,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–atual","team":"Goiás","appearances":19,"goals":2,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 13)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('lourenco', 'Lourenço', 'João Paulo Ferreira Lourenço', 97, 'Volante', 'Volantes', '1997-09-07', 'Brasil', 169, 'Destro',
  '[{"period":"mar/2017–set/2020","team":"Avaí","appearances":97,"goals":4,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"set/2020–fev/2021","team":"Santa Cruz","appearances":17,"goals":4,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2021–abr/2022","team":"Avaí","appearances":67,"goals":7,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2022–dez/2022","team":"CSA","appearances":32,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2023–dez/2023","team":"Vila Nova","appearances":51,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2023–dez/2025","team":"Ceará","appearances":98,"goals":9,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–atual","team":"Goiás","appearances":35,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 14)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('filipe_machado', 'Filipe Machado', 'Luiz Filipe da Rosa Machado', 5, 'Volante', 'Volantes', '1996-01-20', 'Brasil', 175, null,
  '[{"period":"jul/2016–fev/2018","team":"Grêmio","appearances":7,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2018–nov/2018","team":"Boa Esporte","appearances":22,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2019–nov/2019","team":"São José-RS","appearances":17,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2020–jan/2021","team":"Cruzeiro","appearances":37,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2021–jul/2024","team":"Cruzeiro","appearances":94,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2024–jan/2025","team":"Vitória","appearances":18,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–nov/2025","team":"Coritiba","appearances":41,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–nov/2026","team":"Goiás","appearances":32,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 15)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('baldoria', 'Baldória', 'Guilherme Baldória de Camargo', 55, 'Volante', 'Volantes', '2005-04-21', 'Brasil', 181, 'Destro',
  '[{"period":"fev/2025–atual","team":"Goiás","appearances":31,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 16)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('juninho', 'Juninho', 'Adilson dos Anjos Oliveira', 8, 'Volante', 'Volantes', '1987-10-23', 'Brasil', 173, 'Destro',
  '[{"period":"out/2011–mai/2012","team":"Rio Verde","appearances":17,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jun/2012–mai/2013","team":"Mogi Mirim","appearances":16,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2013–abr/2014","team":"Athletico Paranaense","appearances":38,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2014–jan/2016","team":"Ponte Preta","appearances":73,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2016–mai/2016","team":"Ferroviária","appearances":18,"goals":2,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2016–nov/2024","team":"América-MG","appearances":438,"goals":37,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–atual","team":"Goiás","appearances":83,"goals":3,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 17)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('lucas_rodrigues', 'Lucas Rodrigues', 'Lucas Rodrigues Moreira Costa', 35, 'Volante', 'Volantes', '2007-10-29', 'Brasil', 180, null,
  '[{"period":"fev/2025–atual","team":"Goiás","appearances":26,"goals":4,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 18)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('gege', 'Gegê', 'Geirton Marques Aires', 28, 'Meia-atacante', 'Meios-campistas', '1994-01-28', 'Brasil', 175, 'Canhoto',
  '[{"period":"abr/2013–jan/2017","team":"Botafogo","appearances":77,"goals":6,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2017–nov/2017","team":"ABC","appearances":51,"goals":10,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2018–jun/2018","team":"Adana Demirspor","appearances":13,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2019–dez/2019","team":"Avaí","appearances":19,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2020–dez/2020","team":"Brasil de Pelotas","appearances":21,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2021–mai/2021","team":"Santo André","appearances":11,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2021–dez/2021","team":"Londrina","appearances":18,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–abr/2022","team":"Ferroviária","appearances":12,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2022–nov/2022","team":"Londrina","appearances":30,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2022–dez/2023","team":"Vitória","appearances":43,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2024–dez/2025","team":"CRB","appearances":106,"goals":19,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–dez/2026","team":"Goiás","appearances":28,"goals":3,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 19)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('lucas_lima', 'Lucas Lima', 'Lucas Rafael Araújo Lima', 10, 'Meia-atacante', 'Meios-campistas', '1990-07-09', 'Brasil', 176, 'Canhoto',
  '[{"period":"jan/2011–jul/2012","team":"Inter de Limeira","appearances":38,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2012–mar/2013","team":"Internacional","appearances":16,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2013–fev/2014","team":"Sport Recife","appearances":53,"goals":9,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2014–dez/2017","team":"Santos","appearances":201,"goals":19,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2018–ago/2021","team":"Palmeiras","appearances":165,"goals":12,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2021–dez/2022","team":"Fortaleza","appearances":68,"goals":1,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2023–dez/2023","team":"Santos","appearances":50,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2024–dez/2024","team":"Sport Recife","appearances":53,"goals":3,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–jan/2026","team":"Sport Recife","appearances":48,"goals":4,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2026–atual","team":"Goiás","appearances":32,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 20)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('brayann', 'Brayann', 'Brayann Brito Batista', 88, 'Meia-atacante', 'Meios-campistas', '1997-10-25', 'Brasil', 176, 'Canhoto',
  '[{"period":"ago/2021–dez/2021","team":"Guarany de Sobral","appearances":9,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2022","team":"Guarany de Sobral","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Biografia oficial do Goiás também lista o Guarany em 2022; totais granulares não encontrados."},
    {"period":"dez/2021–dez/2022","team":"Maracanã","appearances":5,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2023–mar/2023","team":"Caucaia","appearances":10,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2023–abr/2023","team":"Afogados da Ingazeira","appearances":2,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2023–nov/2023","team":"Caucaia","appearances":11,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2023–jun/2024","team":"Altos","appearances":19,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jun/2024–ago/2025","team":"CSA","appearances":44,"goals":6,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"set/2025–atual","team":"Goiás","appearances":26,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 21)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('wellington_rato', 'Wellington Rato', 'Wellington Soares da Silva', 27, 'Ponta-direita', 'Meios-campistas', '1992-06-28', 'Brasil', 172, null,
  '[{"period":"jan/2013–jun/2014","team":"Audax Rio","appearances":22,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2014–fev/2015","team":"Guaratinguetá","appearances":5,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2015–nov/2016","team":"Red Bull Brasil","appearances":22,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2017–jun/2017","team":"Caldense","appearances":15,"goals":4,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jun/2017–out/2018","team":"Sampaio Corrêa","appearances":27,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2018–jun/2019","team":"Joinville","appearances":13,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2019–set/2020","team":"Ferroviário","appearances":22,"goals":7,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"out/2020–mar/2021","team":"Atlético-GO","appearances":30,"goals":6,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2021–dez/2021","team":"V-Varen Nagasaki","appearances":23,"goals":7,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–dez/2022","team":"Atlético-GO","appearances":70,"goals":15,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2022–jan/2025","team":"São Paulo","appearances":105,"goals":6,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–jul/2025","team":"Vitória","appearances":24,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2025–dez/2026","team":"Goiás","appearances":22,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 22)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('pedrinho', 'Pedrinho', 'Pedro Junqueira de Oliveira', 17, 'Ponta-direita', 'Atacantes', '2004-03-23', 'Brasil', 182, 'Destro',
  '[{"period":"mai/2022–atual","team":"Goiás","appearances":96,"goals":6,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 23)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('anselmo_ramon', 'Anselmo Ramon', 'Anselmo Ramon Alves Herculano', 9, 'Centroavante', 'Atacantes', '1988-06-23', 'Brasil', 182, 'Destro',
  '[{"period":"fev/2009–mai/2009","team":"Cabofriense","appearances":11,"goals":6,"loan":true,"is_goias":false,"data_quality":"verified","notes":"Empréstimo cruzado com histórico de transferências."},
    {"period":"jun/2009–dez/2009","team":"Kashiwa Reysol","appearances":5,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":"Empréstimo cruzado com histórico de transferências."},
    {"period":"jan/2010–mai/2010","team":"Rio Branco-ES","appearances":13,"goals":5,"loan":true,"is_goias":false,"data_quality":"verified","notes":"Empréstimo cruzado com histórico de transferências."},
    {"period":"mai/2010–dez/2010","team":"Avaí","appearances":4,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":"Empréstimo cruzado com histórico de transferências."},
    {"period":"ago/2010–dez/2010","team":"CFR Cluj","appearances":3,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":"Empréstimo cruzado com histórico de transferências."},
    {"period":"jan/2011–mai/2011","team":"Osasco Sporting","appearances":17,"goals":10,"loan":true,"is_goias":false,"data_quality":"verified","notes":"Empréstimo cruzado com histórico de transferências."},
    {"period":"mai/2011–jan/2014","team":"Cruzeiro","appearances":83,"goals":25,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2014–fev/2018","team":"Zhejiang Professional","appearances":67,"goals":35,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2018–mai/2019","team":"Guarani","appearances":13,"goals":2,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mai/2019–dez/2019","team":"Vitória","appearances":32,"goals":7,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2020–dez/2021","team":"Chapecoense","appearances":81,"goals":21,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–abr/2025","team":"CRB","appearances":177,"goals":64,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"abr/2025–atual","team":"Goiás","appearances":76,"goals":24,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 24)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('cadu', 'Cadu', 'Carlos Eduardo Amaral Pereira de Castro', 18, 'Centroavante', 'Atacantes', '2004-05-24', 'Brasil', 188, 'Destro',
  '[{"period":"abr/2022–dez/2022","team":"Atlético-MG","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem no profissional identificada; totais não exibidos."},
    {"period":"fev/2023–fev/2026","team":"Atlético-MG","appearances":38,"goals":4,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2026–dez/2026","team":"Goiás","appearances":25,"goals":4,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 25)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('felipe_clemente', 'Felipe Clemente', 'Luiz Felipe Clemente de Almeida', 11, 'Centroavante', 'Atacantes', '1999-06-17', 'Brasil', 181, 'Destro',
  '[{"period":"2021","team":"Uberaba","appearances":12,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2022","team":"Capital-DF","appearances":15,"goals":5,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2022","team":"Uberaba","appearances":8,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2022","team":"Ceilândia","appearances":4,"goals":3,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2022","team":"Anapolina","appearances":5,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2022","team":"Araxá","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Clube consta no histórico; jogos/gols não publicados na tabela consultada."},
    {"period":"2023","team":"Ceilândia","appearances":26,"goals":10,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2023","team":"Ceilandense","appearances":8,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2024","team":"Ceilândia","appearances":15,"goals":7,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2024","team":"Manauara","appearances":12,"goals":4,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2025","team":"Ceilândia","appearances":13,"goals":7,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2025","team":"Confiança","appearances":7,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"2025","team":"Pouso Alegre","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Clube consta no histórico; totais não publicados."},
    {"period":"2025","team":"Brasília","appearances":7,"goals":10,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2025–dez/2025","team":"Kiryat Yam SC","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"review","notes":"365Scores lista a passagem; outro histórico consultado traz clubes brasileiros no mesmo ano. Revisar cronologia antes de produção se a ordem exata for crítica."},
    {"period":"jan/2026–ago/2026","team":"Gama","appearances":32,"goals":21,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"ago/2026–dez/2026","team":"Goiás","appearances":0,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":"Chegou por empréstimo em 21/08/2026; snapshot antes de estreia oficial pelo Goiás."}]'::jsonb, 26)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('jean_carlos', 'Jean Carlos', 'Jean Carlos Alves Ferreira', 21, 'Meia-atacante', 'Atacantes', '2005-05-08', 'Brasil', null, null,
  '[{"period":"ago/2024–dez/2024","team":"Atlético-GO","appearances":3,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"fev/2025–atual","team":"Goiás","appearances":47,"goals":4,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 27)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('halerrandrio', 'Halerrandrio', 'Halerrandrio dos Santos Feitosa', 77, 'Ponta-direita', 'Atacantes', '2006-07-08', 'Brasil', 175, null,
  '[{"period":"abr/2023–atual","team":"Goiás","appearances":12,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 28)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('esli_garcia', 'Esli Garcia', 'Esli Samuel García Cordero', 15, 'Ponta-esquerda', 'Atacantes', '2000-07-14', 'Venezuela', 165, null,
  '[{"period":"ago/2016–mai/2018","team":"Portuguesa FC (Venezuela)","appearances":41,"goals":9,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jul/2018–dez/2019","team":"Deportivo Táchira","appearances":55,"goals":12,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2020–fev/2021","team":"Santiago Wanderers","appearances":11,"goals":0,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"mar/2021–dez/2021","team":"Deportivo Táchira","appearances":15,"goals":1,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2022–dez/2022","team":"Universidad Central","appearances":27,"goals":5,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2023–dez/2023","team":"Deportivo Táchira","appearances":31,"goals":5,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2024–nov/2024","team":"Paysandu","appearances":38,"goals":11,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"jan/2025–atual","team":"Goiás","appearances":44,"goals":5,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 29)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

insert into public.squad_members (id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, club_history, sort_order)
values
('kadu_sousa', 'Kadu Sousa', 'Carlos Eduardo de Sousa Leopoldino', 40, 'Ponta-esquerda', 'Atacantes', '2002-03-03', 'Brasil', 178, null,
  '[{"period":"2022","team":"São Joseense","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"review","notes":"FotMob exibe uma faixa de datas incoerente para esta passagem; clube confirmado, período exato deve ser revisado."},
    {"period":"mar/2023–mai/2023","team":"Široki Brijeg","appearances":4,"goals":0,"loan":false,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"nov/2024–jan/2025","team":"AC Paranavaí","appearances":null,"goals":null,"loan":false,"is_goias":false,"data_quality":"partial","notes":"Passagem identificada; totais não exibidos."},
    {"period":"jan/2025–set/2025","team":"Anápolis","appearances":28,"goals":4,"loan":true,"is_goias":false,"data_quality":"verified","notes":null},
    {"period":"dez/2025–dez/2026","team":"Goiás","appearances":16,"goals":6,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}]'::jsonb, 30)
on conflict (id) do update set
  name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number,
  position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality,
  height_cm = excluded.height_cm, foot = excluded.foot, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();
