import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/release/app_platform.dart';
import 'package:goias_app/core/release/app_release_requirement.dart';
import 'package:goias_app/core/release/app_version_comparator.dart';
import 'package:goias_app/core/release/release_requirement_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Gate de release, mesmo espírito do `SplashGate`: um `ChangeNotifier` que
/// o router consulta pra decidir se redireciona pra `/update-required`.
///
/// Política fail-safe (nunca trava o app por indisponibilidade): timeout
/// curto + qualquer erro (rede, parse, o que for) é tratado como "não
/// bloqueado" — uma indisponibilidade temporária do Supabase nunca pode
/// impedir TODO MUNDO de usar o app. O contrapeso é que isso só protege de
/// verdade quem já roda uma versão nova o bastante pra consultar este gate
/// — um app antigo publicado sem essa checagem simplesmente não sabe que
/// ela existe (ver docs/multiclub/36_etapa_rollout_gate_report.md, achado
/// central §18).
class ReleaseGate extends ChangeNotifier {
  ReleaseGate(this._repository);

  final ReleaseRequirementRepository _repository;

  static const _checkTimeout = Duration(seconds: 3);

  bool _checked = false;
  bool _blocked = false;
  AppReleaseRequirement? _requirement;

  bool get checked => _checked;
  bool get blocked => _blocked;
  AppReleaseRequirement? get requirement => _requirement;

  /// Idempotente — só a primeira chamada consulta o servidor; chamadas
  /// seguintes (ex.: se o router reavaliar o redirect várias vezes) são
  /// no-op. Nunca lança: qualquer falha vira "não bloqueado".
  Future<void> ensureChecked() async {
    if (_checked) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final result = await _repository
          .getRequirement(platform: currentPlatformKey())
          .timeout(_checkTimeout);
      if (result case Success(data: final requirement?)) {
        if (requirement.forceUpdate &&
            isBelowMinimumRelease(
              currentBuild: currentBuild,
              currentVersion: packageInfo.version,
              minimumBuild: requirement.minimumBuild,
              minimumVersion: requirement.minimumVersion,
            )) {
          _blocked = true;
          _requirement = requirement;
        }
      }
    } catch (_) {
      // Timeout, sem internet, resposta inválida, o que for — fail-open.
    } finally {
      _checked = true;
      notifyListeners();
    }
  }
}
