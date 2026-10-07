import 'dart:async';

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/domain/idol_stats_calculator.dart';
import 'package:goias_app/features/club/domain/repositories/active_idol_stats_repository.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Calcula os números dos ídolos ativos a partir das partidas reais do
/// clube (`FootballRepository`), sem backend novo:
///
///   1. UMA leitura da temporada (`getSeasonFixtures`);
///   2. detalhes (`getMatchDetails`) só das partidas FINALIZADAS posteriores
///      ao baseline mais antigo — compartilhadas por todos os ídolos ativos,
///      então o custo não cresce com a quantidade de ídolos (sem N+1);
///   3. cálculo local e puro (`computeIdolStats`).
///
/// Partida finalizada não muda: o detalhe dela fica em cache em memória e
/// nunca é buscado duas vezes na mesma sessão.
class FootballActiveIdolStatsRepository implements ActiveIdolStatsRepository {
  FootballActiveIdolStatsRepository(this._football, this._clubTeamId);

  final FootballRepository _football;
  final int _clubTeamId;

  /// Quantos detalhes buscar ao mesmo tempo — limite pequeno de propósito
  /// (cada um é um subrequest do Worker).
  static const _batchSize = 4;

  final _finishedCache = <String, IdolMatchRecord>{};

  /// Último resultado COMPLETO por ídolo (conjunto totalmente verificado de
  /// partidas até então). Só é gravado quando nenhuma partida falhou; um
  /// resultado incompleto jamais entra aqui nem substitui o que está exibido.
  final _lastComplete = <String, IdolStats>{};

  @override
  IdolStats? lastCompleteFor(ClubIdol idol) => _lastComplete[idol.name];

  @override
  Future<Map<String, IdolStats>> loadStats(List<ClubIdol> idols) async {
    final tracked = [
      for (final idol in idols)
        if (idol.tracking != null) idol,
    ];
    if (tracked.isEmpty) return const {};

    // Fail-closed: o que se mostra quando não dá para verificar tudo.
    Map<String, IdolStats> lastKnown() => {
      for (final idol in tracked)
        idol.name:
            _lastComplete[idol.name] ??
            IdolStats.fromBaseline(idol.tracking!.baseline),
    };

    try {
      final fixtures = await _football.getSeasonFixtures();
      if (fixtures is! Success<List<Match>>) return lastKnown();

      final cutoffs = [
        for (final idol in tracked)
          parseKickoffInstant(idol.tracking!.baseline.throughKickoff),
      ];
      if (cutoffs.any((c) => c == null)) return lastKnown();
      final earliest = cutoffs.cast<DateTime>().reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );

      final candidates = [
        for (final match in fixtures.data)
          if (match.status == MatchStatus.finished &&
              match.kickoff != null &&
              match.kickoff!.isAfter(earliest))
            match,
      ];

      var complete = true;
      final records = <IdolMatchRecord>[];
      for (var i = 0; i < candidates.length; i += _batchSize) {
        final batch = candidates.skip(i).take(_batchSize);
        final loaded = await Future.wait(batch.map(_record));
        for (final record in loaded) {
          if (record == null) {
            complete = false;
          } else {
            records.add(record);
          }
        }
      }

      // Alguma partida finalizada não pôde ser verificada: NÃO publica um
      // total parcial — mantém o último completo (ou o baseline).
      if (!complete) return lastKnown();

      final fresh = {
        for (final idol in tracked)
          idol.name: computeIdolStats(
            tracking: idol.tracking!,
            clubTeamId: _clubTeamId,
            records: records,
          ),
      };
      _lastComplete.addAll(fresh);
      return fresh;
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return lastKnown();
    }
  }

  Future<IdolMatchRecord?> _record(Match match) async {
    final cached = _finishedCache[match.id];
    if (cached != null) return cached;
    final result = await _football.getMatchDetails(match.id);
    if (result
        is! Success<
          ({
            Match match,
            List<MatchEvent> events,
            MatchLineups? lineups,
            List<MatchStat> stats,
          })
        >) {
      return null;
    }
    final data = result.data;
    final record = IdolMatchRecord(
      match: data.match,
      events: data.events,
      lineups: data.lineups,
    );
    // Só guarda partida finalizada COM escalação: sem ela o resultado pode
    // mudar quando a fonte publicar, então tenta de novo na próxima vez.
    if (data.match.status == MatchStatus.finished && data.lineups != null) {
      _finishedCache[match.id] = record;
    }
    return record;
  }
}
