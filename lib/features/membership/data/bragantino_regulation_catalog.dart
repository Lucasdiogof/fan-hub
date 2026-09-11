import 'package:goias_app/features/membership/domain/entities/regulation_version.dart';

/// Versão vigente do Termo de Adesão Massa Bruta (ver
/// `bragantino_regulation_content.dart` pro porquê deste texto ser próprio
/// do app, não uma cópia do Regulamento oficial do clube).
class BragantinoRegulationCatalog {
  const BragantinoRegulationCatalog._();

  static final current = RegulationVersion(
    id: 'massa-bruta-fan-hub-2026-09-11',
    version: '2026-09-11',
    effectiveAt: DateTime(2026, 9, 11),
    assetPath: 'lib/assets/legal/bragantino_membership_regulation.md',
  );
}
