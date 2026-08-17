/**
 * Cache-first usando a Cache API do Workers runtime. A chave de cache é a
 * própria URL da requisição (inclui query string, então `?scope=upcoming` e
 * `?scope=results` não colidem) mais `cacheVersion` (ver `CACHE_VERSION` no
 * wrangler.toml) — sem isso, uma correção de bug no formato dos dados só
 * valeria pros usuários depois do TTL antigo expirar, mesmo já deployada.
 * TTL é aplicado via `Cache-Control`.
 */
export async function cacheFirst(
  request: Request,
  ttlSeconds: number,
  logPrefix: string,
  cacheVersion: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  fetcher: () => Promise<unknown>,
): Promise<Response> {
  const cache = (caches as unknown as { default: Cache }).default;
  const versionedUrl = new URL(request.url);
  versionedUrl.searchParams.set('__cv', cacheVersion);
  const cacheKey = new Request(versionedUrl.toString(), { method: 'GET' });

  const cached = await cache.match(cacheKey);
  if (cached) {
    console.log(`${logPrefix}.cache_hit`);
    return cached;
  }

  console.log(`${logPrefix}.cache_miss`);
  const data = await fetcher();

  const response = new Response(JSON.stringify(data), {
    headers: {
      'content-type': 'application/json',
      'cache-control': `public, max-age=${ttlSeconds}`,
      'access-control-allow-origin': '*',
    },
  });

  await cache.put(cacheKey, response.clone());
  return response;
}
