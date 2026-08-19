import 'package:goias_app/features/membership/domain/entities/regulation_version.dart';

/// Versão vigente do Regulamento do Sócio Esmeralda — fonte única de qual
/// arquivo carregar e qual identificador gravar num aceite.
class RegulationCatalog {
  const RegulationCatalog._();

  static final current = RegulationVersion(
    id: 'socio-esmeralda-2026-03-26',
    version: '2026-03-26',
    effectiveAt: DateTime(2026, 3, 26),
    assetPath: 'lib/assets/legal/membership_regulation.md',
  );
}
