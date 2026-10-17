import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/network/offline_snapshot_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter que responde com JSON enquanto [online] e falha de conexão
/// (como o modo avião) quando não.
class _FakeAdapter implements HttpClientAdapter {
  bool online = true;
  Map<String, dynamic> body = {};
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (!online) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late OfflineSnapshotStatus status;
  late _FakeAdapter adapter;
  late Dio dio;
  var clock = DateTime(2026, 10, 15, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    status = OfflineSnapshotStatus();
    adapter = _FakeAdapter();
    clock = DateTime(2026, 10, 15, 10);
    dio = Dio(BaseOptions(baseUrl: 'https://w.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(OfflineSnapshotInterceptor(status, now: () => clock));
  });

  test(
    'offline without any previous visit -> original network error',
    () async {
      adapter.online = false;
      await expectLater(
        dio.get<Map<String, dynamic>>('/api/news'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
      expect(status.savedAt(SnapshotCategory.news), isNull);
    },
  );

  test('offline after an online visit -> saved copy + stale marker', () async {
    adapter.body = {
      'items': [
        {'id': 'a'},
      ],
    };
    await dio.get<Map<String, dynamic>>('/api/news');
    expect(status.savedAt(SnapshotCategory.news), isNull);

    adapter.online = false;
    clock = clock.add(const Duration(hours: 5));
    final res = await dio.get<Map<String, dynamic>>('/api/news');
    final items = res.data!['items'] as List<dynamic>;
    expect((items.single as Map<String, dynamic>)['id'], 'a');
    expect(status.savedAt(SnapshotCategory.news), isNotNull);

    // back online -> fresh again, marker cleared
    adapter.online = true;
    await dio.get<Map<String, dynamic>>('/api/news');
    expect(status.savedAt(SnapshotCategory.news), isNull);
  });

  test('a saved live match is never served as live', () async {
    adapter.body = {
      'matches': [
        {'id': '1', 'status': 'live', 'minute': '67'},
        {'id': '2', 'status': 'finished', 'minute': null},
      ],
    };
    await dio.get<Map<String, dynamic>>('/api/football/team/goias');
    adapter.online = false;
    final res = await dio.get<Map<String, dynamic>>('/api/football/team/goias');
    final matches = (res.data!['matches'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(matches[0]['status'], 'unknown');
    expect(matches[0].containsKey('minute'), isFalse);
    expect(matches[1]['status'], 'finished');
  });

  test('too old snapshot is not served', () async {
    adapter.body = {'items': <Object>[]};
    await dio.get<Map<String, dynamic>>('/api/news');
    adapter.online = false;
    clock = clock.add(const Duration(days: 8));
    await expectLater(
      dio.get<Map<String, dynamic>>('/api/news'),
      throwsA(isA<DioException>()),
    );
  });

  test('live fixture detail is never cached', () async {
    adapter.body = {'x': 1};
    await dio.get<Map<String, dynamic>>('/api/football/fixtures/9');
    adapter.online = false;
    await expectLater(
      dio.get<Map<String, dynamic>>('/api/football/fixtures/9'),
      throwsA(isA<DioException>()),
    );
  });
}
