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
