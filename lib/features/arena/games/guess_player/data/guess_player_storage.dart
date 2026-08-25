import 'dart:convert';

import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Só existe UMA rodada ativa por vez (diferente de Lineup/CareerPath, que
/// guardam progresso por partida/jogador navegável) — chave fixa, sem id.
class GuessPlayerStorage {
  static const _key = 'guess_player_active_round';

  Future<GuessPlayerRoundState?> loadActiveRound() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GuessPlayerRoundState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveRound(GuessPlayerRoundState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> clearActiveRound() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
