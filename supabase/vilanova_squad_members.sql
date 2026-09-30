-- Elenco profissional atual do Vila Nova (squad_members).
-- GERADO por `node tooling/vilanova_content/generate_seed_sql.mjs` a partir de
-- docs/vila_nova_data/data/squad_current.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do
-- Bragantino (a trava abaixo para se não for). Idempotente.
--
-- 31 atletas. photo_url = foto individual real do site oficial (AVIF,
-- hotlink direto, 2026-09-30 — ver editorial_note do pacote). club_history vazio
-- (REVIEW no pacote) — ver cabeçalho do gerador.

do $$
begin
  if not exists (select 1 from public.clubs where id = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e' and slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.squad_members (id, club_id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, photo_url, instagram_url, club_history, sort_order, active) values
  ('vn_helton_leite', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Helton Leite', 'Helton Brant Aleixo Leite', 1, 'Goleiro', 'Goleiros', '1990-11-02', 'Brasil', 196, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/helton-leite-453.avif', 'https://www.instagram.com/heltonleite77/', '[]'::jsonb, 0, true),
  ('vn_dalberson', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Dalberson', 'Dalberson Ferreira do Amaral', 29, 'Goleiro', 'Goleiros', '1997-01-13', 'Brasil', 191, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/dalberson-810.avif', null, '[]'::jsonb, 1, true),
  ('vn_gabriel_atila', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Gabriel Átila', 'Gabriel Átila Cardoso da Silva', 30, 'Goleiro', 'Goleiros', '2003-01-22', 'Brasil', 193, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/gabriel-atila-692.avif', null, '[]'::jsonb, 2, true),
  ('vn_tiago_pagnussat', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Tiago Pagnussat', 'Tiago Pagnussat', 3, 'Zagueiro', 'Zagueiros', '1990-06-17', 'Brasil', 191, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/tiago-pagnussat-614.avif', null, '[]'::jsonb, 3, true),
  ('vn_douglas_mendes', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Douglas Mendes', 'Douglas Mendes Moreira', 4, 'Zagueiro', 'Zagueiros', '2004-06-13', 'Brasil', 188, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/douglas-mendes-285.avif', null, '[]'::jsonb, 4, true),
  ('vn_anderson_jesus', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Anderson Jesus', 'Anderson de Jesus Santos', 14, 'Zagueiro', 'Zagueiros', '1995-03-02', 'Brasil', 186, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/anderson-jesus-051.avif', null, '[]'::jsonb, 5, true),
  ('vn_breno_bora', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Breno Bora', 'Breno Augusto de Azevedo Bora', 23, 'Zagueiro', 'Zagueiros', '2002-05-22', 'Brasil', 186, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/breno-bora-580.avif', null, '[]'::jsonb, 6, true),
  ('vn_jonathan_costa', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Jonathan Costa', 'Jonathan Aparecido de Oliveira da Costa', null, 'Zagueiro', 'Zagueiros', '1995-04-19', 'Brasil', 186, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/jonathan-costa-809.avif', null, '[]'::jsonb, 7, true),
  ('vn_samuel', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Samuel', 'Samuel Lucas de Oliveira Souza', null, 'Zagueiro', 'Zagueiros', '2007-08-13', 'Brasil', 189, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/samuel-648.avif', null, '[]'::jsonb, 8, true),
  ('vn_hayner', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Hayner', 'Hayner William Monjardim Cordeiro', 22, 'Lateral-direito', 'Laterais-direitos', '1995-10-02', 'Brasil', 178, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/hayner-143.avif', 'https://www.instagram.com/hayner_27/', '[]'::jsonb, 9, true),
  ('vn_higor_luiz', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Higor Luiz', 'Higor Luiz de Souza', 6, 'Lateral-esquerdo', 'Laterais-esquerdos', '2004-12-27', 'Brasil', 178, 'Canhoto', 'https://www.vilanovafc.com.br/imgs/270/370/images/higor-luiz-583.avif', null, '[]'::jsonb, 10, true),
  ('vn_willian_formiga', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Willian Formiga', 'Willian Prado Camargo', 13, 'Lateral-esquerdo', 'Laterais-esquerdos', '1995-01-22', 'Brasil', 185, 'Canhoto', 'https://www.vilanovafc.com.br/imgs/270/370/images/willian-formiga-896.avif', null, '[]'::jsonb, 11, true),
  ('vn_igor_carius', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Igor Cariús', 'Igor Aquino da Silva', 16, 'Lateral-esquerdo', 'Laterais-esquerdos', '1993-05-01', 'Brasil', 182, 'Canhoto', 'https://www.vilanovafc.com.br/imgs/270/370/images/igor-carius-029.avif', null, '[]'::jsonb, 12, true),
  ('vn_joao_vieira', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'João Vieira', 'João Pedro Vieira', 5, 'Volante', 'Volantes', '1997-11-08', 'Brasil', 173, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/joao-vieira-816.avif', null, '[]'::jsonb, 13, true),
  ('vn_willian_maranhao', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Willian Maranhão', 'Willian Marlon Ferreira Moraes', 8, 'Volante', 'Volantes', '1995-12-14', 'Brasil', 179, 'Canhoto', 'https://www.vilanovafc.com.br/imgs/270/370/images/willian-maranhao-793.avif', null, '[]'::jsonb, 14, true),
  ('vn_dudu', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Dudu', 'Eduardo dos Santos', 15, 'Volante', 'Volantes', '2001-12-03', 'Brasil', 184, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/dudu-248.avif', null, '[]'::jsonb, 15, true),
  ('vn_enzo_bizzotto', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Enzo', 'Enzo Bizzotto Costa', 18, 'Volante', 'Volantes', '2003-04-30', 'Brasil', 185, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/enzo-806.avif', null, '[]'::jsonb, 16, true),
  ('vn_nathan_camargo', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Nathan Camargo', 'Nathan Camargo dos Santos', 20, 'Volante', 'Volantes', '2005-07-25', 'Brasil', 177, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/nathan-camargo-402.avif', null, '[]'::jsonb, 17, true),
  ('vn_higor_meritao', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Higor Meritão', 'Higor Matheus Meritão', null, 'Volante', 'Volantes', '1994-06-23', 'Brasil', null, 'Canhoto', 'https://www.vilanovafc.com.br/imgs/270/370/images/higor-meritao-627.avif', 'https://www.instagram.com/higormeritao/', '[]'::jsonb, 18, true),
  ('vn_marquinhos_gabriel', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Marquinhos Gabriel', 'Marcos Gabriel do Nascimento', 10, 'Meia', 'Meios-campistas', '1990-07-21', 'Brasil', 174, 'Canhoto', 'https://www.vilanovafc.com.br/imgs/270/370/images/marquinhos-gabriel-089.avif', 'https://www.instagram.com/marquinhosgabriel20/', '[]'::jsonb, 19, true),
  ('vn_dodo', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Dodô', 'Raphael Guimarães de Paula', 31, 'Meia', 'Meios-campistas', '1994-09-05', 'Brasil', 171, 'Destro', 'https://www.vilanovafc.com.br/imgs/270/370/images/dodo-759.avif', null, '[]'::jsonb, 20, true),
  ('vn_andre_luis', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'André Luís', 'André Luís da Costa Alfredo', 7, 'Atacante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/andre-luis-941.avif', null, '[]'::jsonb, 21, true),
  ('vn_gustavo_puskas', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Gustavo Puskas', 'Gustavo Puskas Pinheiro Lemos', 9, 'Centroavante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/gustavo-puskas-783.avif', null, '[]'::jsonb, 22, true),
  ('vn_ryan', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Ryan', 'Ryan Aparecido Lima Cassiano', 11, 'Ponta', 'Atacantes', '2001-06-18', 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/ryan-385.avif', null, '[]'::jsonb, 23, true),
  ('vn_everton_galdino', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Éverton Galdino', 'Everton Galdino Moreira', 17, 'Atacante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/everton-galdino-691.avif', 'https://www.instagram.com/evertongaldinoo/', '[]'::jsonb, 24, true),
  ('vn_dellatorre', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Dellatorre', 'Guilherme Augusto Alves Dellatorre', 49, 'Centroavante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/dellatorre-534.avif', null, '[]'::jsonb, 25, true),
  ('vn_emerson_urso', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Emerson Urso', 'Emerson Lima Freitas', 70, 'Ponta', 'Atacantes', '2001-05-13', 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/emerson-urso-896.avif', null, '[]'::jsonb, 26, true),
  ('vn_janderson', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Janderson', 'Janderson Santos de Souza', 99, 'Atacante', 'Atacantes', '1999-02-26', 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/janderson-468.avif', null, '[]'::jsonb, 27, true),
  ('vn_bruno_xavier', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Bruno Xavier', 'Bruno César Xavier Sislo', null, 'Atacante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/bruno-xavier-973.avif', null, '[]'::jsonb, 28, true),
  ('vn_lincoln', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Lincoln', 'Lincoln Corrêa dos Santos', null, 'Centroavante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/lincoln-317.avif', 'https://www.instagram.com/lincoln9/', '[]'::jsonb, 29, true),
  ('vn_rafa_silva', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Rafa Silva', 'Rafael da Silva', null, 'Centroavante', 'Atacantes', null, 'Brasil', null, null, 'https://www.vilanovafc.com.br/imgs/270/370/images/rafa-silva-051.avif', null, '[]'::jsonb, 30, true)
on conflict (id) do update set club_id = excluded.club_id, name = excluded.name, full_name = excluded.full_name, shirt_number = excluded.shirt_number, position = excluded.position, position_group = excluded.position_group, birth_date = excluded.birth_date, nationality = excluded.nationality, height_cm = excluded.height_cm, foot = excluded.foot, photo_url = excluded.photo_url, instagram_url = excluded.instagram_url, club_history = excluded.club_history, sort_order = excluded.sort_order, active = excluded.active;
