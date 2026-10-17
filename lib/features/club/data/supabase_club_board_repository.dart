import 'dart:async';

import 'package:goias_app/core/cache/json_snapshot_cache.dart';
import 'package:goias_app/core/error/connectivity_error.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/features/club/domain/repositories/club_board_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClubBoardRepository implements ClubBoardRepository {
  SupabaseClubBoardRepository(
    this._client, {
    this._cache = const JsonSnapshotCache(),
    String cacheScope = 'default',
  }) : _cacheKey = 'club_board:$cacheScope';

  final SupabaseClient _client;
  final JsonSnapshotCache _cache;
  final String _cacheKey;

  @override
  Future<Result<List<ClubBoardSection>>> getBoard() async {
    try {
      final sectionRows = await _client
          .from('club_board_sections')
          .select()
          .order('sort_order', ascending: true);
      final memberRows = await _client
          .from('club_board_members')
          .select()
          .order('sort_order', ascending: true);
      final sections = _parse(sectionRows, memberRows);
      await _cache.write(_cacheKey, {
        'sections': sectionRows,
        'members': memberRows,
      });
      return Success(sections);
    } catch (error, stackTrace) {
      if (!isConnectivityError(error)) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      }
      final saved = await _readSaved();
      if (saved != null) return saved;
      return Error(
        isConnectivityError(error)
            ? const NetworkFailure('Sem conexão com a internet.')
            : const ServerFailure('Não foi possível carregar a diretoria.'),
      );
    }
  }

  Future<Result<List<ClubBoardSection>>?> _readSaved() async {
    final snapshot = await _cache.read(_cacheKey);
    if (snapshot == null) return null;
    try {
      final payload = snapshot.payload as Map<String, dynamic>;
      final sections = _parse(
        payload['sections'] as List<dynamic>,
        payload['members'] as List<dynamic>,
      );
      return Success(sections, cachedAt: snapshot.savedAt);
    } catch (_) {
      return null;
    }
  }

  List<ClubBoardSection> _parse(
    List<dynamic> sectionRows,
    List<dynamic> memberRows,
  ) {
    final members = memberRows
        .map((row) => ClubBoardMember.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
    final membersBySection = <String, List<ClubBoardMember>>{};
    for (var i = 0; i < memberRows.length; i++) {
      final row = memberRows[i] as Map<String, dynamic>;
      (membersBySection[row['section_id'] as String] ??= []).add(members[i]);
    }
    return sectionRows
        .map((row) => row as Map<String, dynamic>)
        .map(
          (row) => ClubBoardSection(
            id: row['id'] as String,
            title: row['title'] as String,
            members: membersBySection[row['id']] ?? const [],
          ),
        )
        .where((section) => section.members.isNotEmpty)
        .toList(growable: false);
  }
}
