import type { Env } from '../football/_lib/config';
import { errorResponse } from '../football/_lib/respond';

/**
 * Só existem pra isso: hosts de imagem que o app usa e que não mandam
 * `Access-Control-Allow-Origin`, então o Flutter Web (CanvasKit/Skwasm) não
 * consegue ler os bytes pra decodificar. Lista fechada de propósito — isto
 * não é um proxy aberto, só busca esses hosts específicos.
 */
const ALLOWED_HOSTS = new Set(['images.onefootball.com', 'static.goiasec.com.br']);

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

  if (!ALLOWED_HOSTS.has(targetUrl.hostname)) {
    return errorResponse('Host de imagem não permitido.', 403);
  }

  const cache = (caches as unknown as { default: Cache }).default;
  const cacheKey = new Request(requestUrl.toString(), { method: 'GET' });
  const cached = await cache.match(cacheKey);
  if (cached) return cached;

  let upstream: Response;
  try {
    upstream = await fetch(targetUrl.toString(), { headers: { accept: 'image/*' } });
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
