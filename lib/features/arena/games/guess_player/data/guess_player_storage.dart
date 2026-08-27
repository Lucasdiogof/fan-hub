import 'dart:convert';

import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Só existe UMA rodada ativa por vez (diferente de Lineup/CareerPath, que
/// guardam progresso por partida/jogador navegável) — chave fixa, sem id.
class GuessPlayerStorage {
  static const _key = 'guess_player_active_round';
  static const _playedKey = 'guess_player_stats_played';
  static const _correctKey = 'guess_player_stats_correct';
  static const _seenKey = 'guess_player_seen_ids';

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

  /// Estatística real (não estimada) pro card da Arena: quantas rodadas
  /// terminaram (ganhas ou perdidas) e quantas foram acertadas.
  Future<({int played, int correct})> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      played: prefs.getInt(_playedKey) ?? 0,
      correct: prefs.getInt(_correctKey) ?? 0,
    );
  }

  /// Chamado uma vez por rodada, no momento em que ela termina (ver
  /// `GuessPlayerCubit.submitGuess`) — nunca no meio da rodada.
  Future<void> recordRoundResult({required bool won}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playedKey, (prefs.getInt(_playedKey) ?? 0) + 1);
    if (won) {
      await prefs.setInt(_correctKey, (prefs.getInt(_correctKey) ?? 0) + 1);
    }
  }

  Future<Set<String>> loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_seenKey);
    return raw?.toSet() ?? {};
  }

  Future<void> addSeenId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_seenKey) ?? [];
    await prefs.setStringList(_seenKey, [...current, id]);
  }

  Future<void> clearSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
  }
}
