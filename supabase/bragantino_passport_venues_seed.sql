-- Catálogo de estádios do Passaporte do Bragantino + ligação das
-- partidas. GERADO por `node tooling/bragantino_passport/build_venues.mjs`
-- — não edite à mão, edite os grupos de normalização no script.
--
-- Rode no projeto Supabase do BRAGANTINO, DEPOIS de
-- `bragantino_passport_infra.sql` e dos seeds de partida.
-- Idempotente: reexecutar apenas reescreve os mesmos valores.
--
-- 149 estádios, a partir de 1084 partidas com
-- estádio confirmado na ficha (evidência MATCH_SPECIFIC).

insert into public.venues
  (id, canonical_name, display_name, city, state, country, aliases)
values
  ('venue_nabi_abi_chedid', 'Nabi Abi Chedid', 'Estádio Nabi Abi Chedid', 'Bragança Paulista', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_municipal_cicero_de_souza_marques', 'Estádio Municipal Cícero de Souza Marques', 'Estádio Cícero de Souza Marques', 'Bragança Paulista', 'SP', 'BR', '{}'::text[]),
  ('venue_serra_dourada', 'Serra Dourada', 'Serra Dourada', 'Goiânia', 'GO', 'BR', '{}'::text[]),
  ('venue_estadio_urbano_caldeira', 'Estádio Urbano Caldeira', 'Vila Belmiro', 'Santos', 'SP', 'BR', array['Urbano Caldeira (Vila Belmiro)']),
  ('venue_estadio_cicero_pompeu_de_toledo', 'Estádio Cícero Pompeu de Toledo', 'MorumBIS', 'São Paulo', 'SP', 'BR', array['Cícero Pompeu de Toledo (Morumbis)', 'MorumBIS']),
  ('venue_moises_lucarelli', 'Moisés Lucarelli', 'Moisés Lucarelli', 'Campinas', 'SP', 'BR', '{}'::text[]),
  ('venue_governador_placido_aderaldo_castelo_castelao', 'Governador Plácido Aderaldo Castelo (Castelão)', 'Castelão', 'Fortaleza', 'CE', 'BR', '{}'::text[]),
  ('venue_neo_quimica_arena', 'Neo Química Arena', 'Neo Química Arena', 'São Paulo', 'SP', 'BR', array['Neo Química Arena (Arena Corinthians)']),
  ('venue_estadio_jornalista_mario_filho', 'Estádio Jornalista Mário Filho', 'Maracanã', 'Rio de Janeiro', 'RJ', 'BR', array['Estadio Jornalista Mário Filho (Maracanã)', 'Estádio Jornalista Mário Filho (Maracanã)']),
  ('venue_nubank_parque', 'Nubank Parque', 'Nubank Parque', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_anacleto_campanella', 'Anacleto Campanella', 'Anacleto Campanella', 'São Caetano do Sul', 'SP', 'BR', '{}'::text[]),
  ('venue_santa_cruz', 'Santa Cruz', 'Estádio Santa Cruz', 'Ribeirão Preto', 'SP', 'BR', '{}'::text[]),
  ('venue_paulo_machado_de_carvalho_pacaembu', 'Paulo Machado de Carvalho (Pacaembu)', 'Paulo Machado de Carvalho (Pacaembu)', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_olimpico_nilton_santos', 'Estádio Olímpico Nilton Santos', 'Estádio Nilton Santos', 'Rio de Janeiro', 'RJ', 'BR', array['Estádio Olímpico Nilton Santos (Engenhão)']),
  ('venue_raimundo_sampaio_arena_independencia', 'Raimundo Sampaio (Arena Independência)', 'Arena Independência', 'Belo Horizonte', 'MG', 'BR', '{}'::text[]),
  ('venue_brinco_de_ouro_da_princesa', 'Brinco de Ouro da Princesa', 'Brinco de Ouro da Princesa', 'Campinas', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_vasco_da_gama', 'Estádio Vasco da Gama', 'São Januário', 'Rio de Janeiro', 'RJ', 'BR', array['Estádio São Januário', 'Estádio Vasco da Gama (São Januário)']),
  ('venue_durival_britto_e_silva_vila_capanema', 'Durival Britto e Silva (Vila Capanema)', 'Durival Britto e Silva (Vila Capanema)', 'Curitiba', 'PR', 'BR', '{}'::text[]),
  ('venue_oswaldo_teixeira_duarte_caninde', 'Oswaldo Teixeira Duarte (Canindé)', 'Canindé', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_manoel_barradas', 'Estádio Manoel Barradas', 'Barradão', 'Salvador', 'BA', 'BR', array['Manoel Barradas (Barradão)']),
  ('venue_arena_barueri', 'Arena Barueri', 'Arena Barueri', 'Barueri', 'SP', 'BR', '{}'::text[]),
  ('venue_heriberto_hulse', 'Heriberto Hülse', 'Heriberto Hülse', 'Criciúma', 'SC', 'BR', '{}'::text[]),
  ('venue_estadio_jose_maria_de_campos_maia', 'Estádio José Maria de Campos Maia', 'Estádio Maião', 'Mirassol', 'SP', 'BR', array['José Maria de Campos Maia (Maião)']),
  ('venue_maria_lamas_farache_frasqueirao', 'Maria Lamas Farache (Frasqueirão)', 'Maria Lamas Farache (Frasqueirão)', 'Natal', 'RN', 'BR', '{}'::text[]),
  ('venue_aderbal_ramos_da_silva_ressacada', 'Aderbal Ramos da Silva (Ressacada)', 'Aderbal Ramos da Silva (Ressacada)', 'Florianópolis', 'SC', 'BR', '{}'::text[]),
  ('venue_arena_joinville', 'Arena Joinville', 'Arena Joinville', 'Joinville', 'SC', 'BR', '{}'::text[]),
  ('venue_adelmar_da_costa_carvalho_ilha_do_retiro', 'Adelmar da Costa Carvalho (Ilha do Retiro)', 'Ilha do Retiro', 'Recife', 'PE', 'BR', '{}'::text[]),
  ('venue_arena_pantanal', 'Arena Pantanal', 'Arena Pantanal', 'Cuiabá', 'MT', 'BR', '{}'::text[]),
  ('venue_complexo_esportivo_cultural_octavio_mangabeira', 'Complexo Esportivo Cultural Octávio Mangabeira', 'Arena Fonte Nova', 'Salvador', 'BA', 'BR', array['Arena Fonte Nova', 'Casa de Apostas Arena Fonte Nova']),
  ('venue_estadio_joaquim_americo_guimaraes', 'Estádio Joaquim Américo Guimarães', 'Arena da Baixada', 'Curitiba', 'PR', 'BR', array['Estádio Mário Celso Petraglia', 'Estádio Mário Celso Petraglia (Arena da Baixada)']),
  ('venue_estadio_jose_pinheiro_borda', 'Estádio José Pinheiro Borda', 'Beira-Rio', 'Porto Alegre', 'RS', 'BR', array['José Pinheiro Borda (Beira-Rio)']),
  ('venue_municipal_professor_dario_rodrigues_leite', 'Municipal Professor Dario Rodrigues Leite', 'Municipal Professor Dario Rodrigues Leite', 'Guaratinguetá', 'SP', 'BR', '{}'::text[]),
  ('venue_bruno_jose_daniel', 'Bruno José Daniel', 'Bruno José Daniel', 'Santo André', 'SP', 'BR', '{}'::text[]),
  ('venue_alfredo_jaconi', 'Alfredo Jaconi', 'Alfredo Jaconi', 'Caxias do Sul', 'RS', 'BR', '{}'::text[]),
  ('venue_estadio_governador_magalhaes_pinto', 'Estádio Governador Magalhães Pinto', 'Mineirão', 'Belo Horizonte', 'MG', 'BR', array['Estádio Gov. Magalhães Pinto (Mineirão)']),
  ('venue_dr_novelli_junior', 'Dr. Novelli Júnior', 'Dr. Novelli Júnior', 'Jaú', 'SP', 'BR', '{}'::text[]),
  ('venue_cic_walter_ribeiro', 'CIC Walter Ribeiro', 'CIC Walter Ribeiro', 'Sorocaba', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_major_antonio_couto_pereira', 'Estádio Major Antônio Couto Pereira', 'Couto Pereira', 'Curitiba', 'PR', 'BR', '{}'::text[]),
  ('venue_rei_pele_trapichao', 'Rei Pelé (Trapichão)', 'Rei Pelé (Trapichão)', 'Maceió', 'AL', 'BR', '{}'::text[]),
  ('venue_orlando_scarpelli', 'Orlando Scarpelli', 'Orlando Scarpelli', 'Florianópolis', 'SC', 'BR', '{}'::text[]),
  ('venue_romildo_vitor_gomes_ferreira', 'Romildo Vitor Gomes Ferreira', 'Romildo Vitor Gomes Ferreira', 'Mogi Mirim', 'SP', 'BR', '{}'::text[]),
  ('venue_municipal_dos_amaros', 'Municipal dos Amaros', 'Municipal dos Amaros', 'Nazaré Paulista', 'SP', 'BR', '{}'::text[]),
  ('venue_prefeito_dilzon_luiz_de_melo_melao', 'Prefeito Dilzon Luiz de Melo (Melão)', 'Prefeito Dilzon Luiz de Melo (Melão)', 'Varginha', 'MG', 'BR', '{}'::text[]),
  ('venue_arena_do_gremio', 'Arena do Grêmio', 'Arena do Grêmio', 'Porto Alegre', 'RS', 'BR', '{}'::text[]),
  ('venue_estadio_municipal_primeiro_de_maio', 'Estádio Municipal Primeiro de Maio', 'Estádio Municipal Primeiro de Maio', 'São Bernardo do Campo', 'SP', 'BR', '{}'::text[]),
  ('venue_jayme_pinheiro_de_ulhoa_cintra', 'Jayme Pinheiro de Ulhoa Cintra', 'Jayme Pinheiro de Ulhoa Cintra', 'Jundiaí', 'SP', 'BR', '{}'::text[]),
  ('venue_coaracy_da_mata_fonseca_fumeirao', 'Coaracy da Mata Fonseca (Fumeirão)', 'Coaracy da Mata Fonseca (Fumeirão)', 'Arapiraca', 'AL', 'BR', '{}'::text[]),
  ('venue_arena_romeirao_mauro_sampaio', 'Arena Romeirão (Mauro Sampaio)', 'Arena Romeirão (Mauro Sampaio)', 'Juazeiro do Norte', 'CE', 'BR', '{}'::text[]),
  ('venue_gilberto_siqueira_lopes', 'Gilberto Siqueira Lopes', 'Gilberto Siqueira Lopes', 'Lins', 'SP', 'BR', '{}'::text[]),
  ('venue_sylvio_raulino_de_oliveira_cidadania', 'Sylvio Raulino de Oliveira (Cidadania)', 'Sylvio Raulino de Oliveira (Cidadania)', 'Volta Redonda', 'RJ', 'BR', '{}'::text[]),
  ('venue_passo_das_emas', 'Passo das Emas', 'Passo das Emas', 'Lucas do Rio Verde', 'MT', 'BR', '{}'::text[]),
  ('venue_haile_pinheiro_serrinha', 'Hailé Pinheiro (Serrinha)', 'Hailé Pinheiro (Serrinha)', 'Goiânia', 'GO', 'BR', '{}'::text[]),
  ('venue_arena_mrv', 'Arena MRV', 'Arena MRV', 'Belo Horizonte', 'MG', 'BR', '{}'::text[]),
  ('venue_frederico_dalmaso', 'Frederico Dalmaso', 'Frederico Dalmaso', 'Sertãozinho', 'SP', 'BR', '{}'::text[]),
  ('venue_martins_pereira', 'Martins Pereira', 'Martins Pereira', 'Guaratinguetá', 'SP', 'BR', '{}'::text[]),
  ('venue_elmo_serejo_farias_serejao', 'Elmo Serejo Farias (Serejão)', 'Elmo Serejo Farias (Serejão)', 'Taguatinga', 'DF', 'BR', '{}'::text[]),
  ('venue_joao_claudio_de_vasconcelos_machado_machadao', 'João Cláudio de Vasconcelos Machado (Machadão)', 'João Cláudio de Vasconcelos Machado (Machadão)', 'Natal', 'RN', 'BR', '{}'::text[]),
  ('venue_governador_roberto_santos_pituacu', 'Governador Roberto Santos (Pituaçu)', 'Governador Roberto Santos (Pituaçu)', 'Salvador', 'BA', 'BR', '{}'::text[]),
  ('venue_joao_lamego_netto_ipatingao', 'João Lamego Netto (Ipatingão)', 'João Lamego Netto (Ipatingão)', 'Ipatinga', 'MG', 'BR', '{}'::text[]),
  ('venue_dr_augusto_schmidt_filho_schimitao', 'Dr. Augusto Schmidt Filho (Schimitão)', 'Dr. Augusto Schmidt Filho (Schimitão)', 'Rio Claro', 'SP', 'BR', '{}'::text[]),
  ('venue_arena_conda', 'Arena Condá', 'Arena Condá', 'Chapecó', 'SC', 'BR', '{}'::text[]),
  ('venue_prefeito_jose_liberatti', 'Prefeito José Liberatti', 'Prefeito José Liberatti', 'Osasco', 'SP', 'BR', '{}'::text[]),
  ('venue_arena_pernambuco', 'Arena Pernambuco', 'Arena Pernambuco', 'São Lourenço da Mata', 'PE', 'BR', '{}'::text[]),
  ('venue_governador_joao_castelo_castelao', 'Governador João Castelo (Castelão)', 'Governador João Castelo (Castelão)', 'São Luís', 'MA', 'BR', '{}'::text[]),
  ('venue_radialista_mario_helenio_municipal_de_juiz_de_fo', 'Radialista Mario Helênio (Municipal de Juiz de Fora)', 'Radialista Mario Helênio (Municipal de Juiz de Fora)', 'Juiz de Fora', 'MG', 'BR', '{}'::text[]),
  ('venue_jose_batista_pereira_fernandes_distrital_do_inam', 'José Batista Pereira Fernandes (Distrital do Inamar)', 'Distrital do Inamar', 'Diadema', 'SP', 'BR', '{}'::text[]),
  ('venue_antonio_accioly', 'Antônio Accioly', 'Antônio Accioly', 'Goiânia', 'GO', 'BR', '{}'::text[]),
  ('venue_doutor_jorge_ismael_de_biasi_jorjao', 'Doutor Jorge Ismael de Biasi (Jorjão)', 'Estádio Jorjão', 'Novo Horizonte', 'SP', 'BR', '{}'::text[]),
  ('venue_defensores_del_chaco', 'Defensores del Chaco', 'Defensores del Chaco', 'Assunção', null, 'PY', '{}'::text[]),
  ('venue_ernesto_schlemm_sobrinho_ernestao', 'Ernesto Schlemm Sobrinho (Ernestão)', 'Ernesto Schlemm Sobrinho (Ernestão)', 'Joinville', 'SC', 'BR', '{}'::text[]),
  ('venue_palestra_italia_parque_antartica', 'Palestra Itália (Parque Antártica)', 'Palestra Itália (Parque Antártica)', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_ilie_vidal_ninho_da_aguia', 'Iliê Vidal (Ninho da Águia)', 'Iliê Vidal (Ninho da Águia)', 'Amambai', 'MS', 'BR', '{}'::text[]),
  ('venue_giulite_coutinho_edson_passos', 'Giulite Coutinho (Edson Passos)', 'Giulite Coutinho (Edson Passos)', 'Mesquita', 'RJ', 'BR', '{}'::text[]),
  ('venue_governador_ernani_satiro_o_amigao', 'Governador Ernani Sátiro (O Amigão)', 'Governador Ernani Sátiro (O Amigão)', 'Campina Grande', 'PB', 'BR', '{}'::text[]),
  ('venue_dr_alfredo_de_castilho', 'Dr. Alfredo de Castilho', 'Dr. Alfredo de Castilho', 'Bauru', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_nacional_mane_garrincha', 'Estádio Nacional Mané Garrincha', 'Estádio Nacional Mané Garrincha', 'Brasília', 'DF', 'BR', '{}'::text[]),
  ('venue_alcides_santos_pici', 'Alcides Santos (Pici)', 'Alcides Santos (Pici)', 'Fortaleza', 'CE', 'BR', '{}'::text[]),
  ('venue_estadio_esportes_da_sorte_aflitos', 'Estádio Esportes da Sorte Aflitos', 'Estádio Esportes da Sorte Aflitos', 'Recife', 'PE', 'BR', '{}'::text[]),
  ('venue_barao_da_serra_negra', 'Barão da Serra Negra', 'Barão da Serra Negra', 'Piracicaba', 'SP', 'BR', '{}'::text[]),
  ('venue_jose_nazareno_do_nascimento_nazarenao', 'José Nazareno do Nascimento (Nazarenão)', 'José Nazareno do Nascimento (Nazarenão)', 'Natal', 'RN', 'BR', '{}'::text[]),
  ('venue_presidente_vargas_pv', 'Presidente Vargas (PV)', 'Presidente Vargas (PV)', 'Fortaleza', 'CE', 'BR', '{}'::text[]),
  ('venue_olimpico_do_para_mangueirao', 'Olímpico do Pará (Mangueirão)', 'Olímpico do Pará (Mangueirão)', 'Belém', 'PA', 'BR', '{}'::text[]),
  ('venue_municipal_tenente_carrico', 'Municipal Tenente Carriço', 'Municipal Tenente Carriço', 'Penápolis', 'SP', 'BR', '{}'::text[]),
  ('venue_arena_alviazul', 'Arena Alviazul', 'Arena Alviazul', 'Lajeado', 'RS', 'BR', '{}'::text[]),
  ('venue_jose_do_rego_maciel_arruda', 'José do Rego Maciel (Arruda)', 'José do Rego Maciel (Arruda)', 'Recife', 'PE', 'BR', '{}'::text[]),
  ('venue_bento_mendes_de_freitas_bento_freitas', 'Bento Mendes de Freitas (Bento Freitas)', 'Bento Mendes de Freitas (Bento Freitas)', 'Pelotas', 'RS', 'BR', '{}'::text[]),
  ('venue_jacy_scaff_estadio_do_cafe', 'Jacy Scaff (Estádio do Café)', 'Jacy Scaff (Estádio do Café)', 'Londrina', 'PR', 'BR', '{}'::text[]),
  ('venue_antonio_guimaraes_de_almeida_almeidao', 'Antônio Guimarães de Almeida (Almeidão)', 'Antônio Guimarães de Almeida (Almeidão)', 'Cataguases', 'MG', 'BR', '{}'::text[]),
  ('venue_olimpico_colosso_da_lagoa', 'Olímpico Colosso da Lagoa', 'Olímpico Colosso da Lagoa', 'Erechim', 'RS', 'BR', '{}'::text[]),
  ('venue_arena_da_fonte_luminosa', 'Arena da Fonte Luminosa', 'Arena da Fonte Luminosa', 'Araraquara', 'SP', 'BR', '{}'::text[]),
  ('venue_major_jose_levy_sobrinho', 'Major José Levy Sobrinho', 'Major José Levy Sobrinho', 'Limeira', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_monumental_banco_pichincha', 'Estadio Monumental Banco Pichincha', 'Estadio Monumental Banco Pichincha', 'Guayaquil', null, 'EC', '{}'::text[]),
  ('venue_estadio_jorge_luis_hirschi', 'Estadio Jorge Luis Hirschi', 'Estadio Jorge Luis Hirschi', 'La Plata', 'Buenos Aires', 'AR', '{}'::text[]),
  ('venue_estadio_ramon_aguilera_costas', 'Estadio Ramón Aguilera Costas', 'Tahuichi Aguilera', 'Santa Cruz de la Sierra', null, 'BO', array['Ramón Tahuichi Aguilera']),
  ('venue_antonio_marques_da_silva_mariz_marizao', 'Antônio Marques da Silva Mariz (Marizão)', 'Marizão', 'Sousa', 'PB', 'BR', '{}'::text[]),
  ('venue_municipal_dr_jose_lancha_filho_lanchao', 'Municipal Dr. José Lancha Filho (Lanchão)', 'Municipal Dr. José Lancha Filho (Lanchão)', 'Franca', 'SP', 'BR', '{}'::text[]),
  ('venue_universitario_pedro_pedrossian_morenao', 'Universitário Pedro Pedrossian (Morenão)', 'Universitário Pedro Pedrossian (Morenão)', 'Campo Grande', 'MS', 'BR', '{}'::text[]),
  ('venue_francisco_ribeiro_nogueira_nogueirao', 'Francisco Ribeiro Nogueira (Nogueirão)', 'Francisco Ribeiro Nogueira (Nogueirão)', 'Mogi das Cruzes', 'SP', 'BR', '{}'::text[]),
  ('venue_parque_esportivo_montanha_dos_vinhedos', 'Parque Esportivo Montanha dos Vinhedos', 'Parque Esportivo Montanha dos Vinhedos', 'Bento Gonçalves', 'RS', 'BR', '{}'::text[]),
  ('venue_municipal_antonio_soares_de_oliveira', 'Municipal Antônio Soares de Oliveira', 'Municipal Antônio Soares de Oliveira', 'Guarulhos', 'SP', 'BR', '{}'::text[]),
  ('venue_bom_jesus_da_lapa', 'Bom Jesus da Lapa', 'Bom Jesus da Lapa', 'Apucarana', 'PR', 'BR', '{}'::text[]),
  ('venue_jose_mammoud_abbas_mamudao', 'José Mammoud Abbas (Mamudão)', 'José Mammoud Abbas (Mamudão)', 'Governador Valadares', 'MG', 'BR', '{}'::text[]),
  ('venue_conde_rodolfo_crespi_rua_javari', 'Conde Rodolfo Crespi (Rua Javari)', 'Conde Rodolfo Crespi (Rua Javari)', 'São Paulo', 'SP', 'BR', '{}'::text[]),
  ('venue_complexo_esportivo_da_ulbra', 'Complexo Esportivo da ULBRA', 'Complexo Esportivo da ULBRA', 'Canoas', 'RS', 'BR', '{}'::text[]),
  ('venue_genervino_evangelista_da_fonseca', 'Genervino Evangelista da Fonseca', 'Genervino Evangelista da Fonseca', 'Catalão', 'GO', 'BR', '{}'::text[]),
  ('venue_governador_alberto_tavares_da_silva_albertao', 'Governador Alberto Tavares da Silva (Albertão)', 'Governador Alberto Tavares da Silva (Albertão)', 'Teresina', 'PI', 'BR', '{}'::text[]),
  ('venue_juscelino_kubitschek', 'Juscelino Kubitschek', 'Juscelino Kubitschek', 'Itumbiara', 'GO', 'BR', '{}'::text[]),
  ('venue_otavio_mangabeira_fonte_nova', 'Otávio Mangabeira (Fonte Nova)', 'Otávio Mangabeira (Fonte Nova)', 'Salvador', 'BA', 'BR', '{}'::text[]),
  ('venue_bento_de_abreu_sampaio_vidal', 'Bento de Abreu Sampaio Vidal', 'Bento de Abreu Sampaio Vidal', 'Marília', 'SP', 'BR', '{}'::text[]),
  ('venue_paulo_constantino_prudentao', 'Paulo Constantino (Prudentão)', 'Paulo Constantino (Prudentão)', 'Presidente Prudente', 'SP', 'BR', '{}'::text[]),
  ('venue_decio_vitta', 'Décio Vitta', 'Décio Vitta', 'Guaratinguetá', 'SP', 'BR', '{}'::text[]),
  ('venue_ademir_cunha', 'Ademir Cunha', 'Ademir Cunha', 'Salgueiro', 'PE', 'BR', '{}'::text[]),
  ('venue_municipal_silvio_salles_caldeirao_da_bruxa', 'Municipal Sílvio Salles (Caldeirão da Bruxa)', 'Municipal Sílvio Salles (Caldeirão da Bruxa)', 'Catanduva', 'SP', 'BR', '{}'::text[]),
  ('venue_fernando_charbub_farah_gigante_do_itibere', 'Fernando Charbub Farah (Gigante do Itiberê)', 'Fernando Charbub Farah (Gigante do Itiberê)', 'Paranaguá', 'PR', 'BR', '{}'::text[]),
  ('venue_antonio_lins_ribeiro_guimaraes', 'Antônio Lins Ribeiro Guimarães', 'Antônio Lins Ribeiro Guimarães', 'Santa Bárbara d''Oeste', 'SP', 'BR', '{}'::text[]),
  ('venue_arena_das_dunas', 'Arena das Dunas', 'Arena das Dunas', 'Natal', 'RN', 'BR', '{}'::text[]),
  ('venue_claudio_moacyr_de_azevedo_moacyrzao', 'Cláudio Moacyr de Azevedo (Moacyrzão)', 'Cláudio Moacyr de Azevedo (Moacyrzão)', 'Macaé', 'RJ', 'BR', '{}'::text[]),
  ('venue_osvaldo_scatena', 'Osvaldo Scatena', 'Osvaldo Scatena', 'Batatais', 'SP', 'BR', '{}'::text[]),
  ('venue_luso_brasileiro', 'Luso-Brasileiro', 'Luso-Brasileiro', 'Rio de Janeiro', 'RJ', 'BR', '{}'::text[]),
  ('venue_leonidas_sodre_de_castro_curuzu', 'Leônidas Sodré de Castro (Curuzu)', 'Leônidas Sodré de Castro (Curuzu)', 'Belém', 'PA', 'BR', '{}'::text[]),
  ('venue_carlos_de_alencar_pinto_vovozao', 'Carlos de Alencar Pinto (Vovozão)', 'Carlos de Alencar Pinto (Vovozão)', 'Fortaleza', 'CE', 'BR', '{}'::text[]),
  ('venue_benito_agnelo_castellano', 'Benito Agnelo Castellano', 'Benito Agnelo Castellano', 'Rio Claro', 'SP', 'BR', '{}'::text[]),
  ('venue_carlos_colnaghi_arena_capivari', 'Carlos Colnaghi (Arena Capivari)', 'Carlos Colnaghi (Arena Capivari)', 'Capivari', 'SP', 'BR', '{}'::text[]),
  ('venue_jonas_alves_ferreira_duarte', 'Jonas Alves Ferreira Duarte', 'Jonas Alves Ferreira Duarte', 'Anápolis', 'GO', 'BR', '{}'::text[]),
  ('venue_municipal_antonio_gomes_martins_fortaleza', 'Municipal Antonio Gomes Martins (Fortaleza)', 'Municipal Antonio Gomes Martins (Fortaleza)', 'Barretos', 'SP', 'BR', '{}'::text[]),
  ('venue_anisio_haddad', 'Anísio Haddad', 'Anísio Haddad', 'São José do Rio Preto', 'SP', 'BR', '{}'::text[]),
  ('venue_joaquim_de_morais_filho_joaquinzao', 'Joaquim de Morais Filho (Joaquinzão)', 'Joaquim de Morais Filho (Joaquinzão)', 'Taubaté', 'SP', 'BR', '{}'::text[]),
  ('venue_elcyr_resende_de_mendonca', 'Elcyr Resende de Mendonça', 'Elcyr Resende de Mendonça', 'Macaé', 'RJ', 'BR', '{}'::text[]),
  ('venue_janio_moraes_laranjao', 'Jânio Moraes (Laranjão)', 'Jânio Moraes (Laranjão)', 'Nova Iguaçu', 'RJ', 'BR', '{}'::text[]),
  ('venue_germano_kruger', 'Germano Krüger', 'Germano Krüger', 'Ponta Grossa', 'PR', 'BR', '{}'::text[]),
  ('venue_olimpico_pedro_ludovico', 'Olímpico Pedro Ludovico', 'Olímpico Pedro Ludovico', 'Goiânia', 'GO', 'BR', '{}'::text[]),
  ('venue_estadio_kleber_andrade', 'Estádio Kleber Andrade', 'Estádio Kleber Andrade', 'Cariacica', 'ES', 'BR', '{}'::text[]),
  ('venue_george_capwell', 'George Capwell', 'George Capwell', 'Guayaquil', null, 'EC', '{}'::text[]),
  ('venue_mario_alberto_kempes', 'Mario Alberto Kempes', 'Mario Alberto Kempes', 'Córdoba', 'Córdoba', 'AR', '{}'::text[]),
  ('venue_pueblo_nuevo_de_san_cristobal', 'Pueblo Nuevo de San Cristóbal', 'Pueblo Nuevo de San Cristóbal', 'San Cristóbal', 'Táchira', 'VE', '{}'::text[]),
  ('venue_dr_lisandro_de_la_torre_gigante_de_arroyito', 'Dr. Lisandro de la Torre (Gigante de Arroyito)', 'Dr. Lisandro de la Torre (Gigante de Arroyito)', 'Rosario', 'Santa Fe', 'AR', '{}'::text[]),
  ('venue_centenario', 'Centenario', 'Centenario', 'Montevideo', null, 'UY', '{}'::text[]),
  ('venue_jose_amalfitani', 'José Amalfitani', 'José Amalfitani', 'Buenos Aires', 'Buenos Aires', 'AR', '{}'::text[]),
  ('venue_gran_parque_central', 'Gran Parque Central', 'Gran Parque Central', 'Montevideo', null, 'UY', '{}'::text[]),
  ('venue_professor_jodilton_souza_superbet_arena', 'Professor Jodilton Souza (Superbet Arena)', 'Professor Jodilton Souza (Superbet Arena)', 'Feira de Santana', 'BA', 'BR', '{}'::text[]),
  ('venue_francisco_sanchez_rumoroso', 'Francisco Sánchez Rumoroso', 'Francisco Sánchez Rumoroso', 'Coquimbo', null, 'CL', '{}'::text[]),
  ('venue_presidente_peron_el_cilindro', 'Presidente Perón (El Cilindro)', 'El Cilindro', 'Avellaneda', 'Buenos Aires', 'AR', '{}'::text[]),
  ('venue_atanasio_girardot', 'Atanasio Girardot', 'Atanasio Girardot', 'Medellín', null, 'CO', '{}'::text[]),
  ('venue_estadio_dr_alfredo_de_castilho', 'Estádio Dr. Alfredo de Castilho', 'Estádio Dr. Alfredo de Castilho', null, null, 'BR', '{}'::text[]),
  ('venue_estadio_benito_agnelo_castellano', 'Estádio Benito Agnelo Castellano', 'Estádio Benito Agnelo Castellano', 'Rio Claro', 'SP', 'BR', '{}'::text[]),
  ('venue_estadio_polideportivo_misael_delgado', 'Estadio Polideportivo Misael Delgado', 'Estadio Polideportivo Misael Delgado', 'Valencia', null, 'VE', '{}'::text[]),
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
update public.passport_matches set venue_id = 'venue_ernesto_schlemm_sobrinho_ernestao'
  where stadium in ('Ernesto Schlemm Sobrinho (Ernestão)');
update public.passport_matches set venue_id = 'venue_municipal_dr_jose_lancha_filho_lanchao'
  where stadium in ('Municipal Dr. José Lancha Filho (Lanchão)');
update public.passport_matches set venue_id = 'venue_paulo_machado_de_carvalho_pacaembu'
  where stadium in ('Paulo Machado de Carvalho (Pacaembu)');
update public.passport_matches set venue_id = 'venue_palestra_italia_parque_antartica'
  where stadium in ('Palestra Itália (Parque Antártica)');
update public.passport_matches set venue_id = 'venue_estadio_urbano_caldeira'
  where stadium in ('Estádio Urbano Caldeira', 'Urbano Caldeira (Vila Belmiro)');
update public.passport_matches set venue_id = 'venue_municipal_professor_dario_rodrigues_leite'
  where stadium in ('Municipal Professor Dario Rodrigues Leite');
update public.passport_matches set venue_id = 'venue_nabi_abi_chedid'
  where stadium in ('Nabi Abi Chedid');
update public.passport_matches set venue_id = 'venue_universitario_pedro_pedrossian_morenao'
  where stadium in ('Universitário Pedro Pedrossian (Morenão)');
update public.passport_matches set venue_id = 'venue_ilie_vidal_ninho_da_aguia'
  where stadium in ('Iliê Vidal (Ninho da Águia)');
update public.passport_matches set venue_id = 'venue_francisco_ribeiro_nogueira_nogueirao'
  where stadium in ('Francisco Ribeiro Nogueira (Nogueirão)');
update public.passport_matches set venue_id = 'venue_frederico_dalmaso'
  where stadium in ('Frederico Dalmaso');
update public.passport_matches set venue_id = 'venue_estadio_municipal_primeiro_de_maio'
  where stadium in ('Estádio Municipal Primeiro de Maio');
update public.passport_matches set venue_id = 'venue_parque_esportivo_montanha_dos_vinhedos'
  where stadium in ('Parque Esportivo Montanha dos Vinhedos');
update public.passport_matches set venue_id = 'venue_municipal_antonio_soares_de_oliveira'
  where stadium in ('Municipal Antônio Soares de Oliveira');
update public.passport_matches set venue_id = 'venue_bom_jesus_da_lapa'
  where stadium in ('Bom Jesus da Lapa');
update public.passport_matches set venue_id = 'venue_jose_mammoud_abbas_mamudao'
  where stadium in ('José Mammoud Abbas (Mamudão)');
update public.passport_matches set venue_id = 'venue_conde_rodolfo_crespi_rua_javari'
  where stadium in ('Conde Rodolfo Crespi (Rua Javari)');
update public.passport_matches set venue_id = 'venue_martins_pereira'
  where stadium in ('Martins Pereira');
update public.passport_matches set venue_id = 'venue_complexo_esportivo_da_ulbra'
  where stadium in ('Complexo Esportivo da ULBRA');
update public.passport_matches set venue_id = 'venue_giulite_coutinho_edson_passos'
  where stadium in ('Giulite Coutinho (Edson Passos)');
update public.passport_matches set venue_id = 'venue_genervino_evangelista_da_fonseca'
  where stadium in ('Genervino Evangelista da Fonseca');
update public.passport_matches set venue_id = 'venue_governador_alberto_tavares_da_silva_albertao'
  where stadium in ('Governador Alberto Tavares da Silva (Albertão)');
update public.passport_matches set venue_id = 'venue_juscelino_kubitschek'
  where stadium in ('Juscelino Kubitschek');
update public.passport_matches set venue_id = 'venue_otavio_mangabeira_fonte_nova'
  where stadium in ('Otávio Mangabeira (Fonte Nova)');
update public.passport_matches set venue_id = 'venue_serra_dourada'
  where stadium in ('Serra Dourada');
update public.passport_matches set venue_id = 'venue_governador_ernani_satiro_o_amigao'
  where stadium in ('Governador Ernani Sátiro (O Amigão)');
update public.passport_matches set venue_id = 'venue_maria_lamas_farache_frasqueirao'
  where stadium in ('Maria Lamas Farache (Frasqueirão)');
update public.passport_matches set venue_id = 'venue_brinco_de_ouro_da_princesa'
  where stadium in ('Brinco de Ouro da Princesa');
update public.passport_matches set venue_id = 'venue_dr_alfredo_de_castilho'
  where stadium in ('Dr. Alfredo de Castilho');
update public.passport_matches set venue_id = 'venue_estadio_cicero_pompeu_de_toledo'
  where stadium in ('Cícero Pompeu de Toledo (Morumbis)', 'MorumBIS');
update public.passport_matches set venue_id = 'venue_arena_barueri'
  where stadium in ('Arena Barueri');
update public.passport_matches set venue_id = 'venue_anacleto_campanella'
  where stadium in ('Anacleto Campanella');
update public.passport_matches set venue_id = 'venue_estadio_vasco_da_gama'
  where stadium in ('Estádio São Januário', 'Estádio Vasco da Gama (São Januário)');
update public.passport_matches set venue_id = 'venue_jayme_pinheiro_de_ulhoa_cintra'
  where stadium in ('Jayme Pinheiro de Ulhoa Cintra');
update public.passport_matches set venue_id = 'venue_moises_lucarelli'
  where stadium in ('Moisés Lucarelli');
update public.passport_matches set venue_id = 'venue_bento_de_abreu_sampaio_vidal'
  where stadium in ('Bento de Abreu Sampaio Vidal');
update public.passport_matches set venue_id = 'venue_estadio_nacional_mane_garrincha'
  where stadium in ('Estádio Nacional Mané Garrincha');
update public.passport_matches set venue_id = 'venue_aderbal_ramos_da_silva_ressacada'
  where stadium in ('Aderbal Ramos da Silva (Ressacada)');
update public.passport_matches set venue_id = 'venue_alcides_santos_pici'
  where stadium in ('Alcides Santos (Pici)');
update public.passport_matches set venue_id = 'venue_bruno_jose_daniel'
  where stadium in ('Bruno José Daniel');
update public.passport_matches set venue_id = 'venue_alfredo_jaconi'
  where stadium in ('Alfredo Jaconi');
update public.passport_matches set venue_id = 'venue_rei_pele_trapichao'
  where stadium in ('Rei Pelé (Trapichão)');
update public.passport_matches set venue_id = 'venue_elmo_serejo_farias_serejao'
  where stadium in ('Elmo Serejo Farias (Serejão)');
update public.passport_matches set venue_id = 'venue_heriberto_hulse'
  where stadium in ('Heriberto Hülse');
update public.passport_matches set venue_id = 'venue_governador_placido_aderaldo_castelo_castelao'
  where stadium in ('Governador Plácido Aderaldo Castelo (Castelão)');
update public.passport_matches set venue_id = 'venue_joao_claudio_de_vasconcelos_machado_machadao'
  where stadium in ('João Cláudio de Vasconcelos Machado (Machadão)');
update public.passport_matches set venue_id = 'venue_governador_roberto_santos_pituacu'
  where stadium in ('Governador Roberto Santos (Pituaçu)');
update public.passport_matches set venue_id = 'venue_durival_britto_e_silva_vila_capanema'
  where stadium in ('Durival Britto e Silva (Vila Capanema)');
update public.passport_matches set venue_id = 'venue_joao_lamego_netto_ipatingao'
  where stadium in ('João Lamego Netto (Ipatingão)');
update public.passport_matches set venue_id = 'venue_oswaldo_teixeira_duarte_caninde'
  where stadium in ('Oswaldo Teixeira Duarte (Canindé)');
update public.passport_matches set venue_id = 'venue_orlando_scarpelli'
  where stadium in ('Orlando Scarpelli');
update public.passport_matches set venue_id = 'venue_romildo_vitor_gomes_ferreira'
  where stadium in ('Romildo Vitor Gomes Ferreira');
update public.passport_matches set venue_id = 'venue_dr_augusto_schmidt_filho_schimitao'
  where stadium in ('Dr. Augusto Schmidt Filho (Schimitão)');
update public.passport_matches set venue_id = 'venue_estadio_jose_maria_de_campos_maia'
  where stadium in ('Estádio José Maria de Campos Maia', 'José Maria de Campos Maia (Maião)');
update public.passport_matches set venue_id = 'venue_estadio_governador_magalhaes_pinto'
  where stadium in ('Estádio Gov. Magalhães Pinto (Mineirão)', 'Estádio Governador Magalhães Pinto');
update public.passport_matches set venue_id = 'venue_estadio_esportes_da_sorte_aflitos'
  where stadium in ('Estádio Esportes da Sorte Aflitos');
update public.passport_matches set venue_id = 'venue_arena_joinville'
  where stadium in ('Arena Joinville');
update public.passport_matches set venue_id = 'venue_estadio_olimpico_nilton_santos'
  where stadium in ('Estádio Olímpico Nilton Santos', 'Estádio Olímpico Nilton Santos (Engenhão)');
update public.passport_matches set venue_id = 'venue_coaracy_da_mata_fonseca_fumeirao'
  where stadium in ('Coaracy da Mata Fonseca (Fumeirão)');
update public.passport_matches set venue_id = 'venue_adelmar_da_costa_carvalho_ilha_do_retiro'
  where stadium in ('Adelmar da Costa Carvalho (Ilha do Retiro)');
update public.passport_matches set venue_id = 'venue_arena_romeirao_mauro_sampaio'
  where stadium in ('Arena Romeirão (Mauro Sampaio)');
update public.passport_matches set venue_id = 'venue_santa_cruz'
  where stadium in ('Santa Cruz');
update public.passport_matches set venue_id = 'venue_paulo_constantino_prudentao'
  where stadium in ('Paulo Constantino (Prudentão)');
update public.passport_matches set venue_id = 'venue_municipal_dos_amaros'
  where stadium in ('Municipal dos Amaros');
update public.passport_matches set venue_id = 'venue_gilberto_siqueira_lopes'
  where stadium in ('Gilberto Siqueira Lopes');
update public.passport_matches set venue_id = 'venue_estadio_manoel_barradas'
  where stadium in ('Estádio Manoel Barradas', 'Manoel Barradas (Barradão)');
update public.passport_matches set venue_id = 'venue_decio_vitta'
  where stadium in ('Décio Vitta');
update public.passport_matches set venue_id = 'venue_prefeito_dilzon_luiz_de_melo_melao'
  where stadium in ('Prefeito Dilzon Luiz de Melo (Melão)');
update public.passport_matches set venue_id = 'venue_sylvio_raulino_de_oliveira_cidadania'
  where stadium in ('Sylvio Raulino de Oliveira (Cidadania)');
update public.passport_matches set venue_id = 'venue_ademir_cunha'
  where stadium in ('Ademir Cunha');
update public.passport_matches set venue_id = 'venue_barao_da_serra_negra'
  where stadium in ('Barão da Serra Negra');
update public.passport_matches set venue_id = 'venue_dr_novelli_junior'
  where stadium in ('Dr. Novelli Júnior');
update public.passport_matches set venue_id = 'venue_municipal_silvio_salles_caldeirao_da_bruxa'
  where stadium in ('Municipal Sílvio Salles (Caldeirão da Bruxa)');
update public.passport_matches set venue_id = 'venue_jose_nazareno_do_nascimento_nazarenao'
  where stadium in ('José Nazareno do Nascimento (Nazarenão)');
update public.passport_matches set venue_id = 'venue_raimundo_sampaio_arena_independencia'
  where stadium in ('Raimundo Sampaio (Arena Independência)');
update public.passport_matches set venue_id = 'venue_fernando_charbub_farah_gigante_do_itibere'
  where stadium in ('Fernando Charbub Farah (Gigante do Itiberê)');
update public.passport_matches set venue_id = 'venue_presidente_vargas_pv'
  where stadium in ('Presidente Vargas (PV)');
update public.passport_matches set venue_id = 'venue_antonio_lins_ribeiro_guimaraes'
  where stadium in ('Antônio Lins Ribeiro Guimarães');
update public.passport_matches set venue_id = 'venue_arena_conda'
  where stadium in ('Arena Condá');
update public.passport_matches set venue_id = 'venue_olimpico_do_para_mangueirao'
  where stadium in ('Olímpico do Pará (Mangueirão)');
update public.passport_matches set venue_id = 'venue_municipal_tenente_carrico'
  where stadium in ('Municipal Tenente Carriço');
update public.passport_matches set venue_id = 'venue_prefeito_jose_liberatti'
  where stadium in ('Prefeito José Liberatti');
update public.passport_matches set venue_id = 'venue_arena_alviazul'
  where stadium in ('Arena Alviazul');
update public.passport_matches set venue_id = 'venue_passo_das_emas'
  where stadium in ('Passo das Emas');
update public.passport_matches set venue_id = 'venue_arena_das_dunas'
  where stadium in ('Arena das Dunas');
update public.passport_matches set venue_id = 'venue_arena_pantanal'
  where stadium in ('Arena Pantanal');
update public.passport_matches set venue_id = 'venue_neo_quimica_arena'
  where stadium in ('Neo Química Arena', 'Neo Química Arena (Arena Corinthians)');
update public.passport_matches set venue_id = 'venue_arena_pernambuco'
  where stadium in ('Arena Pernambuco');
update public.passport_matches set venue_id = 'venue_jose_do_rego_maciel_arruda'
  where stadium in ('José do Rego Maciel (Arruda)');
update public.passport_matches set venue_id = 'venue_governador_joao_castelo_castelao'
  where stadium in ('Governador João Castelo (Castelão)');
update public.passport_matches set venue_id = 'venue_nubank_parque'
  where stadium in ('Nubank Parque');
update public.passport_matches set venue_id = 'venue_cic_walter_ribeiro'
  where stadium in ('CIC Walter Ribeiro');
update public.passport_matches set venue_id = 'venue_claudio_moacyr_de_azevedo_moacyrzao'
  where stadium in ('Cláudio Moacyr de Azevedo (Moacyrzão)');
update public.passport_matches set venue_id = 'venue_complexo_esportivo_cultural_octavio_mangabeira'
  where stadium in ('Arena Fonte Nova', 'Casa de Apostas Arena Fonte Nova');
update public.passport_matches set venue_id = 'venue_osvaldo_scatena'
  where stadium in ('Osvaldo Scatena');
update public.passport_matches set venue_id = 'venue_bento_mendes_de_freitas_bento_freitas'
  where stadium in ('Bento Mendes de Freitas (Bento Freitas)');
update public.passport_matches set venue_id = 'venue_luso_brasileiro'
  where stadium in ('Luso-Brasileiro');
update public.passport_matches set venue_id = 'venue_jacy_scaff_estadio_do_cafe'
  where stadium in ('Jacy Scaff (Estádio do Café)');
update public.passport_matches set venue_id = 'venue_radialista_mario_helenio_municipal_de_juiz_de_fo'
  where stadium in ('Radialista Mario Helênio (Municipal de Juiz de Fora)');
update public.passport_matches set venue_id = 'venue_leonidas_sodre_de_castro_curuzu'
  where stadium in ('Leônidas Sodré de Castro (Curuzu)');
update public.passport_matches set venue_id = 'venue_carlos_de_alencar_pinto_vovozao'
  where stadium in ('Carlos de Alencar Pinto (Vovozão)');
update public.passport_matches set venue_id = 'venue_benito_agnelo_castellano'
  where stadium in ('Benito Agnelo Castellano');
update public.passport_matches set venue_id = 'venue_carlos_colnaghi_arena_capivari'
  where stadium in ('Carlos Colnaghi (Arena Capivari)');
update public.passport_matches set venue_id = 'venue_jonas_alves_ferreira_duarte'
  where stadium in ('Jonas Alves Ferreira Duarte');
update public.passport_matches set venue_id = 'venue_municipal_antonio_gomes_martins_fortaleza'
  where stadium in ('Municipal Antonio Gomes Martins (Fortaleza)');
update public.passport_matches set venue_id = 'venue_anisio_haddad'
  where stadium in ('Anísio Haddad');
update public.passport_matches set venue_id = 'venue_joaquim_de_morais_filho_joaquinzao'
  where stadium in ('Joaquim de Morais Filho (Joaquinzão)');
update public.passport_matches set venue_id = 'venue_jose_batista_pereira_fernandes_distrital_do_inam'
  where stadium in ('José Batista Pereira Fernandes (Distrital do Inamar)');
update public.passport_matches set venue_id = 'venue_elcyr_resende_de_mendonca'
  where stadium in ('Elcyr Resende de Mendonça');
update public.passport_matches set venue_id = 'venue_antonio_guimaraes_de_almeida_almeidao'
  where stadium in ('Antônio Guimarães de Almeida (Almeidão)');
update public.passport_matches set venue_id = 'venue_olimpico_colosso_da_lagoa'
  where stadium in ('Olímpico Colosso da Lagoa');
update public.passport_matches set venue_id = 'venue_janio_moraes_laranjao'
  where stadium in ('Jânio Moraes (Laranjão)');
update public.passport_matches set venue_id = 'venue_arena_da_fonte_luminosa'
  where stadium in ('Arena da Fonte Luminosa');
update public.passport_matches set venue_id = 'venue_antonio_accioly'
  where stadium in ('Antônio Accioly');
update public.passport_matches set venue_id = 'venue_germano_kruger'
  where stadium in ('Germano Krüger');
update public.passport_matches set venue_id = 'venue_estadio_major_antonio_couto_pereira'
  where stadium in ('Estádio Major Antônio Couto Pereira');
update public.passport_matches set venue_id = 'venue_doutor_jorge_ismael_de_biasi_jorjao'
  where stadium in ('Doutor Jorge Ismael de Biasi (Jorjão)');
update public.passport_matches set venue_id = 'venue_estadio_joaquim_americo_guimaraes'
  where stadium in ('Estádio Mário Celso Petraglia', 'Estádio Mário Celso Petraglia (Arena da Baixada)');
update public.passport_matches set venue_id = 'venue_olimpico_pedro_ludovico'
  where stadium in ('Olímpico Pedro Ludovico');
update public.passport_matches set venue_id = 'venue_estadio_jornalista_mario_filho'
  where stadium in ('Estadio Jornalista Mário Filho (Maracanã)', 'Estádio Jornalista Mário Filho (Maracanã)');
update public.passport_matches set venue_id = 'venue_arena_do_gremio'
  where stadium in ('Arena do Grêmio', 'Arena do Grêmio ');
update public.passport_matches set venue_id = 'venue_estadio_jose_pinheiro_borda'
  where stadium in ('Estádio José Pinheiro Borda', 'José Pinheiro Borda (Beira-Rio)');
update public.passport_matches set venue_id = 'venue_haile_pinheiro_serrinha'
  where stadium in ('Hailé Pinheiro (Serrinha)');
update public.passport_matches set venue_id = 'venue_estadio_kleber_andrade'
  where stadium in ('Estádio Kleber Andrade');
update public.passport_matches set venue_id = 'venue_major_jose_levy_sobrinho'
  where stadium in ('Major José Levy Sobrinho');
update public.passport_matches set venue_id = 'venue_george_capwell'
  where stadium in ('George Capwell');
update public.passport_matches set venue_id = 'venue_mario_alberto_kempes'
  where stadium in ('Mario Alberto Kempes');
update public.passport_matches set venue_id = 'venue_pueblo_nuevo_de_san_cristobal'
  where stadium in ('Pueblo Nuevo de San Cristóbal');
update public.passport_matches set venue_id = 'venue_estadio_monumental_banco_pichincha'
  where stadium in ('Estadio Monumental Banco Pichincha');
update public.passport_matches set venue_id = 'venue_dr_lisandro_de_la_torre_gigante_de_arroyito'
  where stadium in ('Dr. Lisandro de la Torre (Gigante de Arroyito)');
update public.passport_matches set venue_id = 'venue_defensores_del_chaco'
  where stadium in ('Defensores del Chaco');
update public.passport_matches set venue_id = 'venue_centenario'
  where stadium in ('Centenario');
update public.passport_matches set venue_id = 'venue_jose_amalfitani'
  where stadium in ('José Amalfitani');
update public.passport_matches set venue_id = 'venue_estadio_jorge_luis_hirschi'
  where stadium in ('Estadio Jorge Luis Hirschi');
update public.passport_matches set venue_id = 'venue_gran_parque_central'
  where stadium in ('Gran Parque Central');
update public.passport_matches set venue_id = 'venue_professor_jodilton_souza_superbet_arena'
  where stadium in ('Professor Jodilton Souza (Superbet Arena)');
update public.passport_matches set venue_id = 'venue_estadio_ramon_aguilera_costas'
  where stadium in ('Estadio Ramón Aguilera Costas', 'Ramón Tahuichi Aguilera');
update public.passport_matches set venue_id = 'venue_arena_mrv'
  where stadium in ('Arena MRV');
update public.passport_matches set venue_id = 'venue_antonio_marques_da_silva_mariz_marizao'
  where stadium in ('Antônio Marques da Silva Mariz (Marizão)');
update public.passport_matches set venue_id = 'venue_francisco_sanchez_rumoroso'
  where stadium in ('Francisco Sánchez Rumoroso');
update public.passport_matches set venue_id = 'venue_presidente_peron_el_cilindro'
  where stadium in ('Presidente Perón (El Cilindro)');
update public.passport_matches set venue_id = 'venue_atanasio_girardot'
  where stadium in ('Atanasio Girardot');
update public.passport_matches set venue_id = 'venue_estadio_municipal_cicero_de_souza_marques'
  where stadium in ('Estádio Municipal Cícero de Souza Marques');
update public.passport_matches set venue_id = 'venue_estadio_dr_alfredo_de_castilho'
  where stadium in ('Estádio Dr. Alfredo de Castilho');
update public.passport_matches set venue_id = 'venue_estadio_benito_agnelo_castellano'
  where stadium in ('Estádio Benito Agnelo Castellano');
update public.passport_matches set venue_id = 'venue_estadio_polideportivo_misael_delgado'
  where stadium in ('Estadio Polideportivo Misael Delgado');
update public.passport_matches set venue_id = 'venue_estadio_monumental'
  where stadium in ('Estadio Monumental');
update public.passport_matches set venue_id = 'venue_estadio_nacional_de_lima'
  where stadium in ('Estadio Nacional de Lima');
update public.passport_matches set venue_id = 'venue_estadio_evandro_almeida'
  where stadium in ('Estádio Evandro Almeida');
