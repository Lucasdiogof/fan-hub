import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/shared/state/load_status.dart';

class GamesState extends Equatable {
  const GamesState({
    this.currentRoundStatus = LoadStatus.initial,
    this.snapshotStatus = LoadStatus.initial,
    this.standingsStatus = LoadStatus.initial,
    this.currentRoundMatches = const [],
    this.roundOffset = 0,
    this.roundLabel,
    this.hasPreviousRound = false,
    this.hasNextRound = false,
    this.nextMatch,
    this.standings = const [],
    this.standingGroups = const [],
    this.competitions = const [],
    this.selectedCompetition,
    this.currentRoundErrorMessage,
    this.snapshotErrorMessage,
    this.standingsErrorMessage,
  });

  final LoadStatus currentRoundStatus;
  final LoadStatus snapshotStatus;
  final LoadStatus standingsStatus;
  final List<Match> currentRoundMatches;

  /// Relativo à rodada atual (0). Negativo = navegou pra rodadas
  /// anteriores. Zerado a cada `loadCurrentRound()`/pull-to-refresh.
  final int roundOffset;
  final String? roundLabel;
  final bool hasPreviousRound;
  final bool hasNextRound;
  final Match? nextMatch;

  /// Populada quando [selectedCompetition]`.format` é `leagueTable` — tabela
  /// achatada, um time por linha.
  final List<Standing> standings;

  /// Populada quando [selectedCompetition]`.format` é `groupStage` — um
  /// grupo por item, cada um com a própria tabela. Exatamente um de
  /// [standings]/[standingGroups] vem preenchido por vez, nunca os dois.
  final List<StandingGroup> standingGroups;

  /// Competições que o clube ativo disputa (sempre inclui a principal) —
  /// popula o seletor da aba Classificação. Vazio até `loadCompetitions()`
  /// responder; a UI não trava nisso (mostra a tabela da principal
  /// enquanto isso, que já carrega em paralelo).
  final List<CompetitionRef> competitions;

  /// `null` até a primeira resposta de `/standings` chegar — depois disso
  /// sempre reflete a competição realmente mostrada (a API já resolveu
  /// "primary" pro `CompetitionRef` real).
  final CompetitionRef? selectedCompetition;
  final String? currentRoundErrorMessage;
  final String? snapshotErrorMessage;
  final String? standingsErrorMessage;

  GamesState copyWith({
    LoadStatus? currentRoundStatus,
    LoadStatus? snapshotStatus,
    LoadStatus? standingsStatus,
    List<Match>? currentRoundMatches,
    int? roundOffset,
    String? roundLabel,
    bool clearRoundLabel = false,
    bool? hasPreviousRound,
    bool? hasNextRound,
    Match? nextMatch,
    bool clearNextMatch = false,
    List<Standing>? standings,
    List<StandingGroup>? standingGroups,
    List<CompetitionRef>? competitions,
    CompetitionRef? selectedCompetition,
    String? currentRoundErrorMessage,
    String? snapshotErrorMessage,
    String? standingsErrorMessage,
  }) {
    return GamesState(
      currentRoundStatus: currentRoundStatus ?? this.currentRoundStatus,
      snapshotStatus: snapshotStatus ?? this.snapshotStatus,
      standingsStatus: standingsStatus ?? this.standingsStatus,
      currentRoundMatches: currentRoundMatches ?? this.currentRoundMatches,
      roundOffset: roundOffset ?? this.roundOffset,
      roundLabel: clearRoundLabel ? null : (roundLabel ?? this.roundLabel),
      hasPreviousRound: hasPreviousRound ?? this.hasPreviousRound,
      hasNextRound: hasNextRound ?? this.hasNextRound,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      standings: standings ?? this.standings,
      standingGroups: standingGroups ?? this.standingGroups,
      competitions: competitions ?? this.competitions,
      selectedCompetition: selectedCompetition ?? this.selectedCompetition,
      currentRoundErrorMessage:
          currentRoundErrorMessage ?? this.currentRoundErrorMessage,
      snapshotErrorMessage: snapshotErrorMessage ?? this.snapshotErrorMessage,
      standingsErrorMessage:
          standingsErrorMessage ?? this.standingsErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    currentRoundStatus,
    snapshotStatus,
    standingsStatus,
    currentRoundMatches,
    roundOffset,
    roundLabel,
    hasPreviousRound,
    hasNextRound,
    nextMatch,
    standings,
    standingGroups,
    competitions,
    selectedCompetition,
    currentRoundErrorMessage,
    snapshotErrorMessage,
    standingsErrorMessage,
  ];
}
