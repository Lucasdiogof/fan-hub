import 'package:flutter/material.dart';
import 'package:goias_app/features/club/data/goias_idols_data.dart';
import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/domain/idol_stats_calculator.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

/// ID do Goiás no OneFootball (o mesmo de `goiasClubConfig`).
const clubTeamId = 1863;

/// O Tadeu REAL do catálogo — os testes usam o baseline de verdade.
ClubIdol get tadeu => GoiasIdolsData.idols.firstWhere((i) => i.name == 'Tadeu');
ActiveIdolTracking get tadeuTracking => tadeu.tracking!;

/// Partida que FECHA o baseline do Tadeu (Novorizontino x Goiás, 01/10/2026).
const baselineMatchId = 'onef-2669540';

/// Partidas posteriores ao baseline (instantes UTC).
final after1 = DateTime.utc(2026, 10, 6, 23, 30); // 06/10 20:30 BRT
final after2 = DateTime.utc(2026, 10, 12, 21, 30); // 12/10 18:30 BRT
final after3 = DateTime.utc(2026, 10, 19, 21, 30);

const _goias = Team(
  id: clubTeamId,
  name: 'Goiás',
  shortName: 'GOI',
  color: Colors.green,
);
const _rival = Team(
  id: 999,
  name: 'Rival',
  shortName: 'RIV',
  color: Colors.blue,
);

LineupPlayer starter(String name, int? id, {int number = 1}) => LineupPlayer(
  name: name,
  jerseyNumber: number,
  photo: '',
  providerPlayerId: id,
);

MatchEvent sub(String playerIn, {MatchEventSide side = MatchEventSide.home}) =>
    MatchEvent(
      minute: "60'",
      side: side,
      type: MatchEventType.substitution,
      player: playerIn,
      detail: 'Fulano',
    );

/// Substituição em que o provedor TROUXE o ID de quem entrou.
MatchEvent subWithId(
  String playerIn,
  int playerInId, {
  MatchEventSide side = MatchEventSide.home,
}) => MatchEvent(
  minute: "60'",
  side: side,
  type: MatchEventType.substitution,
  player: playerIn,
  detail: 'Fulano',
  playerInId: playerInId,
);

MatchEvent goal(
  String scorer, {
  MatchEventSide side = MatchEventSide.home,
  String? detail,
}) => MatchEvent(
  minute: "70'",
  side: side,
  type: MatchEventType.goal,
  player: scorer,
  detail: detail,
);

/// Partida do Goiás. [starters] são os titulares do Goiás; por padrão o
/// Goiás joga em casa (lado `home`).
IdolMatchRecord record({
  required String id,
  required DateTime kickoff,
  MatchStatus status = MatchStatus.finished,
  List<LineupPlayer> starters = const [],
  List<MatchEvent> events = const [],
  bool home = true,
  bool withLineups = true,
}) {
  final match = Match(
    id: id,
    competition: 'Brasileirão Série B',
    round: '1',
    homeTeam: home ? _goias : _rival,
    awayTeam: home ? _rival : _goias,
    stadium: 'Serra Dourada',
    kickoff: kickoff,
    status: status,
  );
  const empty = TeamLineup(teamName: 'Rival', rows: []);
  final goias = TeamLineup(teamName: 'Goiás', rows: [starters]);
  return IdolMatchRecord(
    match: match,
    events: events,
    lineups: withLineups
        ? MatchLineups(home: home ? goias : empty, away: home ? empty : goias)
        : null,
  );
}

/// Titular real do Tadeu (ID 48597).
LineupPlayer get tadeuStarter =>
    starter('Tadeu', tadeuTracking.providerPlayerId);
