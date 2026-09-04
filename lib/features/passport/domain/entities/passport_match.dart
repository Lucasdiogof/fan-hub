import 'package:equatable/equatable.dart';

enum PassportMatchStatus { finished, scheduled, postponed, cancelled, unknown }

PassportMatchStatus _parseStatus(String value) => switch (value) {
  'FINISHED' => PassportMatchStatus.finished,
  'SCHEDULED' => PassportMatchStatus.scheduled,
  'POSTPONED' => PassportMatchStatus.postponed,
  'CANCELLED' => PassportMatchStatus.cancelled,
  _ => PassportMatchStatus.unknown,
};

enum PassportOutcome { win, draw, loss }

PassportOutcome? _parseOutcome(String? value) => switch (value) {
  'WIN' => PassportOutcome.win,
  'DRAW' => PassportOutcome.draw,
  'LOSS' => PassportOutcome.loss,
  _ => null,
};

/// Uma partida do catálogo histórico (ver `passport_matches` no Supabase) —
/// espelha 1:1 o JSON oficial (`passaporte_esmeraldino_partidas_2000_2026`),
/// nunca inventa dado ausente (horário/estádio nulos continuam nulos).
/// `attended` já vem calculado pelo servidor (RPC `passport_matches_for_year`
/// faz o `left join` com a presença do usuário atual) — nunca uma segunda
/// fonte de verdade local.
class PassportMatch extends Equatable {
  const PassportMatch({
    required this.id,
    required this.season,
    required this.matchDate,
    required this.status,
    required this.competition,
    required this.competitionCode,
    required this.opponent,
    required this.attended,
    this.matchTime,
    this.kickoffAt,
    this.round,
    this.clubIsHome,
    this.neutralSite,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.clubScore,
    this.opponentScore,
    this.scoreDisplay,
    this.outcome,
    this.venueName,
    this.venueCity,
  });

  final String id;
  final int season;
  final DateTime matchDate;
  final String? matchTime;
  final DateTime? kickoffAt;
  final PassportMatchStatus status;
  final String competition;
  final String competitionCode;
  final String? round;
  final String opponent;
  final bool? clubIsHome;
  final bool? neutralSite;
  final String? homeTeam;
  final String? awayTeam;
  final int? homeScore;
  final int? awayScore;
  final int? clubScore;
  final int? opponentScore;
  final String? scoreDisplay;
  final PassportOutcome? outcome;
  final String? venueName;
  final String? venueCity;
  final bool attended;

  bool get isFinished => status == PassportMatchStatus.finished;

  /// Nunca partida futura pode ser marcada, mesmo se por algum motivo
  /// viesse marcada como FINISHED — checagem espelha a da RPC de
  /// salvamento, que é quem realmente decide.
  bool get canMarkAttendance =>
      isFinished && !matchDate.isAfter(DateTime.now());

  factory PassportMatch.fromMap(Map<String, dynamic> map) => PassportMatch(
    id: map['id'] as String,
    season: map['season'] as int,
    matchDate: DateTime.parse(map['match_date'] as String),
    matchTime: map['match_time'] as String?,
    kickoffAt: map['kickoff_at'] == null
        ? null
        : DateTime.parse(map['kickoff_at'] as String).toLocal(),
    status: _parseStatus(map['status'] as String),
    competition: map['competition'] as String,
    competitionCode: map['competition_code'] as String,
    round: map['round'] as String?,
    opponent: map['opponent'] as String,
    clubIsHome: map['club_is_home'] as bool?,
    neutralSite: map['neutral_site'] as bool?,
    homeTeam: map['home_team'] as String?,
    awayTeam: map['away_team'] as String?,
    homeScore: map['home_score'] as int?,
    awayScore: map['away_score'] as int?,
    clubScore: map['club_score'] as int?,
    opponentScore: map['opponent_score'] as int?,
    scoreDisplay: map['score_display'] as String?,
    outcome: _parseOutcome(map['outcome'] as String?),
    venueName: map['venue_name'] as String?,
    venueCity: map['venue_city'] as String?,
    attended: map['attended'] as bool? ?? false,
  );

  PassportMatch copyWith({bool? attended}) => PassportMatch(
    id: id,
    season: season,
    matchDate: matchDate,
    matchTime: matchTime,
    kickoffAt: kickoffAt,
    status: status,
    competition: competition,
    competitionCode: competitionCode,
    round: round,
    opponent: opponent,
    clubIsHome: clubIsHome,
    neutralSite: neutralSite,
    homeTeam: homeTeam,
    awayTeam: awayTeam,
    homeScore: homeScore,
    awayScore: awayScore,
    clubScore: clubScore,
    opponentScore: opponentScore,
    scoreDisplay: scoreDisplay,
    outcome: outcome,
    venueName: venueName,
    venueCity: venueCity,
    attended: attended ?? this.attended,
  );

  @override
  List<Object?> get props => [
    id,
    season,
    matchDate,
    matchTime,
    kickoffAt,
    status,
    competition,
    competitionCode,
    round,
    opponent,
    clubIsHome,
    neutralSite,
    homeTeam,
    awayTeam,
    homeScore,
    awayScore,
    clubScore,
    opponentScore,
    scoreDisplay,
    outcome,
    venueName,
    venueCity,
    attended,
  ];
}

/// Uma temporada do seletor de ano — nunca carrega as partidas junto, só a
/// contagem (ver RPC `passport_seasons`).
class PassportSeason extends Equatable {
  const PassportSeason({
    required this.season,
    required this.matchCount,
    required this.finishedCount,
  });

  final int season;
  final int matchCount;
  final int finishedCount;

  factory PassportSeason.fromMap(Map<String, dynamic> map) => PassportSeason(
    season: map['season'] as int,
    matchCount: map['match_count'] as int,
    finishedCount: map['finished_count'] as int,
  );

  @override
  List<Object?> get props => [season, matchCount, finishedCount];
}
