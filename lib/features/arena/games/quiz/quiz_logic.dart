import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_questions.dart';

const quizQuestionsPerRound = 8;
const quizPointsPerCorrect = 100;

int quizScore(int correct) => correct * quizPointsPerCorrect;

/// Um sorteio novo (sem repetir pergunta na mesma rodada) a cada partida,
/// restrito ao nível escolhido. [avoid] traz o texto das perguntas da
/// rodada anterior (vindo de "Mais perguntas" em [QuizEndData]) — elas só
/// entram se não sobrarem [quizQuestionsPerRound] perguntas novas no nível
/// (cada nível tem só 20 perguntas, então em níveis já bastante jogados uma
/// repetição pode ser inevitável). As alternativas de cada pergunta também
/// são embaralhadas aqui: no banco original (fiel ao documento fonte) a
/// resposta certa nunca é a "A" e é "D" em quase 60% dos casos — sem isso
/// dava pra chutar D e acertar bem mais do que por conhecimento de verdade.
/// O banco em si (`quizQuestions`) não é alterado, só a cópia usada nesta
/// rodada.
List<QuizQuestion> pickQuizQuestions(QuizDifficulty difficulty, {Set<String> avoid = const {}}) {
  final levelPool = quizQuestions.where((question) => question.difficulty == difficulty).toList();
  final fresh = levelPool.where((question) => !avoid.contains(question.question)).toList()..shuffle();
  final seen = levelPool.where((question) => avoid.contains(question.question)).toList()..shuffle();
  return [...fresh, ...seen].take(quizQuestionsPerRound).map(_withShuffledOptions).toList();
}

QuizQuestion _withShuffledOptions(QuizQuestion question) {
  final correctText = question.options[question.correctIndex];
  final shuffled = List.of(question.options)..shuffle();
  return QuizQuestion(
    question: question.question,
    options: shuffled,
    correctIndex: shuffled.indexOf(correctText),
    difficulty: question.difficulty,
  );
}
