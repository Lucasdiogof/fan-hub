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

/// Como o placar de uma [PassportMatch] deve ser lido — resolvido uma
/// única vez (ver [PassportMatch.score]), nunca cada tela decidindo por
/// conta própria se pode inferir mando.
enum PassportScoreMode {
  /// `homeScore`/`awayScore` conhecidos — modo padrão, mandante × visitante.
  homeAway,

  /// Só `clubScore`/`opponentScore` conhecidos (comum em 1943-1999: o
  /// resultado é confirmado, mas a fonte não distingue mandante de
  /// visitante). Apresentação NEUTRA pela perspectiva do clube — nunca
  /// infere quem jogou em casa.
  clubPerspective,

  /// Nenhum dos dois pares está completo — placar realmente desconhecido
  /// (hoje só 1 partida em todo o catálogo: Goiás x ABG, 1946).
  unknown,
}

/// Placar resolvido pra exibição — [PassportMatch.score]. As 3 telas do
/// Passaporte (lista, linha v1, ticket v2) leem só isto, nunca
/// `homeScore`/`awayScore`/`clubScore`/`opponentScore` diretamente, pra
/// nunca divergir entre si sobre quando/como mostrar o placar.
class PassportScoreDisplay extends Equatable {
  const PassportScoreDisplay({
    required this.mode,
    this.firstScore,
    this.secondScore,
  });

  final PassportScoreMode mode;

  /// Mandante (modo [PassportScoreMode.homeAway]) ou clube (modo
  /// [PassportScoreMode.clubPerspective]). `null` só no modo
  /// [PassportScoreMode.unknown].
  final int? firstScore;

  /// Visitante (modo [PassportScoreMode.homeAway]) ou adversário (modo
  /// [PassportScoreMode.clubPerspective]). `null` só no modo
  /// [PassportScoreMode.unknown].
  final int? secondScore;

  bool get isKnown => mode != PassportScoreMode.unknown;

  @override
  List<Object?> get props => [mode, firstScore, secondScore];
}

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

  /// `null` em exatamente 1 partida de todo o catálogo (Goiás x ABG, 1946):
  /// existência confirmada, mas dia/mês nunca recuperados por nenhuma
  /// fonte. Nunca fabricar uma data pra preencher — ver
  /// `date_precision` (`'year_only'` nesse caso).
  final DateTime? matchDate;
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

  /// Resolução centralizada do placar pra exibição — ver
  /// [PassportScoreMode]. Regra, nessa ordem:
  /// 1. `homeScore`+`awayScore` completos -> [PassportScoreMode.homeAway].
  /// 2. senão, `clubScore`+`opponentScore` completos ->
  ///    [PassportScoreMode.clubPerspective] (nunca infere mando).
  /// 3. senão -> [PassportScoreMode.unknown].
  PassportScoreDisplay get score {
    if (homeScore != null && awayScore != null) {
      return PassportScoreDisplay(
        mode: PassportScoreMode.homeAway,
        firstScore: homeScore,
        secondScore: awayScore,
      );
    }
    if (clubScore != null && opponentScore != null) {
      return PassportScoreDisplay(
        mode: PassportScoreMode.clubPerspective,
        firstScore: clubScore,
        secondScore: opponentScore,
      );
    }
    return const PassportScoreDisplay(mode: PassportScoreMode.unknown);
  }

  /// Nunca partida futura pode ser marcada, mesmo se por algum motivo
  /// viesse marcada como FINISHED — checagem espelha a da RPC de
  /// salvamento, que é quem realmente decide. Data desconhecida nunca é
  /// tratada como futura (mesma leitura que a RPC faz de `null > current_date`).
  bool get canMarkAttendance =>
      isFinished && (matchDate == null || !matchDate!.isAfter(DateTime.now()));

  factory PassportMatch.fromMap(Map<String, dynamic> map) => PassportMatch(
    id: map['id'] as String,
    season: map['season'] as int,
    matchDate: map['match_date'] == null
        ? null
        : DateTime.parse(map['match_date'] as String),
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

/// Comparador "mais recente primeiro" que nunca quebra com `matchDate`
/// desconhecido — a partida de data desconhecida sempre vai pro final da
/// lista, do mesmo jeito que as RPCs já fazem com `nulls last` no banco.
int compareMatchDateDesc(PassportMatch a, PassportMatch b) {
  final aDate = a.matchDate;
  final bDate = b.matchDate;
  if (aDate == null && bDate == null) return 0;
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return bDate.compareTo(aDate);
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
