-- Diretoria do Vila Nova (club_board_sections/club_board_members).
-- GERADO por `node tooling/vilanova_content/generate_seed_sql.mjs` a partir de
-- docs/vila_nova_data/data/leadership.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do
-- Bragantino (a trava abaixo para se não for). Idempotente.
--
-- 28 pessoas em 6 seções, conforme o site oficial
-- (vilanovafc.com.br/diretoria). O pacote registra divergência com a página
-- da FGF (presidente) — seguimos o site do clube, ver conflicts no JSON.

do $$
begin
  if not exists (select 1 from public.clubs where id = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e' and slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.club_board_sections (id, title, sort_order) values
  ('vn_diretoria_executiva', 'Diretoria Executiva', 0),
  ('vn_conselho_deliberativo', 'Conselho Deliberativo', 1),
  ('vn_conselho_fiscal', 'Conselho Fiscal', 2),
  ('vn_conselho_de_patrimonio', 'Conselho de Patrimônio', 3),
  ('vn_diretoria_de_categorias_de_base', 'Diretoria de Categorias de Base', 4),
  ('vn_diretoria_social', 'Diretoria Social', 5)
on conflict (id) do update set title = excluded.title, sort_order = excluded.sort_order;

insert into public.club_board_members (id, section_id, name, role, photo_url, sort_order) values
  ('vn_diretoria_executiva_00_fabio_brasil_de_castro', 'vn_diretoria_executiva', 'Fábio Brasil de Castro', 'Presidente Executivo', null, 0),
  ('vn_diretoria_executiva_01_vinicius_clementino_cirqueira', 'vn_diretoria_executiva', 'Vinícius Clementino Cirqueira', 'Vice-Presidente', null, 1),
  ('vn_diretoria_executiva_02_romario_barbosa_policarpo', 'vn_diretoria_executiva', 'Romário Barbosa Policarpo', '2º Vice-Presidente', null, 2),
  ('vn_diretoria_executiva_03_hugo_jorge_bravo_de_carvalho', 'vn_diretoria_executiva', 'Hugo Jorge Bravo de Carvalho', 'Vice-Presidente Financeiro e Futebol', null, 3),
  ('vn_diretoria_executiva_04_allan_maximo_de_holanda', 'vn_diretoria_executiva', 'Allan Máximo de Holanda', 'Diretoria Administrativa', null, 4),
  ('vn_diretoria_executiva_05_paulo_henrique_pinheiro', 'vn_diretoria_executiva', 'Paulo Henrique Pinheiro', 'Diretoria Jurídica', null, 5),
  ('vn_diretoria_executiva_06_rodrigo_menezes', 'vn_diretoria_executiva', 'Rodrigo Menezes', 'Diretoria Jurídica', null, 6),
  ('vn_diretoria_executiva_07_murilo_oliviere_reis_sobrinho', 'vn_diretoria_executiva', 'Murilo Oliviere Reis Sobrinho', 'Diretoria de Marketing', null, 7),
  ('vn_diretoria_executiva_08_romario_barbosa_policarpo', 'vn_diretoria_executiva', 'Romário Barbosa Policarpo', 'Diretoria de Comunicação', null, 8),
  ('vn_conselho_deliberativo_00_leandro_bittar_froes', 'vn_conselho_deliberativo', 'Leandro Bittar Froes', 'Presidente', null, 0),
  ('vn_conselho_deliberativo_01_decio_caetano_vieira_filho', 'vn_conselho_deliberativo', 'Décio Caetano Vieira Filho', 'Vice-Presidente', null, 1),
  ('vn_conselho_deliberativo_02_marco_aurelio_tavares_caetano', 'vn_conselho_deliberativo', 'Marco Aurélio Tavares Caetano', 'Secretário', null, 2),
  ('vn_conselho_deliberativo_03_allan', 'vn_conselho_deliberativo', 'Allan', 'Suplente', null, 3),
  ('vn_conselho_fiscal_00_rodrigo_silva_menezes', 'vn_conselho_fiscal', 'Rodrigo Silva Menezes', 'Presidente', null, 0),
  ('vn_conselho_fiscal_01_joao_gonzaga_de_siqueira_junior', 'vn_conselho_fiscal', 'João Gonzaga de Siqueira Júnior', 'Vice-Presidente', null, 1),
  ('vn_conselho_fiscal_02_henrique_cesar_nery_da_veiga_jardim', 'vn_conselho_fiscal', 'Henrique César Nery da Veiga Jardim', 'Secretário', null, 2),
  ('vn_conselho_fiscal_03_nilson_soares_moreira', 'vn_conselho_fiscal', 'Nilson Soares Moreira', 'Suplente', null, 3),
  ('vn_conselho_fiscal_04_fernando_henrique_mussi', 'vn_conselho_fiscal', 'Fernando Henrique Mussi', 'Suplente', null, 4),
  ('vn_conselho_fiscal_05_rafael_lucas_loreto_ribeiro', 'vn_conselho_fiscal', 'Rafael Lucas Loreto Ribeiro', 'Suplente', null, 5),
  ('vn_conselho_de_patrimonio_00_vinicius_de_oliveira_marinari', 'vn_conselho_de_patrimonio', 'Vinícius de Oliveira Marinari', 'Membro', null, 0),
  ('vn_conselho_de_patrimonio_01_fernando_henrique_mussi', 'vn_conselho_de_patrimonio', 'Fernando Henrique Mussi', 'Membro', null, 1),
  ('vn_conselho_de_patrimonio_02_leonardo_cairo_rizzo', 'vn_conselho_de_patrimonio', 'Leonardo Cairo Rizzo', 'Membro', null, 2),
  ('vn_conselho_de_patrimonio_03_jose_carlos_barbosa', 'vn_conselho_de_patrimonio', 'José Carlos Barbosa', 'Membro', null, 3),
  ('vn_diretoria_de_categorias_de_base_00_olimpio_jayme_neto', 'vn_diretoria_de_categorias_de_base', 'Olímpio Jayme Neto', 'Diretor', null, 0),
  ('vn_diretoria_de_categorias_de_base_01_joao_pedro_ferro', 'vn_diretoria_de_categorias_de_base', 'João Pedro Ferro', 'Diretor', null, 1),
  ('vn_diretoria_social_00_janilson_emerick_martins', 'vn_diretoria_social', 'Janilson Emerick Martins', 'Diretor', null, 0),
  ('vn_diretoria_social_01_alexandre_moura_dantas', 'vn_diretoria_social', 'Alexandre Moura Dantas', 'Diretor', null, 1),
  ('vn_diretoria_social_02_marcus_antonio_de_pinho_lorenzzo', 'vn_diretoria_social', 'Marcus Antônio de Pinho Lorenzzo', 'Diretor', null, 2)
on conflict (id) do update set section_id = excluded.section_id, name = excluded.name, role = excluded.role, photo_url = excluded.photo_url, sort_order = excluded.sort_order;
