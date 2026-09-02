import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/arena/games/tactical_identity/data/tactical_identity_repository.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_engine.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `answers` (os 10 ids de alternativa, na ordem das perguntas) é a coluna
/// que de fato importa pra reconstrução — as outras (x, y, archetype,
/// percentuais, closest_coach_id) só existem denormalizadas pra facilitar
/// consulta/analytics no banco depois. O app NUNCA confia nelas pra montar
/// a tela: sempre remonta as `TacticalOption` a partir de `answers` e roda
/// `TacticalIdentityEngine.computeResult` de novo — mesmo princípio de
/// "fonte da verdade única" da sessão em memória, agora pra persistência.
class SupabaseTacticalIdentityRepository implements TacticalIdentityRepository {
  SupabaseTacticalIdentityRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;
  static const _engine = TacticalIdentityEngine();

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  @override
  Future<void> saveResult(TacticalIdentityResult result) async {
    final top = result.closestCoaches.isEmpty
        ? null
        : result.closestCoaches.first.coach.id;
    // onConflict continua 'user_id' — mesma ressalva KEY_SCOPE_BLOCKED de
    // `supabase_player_identity_repository.dart`.
    await _client.from('tactical_identity_results').upsert({
      'user_id': _uid,
      'club_id': _clubId,
      'game_type': 'tactical_identity',
      'x': result.x,
      'y': result.y,
      'archetype': result.archetype.name,
      'possession_percentage': result.possession,
      'vertical_percentage': result.vertical,
      'dogmatic_percentage': result.dogmatic,
      'pragmatic_percentage': result.pragmatic,
      'closest_coach_id': top,
      'answers': result.answers.map((option) => option.id).toList(),
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  @override
  Future<TacticalIdentityResult?> loadLatestResult() async {
    final row = await _client
        .from('tactical_identity_results')
        .select('answers')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .maybeSingle();
    if (row == null) return null;
    try {
      final answerIds = (row['answers'] as List).cast<String>();
      if (answerIds.length != tacticalIdentityQuestions.length) return null;
      final options = [
        for (var i = 0; i < answerIds.length; i++)
          tacticalIdentityQuestions[i].options.firstWhere(
            (option) => option.id == answerIds[i],
          ),
      ];
      return _engine.computeResult(options);
    } catch (_) {
      return null;
    }
  }
}
