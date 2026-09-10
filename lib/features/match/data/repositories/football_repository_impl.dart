import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/data/datasources/football_remote_data_source.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
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
        table: result.standings.map((dto) => dto.toEntity()).map(markActive).toList(),
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
      return Success((
        nextMatch: result.nextMatch?.toEntity(competitionName: ''),
        recentResults: result.recentResults
            .map((dto) => dto.toEntity(competitionName: ''))
            .toList(),
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
