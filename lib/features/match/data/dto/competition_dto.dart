import 'package:goias_app/features/match/domain/entities/competition.dart';

class CompetitionDto {
  const CompetitionDto({required this.name, required this.season});

  final String name;
  final int season;

  factory CompetitionDto.fromJson(Map<String, dynamic> json) => CompetitionDto(
    name: json['name'] as String,
    season: json['season'] as int,
  );

  Competition toEntity() => Competition(name: name, season: season);
}
