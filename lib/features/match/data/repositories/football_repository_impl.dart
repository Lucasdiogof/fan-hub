import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/data/datasources/football_remote_data_source.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FootballRepositoryImpl implements FootballRepository {
  FootballRepositoryImpl(this._remote, this._clubConfig);

  final FootballRemoteDataSource _remote;
  final ClubConfig _clubConfig;

  @override
  Future<
    Result<
      ({
        CompetitionRef competition,
        List<Standing> table,
        List<StandingGroup> groups,
      })
    >
  >
  getStandings({String? competitionId}) async {
    try {
      final result = await _remote.getStandings(competitionId: competitionId);
      // M3.3 tirou o cálculo de "é o clube ativo?" do servidor — o cliente
      // marca a linha comparando o id do time com o oneFootballTeamId do
      // clube ativo deste build (flavor). Sem isto a classificação não
      // destaca mais o time logado. Mesma regra pras linhas dentro de cada
      // grupo (GROUP_STAGE), não só na tabela achatada.
      final activeTeamId = _clubConfig.integrations.oneFootballTeamId;
      Standing markActive(Standing s) =>
          s.copyWith(isActiveClub: s.team.id == activeTeamId);

      // `region`/`isClubParticipating` reais vêm do catálogo
      // (`/api/football/competitions`), não desta resposta — o cubit
      // completa isso casando pelo `id` com `state.competitions` já
      // carregado (ver `GamesCubit.loadStandings`). Aqui ficam os
      // defaults neutros, só pro caso raro do catálogo não estar
      // disponível ainda.
      final competitionRef = CompetitionRef(
        id: competitionId ?? 'primary',
        name: result.competition.name,
        format: result.competition.format ?? CompetitionFormat.leagueTable,
        logoUrl: result.competition.logoUrl,
      );

      final groups = result.groups.map((dto) {
        final group = dto.toEntity();
        return StandingGroup(
          title: group.title,
          standings: group.standings.map(markActive).toList(),
        );
      }).toList();
      // Parte 10 da spec: se o clube ativo disputa a competição, o grupo
      // DELE abre primeiro — nunca a ordem alfabética/crua da fonte.
      groups.sort((a, b) {
        final aHasActive = a.standings.any((s) => s.isActiveClub) ? 0 : 1;
        final bHasActive = b.standings.any((s) => s.isActiveClub) ? 0 : 1;
        return aHasActive.compareTo(bHasActive);
      });

      return Success((
        competition: competitionRef,
        table: result.standings
            .map((dto) => dto.toEntity())
            .map(markActive)
            .toList(),
        groups: groups,
      ));
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) async {
    try {
      final result = await _remote.getStandings(competitionId: competitionId);
      final activeTeamId = _clubConfig.integrations.oneFootballTeamId;
      Standing markActive(Standing s) =>
          s.copyWith(isActiveClub: s.team.id == activeTeamId);

      final competitionRef = CompetitionRef(
        id: competitionId ?? 'primary',
        name: result.competition.name,
        format: result.competition.format ?? CompetitionFormat.leagueTable,
        logoUrl: result.competition.logoUrl,
      );

      List<CompetitionStage> stages;
      if (result.season != null) {
        stages = result.season!.toEntity().stages.map((stage) {
          final groups = stage.groups.map((group) {
            return StandingGroup(
              title: group.title,
              standings: group.standings.map(markActive).toList(),
            );
          }).toList();
          groups.sort((a, b) {
            final aHasActive = a.standings.any((s) => s.isActiveClub) ? 0 : 1;
            final bHasActive = b.standings.any((s) => s.isActiveClub) ? 0 : 1;
            return aHasActive.compareTo(bHasActive);
          });
          return CompetitionStage(
            id: stage.id,
            name: stage.name,
            order: stage.order,
            type: stage.type,
            status: stage.status,
            isCurrent: stage.isCurrent,
            standings: stage.standings.map(markActive).toList(),
            groups: groups,
            rounds: stage.rounds,
          );
        }).toList();
      } else {
        // Fallback pra durante o rollout (cache velho sem `season`) — monta
        // UMA fase só a partir dos campos legados, nunca quebra a tela.
        stages = [
          CompetitionStage(
            id: 'main',
            name: competitionRef.name,
            order: 0,
            type: switch (competitionRef.format) {
              CompetitionFormat.groupStage => StageType.groupStage,
              CompetitionFormat.knockout => StageType.knockout,
              CompetitionFormat.leagueTable => StageType.leagueTable,
            },
            status: StageStatus.active,
            isCurrent: true,
            standings: result.standings
                .map((dto) => dto.toEntity())
                .map(markActive)
                .toList(),
            groups: result.groups.map((dto) => dto.toEntity()).toList(),
          ),
        ];
      }

      return Success((
        competition: competitionRef,
        season: CompetitionSeason(
          id: competitionRef.id,
          label: competitionRef.name,
          stages: stages,
        ),
      ));
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async {
    try {
      final dtos = await _remote.getCompetitions();
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<
    Result<
      ({
        List<Match> matches,
        String? roundLabel,
        bool hasPrevious,
        bool hasNext,
      })
    >
  >
  getCurrentRound({int offset = 0}) async {
    try {
      final result = await _remote.getCurrentRound(offset: offset);
      final matches = result.matches
          .map((dto) => dto.toEntity(competitionName: result.competition.name))
          .toList();
      return Success((
        matches: matches,
        roundLabel: result.roundLabel,
        hasPrevious: result.hasPrevious,
        hasNext: result.hasNext,
      ));
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async {
    try {
      final result = await _remote.getActiveClubSnapshot();
      // REGRA ABSOLUTA (auditoria Matches/football): `/team/:clubCode` não
      // é uma operação de competição principal — o clube pode disputar
      // Brasileirão, Copa do Brasil, torneio continental etc. ao mesmo
      // tempo. Nunca usar `result.competition.name` (que nem representa
      // mais a competição principal, ver `team.ts`) como fallback de
      // partida — cada `MatchDto` já carrega a própria competição real;
      // `''` é a mesma convenção de "desconhecida" que `getSeasonFixtures`
      // já usa logo abaixo.
      final nextMatch = result.nextMatch?.toEntity(competitionName: '');
      final recentResults = result.recentResults
          .map((dto) => dto.toEntity(competitionName: ''))
          .toList();
      if (screenshotHomeMatch) {
        return Success(_asScreenshotHomeMatch(nextMatch, recentResults));
      }
      return Success((nextMatch: nextMatch, recentResults: recentResults));
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  /// Modo de captura de tela (`--dart-define=SCREENSHOT_HOME_MATCH=true`):
  /// o próximo jogo vira jogo em casa do clube ativo e o resultado recente
  /// sai da Home, pra liberar Escalação da Torcida e venda de ingressos
  /// quando o próximo jogo real é fora. Desligado por padrão — nunca em
  /// build de loja.
  static const screenshotHomeMatch = bool.fromEnvironment(
    'SCREENSHOT_HOME_MATCH',
  );

  ({Match? nextMatch, List<Match> recentResults}) _asScreenshotHomeMatch(
    Match? nextMatch,
    List<Match> recentResults,
  ) {
    if (nextMatch == null) {
      return (nextMatch: null, recentResults: recentResults);
    }
    final isHome = nextMatch.homeTeam.matchesClub(_clubConfig);
    // Estádio do último jogo em casa da própria fonte — nada hardcoded por
    // clube.
    final lastHome = recentResults
        .where((m) => m.homeTeam.matchesClub(_clubConfig))
        .firstOrNull;
    // Venda/check-in abrem 48h antes (`TicketFixture.infoFor`): traz o jogo
    // pra dentro dessa janela em dias inteiros, mantendo o horário.
    final now = DateTime.now();
    final kickoff = nextMatch.kickoff;
    final daysAhead = kickoff == null ? 0 : kickoff.difference(now).inDays - 1;
    final homeMatch = Match(
      id: nextMatch.id,
      competition: nextMatch.competition,
      round: nextMatch.round,
      homeTeam: isHome ? nextMatch.homeTeam : nextMatch.awayTeam,
      awayTeam: isHome ? nextMatch.awayTeam : nextMatch.homeTeam,
      stadium: isHome
          ? nextMatch.stadium
          : lastHome?.stadium ?? nextMatch.stadium,
      city: isHome ? nextMatch.city : lastHome?.city ?? nextMatch.city,
      kickoff: daysAhead > 0
          ? kickoff!.subtract(Duration(days: daysAhead))
          : kickoff,
      status: nextMatch.status,
      minute: nextMatch.minute,
    );
    // Tira o resultado recém-encerrado: senão a Home segura o placar
    // (folga do `HomeCubit`) e a Arena esconde a Escalação.
    bool justFinished(Match m) =>
        m.status == MatchStatus.finished &&
        m.kickoff != null &&
        now.difference(m.kickoff!) < const Duration(days: 2);
    return (
      nextMatch: homeMatch,
      recentResults: recentResults.where((m) => !justFinished(m)).toList(),
    );
  }

  @override
  Future<Result<List<Match>>> getSeasonFixtures() async {
    try {
      final dtos = await _remote.getSeasonFixtures();
      return Success(
        dtos.map((dto) => dto.toEntity(competitionName: '')).toList(),
      );
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<
    Result<
      ({
        Match match,
        List<MatchEvent> events,
        MatchLineups? lineups,
        List<MatchStat> stats,
      })
    >
  >
  getMatchDetails(String fixtureId) async {
    try {
      final result = await _remote.getFixtureDetails(fixtureId);
      // `result.competition.name` já é a competição REAL desta partida
      // específica (ou `''` se o OneFootball não trouxe o dado) — nunca a
      // competição principal do clube, ver `fixtureDetails.ts`.
      return Success((
        match: result.match.toEntity(competitionName: result.competition.name),
        events: result.events.map((dto) => dto.toEntity()).toList(),
        lineups: result.lineups?.toEntity(),
        stats: result.stats.map((dto) => dto.toEntity()).toList(),
      ));
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  Failure _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 429) {
      return const ServerFailure(
        'Muitas requisições no momento. Tente novamente em instantes.',
      );
    }
    if (status == 404) {
      return const ServerFailure('Partida não encontrada.');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const ServerFailure('Sem conexão com a internet.');
    }
    return const ServerFailure();
  }
}
