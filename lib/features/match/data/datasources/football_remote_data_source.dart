import 'package:dio/dio.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/match/data/datasources/football_data_source.dart';
import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/competition_season_dto.dart';
import 'package:goias_app/features/match/data/dto/lineup_dto.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/data/dto/match_event_dto.dart';
import 'package:goias_app/features/match/data/dto/match_stat_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_group_dto.dart';

/// Conversa com o Worker (`/api/football/*`) — caminho LEGADO, mantido só
/// durante o rollout para o snapshot Supabase (ver `FootballSource`).
/// As rotas `/team/<code>` usam `ClubConfig.identity.code`.
class FootballRemoteDataSource implements FootballDataSource {
  FootballRemoteDataSource(this._dio, this._clubConfig);

  final Dio _dio;
  final ClubConfig _clubConfig;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async => (await _dio.get<Map<String, dynamic>>(
    path,
    queryParameters: query,
  )).data!;

  /// [competitionId] `null` pega a competição principal do clube ativo. Um
  /// id secundário devolve `groups` em vez de `standings` quando o formato
  /// é `GROUP_STAGE` — quem decide qual olhar é `competition.format`.
  @override
  Future<
    ({
      CompetitionDto competition,
      List<StandingDto> standings,
      List<StandingGroupDto> groups,
      CompetitionSeasonDto? season,
    })
  >
  getStandings({String? competitionId}) async => FootballJson.getStandings(
    await _get('/api/football/standings', {
      'club': _clubConfig.identity.code,
      'competition': ?competitionId,
    }),
  );

  /// Catálogo GLOBAL de competições — cada item já vem com
  /// `isClubParticipating` calculado pro clube deste deploy.
  @override
  Future<List<CompetitionRefDto>> getCompetitions() async =>
      FootballJson.getCompetitions(
        await _get('/api/football/competitions', {
          'club': _clubConfig.identity.code,
        }),
      );

  @override
  Future<
    ({
      CompetitionDto competition,
      List<MatchDto> matches,
      String? roundLabel,
      bool hasPrevious,
      bool hasNext,
    })
  >
  getCurrentRound({int offset = 0}) async => FootballJson.getCurrentRound(
    await _get('/api/football/current-round', {
      'club': _clubConfig.identity.code,
      if (offset != 0) 'offset': offset,
    }),
  );

  @override
  Future<
    ({
      CompetitionDto competition,
      MatchDto? nextMatch,
      List<MatchDto> recentResults,
    })
  >
  getActiveClubSnapshot() async => FootballJson.getActiveClubSnapshot(
    await _get('/api/football/team/${_clubConfig.identity.code}'),
  );

  /// Sem `competition` no nível da resposta — cada partida carrega a
  /// própria (temporada inteira do time, várias competições).
  @override
  Future<List<MatchDto>> getSeasonFixtures() async =>
      FootballJson.getSeasonFixtures(
        await _get('/api/football/team/${_clubConfig.identity.code}/season'),
      );

  @override
  Future<
    ({
      CompetitionDto competition,
      MatchDto match,
      List<MatchEventDto> events,
      MatchLineupsDto? lineups,
      List<MatchStatDto> stats,
    })
  >
  getFixtureDetails(String fixtureId) async => FootballJson.getFixtureDetails(
    await _get('/api/football/fixtures/$fixtureId'),
  );
}
