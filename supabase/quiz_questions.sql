-- ============================================================================
-- Perguntas do Quiz do Verdão. Rode no SQL Editor do Supabase. A tabela vira
-- a fonte da verdade (dá pra adicionar/editar pergunta sem republicar o app);
-- o app cai no banco local (const quizQuestions) se a tabela estiver vazia ou
-- sem rede. Leitura é pública; escrita só pelo dashboard/admin.
-- Contrato de id: '<nivel>_<nn>' (ex. torcedor_01) — nunca reaproveitar id
-- pra outra pergunta (o progresso do usuário é rastreado por id).
-- ============================================================================

create table if not exists public.quiz_questions (
  id text primary key,
  difficulty text not null check (difficulty in ('torcedor','esmeraldino','fanatico')),
  question text not null,
  options jsonb not null,
  correct_index int not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.quiz_questions enable row level security;

drop policy if exists "read quiz questions" on public.quiz_questions;
create policy "read quiz questions" on public.quiz_questions
  for select using (true);

insert into public.quiz_questions (id, difficulty, question, options, correct_index, sort_order) values
('torcedor_01', 'torcedor', 'Em que data o Goiás Esporte Clube foi fundado?', jsonb_build_array('6 de abril de 1939', '6 de abril de 1943', '12 de maio de 1945', '1º de janeiro de 1950'), 1, 1),
('torcedor_02', 'torcedor', 'Qual foi o primeiro título conquistado pelo Goiás?', jsonb_build_array('Copa Centro-Oeste', 'Campeonato Brasileiro Série B', 'Campeonato Goiano de 1966', 'Copa Verde'), 2, 2),
('torcedor_03', 'torcedor', 'Quem o Goiás derrotou na decisão do Goianão de 1966 para conquistar seu primeiro título?', jsonb_build_array('Atlético-GO', 'Goiânia', 'Anápolis', 'Vila Nova'), 3, 3),
('torcedor_04', 'torcedor', 'Quantas vezes o Goiás conquistou o Campeonato Brasileiro da Série B?', jsonb_build_array('Uma', 'Duas', 'Três', 'Quatro'), 1, 4),
('torcedor_05', 'torcedor', 'Em qual competição o Goiás conquistou um título nacional pela primeira vez?', jsonb_build_array('Copa do Brasil', 'Copa Verde', 'Série C', 'Campeonato Brasileiro Série B'), 3, 5),
('torcedor_06', 'torcedor', 'Qual foi a melhor colocação da história do Goiás no Campeonato Brasileiro Série A?', jsonb_build_array('Vice-campeão', '3º lugar', '4º lugar', '5º lugar'), 1, 6),
('torcedor_07', 'torcedor', 'A campanha de 2005 garantiu ao Goiás uma vaga inédita em qual competição?', jsonb_build_array('Mundial de Clubes', 'Copa Mercosul', 'Recopa Sul-Americana', 'Copa Libertadores'), 3, 7),
('torcedor_08', 'torcedor', 'Em que ano o Goiás disputou a Copa Libertadores pela primeira vez?', jsonb_build_array('2003', '2004', '2005', '2006'), 3, 8),
('torcedor_09', 'torcedor', 'Contra qual clube o Goiás disputou a final da Copa Sul-Americana de 2010?', jsonb_build_array('San Lorenzo', 'Vélez Sarsfield', 'Estudiantes', 'Independiente'), 3, 9),
('torcedor_10', 'torcedor', 'Contra quem o Goiás disputou a final da Copa do Brasil de 1990?', jsonb_build_array('Corinthians', 'Grêmio', 'Vasco', 'Flamengo'), 3, 10),
('torcedor_11', 'torcedor', 'Qual jogador marcou 31 gols pelo Goiás no Brasileirão de 2003?', jsonb_build_array('Araújo', 'Alex Dias', 'Paulo Baier', 'Dimba'), 3, 11),
('torcedor_12', 'torcedor', 'Contra quem o Goiás conquistou a Copa Verde de 2023?', jsonb_build_array('Cuiabá', 'Brasiliense', 'Remo', 'Paysandu'), 3, 12),
('torcedor_13', 'torcedor', 'Em que ano o Goiás passou a fazer parte do Clube dos 13?', jsonb_build_array('1993', '1995', '1997', '1999'), 2, 13),
('torcedor_14', 'torcedor', 'Qual foi o primeiro adversário do Goiás no Campeonato Brasileiro?', jsonb_build_array('Flamengo', 'Santos', 'Olaria', 'América-RJ'), 2, 14),
('torcedor_15', 'torcedor', 'Qual foi o placar da primeira partida do Goiás no Campeonato Brasileiro, em 1973?', jsonb_build_array('Goiás 1 x 0 Olaria', 'Olaria 2 x 1 Goiás', 'Goiás 2 x 0 Olaria', 'Goiás 0 x 0 Olaria'), 3, 15),
('torcedor_16', 'torcedor', 'Contra qual clube saiu a primeira vitória do Goiás em um Campeonato Brasileiro?', jsonb_build_array('Vasco', 'Botafogo', 'Flamengo', 'Santos'), 2, 16),
('torcedor_17', 'torcedor', 'Quem foi o primeiro jogador do Goiás a terminar como artilheiro do Campeonato Brasileiro?', jsonb_build_array('Araújo', 'Dill', 'Lincoln', 'Túlio Maravilha'), 3, 17),
('torcedor_18', 'torcedor', 'Qual jogador detém a histórica marca de 831 partidas pelo Goiás?', jsonb_build_array('Amaral', 'Araújo', 'Fernandão', 'Harlei'), 3, 18),
('torcedor_19', 'torcedor', 'Contra qual clube o Goiás disputou o jogo decisivo do título da Série B de 1999?', jsonb_build_array('Bahia', 'Náutico', 'Paraná', 'Santa Cruz'), 3, 19),
('torcedor_20', 'torcedor', 'Contra qual equipe aconteceu o primeiro jogo oficial do Goiás no Estádio Hailé Pinheiro?', jsonb_build_array('Vila Nova', 'Atlético-GO', 'Goiânia', 'Inhumas'), 3, 20),
('esmeraldino_01', 'esmeraldino', 'Qual equipe eliminou o Goiás nas oitavas de final da Libertadores de 2006?', jsonb_build_array('Boca Juniors', 'River Plate', 'Vélez Sarsfield', 'Estudiantes'), 3, 21),
('esmeraldino_02', 'esmeraldino', 'Mesmo eliminado, qual foi o placar da vitória do Goiás sobre o Estudiantes no Serra Dourada em 2006?', jsonb_build_array('1 x 0', '2 x 0', '3 x 1', '4 x 2'), 2, 22),
('esmeraldino_03', 'esmeraldino', 'Como terminou a decisão da Sul-Americana de 2010?', jsonb_build_array('Goiás campeão no tempo normal', 'Goiás campeão nos pênaltis', 'Independiente campeão no tempo normal', 'Independiente campeão nos pênaltis'), 3, 23),
('esmeraldino_04', 'esmeraldino', 'Quem marcou o gol do Goiás no jogo de volta da final da Sul-Americana de 2010?', jsonb_build_array('Harlei', 'Rafael Tolói', 'Carlos Alberto', 'Rafael Moura'), 3, 24),
('esmeraldino_05', 'esmeraldino', 'Qual sequência representa o pentacampeonato goiano conquistado pelo Goiás?', jsonb_build_array('1993–1997', '1994–1998', '1995–1999', '1996–2000'), 3, 25),
('esmeraldino_06', 'esmeraldino', 'Quem eliminou o Goiás na semifinal do Campeonato Brasileiro de 1996?', jsonb_build_array('Palmeiras', 'Cruzeiro', 'Portuguesa', 'Grêmio'), 3, 26),
('esmeraldino_07', 'esmeraldino', 'Qual foi a maior goleada do Goiás registrada no Campeonato Brasileiro?', jsonb_build_array('Goiás 6 x 0 Bahia', 'Goiás 7 x 1 Vitória', 'Goiás 7 x 0 Juventude', 'Goiás 8 x 0 Paraná'), 2, 27),
('esmeraldino_08', 'esmeraldino', 'Qual adversário o Goiás enfrentou em sua estreia na Libertadores de 2006?', jsonb_build_array('Deportivo Táchira', 'The Strongest', 'Deportivo Cuenca', 'Newell''s Old Boys'), 2, 28),
('esmeraldino_09', 'esmeraldino', 'Qual destas equipes NÃO estava no grupo do Goiás na Libertadores de 2006?', jsonb_build_array('Newell''s Old Boys', 'The Strongest', 'Unión Española', 'River Plate'), 3, 29),
('esmeraldino_10', 'esmeraldino', 'Quantos pontos o Goiás fez na fase de grupos da Libertadores de 2006?', jsonb_build_array('8', '9', '11', '13'), 2, 30),
('esmeraldino_11', 'esmeraldino', 'Qual foi o placar agregado da final da Copa Verde de 2023?', jsonb_build_array('2 x 0', '3 x 1', '4 x 1', '4 x 2'), 2, 31),
('esmeraldino_12', 'esmeraldino', 'Antes de enfrentar o Paysandu na final da Copa Verde de 2023, quem o Goiás eliminou na semifinal?', jsonb_build_array('Remo', 'Vila Nova', 'Cuiabá', 'Atlético-GO'), 2, 32),
('esmeraldino_13', 'esmeraldino', 'Por que os fundadores do Goiás acabaram fazendo a reunião do lado de fora da casa dos irmãos Barsi?', jsonb_build_array('Faltou energia elétrica', 'A casa estava fechada', 'A conversa estava fazendo muito barulho', 'Começou a chover'), 2, 33),
('esmeraldino_14', 'esmeraldino', 'Quem marcou o primeiro gol da história do Goiás no Campeonato Brasileiro?', jsonb_build_array('Túlio Maravilha', 'Lucinho', 'Matinha', 'Lincoln'), 3, 34),
('esmeraldino_15', 'esmeraldino', 'Em 1974, o Goiás protagonizou uma reação histórica contra o Santos de Pelé. Qual era o placar antes da reação?', jsonb_build_array('2 x 0', '3 x 0', '4 x 1', '5 x 2'), 2, 35),
('esmeraldino_16', 'esmeraldino', 'Como terminou o histórico Goiás x Santos de 1974 no Pacaembu?', jsonb_build_array('Santos 5 x 4 Goiás', 'Goiás 5 x 4 Santos', 'Santos 4 x 4 Goiás', 'Santos 4 x 3 Goiás'), 2, 36),
('esmeraldino_17', 'esmeraldino', 'Quantos gols Túlio Maravilha marcou para ser artilheiro do Brasileiro de 1989?', jsonb_build_array('9', '10', '11', '15'), 2, 37),
('esmeraldino_18', 'esmeraldino', 'Quem é o maior artilheiro da história do Goiás?', jsonb_build_array('Fernandão', 'Dill', 'Lincoln', 'Araújo'), 3, 38),
('esmeraldino_19', 'esmeraldino', 'Quantos gols Araújo marcou pelo Goiás?', jsonb_build_array('108', '133', '140', '145'), 3, 39),
('esmeraldino_20', 'esmeraldino', 'Quem era o técnico do Goiás na conquista da Série B de 1999?', jsonb_build_array('Enderson Moreira', 'Geninho', 'Paulo Gonçalves', 'Hélio dos Anjos'), 3, 40),
('fanatico_01', 'fanatico', 'Qual clube o Goiás eliminou nos pênaltis na semifinal da Copa do Brasil de 1990?', jsonb_build_array('Atlético-MG', 'Flamengo', 'Grêmio', 'Criciúma'), 3, 41),
('fanatico_02', 'fanatico', 'Quem foi o adversário do Goiás no amistoso de inauguração do Estádio Hailé Pinheiro, em 1995?', jsonb_build_array('São Paulo', 'Peñarol', 'Atlético-MG', 'Kashima Antlers'), 3, 42),
('fanatico_03', 'fanatico', 'Quem marcou o primeiro gol da história do Goiás na Libertadores?', jsonb_build_array('Romerito', 'Jadílson', 'Welliton', 'Rogério Corrêa'), 3, 43),
('fanatico_04', 'fanatico', 'Qual jogador marcou dois gols na goleada de 7 x 0 sobre o Juventude em 2003?', jsonb_build_array('Apenas Dimba', 'Apenas Danilo', 'Dimba e Danilo marcaram dois cada', 'Araújo e Dimba'), 2, 44),
('fanatico_05', 'fanatico', 'Qual destes jogadores NÃO é citado entre os nomes do time do Goiás na Libertadores de 2006?', jsonb_build_array('Harlei', 'Romerito', 'Jadílson', 'Túlio Maravilha'), 3, 45),
('fanatico_06', 'fanatico', 'Onde aconteceu a reunião que deu origem ao Goiás Esporte Clube?', jsonb_build_array('Em um bar no Centro', 'No Estádio Olímpico', 'Na sede da Federação Goiana', 'Na calçada da Rua 23'), 3, 46),
('fanatico_07', 'fanatico', 'Quantos gols Paghetti marcou na reação histórica contra o Santos de Pelé, em 1974?', jsonb_build_array('1', '2', '3', '4'), 2, 47),
('fanatico_08', 'fanatico', 'Quem aparece atrás de Araújo entre os maiores artilheiros históricos do clube nas estatísticas divulgadas pelo Goiás?', jsonb_build_array('Fernandão', 'Lincoln', 'Dill', 'Túlio Maravilha'), 2, 48),
('fanatico_09', 'fanatico', 'Quantas partidas Fernandão disputou pelo Goiás?', jsonb_build_array('198', '225', '271', '319'), 2, 49),
('fanatico_10', 'fanatico', 'Quantos gols Fernandão marcou com a camisa esmeraldina?', jsonb_build_array('89', '99', '108', '121'), 2, 50),
('fanatico_11', 'fanatico', 'Qual jogador participou de TODOS os cinco títulos do pentacampeonato goiano de 1996 a 2000?', jsonb_build_array('Araújo', 'Harlei', 'Dill', 'Fernandão'), 3, 51),
('fanatico_12', 'fanatico', 'Contra qual clube Fernandão marcou seu famoso gol de bicicleta de fora da área?', jsonb_build_array('Flamengo', 'Vila Nova', 'Palmeiras', 'Bahia'), 3, 52),
('fanatico_13', 'fanatico', 'Qual foi o placar do jogo marcado pela famosa bicicleta de Fernandão contra o Bahia?', jsonb_build_array('Goiás 3 x 2 Bahia', 'Goiás 4 x 2 Bahia', 'Goiás 3 x 3 Bahia', 'Goiás 4 x 4 Bahia'), 3, 53),
('fanatico_14', 'fanatico', 'Qual foi o placar do jogo decisivo do título da Série B de 1999 contra o Santa Cruz?', jsonb_build_array('Goiás 1 x 0 Santa Cruz', 'Goiás 2 x 1 Santa Cruz', 'Goiás 0 x 0 Santa Cruz', 'Goiás 3 x 0 Santa Cruz'), 2, 54),
('fanatico_15', 'fanatico', 'Quantas vitórias o Goiás teve na campanha da Série B de 1999?', jsonb_build_array('12', '13', '14', '15'), 3, 55),
('fanatico_16', 'fanatico', 'Quem marcou os três gols do Goiás na vitória por 3 x 1 sobre o Inhumas no primeiro jogo oficial da Serrinha?', jsonb_build_array('Araújo', 'Dill', 'Fernandão', 'Marcelo Batista'), 3, 56),
('fanatico_17', 'fanatico', 'Qual foi a maior sequência de invencibilidade histórica do Goiás na Serrinha citada pelo clube?', jsonb_build_array('22 partidas', '29 partidas', '34 partidas', '38 partidas'), 3, 57),
('fanatico_18', 'fanatico', 'Quem é o maior artilheiro da história do Estádio Hailé Pinheiro segundo os registros do Goiás?', jsonb_build_array('Araújo', 'Fernandão', 'Dill', 'Walter'), 2, 58),
('fanatico_19', 'fanatico', 'Qual seleção utilizou a Serrinha como local de preparação para a Copa das Confederações de 2013?', jsonb_build_array('Argentina', 'Uruguai', 'Portugal', 'Brasil'), 3, 59),
('fanatico_20', 'fanatico', 'Qual foi a maior goleada registrada pelo Goiás no Estádio Hailé Pinheiro?', jsonb_build_array('Goiás 7 x 0 São José-AP', 'Goiás 8 x 0 Anápolis', 'Goiás 9 x 0 Serra-ES', 'Goiás 10 x 0 Goiânia'), 2, 60)
on conflict (id) do nothing;
