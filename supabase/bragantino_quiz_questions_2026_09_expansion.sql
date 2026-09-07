-- Quiz do Bragantino — expansão com as 25 perguntas READY novas do pacote
-- `docs/bragantino_data/data/quiz_questions_seed_v3.json` (44 READY ao
-- todo; as outras 19 já estão em supabase/bragantino_quiz_questions.sql,
-- byte-idênticas, confirmado por diff antes de gerar este arquivo).
--
-- bra_q_017 (gols do Lincom, opção correta "73") fica de FORA de propósito
-- mesmo com o conflito do Lincom resolvido (160/72) — o `correct_index`
-- dessa pergunta aponta pro número ERRADO/disputado, não é mais "fonte
-- pendente", é uma pergunta com resposta incorreta. As 2 perguntas de
-- técnico (1990/1991) também ficam de fora — continuam em
-- `review_candidates`, `NEEDS_SOURCE_RECHECK`.
--
-- Mesmo mapeamento de dificuldade já usado no arquivo anterior:
-- EASY->torcedor, MEDIUM->esmeraldino (nome do tier, nunca mostrado ao
-- usuário), HARD->fanatico. `sort_order` continua a partir do maior já
-- usado por tier no arquivo anterior (torcedor até 8, esmeraldino até 8,
-- fanatico até 3).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj), depois de bragantino_quiz_questions.sql.

insert into public.quiz_questions (id, club_id, difficulty, question, options, correct_index, sort_order) values
('bra_q_021', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Qual estádio passou a ser a casa provisória do Red Bull Bragantino em 2025?', jsonb_build_array('Estádio Municipal Cícero de Souza Marques', 'Morumbi', 'Canindé', 'Arena Barueri'), 0, 9),
('bra_q_027', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Quem treinava o Bragantino nas finais da Série B de 1989?', jsonb_build_array('Vanderlei Luxemburgo', 'Carlos Alberto Parreira', 'Marcelo Veiga', 'Maurício Barbieri'), 0, 10),
('bra_q_028', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Quem treinava o Bragantino na final do Brasileirão de 1991?', jsonb_build_array('Carlos Alberto Parreira', 'Vanderlei Luxemburgo', 'Antônio Carlos Zago', 'Pedro Caixinha'), 0, 11),
('bra_q_031', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Quem foi o adversário do Bragantino na final do Paulista de 1990?', jsonb_build_array('Novorizontino', 'São Paulo', 'Palmeiras', 'Guarani'), 0, 12),
('bra_q_032', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Quem foi o adversário do Bragantino na final do Brasileiro de 1991?', jsonb_build_array('São Paulo', 'Corinthians', 'Santos', 'Flamengo'), 0, 13),
('bra_q_035', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Qual jogador foi contratado em setembro de 2026 com vínculo até agosto de 2031?', jsonb_build_array('Wallace Yan', 'Fernando', 'Pedro Henrique', 'Vinicinho'), 0, 14),
('bra_q_022', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual é a capacidade informada para o Estádio Municipal Cícero de Souza Marques?', jsonb_build_array('12 mil pessoas', '18 mil pessoas', '20 mil pessoas', '8 mil pessoas'), 0, 9),
('bra_q_025', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual foi o último adversário do Braga no Nabi Abi Chedid em abril de 2025?', jsonb_build_array('Cruzeiro', 'Corinthians', 'São Paulo', 'Santos'), 0, 10),
('bra_q_026', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual foi o placar do último jogo do Braga no Nabi Abi Chedid?', jsonb_build_array('1 a 0', '2 a 0', '1 a 1', '3 a 1'), 0, 11),
('bra_q_029', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Quem treinava o Red Bull Bragantino na final da Sul-Americana de 2021?', jsonb_build_array('Maurício Barbieri', 'Pedro Caixinha', 'Antônio Carlos Zago', 'Vagner Mancini'), 0, 12),
('bra_q_030', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Em qual estádio foi disputada a final da Sul-Americana de 2021?', jsonb_build_array('Estádio Centenário, Montevidéu', 'Maracanã', 'Morumbi', 'Defensores del Chaco'), 0, 13),
('bra_q_033', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual goleiro aparece nas finais históricas de 1989, 1990 e 1991?', jsonb_build_array('Marcelo', 'Cleiton', 'Gleguer', 'Júlio César'), 0, 14),
('bra_q_034', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual jogador aparece nas equipes históricas e é vencedor da Bola de Ouro Placar de 1991?', jsonb_build_array('Mauro Silva', 'Gil Baiano', 'Ivair', 'Biro-Biro'), 0, 15),
('bra_q_036', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Até quando Fernando renovou seu contrato com o Braga em setembro de 2026?', jsonb_build_array('31 de dezembro de 2028', '31 de dezembro de 2027', 'agosto de 2031', 'dezembro de 2029'), 0, 16),
('bra_q_039', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Para qual clube Pedro Henrique foi vendido em setembro de 2026?', jsonb_build_array('Al Ettifaq', 'Al Hilal', 'Al Nassr', 'Al Ittihad'), 0, 17),
('bra_q_041', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual fornecedora de material esportivo veste o Red Bull Bragantino em 2026?', jsonb_build_array('PUMA', 'Nike', 'Adidas', 'New Balance'), 0, 18),
('bra_q_042', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual marca aparece como patrocinadora premium do clube em 2026?', jsonb_build_array('Farmina / N&D', 'Curaprox', 'KNN Idiomas', 'PUMA'), 0, 19),
('bra_q_043', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual patrocinadora está ligada às categorias de base em 2026?', jsonb_build_array('Curaprox', 'Al Ettifaq', 'BDO', 'CONMEBOL'), 0, 20),
('bra_q_044', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual empresa entrou como patrocinadora da base e do futebol feminino em setembro de 2026?', jsonb_build_array('KNN Idiomas', 'Farmina', 'PUMA', 'Betfast'), 0, 21),
('bra_q_023', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Quantos camarotes possui o Cícero de Souza Marques após a reforma?', jsonb_build_array('35', '14', '25', '20'), 0, 4),
('bra_q_024', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Quantas cabines de transmissão possui o Cícero de Souza Marques?', jsonb_build_array('14', '35', '12', '25'), 0, 5),
('bra_q_037', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Quantos jogos Fernando tinha pelo Braga no anúncio de renovação de 3/9/2026?', jsonb_build_array('44', '54', '34', '64'), 0, 6),
('bra_q_038', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Quantos gols Fernando tinha pelo Braga no anúncio da renovação?', jsonb_build_array('7', '9', '11', '5'), 0, 7),
('bra_q_040', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Quantos jogos Pedro Henrique somava pelo Braga, contando também a passagem de 2015, ao ser vendido?', jsonb_build_array('115', '105', '125', '95'), 0, 8),
('bra_q_045', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Qual foi a receita líquida auditada do clube em 2025?', jsonb_build_array('R$ 499,199 milhões', 'R$ 31,773 milhões', 'R$ 912,658 milhões', 'R$ 140,283 milhões'), 0, 9)
on conflict (id) do update set
  club_id = excluded.club_id, difficulty = excluded.difficulty, question = excluded.question,
  options = excluded.options, correct_index = excluded.correct_index, sort_order = excluded.sort_order;
