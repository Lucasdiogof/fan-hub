import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/squad/domain/repositories/squad_repository.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSquadRepository implements SquadRepository {
  SupabaseSquadRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<SquadMember>>> getSquad() async {
    try {
      final rows = await _client
          .from('squad_members')
          .select()
          .order('sort_order', ascending: true);
      final members = rows
          .map((row) => SquadMember.fromJson(row))
          .toList(growable: false);
      return Success(members);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure('Não foi possível carregar o elenco.'));
    }
  }
}
