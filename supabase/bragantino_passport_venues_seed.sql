-- Catálogo de estádios do Passaporte do Bragantino + ligação das
-- partidas. GERADO por `node tooling/bragantino_passport/build_venues.mjs`
-- — não edite à mão, edite os grupos de normalização no script.
--
-- Rode no projeto Supabase do BRAGANTINO, DEPOIS de
-- `bragantino_passport_infra.sql` e dos seeds de partida.
-- Idempotente: reexecutar apenas reescreve os mesmos valores.
--
-- 49 estádios, a partir de 186 partidas com
-- estádio confirmado na ficha (evidência MATCH_SPECIFIC).

insert into public.venues
  (id, canonical_name, display_name, city, state, country, aliases)
values
  ('venue_estadio_municipal_cicero_de_souza_marques', 'Estádio Municipal Cícero de Souza Marques', 'Estádio Cícero de Souza Marques', 'Bragança Paulista', 'SP', 'BR', '{}'::text[]),
  ('venue_nabi_abi_chedid', 'Nabi Abi Chedid', 'Estádio Nabi Abi Chedid', 'Bragança Paulista', 'SP', 'BR', '{}'::text[]),
  ('venue_neo_quimica_arena', 'Neo Química Arena', 'Neo Química Arena', 'São Paulo', 'SP', 'BR', array['Neo Química Arena (Arena Corinthians)']),
  ('venue_estadio_jornalista_mario_filho', 'Estádio Jornalista Mário Filho', 'Maracanã', 'Rio de Janeiro', 'RJ', 'BR', array['Estadio Jornalista Mário Filho (Maracanã)', 'Estádio Jornalista Mário Filho (Maracanã)']),
  ('venue_estadio_olimpico_nilton_santos', 'Estádio Olímpico Nilton Santos', 'Estádio Nilton Santos', 'Rio de Janeiro', 'RJ', 'BR', array['Estádio Olímpico Nilton Santos (Engenhão)']),
  ('venue_arena_mrv', 'Arena MRV', 'Arena MRV', 'Belo Horizonte', 'MG', 'BR', '{}'::text[]),
  ('venue_nubank_parque', 'Nubank Parque', 'Nubank Parque', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_urbano_caldeira', 'Estádio Urbano Caldeira', 'Vila Belmiro', 'Santos', 'SP', 'BR', array['Urbano Caldeira (Vila Belmiro)']),
  ('venue_estadio_jose_maria_de_campos_maia', 'Estádio José Maria de Campos Maia', 'Estádio Maião', 'Mirassol', 'SP', 'BR', array['José Maria de Campos Maia (Maião)']),
  ('venue_estadio_cicero_pompeu_de_toledo', 'Estádio Cícero Pompeu de Toledo', 'MorumBIS', 'São Paulo', 'SP', 'BR', array['Cícero Pompeu de Toledo (Morumbis)', 'MorumBIS']),
  ('venue_estadio_joaquim_americo_guimaraes', 'Estádio Joaquim Américo Guimarães', 'Arena da Baixada', 'Curitiba', 'PR', 'BR', array['Estádio Mário Celso Petraglia', 'Estádio Mário Celso Petraglia (Arena da Baixada)']),
  ('venue_estadio_jose_pinheiro_borda', 'Estádio José Pinheiro Borda', 'Beira-Rio', 'Porto Alegre', 'RS', 'BR', array['José Pinheiro Borda (Beira-Rio)']),
  ('venue_estadio_manoel_barradas', 'Estádio Manoel Barradas', 'Barradão', 'Salvador', 'BA', 'BR', array['Manoel Barradas (Barradão)']),
  ('venue_estadio_vasco_da_gama', 'Estádio Vasco da Gama', 'São Januário', 'Rio de Janeiro', 'RJ', 'BR', array['Estádio São Januário', 'Estádio Vasco da Gama (São Januário)']),
  ('venue_complexo_esportivo_cultural_octavio_mangabeira', 'Complexo Esportivo Cultural Octávio Mangabeira', 'Arena Fonte Nova', 'Salvador', 'BA', 'BR', array['Arena Fonte Nova', 'Casa de Apostas Arena Fonte Nova']),
  ('venue_governador_placido_aderaldo_castelo_castelao', 'Governador Plácido Aderaldo Castelo (Castelão)', 'Castelão', 'Fortaleza', 'CE', 'BR', '{}'::text[]),
  ('venue_alfredo_jaconi', 'Alfredo Jaconi', 'Alfredo Jaconi', 'Caxias do Sul', 'RS', 'BR', '{}'::text[]),
  ('venue_heriberto_hulse', 'Heriberto Hülse', 'Heriberto Hülse', 'Criciúma', 'SC', 'BR', '{}'::text[]),
  ('venue_estadio_major_antonio_couto_pereira', 'Estádio Major Antônio Couto Pereira', 'Couto Pereira', 'Curitiba', 'PR', 'BR', '{}'::text[]),
  ('venue_antonio_marques_da_silva_mariz_marizao', 'Antônio Marques da Silva Mariz (Marizão)', 'Marizão', 'Sousa', 'PB', 'BR', '{}'::text[]),
  ('venue_santa_cruz', 'Santa Cruz', 'Estádio Santa Cruz', 'Ribeirão Preto', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_governador_magalhaes_pinto', 'Estádio Governador Magalhães Pinto', 'Mineirão', 'Belo Horizonte', 'MG', 'BR', array['Estádio Gov. Magalhães Pinto (Mineirão)']),
  ('venue_arena_do_gremio', 'Arena do Grêmio', 'Arena do Grêmio', 'Porto Alegre', 'RS', 'BR', '{}'::text[]),
  ('venue_brinco_de_ouro_da_princesa', 'Brinco de Ouro da Princesa', 'Brinco de Ouro da Princesa', 'Campinas', 'SP', 'BR', '{}'::text[]),
  ('venue_dr_novelli_junior', 'Dr. Novelli Júnior', 'Dr. Novelli Júnior', 'Jaú', 'SP', 'BR', '{}'::text[]),
  ('venue_doutor_jorge_ismael_de_biasi_jorjao', 'Doutor Jorge Ismael de Biasi (Jorjão)', 'Estádio Jorjão', 'Novo Horizonte', 'SP', 'BR', '{}'::text[]),
  ('venue_bruno_jose_daniel', 'Bruno José Daniel', 'Bruno José Daniel', 'Santo André', 'SP', 'BR', '{}'::text[]),
  ('venue_oswaldo_teixeira_duarte_caninde', 'Oswaldo Teixeira Duarte (Canindé)', 'Canindé', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_antonio_accioly', 'Antônio Accioly', 'Antônio Accioly', 'Goiânia', 'GO', 'BR', '{}'::text[]),
  ('venue_raimundo_sampaio_arena_independencia', 'Raimundo Sampaio (Arena Independência)', 'Arena Independência', 'Belo Horizonte', 'MG', 'BR', '{}'::text[]),
  ('venue_arena_pantanal', 'Arena Pantanal', 'Arena Pantanal', 'Cuiabá', 'MT', 'BR', '{}'::text[]),
  ('venue_estadio_monumental_banco_pichincha', 'Estadio Monumental Banco Pichincha', 'Estadio Monumental Banco Pichincha', 'Guayaquil', null, 'EC', '{}'::text[]),
  ('venue_francisco_sanchez_rumoroso', 'Francisco Sánchez Rumoroso', 'Francisco Sánchez Rumoroso', 'Coquimbo', null, 'CL', '{}'::text[]),
  ('venue_defensores_del_chaco', 'Defensores del Chaco', 'Defensores del Chaco', 'Assunção', null, 'PY', '{}'::text[]),
  ('venue_presidente_peron_el_cilindro', 'Presidente Perón (El Cilindro)', 'El Cilindro', 'Avellaneda', 'Buenos Aires', 'AR', '{}'::text[]),
  ('venue_atanasio_girardot', 'Atanasio Girardot', 'Atanasio Girardot', 'Medellín', null, 'CO', '{}'::text[]),
  ('venue_moises_lucarelli', 'Moisés Lucarelli', 'Moisés Lucarelli', 'Campinas', 'SP', 'BR', '{}'::text[]),
  ('venue_major_jose_levy_sobrinho', 'Major José Levy Sobrinho', 'Major José Levy Sobrinho', 'Limeira', 'SP', 'BR', '{}'::text[]),
  ('venue_jose_batista_pereira_fernandes_distrital_do_inam', 'José Batista Pereira Fernandes (Distrital do Inamar)', 'Distrital do Inamar', 'Diadema', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_municipal_primeiro_de_maio', 'Estádio Municipal Primeiro de Maio', 'Estádio Municipal Primeiro de Maio', 'São Bernardo do Campo', 'SP', 'BR', '{}'::text[]),
  ('venue_adelmar_da_costa_carvalho_ilha_do_retiro', 'Adelmar da Costa Carvalho (Ilha do Retiro)', 'Ilha do Retiro', 'Recife', 'PE', 'BR', '{}'::text[]),
  ('venue_estadio_dr_alfredo_de_castilho', 'Estádio Dr. Alfredo de Castilho', 'Estádio Dr. Alfredo de Castilho', null, null, 'BR', '{}'::text[]),
  ('venue_estadio_benito_agnelo_castellano', 'Estádio Benito Agnelo Castellano', 'Estádio Benito Agnelo Castellano', 'Rio Claro', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_polideportivo_misael_delgado', 'Estadio Polideportivo Misael Delgado', 'Estadio Polideportivo Misael Delgado', 'Valencia', null, 'VE', '{}'::text[]),
  ('venue_arena_conda', 'Arena Condá', 'Arena Condá', 'Chapecó', 'SC', 'BR', '{}'::text[]),
  ('venue_estadio_ramon_aguilera_costas', 'Estadio Ramón Aguilera Costas', 'Estadio Ramón Aguilera Costas', 'Santa Cruz de la Sierra', null, 'BO', '{}'::text[]),
  ('venue_estadio_monumental', 'Estadio Monumental', 'Estadio Monumental', 'Buenos Aires', null, 'AR', '{}'::text[]),
  ('venue_estadio_nacional_de_lima', 'Estadio Nacional de Lima', 'Estadio Nacional de Lima', 'Lima', null, 'PE', '{}'::text[]),
  ('venue_estadio_evandro_almeida', 'Estádio Evandro Almeida', 'Estádio Evandro Almeida', 'Belém', 'PA', 'BR', '{}'::text[])
on conflict (id) do update set
  canonical_name = excluded.canonical_name,
  display_name = excluded.display_name,
  city = excluded.city,
  state = excluded.state,
  country = excluded.country,
  aliases = excluded.aliases,
  updated_at = now();

-- Rede de segurança: o seed de partidas já grava `venue_id` direto, mas
-- linhas importadas antes deste catálogo existir ficariam sem ligação.
-- O casamento é pelo TEXTO EXATO gravado em `passport_matches.stadium`,
-- que segue intacto como provenance.
update public.passport_matches set venue_id = 'venue_neo_quimica_arena'
  where stadium in ('Neo Química Arena', 'Neo Química Arena (Arena Corinthians)');
update public.passport_matches set venue_id = 'venue_nabi_abi_chedid'
  where stadium in ('Nabi Abi Chedid');
update public.passport_matches set venue_id = 'venue_brinco_de_ouro_da_princesa'
  where stadium in ('Brinco de Ouro da Princesa');
update public.passport_matches set venue_id = 'venue_dr_novelli_junior'
  where stadium in ('Dr. Novelli Júnior');
update public.passport_matches set venue_id = 'venue_estadio_cicero_pompeu_de_toledo'
  where stadium in ('Cícero Pompeu de Toledo (Morumbis)', 'MorumBIS');
update public.passport_matches set venue_id = 'venue_doutor_jorge_ismael_de_biasi_jorjao'
  where stadium in ('Doutor Jorge Ismael de Biasi (Jorjão)');
update public.passport_matches set venue_id = 'venue_bruno_jose_daniel'
  where stadium in ('Bruno José Daniel');
update public.passport_matches set venue_id = 'venue_oswaldo_teixeira_duarte_caninde'
  where stadium in ('Oswaldo Teixeira Duarte (Canindé)');
update public.passport_matches set venue_id = 'venue_estadio_joaquim_americo_guimaraes'
  where stadium in ('Estádio Mário Celso Petraglia', 'Estádio Mário Celso Petraglia (Arena da Baixada)');
update public.passport_matches set venue_id = 'venue_estadio_jose_pinheiro_borda'
  where stadium in ('Estádio José Pinheiro Borda', 'José Pinheiro Borda (Beira-Rio)');
update public.passport_matches set venue_id = 'venue_antonio_accioly'
  where stadium in ('Antônio Accioly');
update public.passport_matches set venue_id = 'venue_estadio_manoel_barradas'
  where stadium in ('Estádio Manoel Barradas', 'Manoel Barradas (Barradão)');
update public.passport_matches set venue_id = 'venue_alfredo_jaconi'
  where stadium in ('Alfredo Jaconi');
update public.passport_matches set venue_id = 'venue_arena_mrv'
  where stadium in ('Arena MRV');
update public.passport_matches set venue_id = 'venue_heriberto_hulse'
  where stadium in ('Heriberto Hülse');
update public.passport_matches set venue_id = 'venue_estadio_jornalista_mario_filho'
  where stadium in ('Estadio Jornalista Mário Filho (Maracanã)', 'Estádio Jornalista Mário Filho (Maracanã)');
update public.passport_matches set venue_id = 'venue_estadio_vasco_da_gama'
  where stadium in ('Estádio São Januário', 'Estádio Vasco da Gama (São Januário)');
update public.passport_matches set venue_id = 'venue_raimundo_sampaio_arena_independencia'
  where stadium in ('Raimundo Sampaio (Arena Independência)');
update public.passport_matches set venue_id = 'venue_arena_pantanal'
  where stadium in ('Arena Pantanal');
update public.passport_matches set venue_id = 'venue_estadio_olimpico_nilton_santos'
  where stadium in ('Estádio Olímpico Nilton Santos', 'Estádio Olímpico Nilton Santos (Engenhão)');
update public.passport_matches set venue_id = 'venue_nubank_parque'
  where stadium in ('Nubank Parque');
update public.passport_matches set venue_id = 'venue_estadio_major_antonio_couto_pereira'
  where stadium in ('Estádio Major Antônio Couto Pereira');
update public.passport_matches set venue_id = 'venue_complexo_esportivo_cultural_octavio_mangabeira'
  where stadium in ('Arena Fonte Nova', 'Casa de Apostas Arena Fonte Nova');
update public.passport_matches set venue_id = 'venue_governador_placido_aderaldo_castelo_castelao'
  where stadium in ('Governador Plácido Aderaldo Castelo (Castelão)');
update public.passport_matches set venue_id = 'venue_antonio_marques_da_silva_mariz_marizao'
  where stadium in ('Antônio Marques da Silva Mariz (Marizão)');
update public.passport_matches set venue_id = 'venue_santa_cruz'
  where stadium in ('Santa Cruz');
update public.passport_matches set venue_id = 'venue_estadio_monumental_banco_pichincha'
  where stadium in ('Estadio Monumental Banco Pichincha');
update public.passport_matches set venue_id = 'venue_francisco_sanchez_rumoroso'
  where stadium in ('Francisco Sánchez Rumoroso');
update public.passport_matches set venue_id = 'venue_defensores_del_chaco'
  where stadium in ('Defensores del Chaco');
update public.passport_matches set venue_id = 'venue_presidente_peron_el_cilindro'
  where stadium in ('Presidente Perón (El Cilindro)');
update public.passport_matches set venue_id = 'venue_atanasio_girardot'
  where stadium in ('Atanasio Girardot');
update public.passport_matches set venue_id = 'venue_estadio_urbano_caldeira'
  where stadium in ('Estádio Urbano Caldeira', 'Urbano Caldeira (Vila Belmiro)');
update public.passport_matches set venue_id = 'venue_moises_lucarelli'
  where stadium in ('Moisés Lucarelli');
update public.passport_matches set venue_id = 'venue_major_jose_levy_sobrinho'
  where stadium in ('Major José Levy Sobrinho');
update public.passport_matches set venue_id = 'venue_jose_batista_pereira_fernandes_distrital_do_inam'
  where stadium in ('José Batista Pereira Fernandes (Distrital do Inamar)');
update public.passport_matches set venue_id = 'venue_estadio_municipal_primeiro_de_maio'
  where stadium in ('Estádio Municipal Primeiro de Maio');
update public.passport_matches set venue_id = 'venue_estadio_municipal_cicero_de_souza_marques'
  where stadium in ('Estádio Municipal Cícero de Souza Marques');
update public.passport_matches set venue_id = 'venue_estadio_jose_maria_de_campos_maia'
  where stadium in ('Estádio José Maria de Campos Maia', 'José Maria de Campos Maia (Maião)');
update public.passport_matches set venue_id = 'venue_estadio_governador_magalhaes_pinto'
  where stadium in ('Estádio Gov. Magalhães Pinto (Mineirão)', 'Estádio Governador Magalhães Pinto');
update public.passport_matches set venue_id = 'venue_arena_do_gremio'
  where stadium in ('Arena do Grêmio', 'Arena do Grêmio ');
update public.passport_matches set venue_id = 'venue_adelmar_da_costa_carvalho_ilha_do_retiro'
  where stadium in ('Adelmar da Costa Carvalho (Ilha do Retiro)');
update public.passport_matches set venue_id = 'venue_estadio_dr_alfredo_de_castilho'
  where stadium in ('Estádio Dr. Alfredo de Castilho');
update public.passport_matches set venue_id = 'venue_estadio_benito_agnelo_castellano'
  where stadium in ('Estádio Benito Agnelo Castellano');
update public.passport_matches set venue_id = 'venue_estadio_polideportivo_misael_delgado'
  where stadium in ('Estadio Polideportivo Misael Delgado');
update public.passport_matches set venue_id = 'venue_arena_conda'
  where stadium in ('Arena Condá');
update public.passport_matches set venue_id = 'venue_estadio_ramon_aguilera_costas'
  where stadium in ('Estadio Ramón Aguilera Costas');
update public.passport_matches set venue_id = 'venue_estadio_monumental'
  where stadium in ('Estadio Monumental');
update public.passport_matches set venue_id = 'venue_estadio_nacional_de_lima'
  where stadium in ('Estadio Nacional de Lima');
update public.passport_matches set venue_id = 'venue_estadio_evandro_almeida'
  where stadium in ('Estádio Evandro Almeida');
