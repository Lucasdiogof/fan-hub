import { afterEach, describe, expect, it, vi } from 'vitest';
import { handleImageProxy } from './imageProxy';
import type { Env } from '../football/_lib/config';

const env = {} as Env;

function stubFetch(handler: () => Promise<Response> | Response) {
  const fn = vi.fn(handler);
  vi.stubGlobal('fetch', fn);
  return fn;
}

function proxyRequest(targetUrl?: string): Request {
  const url = new URL('https://worker.example/api/image-proxy');
  if (targetUrl !== undefined) url.searchParams.set('url', targetUrl);
  return new Request(url.toString());
}

afterEach(() => vi.unstubAllGlobals());

describe('handleImageProxy', () => {
  it('returns 400 when the url param is missing', async () => {
    const response = await handleImageProxy(proxyRequest(), env);
    expect(response.status).toBe(400);
  });

  it('returns 400 when the url param is not a valid URL', async () => {
    const response = await handleImageProxy(proxyRequest('not-a-url'), env);
    expect(response.status).toBe(400);
  });

  it('returns 403 for a host outside the allowlist', async () => {
    const fetchFn = stubFetch(() => new Response('nope'));
    const response = await handleImageProxy(proxyRequest('https://evil.example/x.png'), env);
    expect(response.status).toBe(403);
    expect(fetchFn).not.toHaveBeenCalled();
  });

  it('fetches an allowed host and re-serves the image with CORS enabled', async () => {
    const bytes = new Uint8Array([1, 2, 3]);
    stubFetch(() => new Response(bytes, { status: 200, headers: { 'content-type': 'image/png' } }));

    const response = await handleImageProxy(
      proxyRequest('https://images.onefootball.com/icons/teams/164/1863.png'),
      env,
    );

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('image/png');
    expect(response.headers.get('access-control-allow-origin')).toBe('*');
    expect(new Uint8Array(await response.arrayBuffer())).toEqual(bytes);
  });

  it('forwards an error status when the upstream fetch fails', async () => {
    stubFetch(() => new Response('not found', { status: 404 }));

    const response = await handleImageProxy(
      proxyRequest('https://static.goiasec.com.br/upload/noticia/missing.jpg'),
      env,
    );

    expect(response.status).toBe(404);
  });
});
