import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_questions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Banco de perguntas do Quiz. Fonte da verdade é o Supabase (editável sem
/// republicar o app — dá pra "quiz da rodada"); o const `quizQuestions`
/// fica como fallback offline / tabela vazia, pra o jogo nunca ficar sem
/// perguntas.
class QuizQuestionRepository {
  QuizQuestionRepository(this._client);

  final SupabaseClient _client;

  Future<List<QuizQuestion>> load() async {
    try {
      final rows = await _client
          .from('quiz_questions')
          .select('id, difficulty, question, options, correct_index')
          .eq('is_active', true)
          .order('id', ascending: true);
      final parsed = <QuizQuestion>[];
      for (final row in rows) {
        final question = _map(row);
        if (question != null) parsed.add(question);
      }
      return parsed.isEmpty ? quizQuestions : parsed;
    } catch (_) {
      return quizQuestions;
    }
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
