import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/ranking/data/supabase_arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';

void main() {
  var online = true;

  SupabaseArenaRankingRepository build() => SupabaseArenaRankingRepository(
    SupabaseClient(
      'https://example.supabase.co',
      'anon',
      httpClient: MockClient((request) async {
        if (!online) throw http.ClientException('offline', request.url);
        return http.Response(
          '[{"rank":1,"user_id":"u1","name":"Ana","total_score":90}]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
    goiasClubConfig,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    online = true;
  });

  test('offline sem visita anterior -> NetworkFailure', () async {
    online = false;
    final result = await build().getRanking(RankingPeriod.allTime);
    expect((result as Error).failure, isA<NetworkFailure>());
  });

  test('offline depois de visita -> placar salvo com cachedAt', () async {
    final repo = build();
    final fresh =
        await repo.getRanking(RankingPeriod.allTime)
            as Success<List<RankingEntry>>;
    expect(fresh.cachedAt, isNull);

    online = false;
    final stale =
        await repo.getRanking(RankingPeriod.allTime)
            as Success<List<RankingEntry>>;
    expect(stale.cachedAt, isNotNull);
    expect(stale.data.single.name, 'Ana');

    // outro período nunca recebe a cópia de um período diferente
    final other = await repo.getRanking(RankingPeriod.weekly);
    expect(other, isA<Error<List<RankingEntry>>>());
  });
}
