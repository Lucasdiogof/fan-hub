import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Base URL do nosso backend interno (`/api/football/*`), nunca de um
/// provedor esportivo diretamente. Vazio em produção (o Flutter é servido
/// pelo próprio Cloudflare Worker, mesma origem das rotas de API); em
/// desenvolvimento local, aponte pra produção via
/// `--dart-define=API_BASE_URL=https://goias-app.lucasdiogo1234.workers.dev`
/// (ou pro `wrangler dev` local, se estiver rodando um). Isso não é segredo —
/// é só uma URL — por isso pode ir em dart-define.
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

class ApiClient {
  const ApiClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _apiBaseUrl,
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
