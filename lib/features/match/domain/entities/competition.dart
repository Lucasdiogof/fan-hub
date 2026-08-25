import 'package:equatable/equatable.dart';

class Competition extends Equatable {
  const Competition({required this.name, required this.season});

  final String name;

  /// Nulo desde a troca pro OneFootball — a fonte não expõe ano de
  /// temporada nesses endpoints (nunca exibido na UI, então tanto faz).
  final int? season;

  @override
  List<Object?> get props => [name, season];
}
