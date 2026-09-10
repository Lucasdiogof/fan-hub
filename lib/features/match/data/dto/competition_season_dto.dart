import 'package:goias_app/features/match/data/dto/competition_stage_dto.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';

class CompetitionSeasonDto {
  const CompetitionSeasonDto({
    required this.id,
    required this.label,
    required this.stages,
  });

  final String id;
  final String label;
  final List<CompetitionStageDto> stages;

  factory CompetitionSeasonDto.fromJson(Map<String, dynamic> json) =>
      CompetitionSeasonDto(
        id: json['id'] as String? ?? 'default',
        label: json['label'] as String? ?? '',
        stages: ((json['stages'] as List?) ?? const [])
            .map((s) => CompetitionStageDto.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  CompetitionSeason toEntity() => CompetitionSeason(
    id: id,
    label: label,
    stages: stages.map((s) => s.toEntity()).toList(),
  );
}
