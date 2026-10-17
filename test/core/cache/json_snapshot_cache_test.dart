import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/cache/json_snapshot_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns null when nothing was ever saved', () async {
    expect(await const JsonSnapshotCache().read('a'), isNull);
  });

  test('round-trips payload and savedAt', () async {
    const cache = JsonSnapshotCache();
    final now = DateTime.utc(2026, 10, 15, 12);
    await cache.write('a', {
      'rows': [1, 2],
    }, now: now);
    final snapshot = await cache.read('a');
    expect(snapshot!.payload, {
      'rows': [1, 2],
    });
    expect(snapshot.savedAt.toUtc(), now);
  });

  test('corrupted record is ignored instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'snapshot_cache:a': '{not json'});
    expect(await const JsonSnapshotCache().read('a'), isNull);
  });
}
