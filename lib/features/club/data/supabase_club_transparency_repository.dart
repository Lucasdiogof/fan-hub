import 'dart:async';

import 'package:goias_app/core/cache/json_snapshot_cache.dart';
import 'package:goias_app/core/error/connectivity_error.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/features/club/domain/repositories/club_transparency_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClubTransparencyRepository implements ClubTransparencyRepository {
  SupabaseClubTransparencyRepository(
    this._client, {
    this._cache = const JsonSnapshotCache(),
    String cacheScope = 'default',
  }) : _cacheKey = 'club_transparency:$cacheScope';

  final SupabaseClient _client;
  final JsonSnapshotCache _cache;
  final String _cacheKey;

  @override
  Future<Result<List<ClubTransparencyTopic>>> getTopics() async {
    try {
      final topicRows = await _client
          .from('club_transparency_topics')
          .select()
          .order('sort_order', ascending: true);
      final documentRows = await _client
          .from('club_transparency_documents')
          .select()
          .order('sort_order', ascending: true);
      final topics = _parse(topicRows, documentRows);
      await _cache.write(_cacheKey, {
        'topics': topicRows,
        'documents': documentRows,
      });
      return Success(topics);
    } catch (error, stackTrace) {
      if (!isConnectivityError(error)) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      }
      final saved = await _readSaved();
      if (saved != null) return saved;
      return Error(
        isConnectivityError(error)
            ? const NetworkFailure('Sem conexão com a internet.')
            : const ServerFailure('Não foi possível carregar a transparência.'),
      );
    }
  }

  Future<Result<List<ClubTransparencyTopic>>?> _readSaved() async {
    final snapshot = await _cache.read(_cacheKey);
    if (snapshot == null) return null;
    try {
      final payload = snapshot.payload as Map<String, dynamic>;
      final topics = _parse(
        payload['topics'] as List<dynamic>,
        payload['documents'] as List<dynamic>,
      );
      return Success(topics, cachedAt: snapshot.savedAt);
    } catch (_) {
      return null;
    }
  }

  List<ClubTransparencyTopic> _parse(
    List<dynamic> topicRows,
    List<dynamic> documentRows,
  ) {
    final documents = documentRows
        .map(
          (row) =>
              ClubTransparencyDocument.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
    final documentsByTopic = <String, List<ClubTransparencyDocument>>{};
    for (var i = 0; i < documentRows.length; i++) {
      final row = documentRows[i] as Map<String, dynamic>;
      (documentsByTopic[row['topic_id'] as String] ??= []).add(documents[i]);
    }
    return topicRows
        .map((row) => row as Map<String, dynamic>)
        .map(
          (row) => ClubTransparencyTopic(
            id: row['id'] as String,
            title: row['title'] as String,
            documents: documentsByTopic[row['id']] ?? const [],
          ),
        )
        .where((topic) => topic.documents.isNotEmpty)
        .toList(growable: false);
  }
}
