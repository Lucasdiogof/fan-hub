import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/features/club/domain/repositories/club_board_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClubBoardRepository implements ClubBoardRepository {
  SupabaseClubBoardRepository(this._client);

  final SupabaseClient _client;

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

      final members = memberRows
          .map((row) => ClubBoardMember.fromJson(row))
          .toList(growable: false);
      final membersBySection = <String, List<ClubBoardMember>>{};
      for (var i = 0; i < memberRows.length; i++) {
        final sectionId = memberRows[i]['section_id'] as String;
        (membersBySection[sectionId] ??= []).add(members[i]);
      }

      final sections = sectionRows
          .map(
            (row) => ClubBoardSection(
              id: row['id'] as String,
              title: row['title'] as String,
              members: membersBySection[row['id']] ?? const [],
            ),
          )
          .where((section) => section.members.isNotEmpty)
          .toList(growable: false);

      return Success(sections);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível carregar a diretoria.'),
      );
    }
  }
}
