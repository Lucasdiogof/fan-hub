import 'package:goias_app/features/arena/games/player_identity/data/player_identity_repository.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_engine.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `answers` (os 10 ids de alternativa, na ordem das perguntas) é a coluna
/// que de fato importa pra reconstrução — as outras (atributos, arquétipo,
/// closest_reference_id) só existem denormalizadas pra facilitar
/// consulta/analytics no banco depois. O app NUNCA confia nelas pra montar
/// a tela: sempre remonta as `PlayerIdentityOption` a partir de `answers` e
/// roda `PlayerIdentityEngine.computeResult` de novo — mesmo princípio de
/// "fonte da verdade única" usado em `SupabaseTacticalIdentityRepository`.
class SupabasePlayerIdentityRepository implements PlayerIdentityRepository {
  SupabasePlayerIdentityRepository(this._client);

  final SupabaseClient _client;
  static const _engine = PlayerIdentityEngine();

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<void> saveResult(PlayerIdentityResult result) async {
    final top = result.closestReferences.isEmpty
        ? null
        : result.closestReferences.first.reference.id;
    await _client.from('player_identity_results').upsert({
      'user_id': _uid,
      'test_type': 'player_identity',
      'archetype': result.archetype.name,
      'creativity': result.attributes.creativity,
      'definition': result.attributes.definition,
      'leadership': result.attributes.leadership,
      'intensity': result.attributes.intensity,
      'technique': result.attributes.technique,
      'tactics': result.attributes.tactics,
      'closest_player_id': top,
      'answers': result.answers.map((option) => option.id).toList(),
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  @override
  Future<PlayerIdentityResult?> loadLatestResult() async {
    final row = await _client
        .from('player_identity_results')
        .select('answers')
        .eq('user_id', _uid)
        .maybeSingle();
    if (row == null) return null;
    try {
      final answerIds = (row['answers'] as List).cast<String>();
      if (answerIds.length != playerIdentityQuestions.length) return null;
      final options = [
        for (var i = 0; i < answerIds.length; i++)
          playerIdentityQuestions[i].options.firstWhere(
            (option) => option.id == answerIds[i],
          ),
      ];
      return _engine.computeResult(options);
    } catch (_) {
      return null;
    }
  }
}
