import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';

/// Uma rodada dentro da `CompetitionStage` de mata-mata (ex.: "Oitavas de
/// final", "Semifinais", "Final") — rearquitetura 2026-09-11 (spec item 6):
/// uma Stage de mata-mata carrega VÁRIAS rounds, nunca uma Stage por round
/// (modelo anterior). `KnockoutBracketView` usa [order]/[isCurrent] pra
/// desenhar as colunas do bracket e escolher onde rolar o scroll inicial.
class KnockoutRound extends Equatable {
  const KnockoutRound({
    required this.id,
    required this.name,
    required this.order,
    required this.status,
    required this.isCurrent,
    required this.ties,
  });

  final String id;
  final String name;
  final int order;
  final StageStatus status;
  final bool isCurrent;
  final List<KnockoutTie> ties;

  @override
  List<Object?> get props => [id, name, order, status, isCurrent, ties];
}
