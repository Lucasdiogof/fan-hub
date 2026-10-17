import 'package:goias_app/core/cache/json_snapshot_cache.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/ranking/data/arena_ranking_error_mapper.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseArenaRankingRepository implements ArenaRankingRepository {
  SupabaseArenaRankingRepository(
    this._client,
    this._clubConfig, [
    this._cache = const JsonSnapshotCache(),
  ]);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;
  final JsonSnapshotCache _cache;

  /// Só o placar PÚBLICO do clube é salvo (nunca `getMyRank`/detalhe, que
  /// são da conta). `isMe` é recalculado com o usuário atual a cada leitura.
  String _cacheKey(RankingPeriod period) =>
      'arena_ranking:$_clubId:${period.apiValue}';

  String? get _uid => _client.auth.currentUser?.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  @override
  Future<Result<ScoreResult>> recordScore({
    required String gameId,
    required String itemId,
    required String eventType,
    int? attemptNumber,
    String? difficulty,
    int? wrongCount,
    int? foundCount,
    int? totalCount,
    bool wasRevealed = false,
    bool wasAbandoned = false,
  }) async {
    try {
      // Runtime novo (M3.2): variante tenant-aware, nunca a
      // `arena_record_score` legacy (fica só pro app antigo — §12 do
      // pedido da M3.2).
      final rows = await _client.rpc<List<dynamic>>(
        'arena_record_score_for_club',
        params: {
          'p_club_id': _clubId,
          'p_game_id': gameId,
          'p_item_id': itemId,
          'p_event_type': eventType,
          'p_attempt_number': attemptNumber,
          'p_difficulty': difficulty,
          'p_wrong_count': wrongCount,
          'p_found_count': foundCount,
          'p_total_count': totalCount,
          'p_was_revealed': wasRevealed,
          'p_was_abandoned': wasAbandoned,
        },
      );
      final row = rows.first as Map<String, dynamic>;
      return Success(
        ScoreResult(
          pointsEarned: (row['points_delta'] as num).toInt(),
          itemScore: (row['item_score'] as num).toInt(),
          totalScore: (row['total_score'] as num).toInt(),
          gameScore: (row['game_score'] as num).toInt(),
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapArenaRankingError(error, stackTrace));
    }
  }

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'arena_ranking_for_club',
        params: {
          'p_club_id': _clubId,
          'p_period': period.apiValue,
          'p_limit': limit,
        },
      );
      final entries = _parseRanking(rows);
      await _cache.write(_cacheKey(period), rows);
      return Success(entries);
    } catch (error, stackTrace) {
      final failure = mapArenaRankingError(error, stackTrace);
      final snapshot = await _cache.read(_cacheKey(period));
      if (snapshot != null) {
        try {
          return Success(
            _parseRanking(snapshot.payload as List<dynamic>),
            cachedAt: snapshot.savedAt,
          );
        } catch (_) {}
      }
      return Error(failure);
    }
  }

  List<RankingEntry> _parseRanking(List<dynamic> rows) {
    final uid = _uid;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final userId = map['user_id'] as String;
      return RankingEntry(
        rank: (map['rank'] as num).toInt(),
        userId: userId,
        // Nome pode faltar num perfil incompleto — string vazia aqui, o
        // fallback traduzido é resolvido na apresentação
        // (`rankingDisplayName`), já que o repositório não tem l10n.
        name: (map['name'] as String?) ?? '',
        avatarUrl: map['avatar_url'] as String?,
        isMember: map['is_member'] as bool? ?? false,
        totalScore: (map['total_score'] as num).toInt(),
        isMe: uid != null && userId == uid,
      );
    }).toList();
  }

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'arena_my_rank_for_club',
        params: {'p_club_id': _clubId, 'p_period': period.apiValue},
      );
      if (rows.isEmpty) return const Success(null);
      final map = rows.first as Map<String, dynamic>;
      return Success((
        rank: (map['rank'] as num).toInt(),
        totalScore: (map['total_score'] as num).toInt(),
      ));
    } catch (error, stackTrace) {
      return Error(mapArenaRankingError(error, stackTrace));
    }
  }

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'arena_user_detail_for_club',
        params: {'p_club_id': _clubId, 'p_user_id': context.userId},
      );
      final breakdown = rows.map((row) {
        final map = row as Map<String, dynamic>;
        return GameScoreBreakdown(
          gameId: map['game_id'] as String,
          score: (map['game_score'] as num).toInt(),
          firstTryCount: (map['first_try_count'] as num).toInt(),
          reviewCount: (map['review_count'] as num).toInt(),
          abandonedOrRevealedCount: (map['abandoned_or_revealed_count'] as num)
              .toInt(),
        );
      }).toList();
      return Success(RankingUserDetail(entry: context, breakdown: breakdown));
    } catch (error, stackTrace) {
      return Error(mapArenaRankingError(error, stackTrace));
    }
  }
}
