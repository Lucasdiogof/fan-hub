import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único ponto por onde passa TODO tráfego HTTP autenticado do Supabase
/// (Postgrest, Storage e o Auth do próprio SDK — ver
/// `Supabase.initialize(httpClient: ...)` em `main.dart`). Sem isso, cada
/// um dos ~15 repositórios que chamam `_client.from(...)` precisaria
/// repetir a mesma lógica de "detectei token expirado, renova e tenta de
/// novo" — aqui entra uma vez só, pra qualquer chamada autenticada,
/// presente ou futura, sem tocar em nenhum repositório.
///
/// O próprio GoTrue já tenta renovar o token PROATIVAMENTE antes de
/// anexar o header (`getSession()`, com dedup nativo entre chamadas
/// concorrentes — várias requisições simultâneas com o mesmo refresh
/// token colapsam numa única chamada de rede de verdade). Mas essa
/// checagem confia no relógio do aparelho: se ele estiver
/// adiantado/atrasado (o Sentry acusou exatamente isso — "clock drift"
/// de ~2h no evento que originou esta classe), o SDK acha que o token
/// ainda vale e manda a requisição do mesmo jeito; o servidor (que não
/// depende do relógio do aparelho) rejeita com 401. Esta classe cobre
/// exatamente esse ponto cego: reage à resposta REAL do servidor, nunca
/// só ao que o relógio local acha.
class SessionAwareHttpClient extends http.BaseClient {
  SessionAwareHttpClient(this._inner, {GoTrueClient Function()? auth})
    : _auth = auth ?? (() => Supabase.instance.client.auth);

  final http.Client _inner;
  final GoTrueClient Function() _auth;

  static const _authPathSegment = '/auth/v1/';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Nunca intercepta o tráfego do próprio Auth (login, refresh, etc.) —
    // senão uma falha ao renovar o token viraria uma tentativa de renovar
    // de novo, recursivamente.
    if (request.url.path.contains(_authPathSegment)) {
      return _inner.send(request);
    }

    // Só sabemos reconstruir, pra tentar de novo, requests com corpo já
    // lido em memória (`http.Request` — cobre toda chamada normal do
    // Postgrest: select/insert/update/upsert/delete/rpc). Upload de
    // arquivo pro Storage usa um request de stream, que não dá pra "reler"
    // depois de consumido — nesse caso raro, sem retry automático: o erro
    // original ainda chega normal pro mapper de cada repositório, exatamente
    // como já acontecia antes desta classe existir.
    if (request is! http.Request) {
      return _inner.send(request);
    }

    final firstAttempt = await http.Response.fromStream(
      await _inner.send(request),
    );
    if (!_looksLikeExpiredJwt(firstAttempt)) {
      return _toStreamedResponse(firstAttempt, request);
    }

    String? freshAccessToken;
    try {
      final refreshed = await _auth().refreshSession();
      freshAccessToken = refreshed.session?.accessToken;
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'auth_session_refreshed',
            category: 'auth',
            level: SentryLevel.info,
            data: {'trigger': 'http_401'},
          ),
        ),
      );
    } on AuthException catch (error) {
      // Falha de REDE ao tentar renovar: a sessão local continua válida
      // (o GoTrue não a descarta nesse caso — ver `_doRefresh` do
      // pacote), só não deu pra confirmar agora. Nunca deslogar por isso.
      // Propaga como um erro de rede "de verdade" (`ClientException`),
      // que todo mapper de repositório já sabe classificar como
      // `NetworkFailure` — sem precisar ensinar cada um sobre JWT/GoTrue.
      if (error is AuthRetryableFetchException) {
        throw http.ClientException(
          'Não foi possível renovar a sessão (sem conexão).',
          request.url,
        );
      }
      // Qualquer outra `AuthException` aqui é definitiva (refresh token
      // inválido/revogado, sessão local incompleta) — o GoTrue já limpou
      // a sessão e emitiu `signedOut` com o motivo certo sozinho (ver
      // `AuthRepositoryImpl._mapEvent`, que já transforma isso num
      // `AuthSessionExpired` consumido pela UI). Aqui só deixamos a
      // resposta 401 original seguir pro Postgrest, que lança a exceção
      // de sempre — o mapper de cada repositório já sabe tratar, e a
      // navegação/aviso pro usuário já está a caminho por outro canal.
      return _toStreamedResponse(firstAttempt, request);
    }

    if (freshAccessToken == null) {
      return _toStreamedResponse(firstAttempt, request);
    }

    // Repete a chamada original UMA única vez, com o token novo. Se essa
    // segunda tentativa também vier com problema (seja lá qual for), o
    // erro sobe normal — nunca um novo ciclo de refresh.
    final retry = _cloneWithFreshToken(request, freshAccessToken);
    final retryResponse = await http.Response.fromStream(
      await _inner.send(retry),
    );
    return _toStreamedResponse(retryResponse, retry);
  }

  bool _looksLikeExpiredJwt(http.Response response) {
    if (response.statusCode != 401) return false;
    final body = response.body;
    return body.contains('PGRST303') ||
        (body.toLowerCase().contains('jwt') &&
            body.toLowerCase().contains('expired'));
  }

  http.Request _cloneWithFreshToken(http.Request original, String token) {
    final clone = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..bodyBytes = original.bodyBytes
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    clone.headers['Authorization'] = 'Bearer $token';
    return clone;
  }

  /// Sempre recebe explicitamente qual [request] originou [response] — não
  /// dá pra confiar em `response.request` (alguns clientes, incluindo o
  /// `MockClient` de teste, só preenchem isso se quem construiu a
  /// `Response` também preencheu, e o Postgrest faz `response.request!`
  /// sem checar null).
  http.StreamedResponse _toStreamedResponse(
    http.Response response,
    http.BaseRequest request,
  ) {
    return http.StreamedResponse(
      http.ByteStream.fromBytes(response.bodyBytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
