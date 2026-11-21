import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/network/offline_snapshot_interceptor.dart';
import 'package:goias_app/features/news/data/datasources/news_data_source.dart';
import 'package:goias_app/features/news/data/dto/news_article_dto.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Chamada injetável (teste) — em produção é `SupabaseClient.rpc` /
/// `SupabaseClient.functions.invoke`.
typedef NewsRpc =
    Future<dynamic> Function(String fn, Map<String, dynamic> params);
typedef NewsFunctionCall =
    Future<dynamic> Function(String fn, Map<String, dynamic> body);

/// Lista: snapshot que `news-refresh` grava em `news_snapshots` (RPC
/// `get_news_snapshot`). Artigo: Edge Function `news-article` (sob demanda,
/// manda só o `id`; a URL vem da lista do servidor). Mesmo contrato JSON do
/// Worker — reaproveita os DTOs.
///
/// `found: false` ou `expired: true` viram [ClubDataUnavailableException].
/// `stale: true` entrega a lista e marca o banner "dados antigos".
class NewsSnapshotDataSource implements NewsDataSource {
  NewsSnapshotDataSource(
    SupabaseClient client,
    this._clubConfig,
    this._status,
  ) : _rpc = ((fn, params) async => client.rpc(fn, params: params)),
      _call = ((fn, body) async {
        final res = await client.functions.invoke(fn, body: body);
        return res.data;
      });

  /// Só para teste.
  NewsSnapshotDataSource.withCalls(
    this._rpc,
    this._call,
    this._clubConfig,
    this._status,
  );

  final NewsRpc _rpc;
  final NewsFunctionCall _call;
  final ClubConfig _clubConfig;
  final OfflineSnapshotStatus _status;

  @override
  Future<List<NewsItemDto>> getList() async {
    final res = await _rpc('get_news_snapshot', {
      'p_club_id': _clubConfig.identity.canonicalClubId,
    });
    final row = res as Map<String, dynamic>?;
    if (row == null || row['found'] != true || row['expired'] == true) {
      throw ClubDataUnavailableException(
        table: 'news_snapshots',
        clubCode: _clubConfig.identity.code,
      );
    }
    if (row['stale'] == true) {
      final age = Duration(seconds: (row['ageSeconds'] as num?)?.toInt() ?? 0);
      _status.markStale(SnapshotCategory.news, DateTime.now().subtract(age));
    } else {
      _status.markFresh(SnapshotCategory.news);
    }
    final items = (row['payload'] as Map<String, dynamic>)['items'] as List;
    return items
        .map((item) => NewsItemDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<NewsArticleDto?> getArticle(String id) async {
    final data =
        await _call('news-article', {
              'id': id,
              'club': _clubConfig.identity.code,
            })
            as Map<String, dynamic>;
    if (data['available'] != true) return null;
    return NewsArticleDto.fromJson(data['article'] as Map<String, dynamic>);
  }
}
