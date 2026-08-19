import 'package:equatable/equatable.dart';

/// Preparado para trocar o texto do regulamento no futuro sem perder a
/// referência de qual versão cada sócio aceitou.
class RegulationVersion extends Equatable {
  const RegulationVersion({
    required this.id,
    required this.version,
    required this.effectiveAt,
    required this.assetPath,
  });

  final String id;
  final String version;
  final DateTime effectiveAt;
  final String assetPath;

  @override
  List<Object?> get props => [id, version, effectiveAt, assetPath];
}
