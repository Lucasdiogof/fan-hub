import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/network/session_aware_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

/// JWT falso só pra o GoTrue conseguir decodificar um `exp` — a
/// assinatura não é verificada no cliente, então qualquer valor serve
/// nesses testes (o que decide 401 ou 200 é sempre o mock do "servidor",
/// nunca o relógio local).
String _fakeJwt() {
  String segment(Object payload) =>
      base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  final header = segment({'alg': 'HS256', 'typ': 'JWT'});
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final payload = segment({'sub': 'test-user', 'exp': exp});
  return '$header.$payload.signature';
}

Map<String, dynamic> _sessionJson(String tokenSuffix, String refreshToken) {
  return {
    'access_token': '${_fakeJwt()}-$tokenSuffix',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': refreshToken,
    'user': {
      'id': 'test-user',
      'aud': 'authenticated',
      'created_at': DateTime.now().toIso8601String(),
    },
  };
}

http.Response _json(Object body, int status) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  const url = 'https://example.supabase.co';
  const anonKey = 'anon-key';

  /// Monta um `SupabaseClient` de verdade (mesma classe usada em produção,
  /// via `supabase_flutter`, que reexporta o pacote `supabase`) contra um
  /// backend falso controlado pelo teste — cobre o comportamento real de
  /// dedup/retry do GoTrue, não uma reimplementação nossa dele.
  ({
    SupabaseClient client,
    SessionAwareHttpClient sessionClient,
    int Function() refreshCallCount,
    List<String?> Function() restAuthHeaders,
  })
  buildClient({
    required http.Response Function(http.Request request) onRest,
    http.Response Function(http.Request request)? onRefresh,
  }) {
    var refreshCalls = 0;
    final restAuthHeaders = <String?>[];
    late SupabaseClient client;

    final mock = MockClient((request) async {
      if (request.url.path.contains('/auth/v1/token')) {
        if (request.url.queryParameters['grant_type'] == 'refresh_token') {
          refreshCalls++;
          if (onRefresh != null) return onRefresh(request);
          return _json(_sessionJson('v2', 'refresh-v2'), 200);
        }
        // grant_type=password — login inicial de cada teste.
        return _json(_sessionJson('v1', 'refresh-v1'), 200);
      }

      restAuthHeaders.add(request.headers['Authorization']);
      return onRest(request);
    });

    final sessionClient = SessionAwareHttpClient(mock, auth: () => client.auth);
    client = SupabaseClient(
      url,
      anonKey,
      httpClient: sessionClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    );

    return (
      client: client,
      sessionClient: sessionClient,
      refreshCallCount: () => refreshCalls,
      restAuthHeaders: () => restAuthHeaders,
    );
  }

  test('sessão válida: passa direto, sem nenhum refresh', () async {
    final env = buildClient(
      onRest: (req) => _json([
        {'id': 1},
      ], 200),
    );
    await env.client.auth.signInWithPassword(email: 'a@a.com', password: 'x');

    final result = await env.client.from('games').select();

    expect(result, [
      {'id': 1},
    ]);
    expect(env.refreshCallCount(), 0);
  });

  test(
    // Regressão específica do bug real (Sentry: 6 issues simultâneas de
    // PostgrestException JWT expired, com "clock drift" de ~2h reportado
    // pelo SDK): a sessão LOCAL continua válida por `isExpired` (o token
    // aqui vence daqui a 1h, de propósito — nunca usamos um JWT já
    // vencido) — então o `getSession()` proativo do GoTrue não renova
    // nada sozinho, e a requisição sai com o token "válido" do ponto de
    // vista do aparelho. O SERVIDOR (meu mock, fazendo o papel de um
    // relógio correto) é quem rejeita com 401/PGRST303. Sem o
    // `SessionAwareHttpClient`, essa combinação é exatamente o que
    // produzia o erro cru chegando no repositório.
    'servidor rejeita um token que o cliente ainda acha válido (clock drift): renova e repete com o token novo',
    () async {
      var restCalls = 0;
      final env = buildClient(
        onRest: (req) {
          restCalls++;
          if (restCalls == 1) {
            return _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401);
          }
          return _json([
            {'id': 42},
          ], 200);
        },
      );
      await env.client.auth.signInWithPassword(
        email: 'a@a.com',
        password: 'x',
      );

      final sessionBefore = env.client.auth.currentSession!;
      final tokenA = sessionBefore.accessToken;
      expect(
        sessionBefore.isExpired,
        isFalse,
        reason:
            'precondição do cenário: o cliente precisa achar a sessão '
            'válida — é isso que faz o GoTrue não renovar sozinho antes '
            'de mandar a requisição, deixando só o SessionAwareHttpClient '
            'pra reagir à rejeição do servidor.',
      );

      final result = await env.client.from('games').select();

      final tokenB = env.client.auth.currentSession!.accessToken;
      expect(result, [
        {'id': 42},
      ]);
      expect(restCalls, 2);
      expect(env.refreshCallCount(), 1);
      expect(
        tokenB,
        isNot(tokenA),
        reason: 'o refresh precisa ter trocado o token de verdade',
      );
      expect(
        env.restAuthHeaders()[0],
        'Bearer $tokenA',
        reason: 'primeira tentativa usa o token antigo (A)',
      );
      expect(
        env.restAuthHeaders()[1],
        'Bearer $tokenB',
        reason:
            'o retry precisa usar o token NOVO (B) — nunca reenviar a '
            'requisição original com o header antigo',
      );
    },
  );

  test('5 chamadas simultâneas com token expirado geram só 1 refresh', () async {
    final env = buildClient(
      onRest: (req) {
        final auth = req.headers['Authorization'] ?? '';
        if (auth.endsWith('-v1')) {
          return _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401);
        }
        return _json([
          {'id': 1},
        ], 200);
      },
    );
    await env.client.auth.signInWithPassword(email: 'a@a.com', password: 'x');

    final results = await Future.wait(
      List.generate(5, (_) => env.client.from('games').select()),
    );

    expect(results, everyElement(isNotEmpty));
    expect(
      env.refreshCallCount(),
      1,
      reason:
          'GoTrue já deduplica chamadas concorrentes de refreshSession pelo '
          'mesmo refresh token — só deve existir 1 chamada de rede de '
          'verdade mesmo com 5 requests batendo 401 ao mesmo tempo.',
    );
  });

  test(
    'refresh falha por rede: não desloga, propaga como erro de rede',
    () async {
      final env = buildClient(
        onRest: (req) =>
            _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401),
        onRefresh: (req) => throw Exception('simulated network failure'),
      );
      await env.client.auth.signInWithPassword(
        email: 'a@a.com',
        password: 'x',
      );

      final events = <AuthChangeEvent>[];
      env.client.auth.onAuthStateChange.listen(
        (state) => events.add(state.event),
        onError: (_) {},
      );

      // Chama `send` direto (não `client.from('games').select()`): o
      // Postgrest tem seu próprio retry embutido pra qualquer `Exception`
      // que `send` jogue (não dá pra desligar por request nem por
      // `SupabaseQueryBuilder` — uma limitação do SDK, não deste código),
      // o que multiplicaria por 4 o tempo desse cenário sem testar nada
      // a mais sobre o `SessionAwareHttpClient` em si.
      final request = http.Request(
        'GET',
        Uri.parse('$url/rest/v1/games?select=*'),
      )..headers['Authorization'] = 'Bearer irrelevant';

      await expectLater(
        () => env.sessionClient.send(request),
        throwsA(isA<http.ClientException>()),
      );

      expect(env.client.auth.currentSession, isNotNull);
      expect(events, isNot(contains(AuthChangeEvent.signedOut)));
    },
    // O próprio GoTrue já retenta uma falha de rede internamente (backoff
    // exponencial, até ~12s antes de desistir — ver `_refreshAccessToken`
    // no pacote `gotrue`) ANTES de nos devolver `AuthRetryableFetchException`.
    // É um comportamento bom pra produção (uma instabilidade passageira se
    // resolve sozinha, sem o app precisar fazer nada) — só torna este teste
    // específico (onde a falha nunca some) inerentemente lento.
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'refresh token inválido: sessão é encerrada (signedOut/sessionExpired) e o 401 original sobe',
    () async {
      final env = buildClient(
        onRest: (req) => _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401),
        onRefresh: (req) => _json({
          'code': 'refresh_token_not_found',
          'error_code': 'refresh_token_not_found',
          'msg': 'Invalid Refresh Token: Refresh Token Not Found',
        }, 400),
      );
      await env.client.auth.signInWithPassword(
        email: 'a@a.com',
        password: 'x',
      );

      final states = <AuthState>[];
      env.client.auth.onAuthStateChange.listen(states.add, onError: (_) {});

      await expectLater(
        () => env.client.from('games').select(),
        throwsA(isA<PostgrestException>()),
      );
      await Future<void>.delayed(Duration.zero);

      final signedOut = states.where((s) => s.event == AuthChangeEvent.signedOut);
      expect(signedOut, isNotEmpty);
      expect(signedOut.first.signOutReason, SignOutReason.sessionExpired);
      expect(env.refreshCallCount(), 1);
    },
  );

  test('retry também falha: não entra em loop, refresh só acontece uma vez', () async {
    var restCalls = 0;
    final env = buildClient(
      onRest: (req) {
        restCalls++;
        return _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401);
      },
    );
    await env.client.auth.signInWithPassword(email: 'a@a.com', password: 'x');

    await expectLater(
      () => env.client.from('games').select(),
      throwsA(isA<PostgrestException>()),
    );

    expect(restCalls, 2);
    expect(env.refreshCallCount(), 1);
  });
}
