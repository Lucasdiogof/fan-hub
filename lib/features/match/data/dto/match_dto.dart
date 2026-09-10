import 'package:goias_app/features/match/data/dto/team_dto.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

class MatchDto {
  const MatchDto({
    required this.id,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoffRaw,
    required this.statusName,
    this.venue,
    this.homeScore,
    this.awayScore,
    this.minute,
    this.competition,
  });

  final String id;
  final String round;
  final TeamDto homeTeam;
  final TeamDto awayTeam;

  /// Preenchido nos endpoints onde uma partida pode ser de uma competição
  /// diferente da principal do clube (Goianão, Copa do Brasil, torneio
  /// continental...): temporada (`getSeasonFixtures`) e o feed do time
  /// (`getActiveClubSnapshot`). `standings`/`current-round` são operações
  /// da competição principal de verdade — todo item já é dela, então nunca
  /// precisam desse campo por partida (ver `toEntity`, que nunca usa a
  /// competição principal como fallback de partida, só `''`).
  final String? competition;

  /// Horário de parede do Brasil, sem offset (a fonte não fornece UTC) —
  /// `toEntity` interpreta como America/Sao_Paulo via [parseKickoffInstant]
  /// (correção 2026-09-12: nunca mais parseado como se já fosse hora local
  /// do APARELHO). `null` quando a fonte ainda não confirmou o horário
  /// (visto em jogos futuros do TheSportsDB antes da data ser fechada).
  final String? kickoffRaw;
  final String statusName;
  final String? venue;
  final int? homeScore;
  final int? awayScore;
  final String? minute;

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    return MatchDto(
      id: json['id'] as String,
      round: json['round'] as String? ?? '',
      homeTeam: TeamDto.fromJson(json['homeTeam'] as Map<String, dynamic>),
      awayTeam: TeamDto.fromJson(json['awayTeam'] as Map<String, dynamic>),
      kickoffRaw: json['kickoff'] as String?,
      statusName: json['status'] as String? ?? 'unknown',
      venue: json['venue'] as String?,
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      minute: json['minute'] as String?,
      competition: json['competition'] as String?,
    );
  }

  Match toEntity({required String competitionName}) {
    return Match(
      id: id,
      competition: competition ?? competitionName,
      round: round,
      homeTeam: homeTeam.toEntity(),
      awayTeam: awayTeam.toEntity(),
      stadium: venue ?? '',
      kickoff: parseKickoffInstant(kickoffRaw),
      status: MatchStatus.values.asNameMap()[statusName] ?? MatchStatus.unknown,
      homeScore: homeScore,
      awayScore: awayScore,
      minute: minute,
    );
  }
}
