import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

/// `single`: jogo único. `first`/`second`: ida/volta (spec item 14) — nunca
/// inferido por posição na lista, sempre vindo do provider (ver
/// `KnockoutTieDto`).
enum KnockoutLegType { single, first, second }

class KnockoutLeg extends Equatable {
  const KnockoutLeg({
    required this.legType,
    required this.status,
    this.kickoff,
    this.homeScore,
    this.awayScore,
  });

  final KnockoutLegType legType;
  final MatchStatus status;
  final DateTime? kickoff;

  /// `null` enquanto a partida não tem placar (futura/adiada) — nunca 0
  /// inventado (spec item 14).
  final int? homeScore;
  final int? awayScore;

  @override
  List<Object?> get props => [legType, status, kickoff, homeScore, awayScore];
}

/// Um confronto de mata-mata — jogo único ou ida/volta, com agregado já
/// calculado pelo Worker (spec item 14: "não force tudo pra dentro de
/// Standing"). [aggregateHome]/[aggregateAway] só vêm preenchidos quando
/// TODAS as pernas já têm placar; pênaltis, quando confirmados, aparecem em
/// [penaltyHome]/[penaltyAway] — sem confirmação real de um confronto que
/// foi a pênaltis, os dois ficam `null` (nunca inventado).
class KnockoutTie extends Equatable {
  const KnockoutTie({
    required this.homeTeam,
    required this.awayTeam,
    required this.legs,
    this.aggregateHome,
    this.aggregateAway,
    this.penaltyHome,
    this.penaltyAway,
  });

  final Team homeTeam;
  final Team awayTeam;
  final List<KnockoutLeg> legs;
  final int? aggregateHome;
  final int? aggregateAway;
  final int? penaltyHome;
  final int? penaltyAway;

  bool get isDecided =>
      aggregateHome != null &&
      aggregateAway != null &&
      aggregateHome != aggregateAway;

  bool get wentToPenalties => penaltyHome != null && penaltyAway != null;

  Team? get winner {
    if (wentToPenalties) {
      return penaltyHome! > penaltyAway! ? homeTeam : awayTeam;
    }
    if (isDecided) {
      return aggregateHome! > aggregateAway! ? homeTeam : awayTeam;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    homeTeam,
    awayTeam,
    legs,
    aggregateHome,
    aggregateAway,
    penaltyHome,
    penaltyAway,
  ];
}
