import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uma linha do ranking de um jogo (já com o nome formatado pra exibição e
/// a marcação de "sou eu").
class ArenaLeaderboardEntry {
  const ArenaLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.best,
    required this.isMe,
  });

  final int rank;
  final String name;
  final int best;
  final bool isMe;
}

/// Recordes da Arena. Fonte da verdade é o Supabase (recorde por usuário,
/// segue entre aparelhos), com um espelho em `SharedPreferences` pra leitura
/// instantânea e funcionamento offline — nada quebra sem rede/login.
class ArenaScores {
  ArenaScores(this._client);

  final SupabaseClient _client;
  static const _prefix = 'arena_best_';

  String? get _uid => _client.auth.currentUser?.id;

  Future<int> bestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$gameId';
    final local = prefs.getInt(key) ?? 0;
    final uid = _uid;
    if (uid == null) return local;
    try {
      final row = await _client
          .from('arena_scores')
          .select('best')
          .eq('user_id', uid)
          .eq('game_id', gameId)
          .maybeSingle();
      final remote = (row?['best'] as int?) ?? 0;
      final best = remote > local ? remote : local;
      if (best != local) await prefs.setInt(key, best);
      // Recorde feito offline é maior que o da nuvem: empurra pra cima.
      if (local > remote) unawaited(_pushBest(gameId, local));
      return best;
    } catch (_) {
      return local;
    }
  }

  Future<int> saveIfBest(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$gameId';
    final current = prefs.getInt(key) ?? 0;
    final best = score > current ? score : current;
    if (best != current) await prefs.setInt(key, best);
    await _pushBest(gameId, score);
    return best;
  }

  Future<void> _pushBest(String gameId, int score) async {
    if (_uid == null) return;
    try {
      await _client.rpc<void>(
        'arena_save_best',
        params: {'p_game_id': gameId, 'p_score': score},
      );
    } catch (_) {
      // Sem rede/login — o espelho local já guardou; sincroniza na próxima.
    }
  }

  Future<List<ArenaLeaderboardEntry>> leaderboard(
    String gameId, {
    int limit = 20,
  }) async {
    try {
      final data = await _client.rpc<List<dynamic>>(
        'arena_leaderboard',
        params: {'p_game_id': gameId, 'p_limit': limit},
      );
      final uid = _uid;
      return data.map((row) {
        final map = row as Map<String, dynamic>;
        return ArenaLeaderboardEntry(
          rank: (map['rank'] as num).toInt(),
          name: _formatName(map['name'] as String?),
          best: (map['best'] as num).toInt(),
          isMe: uid != null && map['user_id'] == uid,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Privacidade: mostra só o primeiro nome + inicial do último ("Lucas F.").
  String _formatName(String? fullName) {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return 'Torcedor';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }
}
