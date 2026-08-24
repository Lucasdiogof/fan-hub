/// Três níveis, do mesmo jeito que o banco de perguntas original separa —
/// preparado desde já pro dia em que perguntas, progresso e nível forem
/// pro Supabase (mesmo modelo já usado no Aura: pergunta com dificuldade,
/// acertos/erros por usuário).
enum QuizDifficulty { torcedor, esmeraldino, fanatico }

extension QuizDifficultyLabel on QuizDifficulty {
  String get label => switch (this) {
    QuizDifficulty.torcedor => 'Torcedor',
    QuizDifficulty.esmeraldino => 'Esmeraldino',
    QuizDifficulty.fanatico => 'Fanático',
  };
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final QuizDifficulty difficulty;
}

class QuizEndData {
  const QuizEndData({
    required this.difficulty,
    required this.answeredQuestions,
    required this.correct,
    required this.total,
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
  });

  final QuizDifficulty difficulty;

  /// Texto das perguntas respondidas nesta rodada — usado por "Mais
  /// perguntas" pra evitar repetir as mesmas na rodada seguinte.
  final Set<String> answeredQuestions;
  final int correct;
  final int total;
  final int score;
  final int bestScore;
  final bool isNewRecord;
}
