import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/core/network/offline_snapshot_interceptor.dart';
import 'package:goias_app/features/news/data/datasources/news_snapshot_data_source.dart';

const _item = {
  'id': '555-evento',
  'title': 'Evento',
  'category': '',
  'publishedAt': '2026-11-04',
  'imageUrl': 'https://x.supabase.co/storage/v1/object/public/news-images/covers/a.png',
  'url': 'https://www.vilanovafc.com.br/noticias/555-evento',
};

Map<String, dynamic> _row({bool stale = false, bool expired = false}) => {
  'found': true,
  'payload': {
    'items': [_item],
  },
  'stale': stale,
  'expired': expired,
  'ageSeconds': 120,
};

NewsSnapshotDataSource _ds(
  Map<String, dynamic> rpcResult,
  OfflineSnapshotStatus status, {
  Map<String, dynamic>? fnResult,
  List<List<Object?>>? calls,
}) => NewsSnapshotDataSource.withCalls(
  (fn, params) async {
    calls?.add([fn, params]);
    return rpcResult;
  },
  (fn, body) async {
    calls?.add([fn, body]);
    return fnResult ?? {'available': false, 'url': null};
  },
  vilaNovaClubConfig,
  status,
);

void main() {
  test('lista: lê a RPC com o club_id do clube ativo e mapeia os DTOs', () async {
    final calls = <List<Object?>>[];
    final list = await _ds(_row(), OfflineSnapshotStatus(), calls: calls).getList();
    expect(list.single.id, '555-evento');
    expect(list.single.imageUrl, contains('news-images'));
    expect(calls.single[0], 'get_news_snapshot');
    expect(
      calls.single[1],
      {'p_club_id': vilaNovaClubConfig.identity.canonicalClubId},
    );
  });

  test('os 3 flavors usam o próprio club_id (isolamento)', () async {
    final ids = {
      goiasClubConfig.identity.canonicalClubId,
      vilaNovaClubConfig.identity.canonicalClubId,
      bragantinoClubConfig.identity.canonicalClubId,
    };
    expect(ids.length, 3);
  });

  test('snapshot ausente ou expirado -> ClubDataUnavailableException', () async {
    for (final r in [
      {'found': false},
      _row(expired: true),
    ]) {
      await expectLater(
        _ds(r, OfflineSnapshotStatus()).getList(),
        throwsA(isA<ClubDataUnavailableException>()),
      );
    }
  });

  test('stale entrega a lista e marca o banner; fresco limpa', () async {
    final status = OfflineSnapshotStatus();
    await _ds(_row(stale: true), status).getList();
    expect(status.savedAt(SnapshotCategory.news), isNotNull);
    await _ds(_row(), status).getList();
    expect(status.savedAt(SnapshotCategory.news), isNull);
  });

  test('artigo: manda só id + club; available:false -> null', () async {
    final calls = <List<Object?>>[];
    final article = await _ds(
      _row(),
      OfflineSnapshotStatus(),
      calls: calls,
    ).getArticle('555-evento');
    expect(article, isNull);
    expect(calls.single, [
      'news-article',
      {'id': '555-evento', 'club': 'vilanova'},
    ]);
  });

  test('artigo disponível vira DTO', () async {
    final article = await _ds(
      _row(),
      OfflineSnapshotStatus(),
      fnResult: {
        'available': true,
        'article': {
          ..._item,
          'content': [
            {'type': 'paragraph', 'text': 'Texto.'},
            {'type': 'link', 'text': 'l', 'url': 'https://ok.com/a'},
          ],
        },
      },
    ).getArticle('555-evento');
    expect(article!.content.length, 2);
  });
}
