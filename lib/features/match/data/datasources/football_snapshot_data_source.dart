import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/network/offline_snapshot_interceptor.dart';
import 'package:goias_app/features/match/data/datasources/football_data_source.dart';
import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/competition_season_dto.dart';
import 'package:goias_app/features/match/data/dto/lineup_dto.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/data/dto/match_event_dto.dart';
import 'package:goias_app/features/match/data/dto/match_stat_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_group_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Chamada de RPC injetável (teste) — em produção é `SupabaseClient.rpc`.
typedef SnapshotRpc =
    Future<dynamic> Function(String fn, Map<String, dynamic> params);

/// Lê o snapshot normalizado de futebol que a Edge Function `football-refresh`
/// grava em `football_snapshots` (RPC `get_football_snapshot`). Mesmo
/// contrato JSON do Worker — por isso reaproveita [FootballJson] e os DTOs.
///
/// `found: false` ou `expired: true` viram [ClubDataUnavailableException]
/// (o repositório devolve `Error`, nunca dado em que não se deve confiar).
/// `stale: true` entrega o dado e marca o banner "dados antigos" de Jogos.
class FootballSnapshotDataSource implements FootballDataSource {
  FootballSnapshotDataSource(
    SupabaseClient client,
    this._clubConfig,
    this._status,
  ) : _rpc = ((fn, params) async => client.rpc(fn, params: params));

  /// Só para teste.
  FootballSnapshotDataSource.withRpc(this._rpc, this._clubConfig, this._status);

  final SnapshotRpc _rpc;
  final ClubConfig _clubConfig;
  final OfflineSnapshotStatus _status;

  Future<Map<String, dynamic>> _snapshot(String kind, String key) async {
    final res = await _rpc('get_football_snapshot', {
      'p_club_id': _clubConfig.identity.canonicalClubId,
      'p_kind': kind,
      'p_key': key,
    });
    final row = res as Map<String, dynamic>?;
    if (row == null || row['found'] != true || row['expired'] == true) {
      throw ClubDataUnavailableException(
        table: 'football_snapshots[$kind/$key]',
        clubCode: _clubConfig.identity.code,
      );
    }
    // Detalhe de partida não alimenta o banner (mesma regra do cache antigo).
    if (kind != 'fixture') {
      if (row['stale'] == true) {
        final age = Duration(
          seconds: (row['ageSeconds'] as num?)?.toInt() ?? 0,
        );
        _status.markStale(
          SnapshotCategory.matches,
          DateTime.now().subtract(age),
        );
      } else {
        _status.markFresh(SnapshotCategory.matches);
      }
    }
    return row['payload'] as Map<String, dynamic>;
  }

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
    await _snapshot('standings', competitionId ?? 'primary'),
  );

  @override
  Future<List<CompetitionRefDto>> getCompetitions() async =>
      FootballJson.getCompetitions(await _snapshot('competitions', 'default'));

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
    await _snapshot('current_round', 'offset:$offset'),
  );

  @override
  Future<
    ({
      CompetitionDto competition,
      MatchDto? nextMatch,
      List<MatchDto> recentResults,
    })
  >
  getActiveClubSnapshot() async =>
      FootballJson.getActiveClubSnapshot(await _snapshot('team', 'default'));

  @override
  Future<List<MatchDto>> getSeasonFixtures() async =>
      FootballJson.getSeasonFixtures(await _snapshot('season', 'default'));

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
  getFixtureDetails(String fixtureId) async =>
      FootballJson.getFixtureDetails(await _snapshot('fixture', fixtureId));
}
