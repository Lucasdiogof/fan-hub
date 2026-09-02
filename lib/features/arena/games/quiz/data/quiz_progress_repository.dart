import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uma sessão em andamento (persistida a cada resposta) — permite retomar
/// exatamente de onde o usuário parou se o app fechar no meio.
class QuizSession {
  const QuizSession({
    required this.questionIds,
    required this.currentIndex,
    required this.correctCount,
    required this.isReview,
  });

  final List<String> questionIds;
  final int currentIndex;
  final int correctCount;
  final bool isReview;
}

/// Progresso consolidado de um nível — sempre derivado dos ids já
/// respondidos, nunca de um contador solto (assim, adicionar perguntas novas
/// no futuro só muda o total, sem precisar de migração de dado).
class QuizLevelSummary {
  const QuizLevelSummary({
    required this.answered,
    required this.total,
    required this.pendingReview,
  });

  final int answered;
  final int total;
  final int pendingReview;

  bool get isComplete => total > 0 && answered >= total;
}

class QuizProgressRepository {
  QuizProgressRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  Future<Set<String>> getAnsweredIds(QuizDifficulty difficulty) async {
    final rows = await _client
        .from('quiz_question_progress')
        .select('question_id')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('difficulty', difficulty.name);
    return rows.map((row) => row['question_id'] as String).toSet();
  }

  Future<Set<String>> getPendingReviewIds(QuizDifficulty difficulty) async {
    final rows = await _client
        .from('quiz_question_progress')
        .select('question_id')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('difficulty', difficulty.name)
        .eq('pending_review', true);
    return rows.map((row) => row['question_id'] as String).toSet();
  }

  /// Uma consulta só pros três níveis — usado pela tela de níveis e pelo
  /// card da Arena, que precisam do resumo dos três ao mesmo tempo.
  Future<Map<QuizDifficulty, QuizLevelSummary>> getAllLevelSummaries(
    Map<QuizDifficulty, int> totalsByLevel,
  ) async {
    final rows = await _client
        .from('quiz_question_progress')
        .select('difficulty, pending_review')
        .eq('user_id', _uid)
        .eq('club_id', _clubId);

    final answered = <QuizDifficulty, int>{};
    final pending = <QuizDifficulty, int>{};
    for (final row in rows) {
      final difficulty = QuizDifficulty.values.byName(
        row['difficulty'] as String,
      );
      answered[difficulty] = (answered[difficulty] ?? 0) + 1;
      if (row['pending_review'] == true) {
        pending[difficulty] = (pending[difficulty] ?? 0) + 1;
      }
    }

    return {
      for (final difficulty in QuizDifficulty.values)
        difficulty: QuizLevelSummary(
          answered: answered[difficulty] ?? 0,
          total: totalsByLevel[difficulty] ?? 0,
          pendingReview: pending[difficulty] ?? 0,
        ),
    };
  }

  /// Idempotente: responder a mesma pergunta de novo só atualiza a linha
  /// (chave primária é `user_id, question_id`) — nunca duplica progresso.
  /// Acerto sempre limpa `pending_review` (inclusive numa revisão); erro
  /// sempre liga (ou mantém ligado).
  Future<void> recordAnswer({
    required String questionId,
    required QuizDifficulty difficulty,
    required bool wasCorrect,
  }) async {
    final existing = await _client
        .from('quiz_question_progress')
        .select('was_correct_first_attempt')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('question_id', questionId)
        .maybeSingle();

    // onConflict continua (user_id, question_id) — o par não inclui
    // club_id (KEY_SCOPE_BLOCKED, ver M3.2 §22/M2.2B): o club_id abaixo só
    // marca a linha corretamente quando ela ainda não existe sob outra
    // chave; não resolve colisão entre clubes.
    await _client.from('quiz_question_progress').upsert({
      'user_id': _uid,
      'club_id': _clubId,
      'question_id': questionId,
      'difficulty': difficulty.name,
      'was_correct_first_attempt': existing != null
          ? existing['was_correct_first_attempt'] as bool
          : wasCorrect,
      'pending_review': !wasCorrect,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,question_id');
  }

  Future<QuizSession?> loadSession(QuizDifficulty difficulty) async {
    final row = await _client
        .from('quiz_active_session')
        .select()
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('difficulty', difficulty.name)
        .maybeSingle();
    if (row == null) return null;

    final answers = (row['answers'] as List).cast<Map<String, dynamic>>();
    return QuizSession(
      questionIds: (row['question_ids'] as List).cast<String>(),
      currentIndex: row['current_index'] as int,
      correctCount: answers.where((answer) => answer['correct'] == true).length,
      isReview: row['is_review'] as bool,
    );
  }

  Future<void> saveSession({
    required QuizDifficulty difficulty,
    required List<String> questionIds,
    required int currentIndex,
    required List<Map<String, dynamic>> answers,
    required bool isReview,
  }) async {
    // onConflict continua (user_id, difficulty) — mesma ressalva de
    // KEY_SCOPE_BLOCKED do `recordAnswer` acima.
    await _client.from('quiz_active_session').upsert({
      'user_id': _uid,
      'club_id': _clubId,
      'difficulty': difficulty.name,
      'question_ids': questionIds,
      'current_index': currentIndex,
      'answers': answers,
      'is_review': isReview,
    }, onConflict: 'user_id,difficulty');
  }

  Future<void> clearSession(QuizDifficulty difficulty) async {
    await _client
        .from('quiz_active_session')
        .delete()
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('difficulty', difficulty.name);
  }
}
