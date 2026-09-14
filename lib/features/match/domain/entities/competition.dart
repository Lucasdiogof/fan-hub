import 'package:equatable/equatable.dart';

class Competition extends Equatable {
  const Competition({required this.name, required this.season, this.logoUrl});

  final String name;

  /// Nulo desde a troca pro OneFootball — a fonte não expõe ano de
  /// temporada nesses endpoints (nunca exibido na UI, então tanto faz).
  final int? season;

  /// Escudo da própria competição (`entityTitle.imageObject.path` do
  /// OneFootball) — nulo quando o provider não achou (nunca bloqueia a
  /// resposta por causa disso, ver `fetchCompetitionLogoUrl` no Worker). UI
  /// cai pro ícone genérico quando ausente.
  final String? logoUrl;

  @override
  List<Object?> get props => [name, season, logoUrl];
}
