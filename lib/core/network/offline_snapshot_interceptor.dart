import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goias_app/core/cache/json_snapshot_cache.dart';

/// Quais telas dependem de dado do Worker que muda com o tempo.
enum SnapshotCategory { news, matches }

/// Diz às telas se o que elas estão mostrando veio da última consulta
/// salva (e de quando) — a UI nunca apresenta cache como dado atualizado.
/// Singleton (ver `injection_container.dart`): o interceptor escreve, os
/// banners ouvem.
class OfflineSnapshotStatus extends ChangeNotifier {
  final Map<SnapshotCategory, DateTime> _staleSince = {};

  /// Não nulo = a última resposta dessa categoria veio do aparelho.
  DateTime? savedAt(SnapshotCategory category) => _staleSince[category];

  void markStale(SnapshotCategory category, DateTime savedAt) {
    if (_staleSince[category] == savedAt) return;
    _staleSince[category] = savedAt;
    notifyListeners();
  }

  void markFresh(SnapshotCategory category) {
    if (_staleSince.remove(category) != null) notifyListeners();
  }
}

/// Guarda a última resposta bem-sucedida das consultas de leitura que a
/// Home, Jogos e Mídia fazem ao Worker e, SÓ quando a requisição falha por
/// rede/timeout (nunca por erro HTTP do servidor), devolve essa cópia.
///
/// Regras de segurança do dado:
/// - Nunca cacheia detalhe de partida (`/fixtures/:id`), social ou
///   qualquer rota fora da lista abaixo.
/// - Partida salva "ao vivo"/"intervalo" volta como `unknown` sem minuto:
///   uma cópia antiga NUNCA aparece como jogo em andamento.
/// - Passou de [maxAge], não serve (tela mostra erro/vazio claro).
class OfflineSnapshotInterceptor extends Interceptor {
  OfflineSnapshotInterceptor(
    this._status, {
    this._cache = const JsonSnapshotCache(),
    DateTime Function()? now,
    this.newsMaxAge = const Duration(days: 7),
    this.matchesMaxAge = const Duration(days: 14),
  }) : _now = now ?? DateTime.now;

  final OfflineSnapshotStatus _status;
  final JsonSnapshotCache _cache;
  final DateTime Function() _now;
  final Duration newsMaxAge;
  final Duration matchesMaxAge;

  static const _servedFromSnapshotKey = 'servedFromSnapshot';

  SnapshotCategory? _categoryOf(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return null;
    final path = options.path;
    if (path == '/api/news') return SnapshotCategory.news;
    if (path.startsWith('/api/football/') &&
        !path.startsWith('/api/football/fixtures/')) {
      return SnapshotCategory.matches;
    }
    return null;
  }

  Duration _maxAge(SnapshotCategory category) =>
      category == SnapshotCategory.news ? newsMaxAge : matchesMaxAge;

  String _keyOf(RequestOptions options) {
    final query = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final suffix = query.map((e) => '${e.key}=${e.value}').join('&');
    return 'http:${options.path}?$suffix';
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final category = _categoryOf(response.requestOptions);
    final data = response.data;
    if (category != null &&
        response.statusCode == 200 &&
        data is Map<String, dynamic> &&
        response.requestOptions.extra[_servedFromSnapshotKey] != true) {
      await _cache.write(_keyOf(response.requestOptions), data, now: _now());
      _status.markFresh(category);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final category = _categoryOf(err.requestOptions);
    final isNetworkFailure =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
    if (category == null || !isNetworkFailure) {
      return handler.next(err);
    }
    final snapshot = await _cache.read(_keyOf(err.requestOptions));
    if (snapshot == null ||
        snapshot.payload is! Map ||
        _now().difference(snapshot.savedAt) > _maxAge(category)) {
      return handler.next(err);
    }
    final payload = _withoutLiveState(
      jsonDecode(jsonEncode(snapshot.payload)) as Map<String, dynamic>,
    );
    _status.markStale(category, snapshot.savedAt);
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: err.requestOptions
          ..extra[_servedFromSnapshotKey] = true,
        statusCode: 200,
        data: payload,
      ),
    );
  }

  /// Troca `live`/`halftime` salvos por `unknown` (e some com o minuto) em
  /// qualquer nível do JSON.
  static Map<String, dynamic> _withoutLiveState(Map<String, dynamic> node) {
    Object? walk(Object? value) {
      if (value is Map<String, dynamic>) {
        final status = value['status'];
        final wasLive = status == 'live' || status == 'halftime';
        return {
          for (final entry in value.entries)
            if (!(wasLive && entry.key == 'minute'))
              entry.key: wasLive && entry.key == 'status'
                  ? 'unknown'
                  : walk(entry.value),
        };
      }
      if (value is List) return value.map(walk).toList();
      return value;
    }

    return walk(node)! as Map<String, dynamic>;
  }
}
