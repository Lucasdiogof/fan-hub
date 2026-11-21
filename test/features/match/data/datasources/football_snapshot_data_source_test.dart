import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/core/network/offline_snapshot_interceptor.dart';
import 'package:goias_app/features/match/data/datasources/football_snapshot_data_source.dart';

const _home = {'id': 1, 'name': 'A', 'shortName': 'A', 'logo': null};
const _away = {'id': 2, 'name': 'B', 'shortName': 'B', 'logo': null};
const _match = {
  'id': 'onef-1',
  'round': '10',
  'homeTeam': _home,
  'awayTeam': _away,
  'kickoff': '2026-11-14T16:30:00.000',
  'venue': null,
  'status': 'finished',
  'homeScore': 3,
  'awayScore': 0,
  'minute': null,
  'competition': 'Série B',
};
const _comp = {'name': 'Série B', 'season': null};
const _empty = <Object>[];

Map<String, dynamic> _row(
  Map<String, dynamic> payload, {
  bool found = true,
  bool stale = false,
  bool expired = false,
  int age = 30,
}) => {
  'found': found,
  'payload': payload,
  'ageSeconds': age,
  'stale': stale,
  'expired': expired,
};

void main() {
  late List<Map<String, dynamic>> calls;
  late OfflineSnapshotStatus status;

  FootballSnapshotDataSource ds(Object? reply, [ClubConfig? club]) {
    calls = [];
    status = OfflineSnapshotStatus();
    return FootballSnapshotDataSource.withRpc(
      (fn, params) async {
        expect(fn, 'get_football_snapshot');
        calls.add(params);
        return reply;
      },
      club ?? goiasClubConfig,
      status,
    );
  }

  String kk(Map<String, dynamic> c) => '${c['p_kind']}/${c['p_key']}';

  test('team/default: parseia o contrato atual, club_id canônico', () async {
    final d = ds(
      _row({
        'competition': _comp,
        'nextMatch': _match,
        'recentResults': [_match],
      }),
    );
    final r = await d.getActiveClubSnapshot();
    expect(r.nextMatch!.homeScore, 3);
    expect(r.recentResults, hasLength(1));
    expect(calls.single, {
      'p_club_id': goiasClubConfig.identity.canonicalClubId,
      'p_kind': 'team',
      'p_key': 'default',
    });
    expect(status.savedAt(SnapshotCategory.matches), isNull);
  });

  test('cada kind/key', () async {
    var d = ds(
      _row({
        'competition': _comp,
        'matches': [_match],
        'round': {'label': 'R10'},
        'hasNext': true,
      }),
    );
    final r = await d.getCurrentRound();
    expect(r.roundLabel, 'R10');
    expect(r.hasNext, isTrue);
    await d.getCurrentRound(offset: -1);
    expect(calls.map(kk), [
      'current_round/offset:0',
      'current_round/offset:-1',
    ]);

    d = ds(
      _row({
        'matches': [_match],
      }),
    );
    expect(await d.getSeasonFixtures(), hasLength(1));
    expect(kk(calls.single), 'season/default');

    d = ds(
      _row({
        'competitions': [
          {
            'id': 'x',
            'name': 'X',
            'format': 'LEAGUE_TABLE',
            'isClubParticipating': true,
          },
        ],
      }),
    );
    expect(await d.getCompetitions(), hasLength(1));
    expect(kk(calls.single), 'competitions/default');

    d = ds(_row({'competition': _comp, 'standings': _empty, 'groups': _empty}));
    await d.getStandings();
    await d.getStandings(competitionId: 'copa-123');
    expect(calls.map(kk), ['standings/primary', 'standings/copa-123']);

    d = ds(_row({'competition': _comp, 'match': _match}));
    final fx = await d.getFixtureDetails('onef-123');
    expect(fx.match.id, 'onef-1');
    expect(fx.lineups, isNull);
    expect(fx.events, isEmpty);
    expect(kk(calls.single), 'fixture/onef-123');
  });

  test('stale entrega o dado e marca o banner; fresh limpa', () async {
    final payload = {
      'competition': _comp,
      'nextMatch': null,
      'recentResults': _empty,
    };
    final d = ds(_row(payload, stale: true, age: 600));
    expect((await d.getActiveClubSnapshot()).nextMatch, isNull);
    expect(status.savedAt(SnapshotCategory.matches), isNotNull);
    await FootballSnapshotDataSource.withRpc(
      (fn, p) async => _row(payload),
      goiasClubConfig,
      status,
    ).getActiveClubSnapshot();
    expect(status.savedAt(SnapshotCategory.matches), isNull);
  });

  test('fixture stale não marca o banner', () async {
    final d = ds(_row({'competition': _comp, 'match': _match}, stale: true));
    await d.getFixtureDetails('onef-1');
    expect(status.savedAt(SnapshotCategory.matches), isNull);
  });

  test('found:false, expired:true e resposta nula -> indisponível', () async {
    for (final reply in [
      _row({}, found: false),
      _row({'competition': _comp}, expired: true),
      null,
    ]) {
      await expectLater(
        ds(reply).getActiveClubSnapshot(),
        throwsA(isA<ClubDataUnavailableException>()),
      );
    }
  });

  test('usa o club_id do clube ativo (Vila e Bragantino)', () async {
    for (final club in [vilaNovaClubConfig, bragantinoClubConfig]) {
      final d = ds(
        _row({
          'competition': _comp,
          'nextMatch': null,
          'recentResults': _empty,
        }),
        club,
      );
      await d.getActiveClubSnapshot();
      expect(calls.single['p_club_id'], club.identity.canonicalClubId);
    }
  });

  test('flag footballSource: os 3 flavors migrados para o snapshot', () {
    for (final c in [
      goiasClubConfig,
      vilaNovaClubConfig,
      bragantinoClubConfig,
    ]) {
      expect(c.integrations.footballSource, FootballSource.supabaseSnapshot);
    }
  });

  test('hasSocial desligado no Vila e Bragantino (TODO-P1); hasNews via Supabase no Vila e Bragantino (D1)', () {
    for (final c in [vilaNovaClubConfig, bragantinoClubConfig]) {
      expect(c.capabilities.hasSocial, isFalse);
    }
    expect(vilaNovaClubConfig.capabilities.hasNews, isTrue);
    expect(vilaNovaClubConfig.integrations.newsSource, NewsSource.supabase);
    expect(bragantinoClubConfig.capabilities.hasNews, isTrue);
    expect(bragantinoClubConfig.integrations.newsSource, NewsSource.supabase);
    expect(goiasClubConfig.integrations.newsSource, NewsSource.supabase);
  });
}
