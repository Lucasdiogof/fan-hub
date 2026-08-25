import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mesma interface de `CareerPathStorage`, mas persistindo no Supabase
/// (`career_path_progress`/`arena_selected_content`) em vez de
/// SharedPreferences — Etapa C da progressão da Arena. `CareerPathCubit`
/// não muda nada: ele já chama essas 4 funções por injeção de construtor.
class SupabaseCareerPathStorage {
  SupabaseCareerPathStorage(this._client);

  final SupabaseClient _client;

  static const _gameId = 'career_path';

  String get _uid => _client.auth.currentUser!.id;

  Future<CareerRoundState?> load(String playerId) async {
    final row = await _client
        .from('career_path_progress')
        .select('round_state')
        .eq('user_id', _uid)
        .eq('player_id', playerId)
        .maybeSingle();
    if (row == null) return null;
    try {
      return CareerRoundState.fromJson(
        row['round_state'] as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CareerRoundState state) async {
    await _client.from('career_path_progress').upsert({
      'user_id': _uid,
      'player_id': state.playerId,
      'round_state': state.toJson(),
      'status': state.isDone ? 'completed' : 'in_progress',
      'completed_at': state.completedAt?.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,player_id');
  }

  Future<String?> loadSelectedPlayerId() async {
    final row = await _client
        .from('arena_selected_content')
        .select('selected_id')
        .eq('user_id', _uid)
        .eq('game_id', _gameId)
        .maybeSingle();
    return row?['selected_id'] as String?;
  }

  Future<void> saveSelectedPlayerId(String playerId) async {
    await _client.from('arena_selected_content').upsert({
      'user_id': _uid,
      'game_id': _gameId,
      'selected_id': playerId,
    }, onConflict: 'user_id,game_id');
  }

  /// Ids dos jogadores que o usuário já concluiu (acertou, errou tudo ou
  /// revelou) — usado tanto pro card de progresso da Arena (`.length`)
  /// quanto pra reembaralhar a ordem mantendo os concluídos no lugar (ver
  /// `shuffleKeepingDone`).
  Future<Set<String>> completedIds() async {
    final rows = await _client
        .from('career_path_progress')
        .select('player_id')
        .eq('user_id', _uid)
        .eq('status', 'completed');
    return rows.map((row) => row['player_id'] as String).toSet();
  }
}
