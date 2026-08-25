import 'package:goias_app/features/match/domain/entities/lineup.dart';

class LineupPlayerDto {
  const LineupPlayerDto({
    required this.name,
    required this.jerseyNumber,
    required this.photo,
  });

  final String name;
  final int jerseyNumber;
  final String photo;

  factory LineupPlayerDto.fromJson(Map<String, dynamic> json) {
    return LineupPlayerDto(
      name: json['name'] as String? ?? '',
      jerseyNumber: json['jerseyNumber'] as int? ?? 0,
      photo: json['photo'] as String? ?? '',
    );
  }

  LineupPlayer toEntity() {
    return LineupPlayer(name: name, jerseyNumber: jerseyNumber, photo: photo);
  }
}

class TeamLineupDto {
  const TeamLineupDto({required this.teamName, required this.rows});

  final String teamName;
  final List<List<LineupPlayerDto>> rows;

  factory TeamLineupDto.fromJson(Map<String, dynamic> json) {
    final rawRows = (json['rows'] as List?) ?? [];
    return TeamLineupDto(
      teamName: json['teamName'] as String? ?? '',
      rows: rawRows
          .map(
            (row) => ((row as List?) ?? [])
                .map((p) => LineupPlayerDto.fromJson(p as Map<String, dynamic>))
                .toList(),
          )
          .toList(),
    );
  }

  TeamLineup toEntity() {
    return TeamLineup(
      teamName: teamName,
      rows: rows.map((row) => row.map((p) => p.toEntity()).toList()).toList(),
    );
  }
}

class MatchLineupsDto {
  const MatchLineupsDto({required this.home, required this.away});

  final TeamLineupDto home;
  final TeamLineupDto away;

  factory MatchLineupsDto.fromJson(Map<String, dynamic> json) {
    return MatchLineupsDto(
      home: TeamLineupDto.fromJson(json['home'] as Map<String, dynamic>),
      away: TeamLineupDto.fromJson(json['away'] as Map<String, dynamic>),
    );
  }

  MatchLineups toEntity() {
    return MatchLineups(home: home.toEntity(), away: away.toEntity());
  }
}
