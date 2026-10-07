import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

/// Uma partida já carregada com o que o cálculo precisa: placar/estado,
/// eventos (gols e substituições) e escalação.
class IdolMatchRecord {
  const IdolMatchRecord({
    required this.match,
    required this.events,
    required this.lineups,
  });

  final Match match;
  final List<MatchEvent> events;
  final MatchLineups? lineups;
}

/// Números atuais de um ídolo que ainda joga:
///
///     baseline auditado  +  o que as partidas POSTERIORES a ele mostram
///
/// É uma função PURA do conjunto de partidas: não acumula estado, não guarda
/// "valor anterior" e não depende da ordem nem de quantas vezes a mesma
/// partida chega. Processar o mesmo conjunto 1, 5 ou 50 vezes dá o mesmo
/// resultado (as partidas são deduplicadas por `Match.id`).
///
/// Regras de contagem (jogo = o jogador entrou em campo):
///   * conta: titular (aparece na escalação do clube) ou entrou por
///     substituição;
///   * NÃO conta: ficou no banco sem entrar, não foi relacionado, partida
///     não finalizada (agendada, adiada, cancelada, suspensa, ao vivo) e
///     qualquer caso sem evidência de que entrou em campo;
///   * a própria partida que fecha o baseline e toda partida que não começa
///     DEPOIS dela nunca entram de novo;
///   * gol = evento de gol do clube atribuído ao jogador, só em partida em
///     que ele jogou; gol contra, e qualquer evento que não seja gol, nunca.
IdolStats computeIdolStats({
  required ActiveIdolTracking tracking,
  required int clubTeamId,
  required Iterable<IdolMatchRecord> records,
  bool isComplete = true,
}) {
  final baseline = tracking.baseline;
  final cutoff = parseKickoffInstant(baseline.throughKickoff);
  final names = {for (final name in tracking.eventNames) normalizeName(name)};

  // Deduplica por id: a mesma partida processada de novo não conta de novo.
  final byId = <String, IdolMatchRecord>{};
  for (final record in records) {
    byId.putIfAbsent(record.match.id, () => record);
  }

  var appearances = 0;
  var goals = 0;
  var counted = 0;
  DateTime? lastProcessed;

  for (final record in byId.values) {
    final match = record.match;
    if (match.id == baseline.throughMatchId) continue;
    if (match.status != MatchStatus.finished) continue;
    final kickoff = match.kickoff;
    if (kickoff == null || cutoff == null || !kickoff.isAfter(cutoff)) continue;

    final side = _clubSide(match, clubTeamId);
    if (side == null) continue; // não é partida do clube — nunca chuta.

    // A partida foi verificada (mesmo que ele não tenha jogado): a data de
    // referência avança até ela.
    if (lastProcessed == null || kickoff.isAfter(lastProcessed)) {
      lastProcessed = kickoff;
    }

    if (!_playedMatch(record, side, tracking, names)) continue;
    appearances += 1;
    counted += 1;
    goals += _goalsIn(record.events, side, names);
  }

  final asOf = lastProcessed == null
      ? baseline.throughDate
      : brazilDateIso(lastProcessed);
  return IdolStats(
    appearances: baseline.appearances + appearances,
    goals: baseline.goals == null ? null : baseline.goals! + goals,
    asOfDate: asOf,
    isComplete: isComplete,
    countedMatches: counted,
  );
}

/// `yyyy-MM-dd` no horário de Brasília a partir de um instante UTC. Offset
/// fixo de -3h (o Brasil não tem horário de verão desde 2019 — mesma
/// premissa de `parseKickoffInstant`), sem depender do banco de fusos.
String brazilDateIso(DateTime instant) {
  final local = instant.toUtc().subtract(const Duration(hours: 3));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

MatchEventSide? _clubSide(Match match, int clubTeamId) {
  if (match.homeTeam.id == clubTeamId) return MatchEventSide.home;
  if (match.awayTeam.id == clubTeamId) return MatchEventSide.away;
  return null;
}

TeamLineup? _lineupOf(MatchLineups? lineups, MatchEventSide side) {
  if (lineups == null) return null;
  return side == MatchEventSide.home ? lineups.home : lineups.away;
}

bool _playedMatch(
  IdolMatchRecord record,
  MatchEventSide side,
  ActiveIdolTracking tracking,
  Set<String> names,
) {
  final lineup = _lineupOf(record.lineups, side);
  final starters = lineup == null
      ? const <LineupPlayer>[]
      : [for (final row in lineup.rows) ...row];

  // 1) Titular — por ID de provedor (vínculo canônico). Só quando a
  //    escalação NÃO traz ID para aquele atleta (ex.: foto genérica removida
  //    pelo Worker) cai no nome exato, e só entre os sem ID.
  for (final player in starters) {
    final id = player.providerPlayerId;
    if (id == tracking.providerPlayerId) return true;
    if (id == null && names.contains(normalizeName(player.name))) return true;
  }

  // 2) Entrou por substituição.
  //    a) Se o evento traz o ID de quem entrou (`playerInId`), SÓ o ID vale: o
  //       nome é ignorado — o ID prevalece sobre o nome.
  //    b) Se o evento não traz ID (é o que o OneFootball manda hoje: só o nome),
  //       cai no nome exato (sem aproximação, sem pedaço de nome), apenas no
  //       lado do clube e só se a escalação da MESMA partida não mostrar, no
  //       mesmo lado, um jogador de mesmo nome com OUTRO ID (homônimo).
  final homonym = starters.any(
    (p) =>
        p.providerPlayerId != null &&
        p.providerPlayerId != tracking.providerPlayerId &&
        names.contains(normalizeName(p.name)),
  );
  return record.events.any((e) {
    if (e.type != MatchEventType.substitution || e.side != side) return false;
    final enteredId = e.playerInId;
    if (enteredId != null) return enteredId == tracking.providerPlayerId;
    if (homonym) return false;
    final entered = e.player;
    return entered != null && names.contains(normalizeName(entered));
  });
}

int _goalsIn(List<MatchEvent> events, MatchEventSide side, Set<String> names) {
  var total = 0;
  for (final e in events) {
    if (e.type != MatchEventType.goal) continue;
    if (e.side != side) continue;
    if (e.detail == _ownGoalDetail) continue; // gol contra nunca é do jogador.
    final scorer = e.player;
    if (scorer == null || !names.contains(normalizeName(scorer))) continue;
    total += 1;
  }
  return total;
}

/// Mesmo rótulo que o Worker usa em `normalizeOneFootballMatchEvent`.
const _ownGoalDetail = 'Contra';
