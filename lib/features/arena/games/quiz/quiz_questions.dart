import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';

/// Banco de 60 perguntas em três níveis (fonte: documento fornecido,
/// "Quiz_Goias_60_Perguntas.docx" — 20 perguntas por nível, gabarito
/// conferido contra o próprio documento).
///
/// TORCEDOR — fatos principais, títulos, campanhas e nomes que quem
/// acompanha o Goiás deve conhecer.
/// ESMERALDINO — história, jogos marcantes, Libertadores, ídolos e
/// detalhes para quem conhece bem o clube.
/// FANÁTICO — recordes, curiosidades e números específicos.
const quizQuestions = <QuizQuestion>[
  // --- TORCEDOR ---------------------------------------------------------
  QuizQuestion(
    question: 'Em que data o Goiás Esporte Clube foi fundado?',
    options: ['6 de abril de 1939', '6 de abril de 1943', '12 de maio de 1945', '1º de janeiro de 1950'],
    correctIndex: 1,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Qual foi o primeiro título conquistado pelo Goiás?',
    options: ['Copa Centro-Oeste', 'Campeonato Brasileiro Série B', 'Campeonato Goiano de 1966', 'Copa Verde'],
    correctIndex: 2,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Quem o Goiás derrotou na decisão do Goianão de 1966 para conquistar seu primeiro título?',
    options: ['Atlético-GO', 'Goiânia', 'Anápolis', 'Vila Nova'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Quantas vezes o Goiás conquistou o Campeonato Brasileiro da Série B?',
    options: ['Uma', 'Duas', 'Três', 'Quatro'],
    correctIndex: 1,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Em qual competição o Goiás conquistou um título nacional pela primeira vez?',
    options: ['Copa do Brasil', 'Copa Verde', 'Série C', 'Campeonato Brasileiro Série B'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Qual foi a melhor colocação da história do Goiás no Campeonato Brasileiro Série A?',
    options: ['Vice-campeão', '3º lugar', '4º lugar', '5º lugar'],
    correctIndex: 1,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'A campanha de 2005 garantiu ao Goiás uma vaga inédita em qual competição?',
    options: ['Mundial de Clubes', 'Copa Mercosul', 'Recopa Sul-Americana', 'Copa Libertadores'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Em que ano o Goiás disputou a Copa Libertadores pela primeira vez?',
    options: ['2003', '2004', '2005', '2006'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Contra qual clube o Goiás disputou a final da Copa Sul-Americana de 2010?',
    options: ['San Lorenzo', 'Vélez Sarsfield', 'Estudiantes', 'Independiente'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Contra quem o Goiás disputou a final da Copa do Brasil de 1990?',
    options: ['Corinthians', 'Grêmio', 'Vasco', 'Flamengo'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Qual jogador marcou 31 gols pelo Goiás no Brasileirão de 2003?',
    options: ['Araújo', 'Alex Dias', 'Paulo Baier', 'Dimba'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Contra quem o Goiás conquistou a Copa Verde de 2023?',
    options: ['Cuiabá', 'Brasiliense', 'Remo', 'Paysandu'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Em que ano o Goiás passou a fazer parte do Clube dos 13?',
    options: ['1993', '1995', '1997', '1999'],
    correctIndex: 2,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Qual foi o primeiro adversário do Goiás no Campeonato Brasileiro?',
    options: ['Flamengo', 'Santos', 'Olaria', 'América-RJ'],
    correctIndex: 2,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Qual foi o placar da primeira partida do Goiás no Campeonato Brasileiro, em 1973?',
    options: ['Goiás 1 x 0 Olaria', 'Olaria 2 x 1 Goiás', 'Goiás 2 x 0 Olaria', 'Goiás 0 x 0 Olaria'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Contra qual clube saiu a primeira vitória do Goiás em um Campeonato Brasileiro?',
    options: ['Vasco', 'Botafogo', 'Flamengo', 'Santos'],
    correctIndex: 2,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Quem foi o primeiro jogador do Goiás a terminar como artilheiro do Campeonato Brasileiro?',
    options: ['Araújo', 'Dill', 'Lincoln', 'Túlio Maravilha'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Qual jogador detém a histórica marca de 831 partidas pelo Goiás?',
    options: ['Amaral', 'Araújo', 'Fernandão', 'Harlei'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Contra qual clube o Goiás disputou o jogo decisivo do título da Série B de 1999?',
    options: ['Bahia', 'Náutico', 'Paraná', 'Santa Cruz'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    question: 'Contra qual equipe aconteceu o primeiro jogo oficial do Goiás no Estádio Hailé Pinheiro?',
    options: ['Vila Nova', 'Atlético-GO', 'Goiânia', 'Inhumas'],
    correctIndex: 3,
    difficulty: QuizDifficulty.torcedor,
  ),

  // --- ESMERALDINO --------------------------------------------------------
  QuizQuestion(
    question: 'Qual equipe eliminou o Goiás nas oitavas de final da Libertadores de 2006?',
    options: ['Boca Juniors', 'River Plate', 'Vélez Sarsfield', 'Estudiantes'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Mesmo eliminado, qual foi o placar da vitória do Goiás sobre o Estudiantes no Serra Dourada em 2006?',
    options: ['1 x 0', '2 x 0', '3 x 1', '4 x 2'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Como terminou a decisão da Sul-Americana de 2010?',
    options: [
      'Goiás campeão no tempo normal',
      'Goiás campeão nos pênaltis',
      'Independiente campeão no tempo normal',
      'Independiente campeão nos pênaltis',
    ],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quem marcou o gol do Goiás no jogo de volta da final da Sul-Americana de 2010?',
    options: ['Harlei', 'Rafael Tolói', 'Carlos Alberto', 'Rafael Moura'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Qual sequência representa o pentacampeonato goiano conquistado pelo Goiás?',
    options: ['1993–1997', '1994–1998', '1995–1999', '1996–2000'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quem eliminou o Goiás na semifinal do Campeonato Brasileiro de 1996?',
    options: ['Palmeiras', 'Cruzeiro', 'Portuguesa', 'Grêmio'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Qual foi a maior goleada do Goiás registrada no Campeonato Brasileiro?',
    options: ['Goiás 6 x 0 Bahia', 'Goiás 7 x 1 Vitória', 'Goiás 7 x 0 Juventude', 'Goiás 8 x 0 Paraná'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Qual adversário o Goiás enfrentou em sua estreia na Libertadores de 2006?',
    options: ['Deportivo Táchira', 'The Strongest', 'Deportivo Cuenca', "Newell's Old Boys"],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Qual destas equipes NÃO estava no grupo do Goiás na Libertadores de 2006?',
    options: ["Newell's Old Boys", 'The Strongest', 'Unión Española', 'River Plate'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quantos pontos o Goiás fez na fase de grupos da Libertadores de 2006?',
    options: ['8', '9', '11', '13'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Qual foi o placar agregado da final da Copa Verde de 2023?',
    options: ['2 x 0', '3 x 1', '4 x 1', '4 x 2'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Antes de enfrentar o Paysandu na final da Copa Verde de 2023, quem o Goiás eliminou na semifinal?',
    options: ['Remo', 'Vila Nova', 'Cuiabá', 'Atlético-GO'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Por que os fundadores do Goiás acabaram fazendo a reunião do lado de fora da casa dos irmãos Barsi?',
    options: [
      'Faltou energia elétrica',
      'A casa estava fechada',
      'A conversa estava fazendo muito barulho',
      'Começou a chover',
    ],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quem marcou o primeiro gol da história do Goiás no Campeonato Brasileiro?',
    options: ['Túlio Maravilha', 'Lucinho', 'Matinha', 'Lincoln'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Em 1974, o Goiás protagonizou uma reação histórica contra o Santos de Pelé. Qual era o placar antes da reação?',
    options: ['2 x 0', '3 x 0', '4 x 1', '5 x 2'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Como terminou o histórico Goiás x Santos de 1974 no Pacaembu?',
    options: ['Santos 5 x 4 Goiás', 'Goiás 5 x 4 Santos', 'Santos 4 x 4 Goiás', 'Santos 4 x 3 Goiás'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quantos gols Túlio Maravilha marcou para ser artilheiro do Brasileiro de 1989?',
    options: ['9', '10', '11', '15'],
    correctIndex: 2,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quem é o maior artilheiro da história do Goiás?',
    options: ['Fernandão', 'Dill', 'Lincoln', 'Araújo'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quantos gols Araújo marcou pelo Goiás?',
    options: ['108', '133', '140', '145'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),
  QuizQuestion(
    question: 'Quem era o técnico do Goiás na conquista da Série B de 1999?',
    options: ['Enderson Moreira', 'Geninho', 'Paulo Gonçalves', 'Hélio dos Anjos'],
    correctIndex: 3,
    difficulty: QuizDifficulty.esmeraldino,
  ),

  // --- FANÁTICO -----------------------------------------------------------
  QuizQuestion(
    question: 'Qual clube o Goiás eliminou nos pênaltis na semifinal da Copa do Brasil de 1990?',
    options: ['Atlético-MG', 'Flamengo', 'Grêmio', 'Criciúma'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quem foi o adversário do Goiás no amistoso de inauguração do Estádio Hailé Pinheiro, em 1995?',
    options: ['São Paulo', 'Peñarol', 'Atlético-MG', 'Kashima Antlers'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quem marcou o primeiro gol da história do Goiás na Libertadores?',
    options: ['Romerito', 'Jadílson', 'Welliton', 'Rogério Corrêa'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual jogador marcou dois gols na goleada de 7 x 0 sobre o Juventude em 2003?',
    options: ['Apenas Dimba', 'Apenas Danilo', 'Dimba e Danilo marcaram dois cada', 'Araújo e Dimba'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual destes jogadores NÃO é citado entre os nomes do time do Goiás na Libertadores de 2006?',
    options: ['Harlei', 'Romerito', 'Jadílson', 'Túlio Maravilha'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Onde aconteceu a reunião que deu origem ao Goiás Esporte Clube?',
    options: ['Em um bar no Centro', 'No Estádio Olímpico', 'Na sede da Federação Goiana', 'Na calçada da Rua 23'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quantos gols Paghetti marcou na reação histórica contra o Santos de Pelé, em 1974?',
    options: ['1', '2', '3', '4'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quem aparece atrás de Araújo entre os maiores artilheiros históricos do clube nas estatísticas divulgadas pelo Goiás?',
    options: ['Fernandão', 'Lincoln', 'Dill', 'Túlio Maravilha'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quantas partidas Fernandão disputou pelo Goiás?',
    options: ['198', '225', '271', '319'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quantos gols Fernandão marcou com a camisa esmeraldina?',
    options: ['89', '99', '108', '121'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual jogador participou de TODOS os cinco títulos do pentacampeonato goiano de 1996 a 2000?',
    options: ['Araújo', 'Harlei', 'Dill', 'Fernandão'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Contra qual clube Fernandão marcou seu famoso gol de bicicleta de fora da área?',
    options: ['Flamengo', 'Vila Nova', 'Palmeiras', 'Bahia'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual foi o placar do jogo marcado pela famosa bicicleta de Fernandão contra o Bahia?',
    options: ['Goiás 3 x 2 Bahia', 'Goiás 4 x 2 Bahia', 'Goiás 3 x 3 Bahia', 'Goiás 4 x 4 Bahia'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual foi o placar do jogo decisivo do título da Série B de 1999 contra o Santa Cruz?',
    options: ['Goiás 1 x 0 Santa Cruz', 'Goiás 2 x 1 Santa Cruz', 'Goiás 0 x 0 Santa Cruz', 'Goiás 3 x 0 Santa Cruz'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quantas vitórias o Goiás teve na campanha da Série B de 1999?',
    options: ['12', '13', '14', '15'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quem marcou os três gols do Goiás na vitória por 3 x 1 sobre o Inhumas no primeiro jogo oficial da Serrinha?',
    options: ['Araújo', 'Dill', 'Fernandão', 'Marcelo Batista'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual foi a maior sequência de invencibilidade histórica do Goiás na Serrinha citada pelo clube?',
    options: ['22 partidas', '29 partidas', '34 partidas', '38 partidas'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Quem é o maior artilheiro da história do Estádio Hailé Pinheiro segundo os registros do Goiás?',
    options: ['Araújo', 'Fernandão', 'Dill', 'Walter'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual seleção utilizou a Serrinha como local de preparação para a Copa das Confederações de 2013?',
    options: ['Argentina', 'Uruguai', 'Portugal', 'Brasil'],
    correctIndex: 3,
    difficulty: QuizDifficulty.fanatico,
  ),
  QuizQuestion(
    question: 'Qual foi a maior goleada registrada pelo Goiás no Estádio Hailé Pinheiro?',
    options: ['Goiás 7 x 0 São José-AP', 'Goiás 8 x 0 Anápolis', 'Goiás 9 x 0 Serra-ES', 'Goiás 10 x 0 Goiânia'],
    correctIndex: 2,
    difficulty: QuizDifficulty.fanatico,
  ),
];
