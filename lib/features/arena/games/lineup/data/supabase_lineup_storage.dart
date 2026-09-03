import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mesma interface de `LineupStorage`, mas persistindo no Supabase
/// (`lineup_match_progress`/`arena_selected_content`) em vez de
/// SharedPreferences — Etapa B da progressão da Arena. `LineupCubit` não
/// muda nada: ele já chama essas 4 funções por injeção de construtor.
class SupabaseLineupStorage {
  SupabaseLineupStorage(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  static const _gameId = 'lineup';

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  Future<LineupGameState?> load(String matchId) async {
    final row = await _client
        .from('lineup_match_progress')
        .select('game_state')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('match_id', matchId)
        .maybeSingle();
    if (row == null) return null;
    try {
      return LineupGameState.fromJson(
        row['game_state'] as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LineupGameState state) async {
    // onConflict continua (user_id, match_id) — KEY_SCOPE_BLOCKED, mesma
    // ressalva de `quiz_progress_repository.dart`.
    await _client.from('lineup_match_progress').upsert({
      'user_id': _uid,
      'club_id': _clubId,
      'match_id': state.matchId,
      'game_state': state.toJson(),
      'status': state.isFinished ? 'completed' : 'in_progress',
      'completed_at': state.completedAt?.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'club_id,user_id,match_id');
  }

  Future<String?> loadSelectedMatchId() async {
    final row = await _client
        .from('arena_selected_content')
        .select('selected_id')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('game_id', _gameId)
        .maybeSingle();
    return row?['selected_id'] as String?;
  }

  Future<void> saveSelectedMatchId(String matchId) async {
    // onConflict continua (user_id, game_id) — mesma ressalva
    // KEY_SCOPE_BLOCKED de `supabase_career_path_storage.dart`.
    await _client.from('arena_selected_content').upsert({
      'user_id': _uid,
      'club_id': _clubId,
      'game_id': _gameId,
      'selected_id': matchId,
    }, onConflict: 'club_id,user_id,game_id');
  }

  /// Ids das partidas que o usuário já concluiu (desistiu ou resolveu os
  /// 11) — usado tanto pro card de progresso da Arena (`.length`, nunca
  /// `jogadores/341`, sempre `partidas/total`) quanto pra reembaralhar a
  /// ordem mantendo as concluídas no lugar (ver `shuffleKeepingDone`).
  Future<Set<String>> completedIds() async {
    final rows = await _client
        .from('lineup_match_progress')
        .select('match_id')
        .eq('user_id', _uid)
        .eq('club_id', _clubId)
        .eq('status', 'completed');
    return rows.map((row) => row['match_id'] as String).toSet();
  }
}
