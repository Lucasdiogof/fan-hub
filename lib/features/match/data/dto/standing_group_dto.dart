import 'package:goias_app/features/match/data/dto/standing_dto.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';

class StandingGroupDto {
  const StandingGroupDto({required this.title, required this.standings});

  final String title;
  final List<StandingDto> standings;

  factory StandingGroupDto.fromJson(Map<String, dynamic> json) =>
      StandingGroupDto(
        title: json['title'] as String,
        standings: (json['standings'] as List)
            .map((s) => StandingDto.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  StandingGroup toEntity() => StandingGroup(
    title: title,
    standings: standings.map((s) => s.toEntity()).toList(),
  );
}
