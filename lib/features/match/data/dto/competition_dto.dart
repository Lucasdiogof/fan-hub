import 'package:goias_app/features/match/domain/entities/competition.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';

class CompetitionDto {
  const CompetitionDto({required this.name, required this.season, this.format});

  final String name;
  final int? season;

  /// `null` nos endpoints que nunca tiveram esse campo (`/team/:code`,
  /// `/current-round`, `/fixtures/:id`) — só `/standings` manda desde a
  /// auditoria multi-competição 2026-09-09. `LEAGUE_TABLE` é o default
  /// seguro quando ausente (comportamento de sempre, tabela achatada).
  final CompetitionFormat? format;

  factory CompetitionDto.fromJson(Map<String, dynamic> json) => CompetitionDto(
    name: json['name'] as String,
    season: json['season'] as int?,
    format: _formatFromJson(json['format'] as String?),
  );

  Competition toEntity() => Competition(name: name, season: season);
}

CompetitionFormat _formatFromJson(String? raw) => switch (raw) {
  'GROUP_STAGE' => CompetitionFormat.groupStage,
  'KNOCKOUT' => CompetitionFormat.knockout,
  _ => CompetitionFormat.leagueTable,
};

/// Um item do catálogo GLOBAL (`/api/football/competitions`) — nunca só as
/// competições do clube ativo (spec multi-competição, item 3).
class CompetitionRefDto {
  const CompetitionRefDto({
    required this.id,
    required this.name,
    required this.region,
    required this.format,
    required this.isClubParticipating,
  });

  final String id;
  final String name;
  final String region;
  final CompetitionFormat format;
  final bool isClubParticipating;

  factory CompetitionRefDto.fromJson(Map<String, dynamic> json) =>
      CompetitionRefDto(
        id: json['id'] as String,
        name: json['name'] as String,
        region: json['region'] as String? ?? '',
        format: _formatFromJson(json['format'] as String?),
        isClubParticipating: json['isClubParticipating'] as bool? ?? false,
      );

  CompetitionRef toEntity() => CompetitionRef(
    id: id,
    name: name,
    region: region,
    format: format,
    isClubParticipating: isClubParticipating,
  );
}
