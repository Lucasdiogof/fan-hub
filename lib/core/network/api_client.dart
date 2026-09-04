import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:sentry_dio/sentry_dio.dart';

const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Host reservado pra documentação/teste (RFC 2606) — nunca resolve de
/// verdade. Usado só quando o clube ativo não tem `workerBaseUrl`
/// configurado: as chamadas falham (erro de conexão, capturado pelos
/// `try/catch` já existentes em cada repository) em vez de silenciosamente
/// caírem no Worker de outro clube. Nunca lança no boot do app — `Dio` é
/// `registerLazySingleton`, e as features que o usam (Jogos/Notícias/
/// Social) já ficam indisponíveis via `ClubCapabilities` antes disso
/// importar na prática.
const _unconfiguredClubHost = 'https://worker-not-configured.invalid';

/// No web, o build normalmente é servido pelo próprio Worker (mesma
/// origem), então a base fica vazia (paths relativos); fora do web, aponta
/// pro Worker do clube ativo. `API_BASE_URL` (via `--dart-define`) é
/// SEMPRE só um override de desenvolvimento/local (ex.: `wrangler dev` na
/// máquina) — nunca deveria ser passado num build de release, e nenhum
/// flavor precisa mais dele: `ClubIntegrations.workerBaseUrl` já resolve a
/// URL certa automaticamente a partir de `APP_CLUB`.
String resolveApiBaseUrl(ClubConfig clubConfig) {
  if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
  if (kIsWeb) return '';
  return clubConfig.integrations.workerBaseUrl ?? _unconfiguredClubHost;
}

class ApiClient {
  const ApiClient._();

  static Dio create(ClubConfig clubConfig) {
    final dio = Dio(
      BaseOptions(
        baseUrl: resolveApiBaseUrl(clubConfig),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: true, error: true),
      );
    }
    // Toda requisição (URL, método, status, duração) vira breadcrumb no
    // Sentry automaticamente — sem isso, um erro de "API fora do ar" só
    // aparece como uma DioException genérica, sem dar pra saber qual
    // endpoint ou se foi timeout de conexão vs. resposta.
    dio.addSentry();
    return dio;
  }
}
