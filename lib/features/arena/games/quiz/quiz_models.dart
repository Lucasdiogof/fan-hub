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
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
  });

  /// Identificador estável (`<nivel>_<nn>`, ex. `torcedor_01`) — é contra
  /// isso, não contra o texto da pergunta, que o progresso é rastreado no
  /// Supabase. Sempre acrescente perguntas novas no FIM de cada nível em
  /// `quiz_questions.dart`; nunca reordene/renumere as existentes, senão o
  /// progresso de quem já jogou desalinha.
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final QuizDifficulty difficulty;
}

class QuizEndData {
  const QuizEndData({
    required this.difficulty,
    required this.isReview,
    required this.correct,
    required this.total,
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
    required this.justCompletedLevel,
    required this.levelAnsweredAfter,
    required this.levelTotal,
    required this.pendingReviewAfter,
  });

  final QuizDifficulty difficulty;

  /// Sessão de revisão (só perguntas pendentes) em vez de descoberta normal
  /// — muda o botão/rótulo mostrado no resultado.
  final bool isReview;
  final int correct;
  final int total;
  final int score;
  final int bestScore;
  final bool isNewRecord;

  /// true só quando esta sessão terminou de completar o nível (respondeu a
  /// última pergunta inédita) — dispara a experiência de conclusão.
  final bool justCompletedLevel;
  final int levelAnsweredAfter;
  final int levelTotal;
  final int pendingReviewAfter;
}
