import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/features/club/domain/repositories/club_transparency_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClubTransparencyRepository implements ClubTransparencyRepository {
  SupabaseClubTransparencyRepository(this._client);

  final SupabaseClient _client;

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

      final documents = documentRows
          .map((row) => ClubTransparencyDocument.fromJson(row))
          .toList(growable: false);
      final documentsByTopic = <String, List<ClubTransparencyDocument>>{};
      for (var i = 0; i < documentRows.length; i++) {
        final topicId = documentRows[i]['topic_id'] as String;
        (documentsByTopic[topicId] ??= []).add(documents[i]);
      }

      final topics = topicRows
          .map(
            (row) => ClubTransparencyTopic(
              id: row['id'] as String,
              title: row['title'] as String,
              documents: documentsByTopic[row['id']] ?? const [],
            ),
          )
          .where((topic) => topic.documents.isNotEmpty)
          .toList(growable: false);

      return Success(topics);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível carregar a transparência.'),
      );
    }
  }
}
