/// Três níveis, do mesmo jeito que o banco de perguntas original separa —
/// preparado desde já pro dia em que perguntas, progresso e nível forem
/// pro Supabase (mesmo modelo já usado no Aura: pergunta com dificuldade,
/// acertos/erros por usuário).
enum QuizDifficulty { torcedor, esmeraldino, fanatico }

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
    required this.correct,
    required this.total,
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
  });

  final int correct;
  final int total;
  final int score;
  final int bestScore;
  final bool isNewRecord;
}
