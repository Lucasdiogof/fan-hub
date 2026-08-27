import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    return dio;
  }
}
