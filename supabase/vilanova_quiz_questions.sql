-- Quiz do Vila Nova (quiz_questions).
-- GERADO por `node tooling/vilanova_content/generate_seed_sql.mjs` a partir de
-- docs/vila_nova_data/arena/quiz.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do
-- Bragantino (a trava abaixo para se não for). Idempotente.
--
-- 45 perguntas READY (torcedor 13, esmeraldino 20, fanatico 12).
-- difficulty usa os códigos internos do schema; o texto mostrado ao jogador
-- usa o gentílico do clube ativo ("Colorado"), nunca "Esmeraldino".

do $$
begin
  if not exists (select 1 from public.clubs where id = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e' and slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.quiz_questions (id, club_id, difficulty, question, options, correct_index, sort_order) values
  ('vn_q_001', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Em que ano o Vila Nova Futebol Clube foi fundado?', jsonb_build_array('1940', '1943', '1946', '1950'), 1, 1),
  ('vn_q_002', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Em qual cidade o Vila Nova foi fundado?', jsonb_build_array('Anápolis', 'Goiânia', 'Aparecida de Goiânia', 'Catalão'), 1, 2),
  ('vn_q_003', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual é a data oficial de fundação do Vila Nova?', jsonb_build_array('29 de julho de 1943', '1º de janeiro de 1943', '13 de março de 1943', '17 de dezembro de 1943'), 0, 1),
  ('vn_q_004', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual associação comunitária está ligada à origem do Vila Nova?', jsonb_build_array('Associação Mariana', 'Associação Comercial', 'Liga Operária Central', 'União Ferroviária'), 0, 2),
  ('vn_q_005', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Em que ano foi criada a Associação Mariana ligada às origens do clube?', jsonb_build_array('1935', '1938', '1941', '1943'), 1, 3),
  ('vn_q_006', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual religioso é citado na história oficial como liderança nas origens do clube?', jsonb_build_array('Padre José Balestiere', 'Padre Pelágio', 'Dom Fernando Gomes', 'Padre Zezinho'), 0, 4),
  ('vn_q_007', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Qual apelido é usado institucionalmente pelo Vila Nova?', jsonb_build_array('Dragão', 'Tigrão', 'Esmeraldino', 'Leão'), 1, 3),
  ('vn_q_008', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Quais são as cores tradicionais do Vila Nova?', jsonb_build_array('Azul e branco', 'Verde e branco', 'Vermelho e branco', 'Preto e amarelo'), 2, 4),
  ('vn_q_009', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Qual é o estádio atual do Vila Nova?', jsonb_build_array('Serra Dourada', 'Antônio Accioly', 'OBA', 'Jonas Duarte'), 2, 5),
  ('vn_q_010', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'O que significa a sigla OBA no estádio do Vila Nova?', jsonb_build_array('Onésio Brasileiro Alvarenga', 'Olímpico Brasiliense Atlético', 'Orlando Batista Alves', 'Operário Brasileiro Associado'), 0, 5),
  ('vn_q_011', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual capacidade o site oficial informa atualmente para o OBA após reavaliação?', jsonb_build_array('8.000', '10.000', '11.788', '15.000'), 1, 6),
  ('vn_q_012', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Para qual capacidade o OBA havia sido ampliado em 2016 antes da reavaliação para 10 mil?', jsonb_build_array('9.500', '10.500', '11.788', '12.500'), 2, 1),
  ('vn_q_013', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Como se chama o centro de treinamento do Vila Nova?', jsonb_build_array('Vila do Tigre', 'Toca do Tigre', 'CT Colorado', 'Casa do Tigrão'), 0, 6),
  ('vn_q_014', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Quantos campos o site oficial informa que existem no CT Vila do Tigre?', jsonb_build_array('3', '4', '5', '6'), 2, 7),
  ('vn_q_015', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Em que ano o profissional passou a treinar integralmente no CT?', jsonb_build_array('2021', '2022', '2023', '2024'), 3, 8),
  ('vn_q_016', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Em que ano o Vila conquistou seu primeiro Campeonato Goiano?', jsonb_build_array('1958', '1961', '1963', '1969'), 1, 7),
  ('vn_q_017', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Quantos Campeonatos Goianos o Vila lista após o título de 2025?', jsonb_build_array('14', '15', '16', '17'), 2, 8),
  ('vn_q_018', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Em que ano o Vila conquistou seu 16º Campeonato Goiano?', jsonb_build_array('2001', '2005', '2015', '2025'), 3, 9),
  ('vn_q_019', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Quantos títulos nacionais da Série C/Terceira Divisão o Vila lista?', jsonb_build_array('1', '2', '3', '4'), 2, 10),
  ('vn_q_020', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual foi o primeiro ano em que o Vila venceu a Série C/Terceira Divisão?', jsonb_build_array('1993', '1995', '1996', '2000'), 2, 9),
  ('vn_q_021', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual destas temporadas de Série C foi conquistada pelo Vila?', jsonb_build_array('2013', '2014', '2015', '2016'), 2, 10),
  ('vn_q_022', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual destas temporadas também terminou com título da Série C do Vila?', jsonb_build_array('2018', '2019', '2020', '2021'), 2, 11),
  ('vn_q_023', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Qual título nacional do Vila é descrito no acervo como conquistado de forma invicta?', jsonb_build_array('Série C de 1996', 'Série C de 2015', 'Série C de 2020', 'Copa Verde de 2024'), 0, 2),
  ('vn_q_024', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Quantas Copas Goiás o acervo oficial lista para o Vila?', jsonb_build_array('1', '2', '3', '4'), 2, 12),
  ('vn_q_025', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Qual destes anos aparece entre os títulos da Copa Goiás do Vila?', jsonb_build_array('1968', '1969', '1970', '1972'), 1, 3),
  ('vn_q_026', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Quantas Copas Leonino Caiado o Vila lista?', jsonb_build_array('1', '2', '3', '4'), 2, 13),
  ('vn_q_027', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Qual destes anos é listado como título da Copa Leonino Caiado?', jsonb_build_array('1978', '1979', '1980', '1982'), 1, 4),
  ('vn_q_028', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Quantas Taças Cidade de Goiânia o Vila lista?', jsonb_build_array('2', '3', '4', '5'), 1, 14),
  ('vn_q_029', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Em que ano o Vila conquistou a Taça Goiás listada no acervo oficial?', jsonb_build_array('1963', '1964', '1966', '1969'), 2, 5),
  ('vn_q_030', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Em quais anos o Vila conquistou a Segunda Divisão Goiana segundo o acervo oficial?', jsonb_build_array('1996 e 2000', '2000 e 2015', '2005 e 2015', '2015 e 2020'), 1, 6),
  ('vn_q_031', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Qual é o nome oficial do programa de sócio-torcedor?', jsonb_build_array('Sócio Colorado', 'Sócio Tigrão', 'Nação Vila', 'Tigre Mais'), 1, 11),
  ('vn_q_032', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Qual é o nome usado pela loja oficial do clube?', jsonb_build_array('Nação Colorada', 'Loja do Tigre', 'Vila Store', 'Tigrão Shop'), 0, 12),
  ('vn_q_033', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual sequência corresponde ao tetracampeonato goiano consecutivo do Vila?', jsonb_build_array('1961–1964', '1969–1972', '1977–1980', '1982–1985'), 2, 15),
  ('vn_q_034', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual nome o clube passou a usar em 1946?', jsonb_build_array('Operário', 'Araguaia', 'Fênix', 'Colorado'), 0, 16),
  ('vn_q_035', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Qual destes anos NÃO corresponde a um título nacional da Série C/Terceira Divisão do Vila?', jsonb_build_array('1996', '2015', '2019', '2020'), 2, 7),
  ('vn_q_036', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Em quais anos o Vila conquistou a Copa Goiás segundo o acervo oficial?', jsonb_build_array('1961, 1962 e 1963', '1969, 1971 e 1976', '1977, 1979 e 1981', '1966, 1972 e 1973'), 1, 17),
  ('vn_q_037', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'torcedor', 'Quantos títulos da Segunda Divisão Goiana o acervo oficial lista para o Vila?', jsonb_build_array('1', '2', '3', '4'), 1, 13),
  ('vn_q_038', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Na Série B 2026, qual foi o placar do clássico Vila Nova x Goiás no OBA?', jsonb_build_array('1–0', '2–0', '2–1', '3–0'), 1, 18),
  ('vn_q_039', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Qual adversário o Vila venceu por 6–0 na Série B 2026?', jsonb_build_array('CRB', 'Ponte Preta', 'Náutico', 'Ceará'), 1, 19),
  ('vn_q_040', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Qual foi o placar de Vila Nova x CRB na 1ª rodada da Série B 2026?', jsonb_build_array('1–0', '1–1', '2–1', '2–2'), 3, 8),
  ('vn_q_041', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Nos pênaltis contra o Velo Clube na Copa do Brasil 2026, qual foi o placar da disputa?', jsonb_build_array('3–2', '4–2', '4–3', '5–4'), 1, 9),
  ('vn_q_042', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Contra quem o Vila foi eliminado nos pênaltis na Copa do Brasil 2026?', jsonb_build_array('Operário-MS', 'Velo Clube', 'Confiança', 'Anápolis'), 2, 10),
  ('vn_q_043', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Na Copa Centro-Oeste/Copa Verde 2026, qual adversário o Vila venceu por 6–0 no OBA?', jsonb_build_array('Capital-DF', 'Operário-MS', 'Rio Branco-ES', 'Primavera'), 1, 11),
  ('vn_q_044', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'fanatico', 'Qual foi o placar de Vila Nova x Anápolis nas quartas da Copa Verde/Centro-Oeste 2026 antes dos pênaltis?', jsonb_build_array('0–0', '1–1', '2–2', '2–1'), 1, 12),
  ('vn_q_045', '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'esmeraldino', 'Em qual ano o clube voltou a usar o nome Vila Nova, segundo a história consultada?', jsonb_build_array('1950', '1952', '1955', '1958'), 2, 20)
on conflict (id) do update set club_id = excluded.club_id, difficulty = excluded.difficulty, question = excluded.question, options = excluded.options, correct_index = excluded.correct_index, sort_order = excluded.sort_order;
