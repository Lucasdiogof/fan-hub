import 'package:equatable/equatable.dart';

/// Resumo do usuário no Passaporte — nunca conta estádios visitados (isso
/// só quando o Passaporte de Estádios existir de verdade, com `venue_id`
/// enriquecido; contar hoje daria um número sempre igual a zero/errado).
class PassportSummary extends Equatable {
  const PassportSummary({
    required this.totalMatches,
    required this.yearsWithAttendance,
    this.firstMarkedMatchId,
    this.firstMarkedMatchDate,
    this.lastMarkedMatchId,
    this.lastMarkedMatchDate,
  });

  final int totalMatches;
  final int yearsWithAttendance;
  final String? firstMarkedMatchId;
  final DateTime? firstMarkedMatchDate;
  final String? lastMarkedMatchId;
  final DateTime? lastMarkedMatchDate;

  static const empty = PassportSummary(totalMatches: 0, yearsWithAttendance: 0);

  factory PassportSummary.fromMap(Map<String, dynamic> map) => PassportSummary(
    totalMatches: map['total_matches'] as int? ?? 0,
    yearsWithAttendance: map['years_with_attendance'] as int? ?? 0,
    firstMarkedMatchId: map['first_marked_match_id'] as String?,
    firstMarkedMatchDate: map['first_marked_match_date'] == null
        ? null
        : DateTime.parse(map['first_marked_match_date'] as String),
    lastMarkedMatchId: map['last_marked_match_id'] as String?,
    lastMarkedMatchDate: map['last_marked_match_date'] == null
        ? null
        : DateTime.parse(map['last_marked_match_date'] as String),
  );

  @override
  List<Object?> get props => [
    totalMatches,
    yearsWithAttendance,
    firstMarkedMatchId,
    firstMarkedMatchDate,
    lastMarkedMatchId,
    lastMarkedMatchDate,
  ];
}

/// Números da trajetória do usuário — só sobre partidas FINISHED marcadas
/// como "Eu fui" (agregado no servidor via `passport_attendance_breakdown`,
/// cobre todas as temporadas de uma vez, nunca só o ano selecionado na
/// tela). [totalMatches] aqui pode ser menor que
/// [PassportSummary.totalMatches] se o usuário tiver marcado alguma
/// partida ainda não finalizada (agendada/adiada).
class PassportAttendanceBreakdown extends Equatable {
  const PassportAttendanceBreakdown({
    required this.totalMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.homeGames,
    required this.awayGames,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final int homeGames;
  final int awayGames;
  final int goalsFor;
  final int goalsAgainst;

  static const empty = PassportAttendanceBreakdown(
    totalMatches: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    homeGames: 0,
    awayGames: 0,
    goalsFor: 0,
    goalsAgainst: 0,
  );

  factory PassportAttendanceBreakdown.fromMap(Map<String, dynamic> map) =>
      PassportAttendanceBreakdown(
        totalMatches: map['total_attended'] as int? ?? 0,
        wins: map['wins'] as int? ?? 0,
        draws: map['draws'] as int? ?? 0,
        losses: map['losses'] as int? ?? 0,
        homeGames: map['home_games'] as int? ?? 0,
        awayGames: map['away_games'] as int? ?? 0,
        goalsFor: map['goals_for'] as int? ?? 0,
        goalsAgainst: map['goals_against'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
    totalMatches,
    wins,
    draws,
    losses,
    homeGames,
    awayGames,
    goalsFor,
    goalsAgainst,
  ];
}

/// Uma linha do ranking do Passaporte — totalmente separado do ranking da
/// Arena (`RankingEntry`), pontuação própria (1 partida marcada = 1 ponto).
class PassportRankingEntry extends Equatable {
  const PassportRankingEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.matchCount,
    required this.isMe,
    this.avatarUrl,
    this.isMember = false,
  });

  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isMember;
  final int matchCount;
  final bool isMe;

  @override
  List<Object?> get props => [
    rank,
    userId,
    name,
    avatarUrl,
    isMember,
    matchCount,
    isMe,
  ];
}

/// Uma alteração pendente enviada em lote pra `passport_save_attendances`.
class PassportAttendanceChange extends Equatable {
  const PassportAttendanceChange({
    required this.matchId,
    required this.attended,
  });

  final String matchId;
  final bool attended;

  Map<String, dynamic> toJson() => {'matchId': matchId, 'attended': attended};

  @override
  List<Object?> get props => [matchId, attended];
}

/// O que a RPC devolveu pra cada item do lote — `applied: false` só deveria
/// acontecer se o servidor rejeitar algo que a UI deixou passar (nunca
/// confiar só na validação do Flutter).
class PassportAttendanceChangeResult extends Equatable {
  const PassportAttendanceChangeResult({
    required this.matchId,
    required this.attended,
    required this.applied,
    this.reason,
  });

  final String matchId;
  final bool attended;
  final bool applied;
  final String? reason;

  factory PassportAttendanceChangeResult.fromMap(Map<String, dynamic> map) =>
      PassportAttendanceChangeResult(
        matchId: map['result_match_id'] as String,
        attended: map['result_attended'] as bool,
        applied: map['applied'] as bool,
        reason: map['reason'] as String?,
      );

  @override
  List<Object?> get props => [matchId, attended, applied, reason];
}
