import 'package:dio/dio.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/data/datasources/football_remote_data_source.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';

class FootballRepositoryImpl implements FootballRepository {
  FootballRepositoryImpl(this._remote);

  final FootballRemoteDataSource _remote;

  @override
  Future<Result<List<Standing>>> getStandings() async {
    try {
      final result = await _remote.getStandings();
      return Success(result.standings.map((dto) => dto.toEntity()).toList());
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (_) {
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<List<Match>>> getCurrentRound() async {
    try {
      final result = await _remote.getCurrentRound();
      final matches = result.matches
          .map((dto) => dto.toEntity(competitionName: result.competition.name))
          .toList();
      return Success(matches);
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (_) {
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getGoiasSnapshot() async {
    try {
      final result = await _remote.getGoiasSnapshot();
      final competitionName = result.competition.name;
      return Success((
        nextMatch: result.nextMatch?.toEntity(competitionName: competitionName),
        recentResults: result.recentResults
            .map((dto) => dto.toEntity(competitionName: competitionName))
            .toList(),
      ));
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (_) {
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<Match>> getMatchDetails(String fixtureId) async {
    try {
      final result = await _remote.getFixtureDetails(fixtureId);
      return Success(
        result.match.toEntity(competitionName: result.competition.name),
      );
    } on DioException catch (e) {
      return Error(_mapDioError(e));
    } catch (_) {
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
