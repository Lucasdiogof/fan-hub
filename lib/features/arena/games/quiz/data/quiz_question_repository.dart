import 'dart:async';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/club_scoped_fallback.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_questions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fallback offline por clube — ver comentário equivalente em
/// `career_player_repository.dart`.
const quizQuestionsFallback = ClubScopedFallback<List<QuizQuestion>>({
  'goias': quizQuestions,
});

/// Banco de perguntas do Quiz. Fonte da verdade é o Supabase (editável sem
/// republicar o app — dá pra "quiz da rodada"), SEMPRE filtrada pelo clube
/// ativo (`club_id`); fallback também resolvido por clube.
class QuizQuestionRepository {
  QuizQuestionRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  /// Ver o comentário equivalente em `career_player_repository.dart`: 0
  /// linhas (sucesso) e falha real (rede/parse) NUNCA são conflatadas —
  /// só a 1ª pode virar `ClubDataUnavailableException` sem fallback; a 2ª
  /// sobe a exceção original intacta.
  Future<List<QuizQuestion>> load() async {
    final clubCode = _clubConfig.identity.code;
    List<QuizQuestion> parsed;
    try {
      final rows = await _client
          .from('quiz_questions')
          .select('id, difficulty, question, options, correct_index')
          .eq('club_id', _clubConfig.identity.canonicalClubId)
          .eq('is_active', true)
          .order('id', ascending: true);
      parsed = <QuizQuestion>[];
      for (final row in rows) {
        final question = _map(row);
        if (question != null) parsed.add(question);
      }
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      final fallback = quizQuestionsFallback.forClub(clubCode);
      if (fallback != null) return fallback;
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (parsed.isNotEmpty) return parsed;
    final fallback = quizQuestionsFallback.forClub(clubCode);
    if (fallback != null) return fallback;
    throw ClubDataUnavailableException(
      table: 'quiz_questions',
      clubCode: clubCode,
    );
  }

  QuizQuestion? _map(Map<String, dynamic> row) {
    QuizDifficulty? difficulty;
    for (final value in QuizDifficulty.values) {
      if (value.name == row['difficulty']) {
        difficulty = value;
        break;
      }
    }
    final options = (row['options'] as List?)
        ?.map((e) => e.toString())
        .toList();
    final correct = (row['correct_index'] as num?)?.toInt();
    if (difficulty == null ||
        options == null ||
        options.length < 2 ||
        correct == null ||
        correct < 0 ||
        correct >= options.length) {
      return null;
    }
    return QuizQuestion(
      id: row['id'] as String,
      question: row['question'] as String,
      options: options,
      correctIndex: correct,
      difficulty: difficulty,
    );
  }
}
