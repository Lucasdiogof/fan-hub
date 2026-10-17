import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// `true` quando [error] é falta de rede / sem resposta (modo avião, DNS,
/// timeout) — diferente de erro HTTP/consulta, que merece outra mensagem.
/// Não depende de `connectivity_plus`: só o que a requisição de fato
/// reportou.
bool isConnectivityError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException ||
      error is HandshakeException) {
    return true;
  }
  final name = error.runtimeType.toString();
  return name.contains('SocketException') ||
      name.contains('ClientException') ||
      name.contains('TimeoutException');
}
