import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _genericErrorMessage =
    'Não foi possível concluir agora. Tente novamente.';

class SupabasePassportRepository implements PassportRepository {
  SupabasePassportRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<Result<List<PassportSeason>>> getSeasons() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('passport_seasons');
      return Success(
        rows
            .map((row) => PassportSeason.fromMap(row as Map<String, dynamic>))
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<List<PassportMatch>>> getMatchesForYear(int year) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'passport_matches_for_year',
        params: {'p_season': year},
      );
      return Success(
        rows
            .map((row) => PassportMatch.fromMap(row as Map<String, dynamic>))
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<PassportSummary>> getSummary() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('passport_summary');
      if (rows.isEmpty) return const Success(PassportSummary.empty);
      return Success(
        PassportSummary.fromMap(rows.first as Map<String, dynamic>),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<PassportAttendanceBreakdown>> getAttendanceBreakdown() async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'passport_attendance_breakdown',
      );
      if (rows.isEmpty) {
        return const Success(PassportAttendanceBreakdown.empty);
      }
      return Success(
        PassportAttendanceBreakdown.fromMap(
          rows.first as Map<String, dynamic>,
        ),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<List<PassportAttendanceChangeResult>>> saveAttendances(
    List<PassportAttendanceChange> changes,
  ) async {
    if (changes.isEmpty) return const Success([]);
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'passport_save_attendances',
        params: {
          'p_changes': changes.map((c) => c.toJson()).toList(growable: false),
        },
      );
      return Success(
        rows
            .map(
              (row) => PassportAttendanceChangeResult.fromMap(
                row as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível salvar suas partidas. Tente novamente.'),
      );
    }
  }

  @override
  Future<Result<List<PassportRankingEntry>>> getRanking({
    int? year,
    int limit = 50,
  }) async {
    try {
      final uid = _uid;
      final rows = await _client.rpc<List<dynamic>>(
        'passport_ranking',
        params: {'p_year': year, 'p_limit': limit},
      );
      return Success(
        rows.map((row) {
          final map = row as Map<String, dynamic>;
          final userId = map['user_id'] as String;
          return PassportRankingEntry(
            rank: map['rank'] as int,
            userId: userId,
            name: map['name'] as String,
            avatarUrl: map['avatar_url'] as String?,
            isMember: map['is_member'] as bool? ?? false,
            matchCount: map['match_count'] as int,
            isMe: uid != null && userId == uid,
          );
        }).toList(growable: false),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<({int rank, int matchCount})?>> getMyRank({int? year}) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'passport_my_rank',
        params: {'p_year': year},
      );
      if (rows.isEmpty) return const Success(null);
      final map = rows.first as Map<String, dynamic>;
      return Success((
        rank: map['rank'] as int,
        matchCount: map['match_count'] as int,
      ));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }
}
