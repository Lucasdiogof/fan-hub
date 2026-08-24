import 'dart:convert';

import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste o progresso de uma rodada por partida — cada `matchId` guarda
/// seu próprio estado, então o torcedor pode ter progresso em várias
/// partidas históricas ao mesmo tempo sem uma sobrescrever a outra.
class LineupStorage {
  static const _prefix = 'lineup_state_';
  static const _selectedMatchKey = 'lineup_selected_match_id';

  Future<LineupGameState?> load(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$matchId');
    if (raw == null) return null;
    try {
      return LineupGameState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Estado salvo em formato antigo/corrompido — melhor recomeçar essa
      // partida do zero do que travar a tela com uma exceção.
      return null;
    }
  }

  Future<void> save(LineupGameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix${state.matchId}',
      jsonEncode(state.toJson()),
    );
  }

  /// Qual partida o torcedor estava vendo por último — pra reabrir o
  /// Adivinhe a Escalação exatamente onde ele parou, não sempre na primeira.
  Future<String?> loadSelectedMatchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedMatchKey);
  }

  Future<void> saveSelectedMatchId(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMatchKey, matchId);
  }
}
