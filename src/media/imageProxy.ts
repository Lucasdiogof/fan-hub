import type { Env } from '../football/_lib/config';
import { errorResponse } from '../football/_lib/respond';

/**
 * Só existem pra isso: hosts de imagem que o app usa e que não mandam
 * `Access-Control-Allow-Origin` (ou bloqueiam hotlink de outro jeito), então
 * o Flutter Web (CanvasKit/Skwasm) não consegue ler os bytes pra decodificar.
 * Lista fechada de propósito — isto não é um proxy aberto, só busca esses
 * hosts específicos. Exatos (host precisa bater igual) e sufixos (pra
 * subdomínios regionais tipo `scontent-gru2-1.cdninstagram.com`).
 */
const ALLOWED_HOSTS = new Set(['images.onefootball.com', 'static.goiasec.com.br']);
const ALLOWED_HOST_SUFFIXES = ['.cdninstagram.com', '.fbcdn.net'];

function isAllowedHost(hostname: string): boolean {
  if (ALLOWED_HOSTS.has(hostname)) return true;
  return ALLOWED_HOST_SUFFIXES.some((suffix) => hostname.endsWith(suffix));
}

// Escudos/fotos de notícia publicadas não mudam depois — pode cachear bastante.
const CACHE_TTL_SECONDS = 60 * 60 * 24 * 7;

/** GET /api/image-proxy?url=<url original> — busca a imagem no servidor e
 * reenvia com CORS liberado, pro Flutter Web conseguir renderizar. */
export async function handleImageProxy(request: Request, _env: Env): Promise<Response> {
  const requestUrl = new URL(request.url);
  const target = requestUrl.searchParams.get('url');
  if (!target) return errorResponse('Parâmetro "url" ausente.', 400);

  let targetUrl: URL;
  try {
    targetUrl = new URL(target);
  } catch {
    return errorResponse('URL inválida.', 400);
  }

  if (!isAllowedHost(targetUrl.hostname)) {
    return errorResponse('Host de imagem não permitido.', 403);
  }

  const cache = (caches as unknown as { default: Cache }).default;
  const cacheKey = new Request(requestUrl.toString(), { method: 'GET' });
  const cached = await cache.match(cacheKey);
  if (cached) return cached;

  let upstream: Response;
  try {
    // O CDN do Instagram (cdninstagram.com/fbcdn.net) rejeita com 403
    // requisições sem cara de navegador — não é falta de CORS (ele já
    // manda `Access-Control-Allow-Origin: *`), é proteção contra hotlink
    // checando User-Agent/Referer. Sem esses dois headers, nem chega a CORS.
    upstream = await fetch(targetUrl.toString(), {
      headers: {
        accept: 'image/*',
        'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        referer: 'https://www.instagram.com/',
      },
    });
  } catch (err) {
    console.error('media.image_proxy.fetch_error', err instanceof Error ? err.message : String(err));
    return errorResponse('Não foi possível buscar a imagem.', 502);
  }

  if (!upstream.ok || !upstream.body) {
    return errorResponse('Não foi possível buscar a imagem.', upstream.status || 502);
  }

  const contentType = upstream.headers.get('content-type') ?? 'application/octet-stream';
  const response = new Response(upstream.body, {
    headers: {
      'content-type': contentType,
      'cache-control': `public, max-age=${CACHE_TTL_SECONDS}, immutable`,
      'access-control-allow-origin': '*',
    },
  });

  await cache.put(cacheKey, response.clone());
  return response;
}
