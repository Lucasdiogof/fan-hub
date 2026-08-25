import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:goias_app/features/arena/games/career_path/data/supabase_career_path_storage.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_storage.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Progresso agregado dos jogos da Arena. Quiz/Escalação/Jogador contam
/// como coleção finita derivada (`respondidas/total`, `concluídas/total`),
/// nunca um contador solto. Quem Vestiu o Manto não é uma coleção finita
/// (o mesmo jogador pode voltar a ser secreto) — por isso carrega
/// separadamente como desempenho (`partidas`/`acertos`), não progresso.
/// Embaixadinhas/Pênaltis ficam de fora (recorde solto).
class ArenaProgressSnapshot {
  const ArenaProgressSnapshot({
    required this.quizAnswered,
    required this.quizTotal,
    required this.lineupCompleted,
    required this.lineupTotal,
    required this.careerCompleted,
    required this.careerTotal,
    required this.guessPlayerPlayed,
    required this.guessPlayerCorrect,
    required this.justUnlockedAchievement,
  });

  final int quizAnswered;
  final int quizTotal;
  final int lineupCompleted;
  final int lineupTotal;
  final int careerCompleted;
  final int careerTotal;
  final int guessPlayerPlayed;
  final int guessPlayerCorrect;

  /// true só na chamada em que a conquista "Lenda Esmeraldina" foi
  /// desbloqueada pela primeira vez — a UI usa isso pra decidir se mostra
  /// a celebração agora (não repete em visitas seguintes).
  final bool justUnlockedAchievement;

  bool get isFullyComplete =>
      quizTotal > 0 &&
      quizAnswered >= quizTotal &&
      lineupTotal > 0 &&
      lineupCompleted >= lineupTotal &&
      careerTotal > 0 &&
      careerCompleted >= careerTotal;
}

class ArenaProgressRepository {
  ArenaProgressRepository({
    required this._client,
    required this._quizQuestionRepository,
    required this._quizProgressRepository,
    required this._lineupStorage,
    required this._careerPathStorage,
    required this._guessPlayerStorage,
  });

  final SupabaseClient _client;
  final QuizQuestionRepository _quizQuestionRepository;
  final QuizProgressRepository _quizProgressRepository;
  final SupabaseLineupStorage _lineupStorage;
  final SupabaseCareerPathStorage _careerPathStorage;
  final GuessPlayerStorage _guessPlayerStorage;

  static const _achievementId = 'arena_100_percent';

  String get _uid => _client.auth.currentUser!.id;

  Future<ArenaProgressSnapshot> loadSnapshot() async {
    final bank = await _quizQuestionRepository.load();
    final totalsByLevel = {
      for (final level in QuizDifficulty.values)
        level: questionsForLevel(bank, level).length,
    };
    final summaries = await _quizProgressRepository.getAllLevelSummaries(
      totalsByLevel,
    );
    final quizAnswered = summaries.values.fold<int>(
      0,
      (sum, summary) => sum + summary.answered,
    );
    final quizTotal = totalsByLevel.values.fold<int>(
      0,
      (sum, total) => sum + total,
    );

    final lineupCompleted = (await _lineupStorage.completedIds()).length;
    final lineupTotal = orderedLineupMatches.length;

    final careerCompleted = (await _careerPathStorage.completedIds()).length;
    final careerTotal = careerPlayers.length;

    final guessPlayerStats = await _guessPlayerStorage.loadStats();

    final fullyComplete =
        quizTotal > 0 &&
        quizAnswered >= quizTotal &&
        lineupTotal > 0 &&
        lineupCompleted >= lineupTotal &&
        careerTotal > 0 &&
        careerCompleted >= careerTotal;

    final justUnlocked = fullyComplete ? await _tryUnlockAchievement() : false;

    return ArenaProgressSnapshot(
      quizAnswered: quizAnswered,
      quizTotal: quizTotal,
      lineupCompleted: lineupCompleted,
      lineupTotal: lineupTotal,
      careerCompleted: careerCompleted,
      careerTotal: careerTotal,
      guessPlayerPlayed: guessPlayerStats.played,
      guessPlayerCorrect: guessPlayerStats.correct,
      justUnlockedAchievement: justUnlocked,
    );
  }

  /// Permanente por design: checa se já existe antes de inserir (pra saber
  /// se é a primeira vez, e assim decidir se mostra a celebração), e o
  /// insert em si nunca sobrescreve/apaga uma linha existente.
  Future<bool> _tryUnlockAchievement() async {
    final existing = await _client
        .from('arena_achievements')
        .select('achievement_id')
        .eq('user_id', _uid)
        .eq('achievement_id', _achievementId)
        .maybeSingle();
    if (existing != null) return false;

    await _client
        .from('arena_achievements')
        .upsert(
          {'user_id': _uid, 'achievement_id': _achievementId},
          onConflict: 'user_id,achievement_id',
          ignoreDuplicates: true,
        );
    return true;
  }
}
