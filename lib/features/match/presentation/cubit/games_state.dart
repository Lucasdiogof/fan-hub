import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/shared/state/load_status.dart';

class GamesState extends Equatable {
  const GamesState({
    this.matchesStatus = LoadStatus.initial,
    this.standingsStatus = LoadStatus.initial,
    this.matches = const [],
    this.standings = const [],
    this.matchesErrorMessage,
    this.standingsErrorMessage,
  });

  final LoadStatus matchesStatus;
  final LoadStatus standingsStatus;
  final List<Match> matches;
  final List<Standing> standings;
  final String? matchesErrorMessage;
  final String? standingsErrorMessage;

  /// Todas as partidas foram buscadas de uma vez — próximo jogo, próximos
  /// jogos e resultados são derivados aqui, sem chamadas extras.
  Match? get nextMatch => MatchOrdering.nextMatch(matches);

  List<Match> get upcomingMatches => MatchOrdering.upcoming(matches);

  List<Match> get results => MatchOrdering.results(matches);

  GamesState copyWith({
    LoadStatus? matchesStatus,
    LoadStatus? standingsStatus,
    List<Match>? matches,
    List<Standing>? standings,
    String? matchesErrorMessage,
    String? standingsErrorMessage,
  }) {
    return GamesState(
      matchesStatus: matchesStatus ?? this.matchesStatus,
      standingsStatus: standingsStatus ?? this.standingsStatus,
      matches: matches ?? this.matches,
      standings: standings ?? this.standings,
      matchesErrorMessage: matchesErrorMessage ?? this.matchesErrorMessage,
      standingsErrorMessage: standingsErrorMessage ?? this.standingsErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    matchesStatus,
    standingsStatus,
    matches,
    standings,
    matchesErrorMessage,
    standingsErrorMessage,
  ];
}
