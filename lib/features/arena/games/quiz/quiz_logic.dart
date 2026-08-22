import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_questions.dart';

const quizQuestionsPerRound = 8;
const quizPointsPerCorrect = 100;

int quizScore(int correct) => correct * quizPointsPerCorrect;

/// Um sorteio novo (sem repetir pergunta na mesma rodada) a cada partida —
/// se o banco de perguntas crescer além de [quizQuestionsPerRound], o
/// jogador não vê sempre as mesmas oito. As alternativas de cada pergunta
/// também são embaralhadas aqui: no banco original (fiel ao documento
/// fonte) a resposta certa nunca é a "A" e é "D" em quase 60% dos casos —
/// sem isso dava pra chutar D e acertar bem mais do que por conhecimento
/// de verdade. O banco em si (`quizQuestions`) não é alterado, só a cópia
/// usada nesta rodada.
List<QuizQuestion> pickQuizQuestions() {
  final pool = List.of(quizQuestions)..shuffle();
  return pool.take(quizQuestionsPerRound).map(_withShuffledOptions).toList();
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
