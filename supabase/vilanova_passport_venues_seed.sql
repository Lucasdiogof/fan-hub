-- Catálogo de estádios do Passaporte do Vila Nova. GERADO por
-- `node tooling/vilanova_passport/generate_passport_sql.mjs` a partir de
-- docs/vila_nova_data/passport/venues.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do Bragantino.
-- Ordem: vilanova_passport_infra.sql -> ESTE -> vilanova_passport_matches_<ano>_seed.sql.
-- Idempotente. 78 estádios (só os usados por alguma partida do pacote).

do $$
begin
  if not exists (select 1 from public.clubs where slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.venues
  (id, canonical_name, display_name, city, state, country, latitude, longitude, aliases)
values
  ('vn_venue_oba', 'Estádio Onésio Brasileiro Alvarenga', 'OBA', 'Goiânia', 'GO', 'BR', null, null, array['Onésio Brasileiro Alvarenga', 'Estádio Onésio Brasileiro Alvarenga']),
  ('vn_venue_ilha_do_retiro', 'Estádio Adelmar da Costa Carvalho', 'Ilha do Retiro', 'Recife', 'PE', 'BR', null, null, array['Ilha do Retiro']),
  ('vn_venue_moises_lucarelli', 'Estádio Moisés Lucarelli', 'Moisés Lucarelli', 'Campinas', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_castelao', 'Estádio Governador Plácido Castelo', 'Arena Castelão', 'Fortaleza', 'CE', 'BR', null, null, array['Castelão']),
  ('vn_venue_serrinha', 'Estádio Hailé Pinheiro', 'Serrinha', 'Goiânia', 'GO', 'BR', null, null, array['Serrinha']),
  ('vn_venue_independ_ncia', 'Estádio Raimundo Sampaio', 'Independência', 'Belo Horizonte', 'MG', 'BR', null, null, array['Arena Independência']),
  ('vn_venue_vgd', 'Estádio Vitorino Gonçalves Dias', 'VGD', 'Londrina', 'PR', 'BR', null, null, array['Vitorino Gonçalves Dias']),
  ('vn_venue_arena_pantanal', 'Arena Pantanal', 'Arena Pantanal', 'Cuiabá', 'MT', 'BR', null, null, '{}'::text[]),
  ('vn_venue_jorjao', 'Estádio Jorge Ismael de Biasi', 'Jorjão', 'Novo Horizonte', 'SP', 'BR', null, null, array['Jorge Ismael de Biasi']),
  ('vn_venue_alfredo_jaconi', 'Estádio Alfredo Jaconi', 'Alfredo Jaconi', 'Caxias do Sul', 'RS', 'BR', null, null, '{}'::text[]),
  ('vn_venue_heriberto_h_lse', 'Estádio Heriberto Hülse', 'Heriberto Hülse', 'Criciúma', 'SC', 'BR', null, null, '{}'::text[]),
  ('vn_venue_rei_pele', 'Estádio Rei Pelé', 'Rei Pelé', 'Maceió', 'AL', 'BR', null, null, '{}'::text[]),
  ('vn_venue_ant_nio_accioly', 'Estádio Antônio Accioly', 'Antônio Accioly', 'Goiânia', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_germano_kr_ger', 'Estádio Germano Krüger', 'Germano Krüger', 'Ponta Grossa', 'PR', 'BR', null, null, '{}'::text[]),
  ('vn_venue_arena_sicredi', 'Arena Sicredi', 'Arena Sicredi', 'São João del-Rei', 'MG', 'BR', null, null, '{}'::text[]),
  ('vn_venue_ressacada', 'Estádio Aderbal Ramos da Silva', 'Ressacada', 'Florianópolis', 'SC', 'BR', null, null, '{}'::text[]),
  ('vn_venue_aflitos', 'Estádio Eládio de Barros Carvalho', 'Aflitos', 'Recife', 'PE', 'BR', null, null, array['Estádio dos Aflitos']),
  ('vn_venue_benitao', 'Estádio Benito Agnelo Castellano', 'Benitão', 'Rio Claro', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_luiz_benedito', 'Estádio Luiz Benedito', 'Luiz Benedito', 'Ouvidor', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_jonas_duarte', 'Estádio Jonas Duarte', 'Jonas Duarte', 'Anápolis', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_jaime_guerra', 'Estádio Jaime Guerra', 'Jaime Guerra', null, 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_olimpico', 'Estádio Olímpico Pedro Ludovico Teixeira', 'Estádio Olímpico', 'Goiânia', 'GO', 'BR', null, null, array['Olímpico']),
  ('vn_venue_kleber_andrade', 'Estádio Estadual Kleber José de Andrade', 'Kleber Andrade', 'Cariacica', 'ES', 'BR', null, null, '{}'::text[]),
  ('vn_venue_cerradao', 'Estádio Antônio Santo Renosto', 'Cerradão', 'Primavera do Leste', 'MT', 'BR', null, null, array['Estádio Cerradão']),
  ('vn_venue_mirandao', 'Estádio Leôncio de Souza Miranda', 'Mirandão', 'Araguaína', 'TO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_serra_dourada', 'Estádio Serra Dourada', 'Serra Dourada', 'Goiânia', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_arapucao', 'Estádio Arapucão', 'Arapucão', 'Jataí', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_elmo_serejo', 'Estádio Elmo Serejo Farias', 'Serejão', 'Brasília', 'DF', 'BR', null, null, array['Boca do Jacaré', 'Boca do Jacaré / Serejão', 'Elmo Serejo']),
  ('vn_venue_major_levy', 'Estádio Major José Levy Sobrinho', 'Major Levy Sobrinho', 'Limeira', 'SP', 'BR', null, null, array['Major Levy Sobrinho']),
  ('vn_venue_mineirao', 'Mineirão', 'Mineirão', 'Belo Horizonte', 'MG', 'BR', null, null, '{}'::text[]),
  ('vn_venue_couto_pereira', 'Estádio Couto Pereira', 'Couto Pereira', 'Curitiba', 'PR', 'BR', null, null, array['Couto Pereira']),
  ('vn_venue_mangueirao', 'Estádio Mangueirão', 'Mangueirão', 'Belém', 'PA', 'BR', null, null, array['Mangueirão']),
  ('vn_venue_carlos_zamith', 'Estádio Carlos Zamith', 'Carlos Zamith', 'Manaus', 'AM', 'BR', null, null, array['Carlos Zamith']),
  ('vn_venue_fonte_luminosa', 'Fonte Luminosa', 'Fonte Luminosa', 'Araraquara', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_raulino_oliveira', 'Estádio Raulino de Oliveira', 'Raulino de Oliveira', 'Volta Redonda', 'RJ', 'BR', null, null, array['Raulino de Oliveira']),
  ('vn_venue_curuzu', 'Curuzu', 'Curuzu', 'Belém', 'PA', 'BR', null, null, array['Estádio da Curuzu']),
  ('vn_venue_arena_conda', 'Arena Condá', 'Arena Condá', 'Chapecó', 'SC', 'BR', null, null, '{}'::text[]),
  ('vn_venue_arena_baixada', 'Arena da Baixada', 'Arena da Baixada', 'Curitiba', 'PR', 'BR', null, null, array['Ligga Arena']),
  ('vn_venue_arena_pernambuco', 'Arena de Pernambuco', 'Arena de Pernambuco', 'São Lourenço da Mata', 'PE', 'BR', null, null, '{}'::text[]),
  ('vn_venue_santa_cruz_ribeirao', 'Estádio Santa Cruz', 'Estádio Santa Cruz', 'Ribeirão Preto', 'SP', 'BR', null, null, array['Arena Nicnet']),
  ('vn_venue_novelli_junior', 'Estádio Novelli Júnior', 'Estádio Novelli Júnior', 'Itu', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_brinco_ouro', 'Estádio Brinco de Ouro da Princesa', 'Brinco de Ouro', 'Campinas', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_hercilio_luz', 'Estádio Doutor Hercílio Luz', 'Hercílio Luz', 'Itajaí', 'SC', 'BR', null, null, '{}'::text[]),
  ('vn_venue_jose_maria_maia', 'Estádio José Maria de Campos Maia', 'José Maria de Campos Maia', 'Mirassol', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_vila_belmiro', 'Estádio Urbano Caldeira', 'Vila Belmiro', 'Santos', 'SP', 'BR', null, null, array['Vila Belmiro']),
  ('vn_venue_valdeir_jose', 'Estádio Valdeir José de Oliveira', 'Valdeir José de Oliveira', 'Goianésia', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_jose_olimpio_rocha', 'Estádio José Olímpio da Rocha', 'José Olímpio da Rocha', 'Águia Branca', 'ES', 'BR', null, null, '{}'::text[]),
  ('vn_venue_estadio_cafe', 'Estádio do Café', 'Estádio do Café', 'Londrina', 'PR', 'BR', null, null, '{}'::text[]),
  ('vn_venue_castelao_sao_luis', 'Estádio Governador João Castelo', 'Castelão', 'São Luís', 'MA', 'BR', null, null, array['Castelão de São Luís']),
  ('vn_venue_antonio_guimaraes', 'Estádio Antônio Guimarães de Almeida', 'Antônio Guimarães de Almeida', 'Tombos', 'MG', 'BR', null, null, '{}'::text[]),
  ('vn_venue_barradao', 'Estádio Manoel Barradas', 'Barradão', 'Salvador', 'BA', 'BR', null, null, array['Manoel Barradas']),
  ('vn_venue_frasqueirao', 'Estádio Maria Lamas Farache', 'Frasqueirão', 'Natal', 'RN', 'BR', null, null, array['Frasqueirão']),
  ('vn_venue_fonte_nova', 'Arena Fonte Nova', 'Arena Fonte Nova', 'Salvador', 'BA', 'BR', null, null, array['Itaipava Arena Fonte Nova']),
  ('vn_venue_florestao', 'Estádio Antônio Aquino Lopes', 'Florestão', 'Rio Branco', 'AC', 'BR', null, null, array['Florestão']),
  ('vn_venue_maracana', 'Estádio do Maracanã', 'Maracanã', 'Rio de Janeiro', 'RJ', 'BR', null, null, array['Estádio Jornalista Mário Filho']),
  ('vn_venue_antonio_carneiro', 'Estádio Antônio Carneiro', 'Antônio Carneiro', 'Alagoinhas', 'BA', 'BR', null, null, '{}'::text[]),
  ('vn_venue_pituacu', 'Estádio de Pituaçu', 'Pituaçu', 'Salvador', 'BA', 'BR', null, null, array['Estádio Governador Roberto Santos']),
  ('vn_venue_noroeste', 'Estádio Noroeste', 'Estádio Noroeste', 'Aquidauana', 'MS', 'BR', null, null, '{}'::text[]),
  ('vn_venue_valdir_wons', 'Estádio Valdir Doilho Wons', 'Valdir Doilho Wons', 'Nova Mutum', 'MT', 'BR', null, null, '{}'::text[]),
  ('vn_venue_baenao', 'Estádio Evandro Almeida', 'Baenão', 'Belém', 'PA', 'BR', null, null, array['Baenão']),
  ('vn_venue_arena_floresta', 'Arena da Floresta', 'Arena da Floresta', 'Rio Branco', 'AC', 'BR', null, null, '{}'::text[]),
  ('vn_venue_arena_amazonia', 'Arena da Amazônia', 'Arena da Amazônia', 'Manaus', 'AM', 'BR', null, null, '{}'::text[]),
  ('vn_venue_almeidao', 'Estádio José Américo de Almeida Filho', 'Almeidão', 'João Pessoa', 'PB', 'BR', null, null, array['Almeidão']),
  ('vn_venue_arruda', 'Estádio José do Rego Maciel', 'Arruda', 'Recife', 'PE', 'BR', null, null, array['Estádio do Arruda']),
  ('vn_venue_frei_epifanio', 'Estádio Frei Epifânio d''Abadia', 'Frei Epifânio', 'Imperatriz', 'MA', 'BR', null, null, '{}'::text[]),
  ('vn_venue_amigao', 'Estádio Governador Ernani Sátyro', 'Amigão', 'Campina Grande', 'PB', 'BR', null, null, array['Amigão']),
  ('vn_venue_augusto_bauer', 'Estádio Augusto Bauer', 'Augusto Bauer', 'Brusque', 'SC', 'BR', null, null, '{}'::text[]),
  ('vn_venue_genervino_fonseca', 'Estádio Genervino da Fonseca', 'Genervino da Fonseca', 'Catalão', 'GO', 'BR', null, null, '{}'::text[]),
  ('vn_venue_jk_itumbiara', 'Estádio Municipal Juscelino Kubitschek de Oliveira', 'Estádio JK', 'Itumbiara', 'GO', 'BR', null, null, array['Juscelino Kubitschek', 'JK (Itumbiara)', 'Estádio JK']),
  ('vn_venue_anibal_toledo', 'Estádio Aníbal Batista de Toledo', 'Aníbal Batista de Toledo', 'Aparecida de Goiânia', 'GO', 'BR', null, null, array['Aníbal Toledo', 'Annibal Batista de Toledo']),
  ('vn_venue_ismael_benigno', 'Estádio Ismael Benigno', 'Colina', 'Manaus', 'AM', 'BR', null, null, array['Estádio da Colina', 'Colina']),
  ('vn_venue_zama_maciel', 'Estádio Zama Maciel', 'Zama Maciel', 'Patos de Minas', 'MG', 'BR', null, null, '{}'::text[]),
  ('vn_venue_bento_mendes_freitas', 'Estádio Bento Mendes de Freitas', 'Bento Freitas', 'Pelotas', 'RS', 'BR', null, null, array['Estádio Bento Freitas', 'Bento de Freitas', 'Bento Freitas']),
  ('vn_venue_durival_britto', 'Estádio Durival Britto e Silva', 'Vila Capanema', 'Curitiba', 'PR', 'BR', null, null, array['Durival de Britto', 'Durival Britto', 'Estádio Vila Capanema']),
  ('vn_venue_arena_barueri', 'Arena Barueri', 'Arena Barueri', 'Barueri', 'SP', 'BR', null, null, '{}'::text[]),
  ('vn_venue_walter_ribeiro', 'Estádio Municipal Walter Ribeiro', 'Walter Ribeiro', 'Sorocaba', 'SP', 'BR', null, null, array['Estádio Walter Ribeiro', 'Walter Ribeiro', 'CIC']),
  ('vn_venue_nabi_abi_chedid', 'Estádio Nabi Abi Chedid', 'Nabi Abi Chedid', 'Bragança Paulista', 'SP', 'BR', null, null, array['Nabi Abi Chedid']),
  ('vn_venue_orlando_scarpelli', 'Estádio Orlando Scarpelli', 'Orlando Scarpelli', 'Florianópolis', 'SC', 'BR', null, null, '{}'::text[])
on conflict (id) do update set
  canonical_name = excluded.canonical_name, display_name = excluded.display_name,
  city = excluded.city, state = excluded.state, country = excluded.country,
  latitude = excluded.latitude, longitude = excluded.longitude,
  aliases = excluded.aliases, updated_at = now();
