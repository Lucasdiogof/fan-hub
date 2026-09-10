import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';

/// Uma fase de uma [CompetitionSeason] (rearquitetura multi-competição
/// 2026-09-10/11, spec item 5/6) — carrega exatamente UM tipo de conteúdo
/// de acordo com [type]: `leagueTable` popula [standings], `groupStage`
/// popula [groups], `knockout` popula [rounds] (uma Stage de mata-mata
/// carrega TODAS as rodadas — Oitavas/Quartas/Semi/Final —, nunca uma
/// Stage por rodada). Nunca mais de um populado ao mesmo tempo.
class CompetitionStage extends Equatable {
  const CompetitionStage({
    required this.id,
    required this.name,
    required this.order,
    required this.type,
    required this.status,
    required this.isCurrent,
    this.standings = const [],
    this.groups = const [],
    this.rounds = const [],
  });

  final String id;
  final String name;
  final int order;
  final StageType type;
  final StageStatus status;
  final bool isCurrent;
  final List<Standing> standings;
  final List<StandingGroup> groups;
  final List<KnockoutRound> rounds;

  bool get hasData =>
      standings.isNotEmpty || groups.isNotEmpty || rounds.isNotEmpty;

  /// Rodada a abrir por padrão dentro desta Stage de mata-mata (spec item
  /// 8, "current knockout round" — conceito DISTINTO de
  /// `CompetitionSeason.currentStage`): a rodada marcada como atual pelo
  /// Worker (mesma prioridade — ativa > última completa), `null` quando
  /// não há rodada nenhuma.
  KnockoutRound? get currentRound {
    if (rounds.isEmpty) return null;
    for (final round in rounds) {
      if (round.isCurrent) return round;
    }
    return rounds.last;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    order,
    type,
    status,
    isCurrent,
    standings,
    groups,
    rounds,
  ];
}
