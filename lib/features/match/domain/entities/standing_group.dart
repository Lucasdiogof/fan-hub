import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';

/// Um grupo de uma competição em fase de grupos (ex.: "Grupo H" da
/// CONMEBOL Sudamericana) — [standings] tem a mesma forma da tabela normal
/// (é a mesma entidade [Standing]/`StandingsRow` reaproveitada), só que
/// escopada a um grupo em vez do campeonato inteiro.
class StandingGroup extends Equatable {
  const StandingGroup({required this.title, required this.standings});

  final String title;
  final List<Standing> standings;

  @override
  List<Object?> get props => [title, standings];
}
