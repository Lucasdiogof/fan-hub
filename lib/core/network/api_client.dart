import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';

const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
const _productionBaseUrl = 'https://goias-app.lucasdiogo1234.workers.dev';

/// No web, o build normalmente é servido pelo próprio Worker (mesma
/// origem), então a base fica vazia (paths relativos); fora do web, aponta
/// pro Worker direto. `API_BASE_URL` (via `--dart-define`) sempre tem
/// prioridade — usado em dev local do Flutter Web, por exemplo.
String resolveApiBaseUrl() {
  if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
  return kIsWeb ? '' : _productionBaseUrl;
}

class ApiClient {
  const ApiClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: resolveApiBaseUrl(),
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
