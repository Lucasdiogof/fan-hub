import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/data/supabase_club_board_repository.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/features/club/domain/repositories/club_board_repository.dart';
import 'package:goias_app/features/club/presentation/cubit/club_board_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';

SupabaseClient _client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'https://example.supabase.co',
      'anon',
      httpClient: MockClient(handler),
    );

http.Response _json(String body, http.Request request) => http.Response(
  body,
  200,
  request: request,
  headers: {'content-type': 'application/json'},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  var online = true;
  Future<http.Response> handler(http.Request request) async {
    if (!online) throw http.ClientException('offline', request.url);
    if (request.url.path.endsWith('club_board_sections')) {
      return _json('[{"id":"s1","title":"Diretoria","sort_order":1}]', request);
    }
    return _json(
      '[{"id":"m1","section_id":"s1","name":"Fulano","role":"Presidente"}]',
      request,
    );
  }

  setUp(() => online = true);

  test(
    'offline without any saved visit -> NetworkFailure, not a hang',
    () async {
      online = false;
      final result = await SupabaseClubBoardRepository(
        _client(handler),
      ).getBoard();
      expect(result, isA<Error<List<ClubBoardSection>>>());
      expect((result as Error).failure, isA<NetworkFailure>());
    },
  );

  test('offline after an online visit -> saved board with cachedAt', () async {
    final repo = SupabaseClubBoardRepository(_client(handler));
    final fresh = await repo.getBoard();
    expect((fresh as Success<List<ClubBoardSection>>).cachedAt, isNull);

    online = false;
    final stale = await repo.getBoard();
    final success = stale as Success<List<ClubBoardSection>>;
    expect(success.cachedAt, isNotNull);
    expect(success.data.single.members.single.name, 'Fulano');

    // back online: fresh again and cache refreshed.
    online = true;
    final again = await repo.getBoard() as Success<List<ClubBoardSection>>;
    expect(again.cachedAt, isNull);
  });

  test(
    'cubit: retry after offline recovers; concurrent loads share one fetch',
    () async {
      final repo = _CountingRepo();
      final cubit = ClubBoardCubit(repo);
      repo.result = const Error(NetworkFailure('Sem conexão com a internet.'));
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.isOffline, isTrue);

      repo.result = const Success([
        ClubBoardSection(
          id: 's',
          title: 'T',
          members: [ClubBoardMember(id: 'm', name: 'N', role: 'R')],
        ),
      ]);
      await Future.wait([cubit.load(), cubit.load(), cubit.refresh()]);
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.isOffline, isFalse);
      expect(repo.calls, 2); // 1 failed + 1 shared retry
      await cubit.close();
    },
  );
}

class _CountingRepo implements ClubBoardRepository {
  int calls = 0;
  late Result<List<ClubBoardSection>> result;

  @override
  Future<Result<List<ClubBoardSection>>> getBoard() async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return result;
  }
}
