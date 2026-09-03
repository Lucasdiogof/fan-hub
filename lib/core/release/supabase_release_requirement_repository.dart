import 'dart:async';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/release/app_release_requirement.dart';
import 'package:goias_app/core/release/release_requirement_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lê `app_release_requirements` — mesmo padrão de `SupabaseSquadRepository`
/// (tabela pública, club-scoped, sem fallback offline: nenhuma linha
/// configurada é uma resposta válida, não erro). Precisa funcionar SEM
/// sessão (chamada antes do login, no boot) — a policy de leitura é pública
/// de propósito (ver migration).
class SupabaseReleaseRequirementRepository implements ReleaseRequirementRepository {
  SupabaseReleaseRequirementRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  @override
  Future<Result<AppReleaseRequirement?>> getRequirement({
    required String platform,
  }) async {
    try {
      final rows = await _client
          .from('app_release_requirements')
          .select()
          .eq('club_id', _clubConfig.identity.canonicalClubId)
          .eq('platform', platform)
          .limit(1);
      if (rows.isEmpty) return const Success(null);
      return Success(AppReleaseRequirement.fromJson(rows.first));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível verificar a versão mínima do app.'),
      );
    }
  }
}
