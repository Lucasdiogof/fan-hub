import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
const _productionBaseUrl = 'https://goias-app.lucasdiogo1234.workers.dev';

String _resolveBaseUrl() {
  if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
  return kIsWeb ? '' : _productionBaseUrl;
}

class ApiClient {
  const ApiClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
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
