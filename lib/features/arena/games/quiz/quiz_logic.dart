import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';

const quizQuestionsPerRound = 8;
const quizPointsPerCorrect = 100;

int quizScore(int correct) => correct * quizPointsPerCorrect;

List<QuizQuestion> questionsForLevel(
  List<QuizQuestion> bank,
  QuizDifficulty difficulty,
) => bank.where((question) => question.difficulty == difficulty).toList();

/// Sessão normal (descoberta de conteúdo): inéditas primeiro, embaralhadas,
/// até [quizQuestionsPerRound]. Se sobrar menos inédita que isso, a sessão
/// sai menor — nunca completa com pergunta repetida só pra fechar o número.
/// Se não sobrar nenhuma inédita (nível já 100%), essa chamada vira replay:
/// embaralha o banco inteiro do nível (não altera progresso permanente).
List<QuizQuestion> pickSessionQuestions(
  List<QuizQuestion> bank,
  QuizDifficulty difficulty, {
  required Set<String> answeredIds,
}) {
  final pool = questionsForLevel(bank, difficulty);
  final fresh =
      pool.where((question) => !answeredIds.contains(question.id)).toList()
        ..shuffle();
  if (fresh.isNotEmpty) {
    return fresh.take(quizQuestionsPerRound).map(shuffleOptions).toList();
  }
  final replay = [...pool]..shuffle();
  return replay.take(quizQuestionsPerRound).map(shuffleOptions).toList();
}

/// Sessão de revisão: só as perguntas ainda pendentes (erradas e não
/// corrigidas) daquele nível, todas de uma vez.
List<QuizQuestion> pickReviewQuestions(
  List<QuizQuestion> bank,
  QuizDifficulty difficulty, {
  required Set<String> pendingReviewIds,
}) {
  final pool = questionsForLevel(bank, difficulty);
  final review =
      pool.where((question) => pendingReviewIds.contains(question.id)).toList()
        ..shuffle();
  return review.map(shuffleOptions).toList();
}

/// No banco original (fiel ao documento fonte) a resposta certa nunca é a
/// "A" e é "D" em quase 60% dos casos — sem embaralhar dava pra chutar D e
/// acertar bem mais do que por conhecimento de verdade. O banco em si
/// (`quizQuestions`) não é alterado, só a cópia usada na sessão/resumo.
QuizQuestion shuffleOptions(QuizQuestion question) {
  final correctText = question.options[question.correctIndex];
  final shuffled = List.of(question.options)..shuffle();
  return QuizQuestion(
    id: question.id,
    question: question.question,
    options: shuffled,
    correctIndex: shuffled.indexOf(correctText),
    difficulty: question.difficulty,
  );
}
