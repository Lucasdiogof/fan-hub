/**
 * Cache-first usando a Cache API do Workers runtime. A chave de cache é a
 * própria URL da requisição (inclui query string, então `?scope=upcoming` e
 * `?scope=results` não colidem). TTL é aplicado via `Cache-Control`.
 */
export async function cacheFirst(
  request: Request,
  ttlSeconds: number,
  logPrefix: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  fetcher: () => Promise<unknown>,
): Promise<Response> {
  const cache = (caches as unknown as { default: Cache }).default;
  const cacheKey = new Request(request.url, { method: 'GET' });

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
