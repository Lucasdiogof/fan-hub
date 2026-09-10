import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/knockout_round_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_group_dto.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';

class CompetitionStageDto {
  const CompetitionStageDto({
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
  final String type;
  final String status;
  final bool isCurrent;
  final List<StandingDto> standings;
  final List<StandingGroupDto> groups;
  final List<KnockoutRoundDto> rounds;

  factory CompetitionStageDto.fromJson(Map<String, dynamic> json) =>
      CompetitionStageDto(
        id: json['id'] as String,
        name: json['name'] as String,
        order: json['order'] as int? ?? 0,
        type: json['type'] as String? ?? 'LEAGUE_TABLE',
        status: json['status'] as String? ?? 'ACTIVE',
        isCurrent: json['isCurrent'] as bool? ?? false,
        standings: ((json['standings'] as List?) ?? const [])
            .map((s) => StandingDto.fromJson(s as Map<String, dynamic>))
            .toList(),
        groups: ((json['groups'] as List?) ?? const [])
            .map((g) => StandingGroupDto.fromJson(g as Map<String, dynamic>))
            .toList(),
        rounds: ((json['rounds'] as List?) ?? const [])
            .map((r) => KnockoutRoundDto.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  CompetitionStage toEntity() => CompetitionStage(
    id: id,
    name: name,
    order: order,
    type: switch (competitionFormatFromJson(type)) {
      CompetitionFormat.groupStage => StageType.groupStage,
      CompetitionFormat.knockout => StageType.knockout,
      CompetitionFormat.leagueTable => StageType.leagueTable,
    },
    status: switch (status) {
      'UPCOMING' => StageStatus.upcoming,
      'COMPLETED' => StageStatus.completed,
      _ => StageStatus.active,
    },
    isCurrent: isCurrent,
    standings: standings.map((s) => s.toEntity()).toList(),
    groups: groups.map((g) => g.toEntity()).toList(),
    rounds: rounds.map((r) => r.toEntity()).toList(),
  );
}
