-- Quiz do Bragantino — só as 19 perguntas READY do pacote de pesquisa do
-- usuário (quiz_questions_seed_v2.json). As 3 em review_candidates
-- (NEEDS_SOURCE_RECHECK: técnico de 1990, técnico de 1991, gols do Lincom)
-- ficam de fora de propósito — não têm fonte individual anexada ainda.
--
-- `difficulty` reaproveita os MESMOS 3 códigos internos do Goiás
-- (torcedor/esmeraldino/fanatico — restrição do schema convergido) — mas
-- o texto mostrado ao jogador NÃO é mais hardcoded "Esmeraldino": o nível
-- do meio agora usa o gentílico do clube ativo (`ClubIdentity.fanDemonym`,
-- "Massa Bruta" pro Bragantino, ver `quiz_models.dart`). O código
-- 'esmeraldino' aqui é só o nome do TIER (nunca aparece pro usuário), não
-- um dado específico do Goiás.
--
-- club_id = canonicalClubId REAL do Bragantino (51683d2a-ea1d-57c6-8014-
-- 996146f242e7, mesmo valor de bragantino_club_config.dart).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.quiz_questions (id, club_id, difficulty, question, options, correct_index, sort_order) values
('bra_q_001', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Em que ano o Bragantino foi fundado?', jsonb_build_array('1928', '1931', '1949', '1965'), 0, 1),
('bra_q_003', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Qual apelido tradicional do Bragantino aparece na história do clube?', jsonb_build_array('Massa Bruta', 'Toro Loko', 'Leão do Interior', 'Pantera'), 0, 2),
('bra_q_005', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Em que ano começou a parceria do Bragantino com a Red Bull?', jsonb_build_array('2019', '2017', '2020', '2021'), 0, 3),
('bra_q_007', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Qual competição nacional o Bragantino venceu em 1989?', jsonb_build_array('Campeonato Brasileiro Série B', 'Campeonato Brasileiro Série A', 'Campeonato Brasileiro Série C', 'Copa do Brasil'), 0, 4),
('bra_q_008', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Qual título estadual o Bragantino conquistou em 1990?', jsonb_build_array('Campeonato Paulista', 'Paulista Série A2', 'Copa Paulista', 'Torneio Rio-São Paulo'), 0, 5),
('bra_q_010', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'O Bragantino foi campeão da Série B novamente em qual ano?', jsonb_build_array('2019', '2018', '2020', '2021'), 0, 6),
('bra_q_013', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Em 2021, o Red Bull Bragantino foi vice-campeão de qual torneio?', jsonb_build_array('CONMEBOL Sul-Americana', 'CONMEBOL Libertadores', 'Copa do Brasil', 'Campeonato Paulista'), 0, 7),
('bra_q_015', '51683d2a-ea1d-57c6-8014-996146f242e7', 'torcedor', 'Em qual ano o Red Bull Bragantino disputou a Libertadores mencionada no levantamento histórico?', jsonb_build_array('2022', '2020', '2021', '2023'), 0, 8),
('bra_q_002', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual é a data de fundação do Bragantino?', jsonb_build_array('8 de janeiro de 1928', '8 de janeiro de 1931', '15 de novembro de 1928', '1º de maio de 1928'), 0, 1),
('bra_q_004', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Segundo a história institucional pesquisada, desde que ano o apelido ''Massa Bruta'' remonta?', jsonb_build_array('1931', '1928', '1965', '1989'), 0, 2),
('bra_q_009', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Em que ano o Bragantino conquistou a Série C do Campeonato Brasileiro?', jsonb_build_array('2007', '2005', '2008', '2010'), 0, 3),
('bra_q_011', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Quais foram os dois anos de títulos da Série B identificados na pesquisa?', jsonb_build_array('1989 e 2019', '1990 e 2019', '1988 e 2007', '1989 e 2021'), 0, 4),
('bra_q_012', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Quais anos aparecem como títulos do Campeonato Paulista Série A2?', jsonb_build_array('1965 e 1988', '1965 e 1989', '1988 e 1990', '1964 e 1988'), 0, 5),
('bra_q_014', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual destas conquistas deve aparecer no app como campanha/vice, e não como título?', jsonb_build_array('Sul-Americana de 2021', 'Série B de 1989', 'Paulista de 1990', 'Série C de 2007'), 0, 6),
('bra_q_019', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual destes nomes pertence à geração histórica destacada de 1990-91?', jsonb_build_array('Gil Baiano', 'Ytalo', 'Artur', 'Aderlan'), 0, 7),
('bra_q_020', '51683d2a-ea1d-57c6-8014-996146f242e7', 'esmeraldino', 'Qual destes jogadores foi colocado no grupo de símbolos históricos com evidência explícita de ''ídolo''?', jsonb_build_array('Léo Jaime', 'Jadsom', 'Matheus Peixoto', 'Guilherme Mattis'), 0, 8),
('bra_q_006', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Em qual mês de 2019 foi anunciada a parceria com a Red Bull, conforme a pesquisa histórica?', jsonb_build_array('Março', 'Janeiro', 'Julho', 'Dezembro'), 0, 1),
('bra_q_016', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Qual jogador do Bragantino foi associado à Bola de Ouro da Placar de 1991 no levantamento de ídolos?', jsonb_build_array('Mauro Silva', 'Lincom', 'Claudinho', 'Léo Ortiz'), 0, 2),
('bra_q_018', '51683d2a-ea1d-57c6-8014-996146f242e7', 'fanatico', 'Qual marca de jogos Cleiton atingiu em 2025 segundo o levantamento anterior?', jsonb_build_array('300 jogos', '250 jogos', '200 jogos', '350 jogos'), 0, 3)
on conflict (id) do update set
  club_id = excluded.club_id, difficulty = excluded.difficulty, question = excluded.question,
  options = excluded.options, correct_index = excluded.correct_index, sort_order = excluded.sort_order;
