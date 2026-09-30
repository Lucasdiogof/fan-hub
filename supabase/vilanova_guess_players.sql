-- Quem Vestiu o Manto do Vila Nova (guess_players).
-- GERADO por `node tooling/vilanova_content/generate_seed_sql.mjs` a partir de
-- docs/vila_nova_data/arena/guess_player.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do
-- Bragantino (a trava abaixo para se não for). Idempotente.
--
-- 50 cartas READY, 31 com photo_key (elenco atual, foto real
-- do site oficial, 2026-09-30). data_status = verified só quando o pacote não lista
-- campo faltando; senão incomplete.

do $$
begin
  if not exists (select 1 from public.clubs where id = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e' and slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.guess_players (id, club_id, name, display_name, aliases, position, shirt_number, academy_club, nationality_code, nationality_name, club_debut_year, photo_key, data_status, sort_order, is_active) values
  ('vn_manto_01', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Dalberson Ferreira do Amaral', 'Dalberson', '["Dalberson"]'::jsonb, 'gol', 29, null, 'BR', 'Brasil', 2026, 'vn_dalberson', 'incomplete', 1, true),
  ('vn_manto_02', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Gabriel Átila Cardoso da Silva', 'Gabriel Átila', '["Gabriel Átila"]'::jsonb, 'gol', 30, 'Vila Nova', 'BR', 'Brasil', 2026, 'vn_gabriel_atila', 'verified', 2, true),
  ('vn_manto_03', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Helton Brant Aleixo Leite', 'Helton Leite', '["Helton Leite"]'::jsonb, 'gol', 1, null, 'BR', 'Brasil', 2026, 'vn_helton_leite', 'incomplete', 3, true),
  ('vn_manto_04', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Anderson de Jesus Santos', 'Anderson Jesus', '["Anderson Jesus"]'::jsonb, 'zag', 14, null, 'BR', 'Brasil', 2026, 'vn_anderson_jesus', 'incomplete', 4, true),
  ('vn_manto_05', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Breno Augusto de Azevedo Bora', 'Breno Bora', '["Breno Bora"]'::jsonb, 'zag', 23, 'Joinville / Atlético Tubarão / Coritiba / Atlético-GO', 'BR', 'Brasil', 2026, 'vn_breno_bora', 'verified', 5, true),
  ('vn_manto_06', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Douglas Mendes Moreira', 'Douglas Mendes', '["Douglas Mendes"]'::jsonb, 'zag', 4, 'Ponte Preta', 'BR', 'Brasil', 2026, 'vn_douglas_mendes', 'verified', 6, true),
  ('vn_manto_07', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Jonathan Aparecido de Oliveira da Costa', 'Jonathan Costa', '["Jonathan Costa"]'::jsonb, 'zag', null, null, 'BR', 'Brasil', 2026, 'vn_jonathan_costa', 'incomplete', 7, true),
  ('vn_manto_08', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Samuel Lucas de Oliveira Souza', 'Samuel', '["Samuel"]'::jsonb, 'zag', null, 'São Caetano', 'BR', 'Brasil', 2026, 'vn_samuel', 'incomplete', 8, true),
  ('vn_manto_09', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Tiago Pagnussat', 'Tiago Pagnussat', '["Tiago Pagnussat"]'::jsonb, 'zag', 3, null, 'BR', 'Brasil', 2025, 'vn_tiago_pagnussat', 'incomplete', 9, true),
  ('vn_manto_10', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Eduardo dos Santos', 'Dudu', '["Dudu"]'::jsonb, 'vol', 15, null, 'BR', 'Brasil', 2026, 'vn_dudu', 'incomplete', 10, true),
  ('vn_manto_11', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Enzo Bizzotto Costa', 'Enzo', '["Enzo"]'::jsonb, 'vol', 18, 'Internacional', 'BR', 'Brasil', 2025, 'vn_enzo_bizzotto', 'verified', 11, true),
  ('vn_manto_12', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Higor Matheus Meritão', 'Higor Meritão', '["Higor Meritão"]'::jsonb, 'vol', 21, null, 'BR', 'Brasil', 2026, 'vn_higor_meritao', 'incomplete', 12, true),
  ('vn_manto_13', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'João Pedro Vieira', 'João Vieira', '["João Vieira"]'::jsonb, 'vol', 5, 'Internacional', 'BR', 'Brasil', 2025, 'vn_joao_vieira', 'verified', 13, true),
  ('vn_manto_14', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Nathan Camargo dos Santos', 'Nathan Camargo', '["Nathan Camargo"]'::jsonb, 'vol', 20, 'RB Bragantino', 'BR', 'Brasil', 2026, 'vn_nathan_camargo', 'verified', 14, true),
  ('vn_manto_15', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Willian Marlon Ferreira Moraes', 'Willian Maranhão', '["Willian Maranhão"]'::jsonb, 'vol', 8, null, 'BR', 'Brasil', 2026, 'vn_willian_maranhao', 'incomplete', 15, true),
  ('vn_manto_16', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Hayner William Monjardim Cordeiro', 'Hayner', '["Hayner"]'::jsonb, 'ld', 22, 'Bahia', 'BR', 'Brasil', 2026, 'vn_hayner', 'verified', 16, true),
  ('vn_manto_17', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Higor Luiz de Souza', 'Higor Luiz', '["Higor Luiz"]'::jsonb, 'le', 6, 'Paraná / Desportivo Brasil', 'BR', 'Brasil', 2024, 'vn_higor_luiz', 'verified', 17, true),
  ('vn_manto_18', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Igor Aquino da Silva', 'Igor Cariús', '["Igor Cariús"]'::jsonb, 'le', 16, null, 'BR', 'Brasil', 2026, 'vn_igor_carius', 'incomplete', 18, true),
  ('vn_manto_19', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Willian Prado Camargo', 'Willian Formiga', '["Willian Formiga"]'::jsonb, 'le', 13, null, 'BR', 'Brasil', 2020, 'vn_willian_formiga', 'incomplete', 19, true),
  ('vn_manto_20', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Raphael Guimarães de Paula', 'Dodô', '["Dodô"]'::jsonb, 'mei', 31, 'Atlético-MG', 'BR', 'Brasil', 2026, 'vn_dodo', 'verified', 20, true),
  ('vn_manto_21', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Marcos Gabriel do Nascimento', 'Marquinhos Gabriel', '["Marquinhos Gabriel"]'::jsonb, 'mei', 10, 'América-RS / Juventude / Passo Fundo / Internacional', 'BR', 'Brasil', 2026, 'vn_marquinhos_gabriel', 'verified', 21, true),
  ('vn_manto_22', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'André Luís da Costa Alfredo', 'André Luís', '["André Luís"]'::jsonb, 'ata', 7, null, 'BR', 'Brasil', 2025, 'vn_andre_luis', 'incomplete', 22, true),
  ('vn_manto_23', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Bruno César Xavier Sislo', 'Bruno Xavier', '["Bruno Xavier"]'::jsonb, 'ata', null, 'Juventus-SP / Portuguesa', 'BR', 'Brasil', 2025, 'vn_bruno_xavier', 'incomplete', 23, true),
  ('vn_manto_24', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Guilherme Augusto Alves Dellatorre', 'Dellatorre', '["Dellatorre"]'::jsonb, 'ata', 49, null, 'BR', 'Brasil', 2026, 'vn_dellatorre', 'incomplete', 24, true),
  ('vn_manto_25', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Emerson Lima Freitas', 'Emerson Urso', '["Emerson Urso"]'::jsonb, 'pe', 70, 'São Caetano', 'BR', 'Brasil', 2024, 'vn_emerson_urso', 'verified', 25, true),
  ('vn_manto_26', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Everton Galdino Moreira', 'Éverton Galdino', '["Éverton Galdino"]'::jsonb, 'ata', 17, 'Vila Nova', 'BR', 'Brasil', 2014, 'vn_everton_galdino', 'verified', 26, true),
  ('vn_manto_27', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Gustavo Puskas Pinheiro Lemos', 'Gustavo Puskas', '["Gustavo Puskas"]'::jsonb, 'ata', 9, 'Flamengo / Athletico-PR', 'BR', 'Brasil', 2026, 'vn_gustavo_puskas', 'verified', 27, true),
  ('vn_manto_28', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Janderson Santos de Souza', 'Janderson', '["Janderson"]'::jsonb, 'ata', 99, 'Joinville', 'BR', 'Brasil', 2026, 'vn_janderson', 'verified', 28, true),
  ('vn_manto_29', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Lincoln Corrêa dos Santos', 'Lincoln', '["Lincoln"]'::jsonb, 'ata', null, 'Flamengo', 'BR', 'Brasil', 2026, 'vn_lincoln', 'incomplete', 29, true),
  ('vn_manto_30', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Rafael da Silva', 'Rafa Silva', '["Rafa Silva"]'::jsonb, 'ata', null, 'Corinthians / Coritiba', 'BR', 'Brasil', 2026, 'vn_rafa_silva', 'incomplete', 30, true),
  ('vn_manto_31', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Ryan Aparecido Lima Cassiano', 'Ryan', '["Ryan"]'::jsonb, 'pe', 11, null, 'BR', 'Brasil', 2026, 'vn_ryan', 'incomplete', 31, true),
  ('vn_manto_32', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Rafael Ferreira Donato', 'Rafael Donato', '["Rafael Donato","Donato"]'::jsonb, 'zag', 5, 'Botafogo', 'BR', 'Brasil', 2020, null, 'incomplete', 32, true),
  ('vn_manto_33', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Alan Cássio da Cruz', 'Alan Mineiro', '["Alan Mineiro"]'::jsonb, 'mei', null, null, 'BR', 'Brasil', 2017, null, 'incomplete', 33, true),
  ('vn_manto_34', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Carlos Frontini', 'Frontini', '["Frontini","Carlos Frontini"]'::jsonb, 'ata', null, null, 'AR', 'Argentina', 2013, null, 'incomplete', 34, true),
  ('vn_manto_35', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Carlos Robston Ludgero Júnior', 'Róbston', '["Róbston","Robston"]'::jsonb, 'vol', null, 'Gama', 'BR', 'Brasil', 2013, null, 'incomplete', 35, true),
  ('vn_manto_36', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Ramires dos Anjos Alves', 'Ramires', '["Ramires"]'::jsonb, 'vol', null, null, 'BR', 'Brasil', 2015, null, 'incomplete', 36, true),
  ('vn_manto_37', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Georgemy Gonçalves', 'Georgemy', '["Georgemy"]'::jsonb, 'gol', 1, 'Cruzeiro', 'BR', 'Brasil', 2021, null, 'incomplete', 37, true),
  ('vn_manto_38', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Alesson dos Santos Batista', 'Alesson', '["Alesson"]'::jsonb, 'pe', null, null, 'BR', 'Brasil', 2021, null, 'incomplete', 38, true),
  ('vn_manto_39', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Diego Barbosa de Oliveira Tavares', 'Diego Tavares', '["Diego Tavares"]'::jsonb, 'pd', 22, null, 'BR', 'Brasil', 2021, null, 'incomplete', 39, true),
  ('vn_manto_40', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Clayton Fernandes Silva', 'Clayton', '["Clayton","Clayton Silva"]'::jsonb, 'ata', null, null, 'BR', 'Brasil', 2021, null, 'incomplete', 40, true),
  ('vn_manto_41', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Altemir Cordeiro Pessôa Neto', 'Neto Pessoa', '["Neto Pessoa"]'::jsonb, 'ata', null, null, 'BR', 'Brasil', 2022, null, 'incomplete', 41, true),
  ('vn_manto_42', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Ralf de Souza Teles', 'Ralf', '["Ralf"]'::jsonb, 'vol', 18, null, 'BR', 'Brasil', 2022, null, 'incomplete', 42, true),
  ('vn_manto_43', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Geremias Ribeiro Júnior', 'Júnior Todinho', '["Júnior Todinho","Junior Todinho"]'::jsonb, 'pe', null, null, 'BR', 'Brasil', 2024, null, 'incomplete', 43, true),
  ('vn_manto_44', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Guilherme Parede Pinheiro', 'Guilherme Parede', '["Guilherme Parede","Parede"]'::jsonb, 'pd', 77, 'Operário Ferroviário / Coritiba', 'BR', 'Brasil', 2023, null, 'incomplete', 44, true),
  ('vn_manto_45', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Hedhe Halls Rocha da Silva', 'Halls', '["Halls"]'::jsonb, 'gol', null, null, 'BR', 'Brasil', 2024, null, 'incomplete', 45, true),
  ('vn_manto_46', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Elias Lira Nogueira Júnior', 'Elias', '["Elias"]'::jsonb, 'ld', 2, null, 'BR', 'Brasil', 2024, null, 'incomplete', 46, true),
  ('vn_manto_47', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Bernardo Schappo', 'Bernardo Schappo', '["Bernardo Schappo","Schappo"]'::jsonb, 'zag', null, 'Ituano', 'BR', 'Brasil', 2025, null, 'incomplete', 47, true),
  ('vn_manto_48', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Gabriel Buscariol Poveda', 'Gabriel Poveda', '["Gabriel Poveda","Poveda"]'::jsonb, 'ata', null, 'Rio Preto / Guarani', 'BR', 'Brasil', 2025, null, 'incomplete', 48, true),
  ('vn_manto_49', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Bruno Pereira Mendes', 'Bruno Mendes', '["Bruno Mendes"]'::jsonb, 'ata', null, 'Guarani', 'BR', 'Brasil', 2025, null, 'incomplete', 49, true),
  ('vn_manto_50', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'Henrique Almeida Caixeta Nascentes', 'Henrique Almeida', '["Henrique Almeida"]'::jsonb, 'ata', null, 'São Paulo', 'BR', 'Brasil', 2023, null, 'incomplete', 50, true)
on conflict (id) do update set club_id = excluded.club_id, name = excluded.name, display_name = excluded.display_name, aliases = excluded.aliases, position = excluded.position, shirt_number = excluded.shirt_number, academy_club = excluded.academy_club, nationality_code = excluded.nationality_code, nationality_name = excluded.nationality_name, club_debut_year = excluded.club_debut_year, photo_key = excluded.photo_key, data_status = excluded.data_status, sort_order = excluded.sort_order, is_active = excluded.is_active;
