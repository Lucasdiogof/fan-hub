import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/release/app_release_requirement.dart';

abstract class ReleaseRequirementRepository {
  /// `null` de sucesso significa "nenhuma linha configurada pra essa
  /// plataforma/clube" — nada a exigir, nunca bloqueia. `Error` é reservado
  /// pra falha real (rede/servidor); quem chama decide a política fail-safe.
  Future<Result<AppReleaseRequirement?>> getRequirement({
    required String platform,
  });
}
