import 'dart:convert';

import 'package:http/http.dart' as http;

/// Dublê de `http.Client` injetado no `SupabaseClient` (parâmetro
/// `httpClient`, real, do pacote `supabase_flutter`) — captura a URL (E o
/// corpo, pra RPCs/insert/upsert/update) de CADA requisição de verdade que
/// o `postgrest` monta a partir de `.select()/.eq()/.order()`/`.rpc()`/
/// `.insert()`/`.upsert()`/`.update()`, sem precisar de nenhum framework de
/// mock.
///
/// Isso prova de verdade que um filtro `.eq('club_id', ...)` chegou na
/// query string (`club_id=eq.<uuid>`) e que `club_id`/`p_club_id` chegou no
/// corpo JSON de um write/RPC — não só que o repository "devolveu dados" ou
/// "não lançou", que poderia continuar passando mesmo sem tenancy nenhuma.
class CapturingHttpClient extends http.BaseClient {
  CapturingHttpClient({this.responseBody = '[]', this.statusCode = 200});

  /// Se não-nulo, `send` lança isto em vez de responder — simula falha de
  /// rede/banco (para testar o caminho `catch`, distinto de "0 linhas").
  Object? throwError;

  final String responseBody;
  final int statusCode;

  Uri? lastRequestUrl;
  final requestUrls = <Uri>[];

  /// Corpo (string JSON) da última requisição — `null` quando a requisição
  /// não carregava corpo (ex.: um GET puro).
  String? lastRequestBody;
  final requestBodies = <String?>[];

  /// Mesmo corpo, já decodificado — `Map<String, dynamic>` pra RPC/upsert
  /// de linha única, `List<dynamic>` pra insert em lote (ex.: `tickets`
  /// comprados de uma vez).
  dynamic get lastRequestBodyJson {
    final body = lastRequestBody;
    if (body == null || body.isEmpty) return null;
    return jsonDecode(body);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequestUrl = request.url;
    requestUrls.add(request.url);
    final body = request is http.Request ? request.body : null;
    lastRequestBody = body;
    requestBodies.add(body);
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
