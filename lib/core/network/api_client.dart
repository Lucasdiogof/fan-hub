import 'package:dio/dio.dart';

/// Base URL do nosso backend interno (`/api/football/*`), nunca da
/// API-Football diretamente. Vazio em produção (mesma origem do site
/// hospedado no Cloudflare Pages); em desenvolvimento local, aponte para o
/// `wrangler pages dev` via `--dart-define=API_BASE_URL=http://localhost:8788`.
/// Isso não é segredo — é só uma URL — por isso pode ir em dart-define.
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

class ApiClient {
  const ApiClient._();

  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}
