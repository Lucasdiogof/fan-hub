import 'dart:convert';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_scoped_storage_key.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Só existe UMA rodada ativa por vez (diferente de Lineup/CareerPath, que
/// guardam progresso por partida/jogador navegável) — chave fixa, sem id.
/// Chaves namespaçadas por clube desde a M3.3 (`ClubScopedStorageKey`) — com
/// migração transparente da chave legacy (sem namespace) só pro Goiás,
/// nunca pra um clube sintético/novo (`LEGACY_LOCAL_STATE_IS_GOIAS_ONLY`).
class GuessPlayerStorage {
  GuessPlayerStorage(this._clubConfig);

  static const _key = 'guess_player_active_round';
  static const _playedKey = 'guess_player_stats_played';
  static const _correctKey = 'guess_player_stats_correct';
  static const _seenKey = 'guess_player_seen_ids';
  static const _seenSignatureKey = 'guess_player_seen_signature';

  final ClubConfig _clubConfig;

  bool get _isGoiasLegacyEligible => _clubConfig.identity.code == 'goias';
  ClubScopedStorageKey get _keys => ClubScopedStorageKey(_clubConfig);

  Future<String?> _migratingGetString(SharedPreferences prefs, String legacyKey) async {
    final scoped = _keys.scoped(legacyKey);
    final value = prefs.getString(scoped);
    if (value != null || !_isGoiasLegacyEligible) return value;
    final legacy = prefs.getString(legacyKey);
    if (legacy != null) await prefs.setString(scoped, legacy);
    return legacy;
  }

  Future<int?> _migratingGetInt(SharedPreferences prefs, String legacyKey) async {
    final scoped = _keys.scoped(legacyKey);
    final value = prefs.getInt(scoped);
    if (value != null || !_isGoiasLegacyEligible) return value;
    final legacy = prefs.getInt(legacyKey);
    if (legacy != null) await prefs.setInt(scoped, legacy);
    return legacy;
  }

  Future<List<String>?> _migratingGetStringList(SharedPreferences prefs, String legacyKey) async {
    final scoped = _keys.scoped(legacyKey);
    final value = prefs.getStringList(scoped);
    if (value != null || !_isGoiasLegacyEligible) return value;
    final legacy = prefs.getStringList(legacyKey);
    if (legacy != null) await prefs.setStringList(scoped, legacy);
    return legacy;
  }

  Future<GuessPlayerRoundState?> loadActiveRound() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await _migratingGetString(prefs, _key);
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
    await prefs.setString(_keys.scoped(_key), jsonEncode(state.toJson()));
  }

  Future<void> clearActiveRound() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keys.scoped(_key));
  }

  /// Estatística real (não estimada) pro card da Arena: quantas rodadas
  /// terminaram (ganhas ou perdidas) e quantas foram acertadas.
  Future<({int played, int correct})> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      played: await _migratingGetInt(prefs, _playedKey) ?? 0,
      correct: await _migratingGetInt(prefs, _correctKey) ?? 0,
    );
  }

  /// Chamado uma vez por rodada, no momento em que ela termina (ver
  /// `GuessPlayerCubit.submitGuess`) — nunca no meio da rodada.
  Future<void> recordRoundResult({required bool won}) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await loadStats();
    await prefs.setInt(_keys.scoped(_playedKey), stats.played + 1);
    if (won) {
      await prefs.setInt(_keys.scoped(_correctKey), stats.correct + 1);
    }
  }

  Future<Set<String>> loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await _migratingGetStringList(prefs, _seenKey);
    return raw?.toSet() ?? {};
  }

  Future<void> addSeenId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadSeenIds();
    await prefs.setStringList(_keys.scoped(_seenKey), [...current, id]);
  }

  Future<void> clearSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keys.scoped(_seenKey));
  }

  /// Fingerprint do catálogo elegível no momento em que os "vistos" foram
  /// montados (ids ordenados e concatenados) — compara com o catálogo atual
  /// pra saber se novos jogadores entraram desde então (ver
  /// `GuessPlayerCubit._resetSeenIfCatalogChanged`).
  Future<String?> loadSeenSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return _migratingGetString(prefs, _seenSignatureKey);
  }

  Future<void> saveSeenSignature(String signature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keys.scoped(_seenSignatureKey), signature);
  }
}
