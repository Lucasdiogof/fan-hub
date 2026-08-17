import 'package:goias_app/features/match/domain/entities/competition.dart';

class CompetitionDto {
  const CompetitionDto({required this.id, required this.name, required this.season});

  final int id;
  final String name;
  final int season;

  factory CompetitionDto.fromJson(Map<String, dynamic> json) => CompetitionDto(
    id: json['id'] as int,
    name: json['name'] as String,
    season: json['season'] as int,
  );

  Competition toEntity() => Competition(id: id, name: name, season: season);
}
