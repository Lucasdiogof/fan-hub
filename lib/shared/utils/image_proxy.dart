import 'package:flutter/foundation.dart';
import 'package:goias_app/core/network/api_client.dart';

/// Hosts que não mandam `Access-Control-Allow-Origin` (ou bloqueiam de
/// outro jeito, tipo o CDN do Instagram exigindo cara de navegador) — sem
/// isso, o Flutter Web (CanvasKit/Skwasm, únicos renderers disponíveis
/// hoje) não consegue ler os bytes da imagem pra decodificar, e ela nunca
/// aparece (cai no fallback silenciosamente). No Android/iOS isso não
/// existe: é tudo regra de navegador. Espelha `ALLOWED_HOST_SUFFIXES` em
/// `src/media/imageProxy.ts` — os subdomínios do Instagram variam por
/// região/post (`scontent-gru2-1.cdninstagram.com` etc.), daí o sufixo em
/// vez de host exato.
final _exactHostsWithoutCors = {
  'images.onefootball.com',
  'static.goiasec.com.br',
};
final _hostSuffixesWithoutCors = ['.cdninstagram.com', '.fbcdn.net'];

bool _needsProxy(String host) {
  if (_exactHostsWithoutCors.contains(host)) return true;
  return _hostSuffixesWithoutCors.any(host.endsWith);
}

/// Devolve a URL certa pra usar em `Image.network`/`CachedNetworkImage`.
/// Fora do web, devolve [url] sem alterar. No web, se o host é um dos que
/// não manda CORS, reescreve pra passar pelo proxy `/api/image-proxy` do
/// próprio Worker (que busca a imagem no servidor e reenvia com CORS
/// liberado) — ver `src/media/imageProxy.ts`.
String proxiedImageUrl(String url) {
  if (!kIsWeb) return url;
  final parsed = Uri.tryParse(url);
  if (parsed == null || !_needsProxy(parsed.host)) return url;
  return Uri.parse(
    '${resolveApiBaseUrl()}/api/image-proxy',
  ).replace(queryParameters: {'url': url}).toString();
}
