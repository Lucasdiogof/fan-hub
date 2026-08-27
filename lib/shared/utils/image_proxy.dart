import 'package:flutter/foundation.dart';
import 'package:goias_app/core/network/api_client.dart';

/// Hosts que não mandam `Access-Control-Allow-Origin` — sem isso, o Flutter
/// Web (CanvasKit/Skwasm, únicos renderers disponíveis hoje) não consegue
/// ler os bytes da imagem pra decodificar, e ela nunca aparece (cai no
/// fallback silenciosamente). No Android/iOS isso não existe: CORS é uma
/// regra de navegador.
final _hostsWithoutCors = {'images.onefootball.com', 'static.goiasec.com.br'};

/// Devolve a URL certa pra usar em `Image.network`/`CachedNetworkImage`.
/// Fora do web, devolve [url] sem alterar. No web, se o host é um dos que
/// não manda CORS, reescreve pra passar pelo proxy `/api/image-proxy` do
/// próprio Worker (que busca a imagem no servidor e reenvia com CORS
/// liberado) — ver `src/media/imageProxy.ts`.
String proxiedImageUrl(String url) {
  if (!kIsWeb) return url;
  final parsed = Uri.tryParse(url);
  if (parsed == null || !_hostsWithoutCors.contains(parsed.host)) return url;
  return Uri.parse(
    '${resolveApiBaseUrl()}/api/image-proxy',
  ).replace(queryParameters: {'url': url}).toString();
}
