import 'dart:convert';

import 'package:http/http.dart' as http;

/// Dublê de `http.Client` injetado no `SupabaseClient` (parâmetro
/// `httpClient`, real, do pacote `supabase_flutter`) — captura a URL de
/// CADA requisição de verdade que o `postgrest` monta a partir de
/// `.select()/.eq()/.order()`, sem precisar de nenhum framework de mock.
///
/// Isso prova de verdade que um filtro `.eq('club_id', ...)` chegou na
/// query string (`club_id=eq.<uuid>`) — não só que o repository "devolveu
/// dados", que poderia continuar passando mesmo sem filtro nenhum.
class CapturingHttpClient extends http.BaseClient {
  CapturingHttpClient({this.responseBody = '[]', this.statusCode = 200});

  /// Se não-nulo, `send` lança isto em vez de responder — simula falha de
  /// rede/banco (para testar o caminho `catch`, distinto de "0 linhas").
  Object? throwError;

  final String responseBody;
  final int statusCode;

  Uri? lastRequestUrl;
  final requestUrls = <Uri>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequestUrl = request.url;
    requestUrls.add(request.url);
    final error = throwError;
    if (error != null) throw error;
    final bodyBytes = utf8.encode(responseBody);
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      statusCode,
      headers: const {'content-type': 'application/json'},
      // postgrest lê `response.request!.method` — sem isto o parse quebra
      // com um null-check, mesmo numa resposta 200 válida.
      request: request,
    );
  }
}
