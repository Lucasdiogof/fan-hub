import { describe, expect, it } from 'vitest';
import {
  authorizeServiceCaller,
  extractBearerToken,
  rejectUnlessServiceCaller,
  timingSafeEqual,
} from './service_caller_auth';

const SERVICE_KEY = 'service-role-key';
const neverVerified = async () => false;

describe('extractBearerToken', () => {
  it('lê o token de "Bearer x"', () => {
    expect(extractBearerToken('Bearer abc')).toBe('abc');
    expect(extractBearerToken('bearer   abc  ')).toBe('abc');
  });

  it('sem header ou sem Bearer -> null', () => {
    expect(extractBearerToken(null)).toBeNull();
    expect(extractBearerToken('')).toBeNull();
    expect(extractBearerToken('Basic abc')).toBeNull();
    expect(extractBearerToken('Bearer ')).toBeNull();
  });
});

describe('timingSafeEqual', () => {
  it('iguais / diferentes / tamanhos diferentes', () => {
    expect(timingSafeEqual('abc', 'abc')).toBe(true);
    expect(timingSafeEqual('abc', 'abd')).toBe(false);
    expect(timingSafeEqual('abc', 'abcd')).toBe(false);
    expect(timingSafeEqual('', 'a')).toBe(false);
  });
});

describe('authorizeServiceCaller', () => {
  it('service_role do runtime (cron / chamada entre functions) passa', async () => {
    const d = await authorizeServiceCaller(`Bearer ${SERVICE_KEY}`, SERVICE_KEY, neverVerified);
    expect(d).toEqual({ ok: true, via: 'service_key' });
  });

  it('regressão: anon key pública NÃO passa, mesmo sendo JWT válido do projeto', async () => {
    const d = await authorizeServiceCaller('Bearer anon-public-key', SERVICE_KEY, neverVerified);
    expect(d).toEqual({ ok: false, status: 403, reason: 'service_role required' });
  });

  it('sem Authorization -> 401', async () => {
    const d = await authorizeServiceCaller(null, SERVICE_KEY, neverVerified);
    expect(d.ok).toBe(false);
    expect(d.ok === false && d.status).toBe(401);
  });

  it('chave secreta nova confirmada pelo Auth admin passa', async () => {
    const d = await authorizeServiceCaller('Bearer sb_secret_x', SERVICE_KEY, async (t) => t === 'sb_secret_x');
    expect(d).toEqual({ ok: true, via: 'auth_admin' });
  });

  it('falha na verificação remota é fail-closed', async () => {
    const d = await authorizeServiceCaller('Bearer whatever', SERVICE_KEY, async () => {
      throw new Error('network down');
    });
    expect(d.ok).toBe(false);
  });

  it('secret ausente no runtime não abre a função', async () => {
    const d = await authorizeServiceCaller('Bearer ', undefined, neverVerified);
    expect(d.ok).toBe(false);
    const d2 = await authorizeServiceCaller('Bearer x', undefined, neverVerified);
    expect(d2.ok).toBe(false);
  });
});

describe('rejectUnlessServiceCaller', () => {
  const url = 'https://example.supabase.co';

  it('anon -> Response 403 e consulta o admin API com o token do chamador', async () => {
    const calls: string[] = [];
    const fakeFetch = (async (input: RequestInfo | URL) => {
      calls.push(String(input));
      return new Response('{}', { status: 401 });
    }) as typeof fetch;
    const req = new Request(`${url}/functions/v1/x`, { headers: { Authorization: 'Bearer anon' } });
    const res = await rejectUnlessServiceCaller(req, url, SERVICE_KEY, fakeFetch);
    expect(res?.status).toBe(403);
    expect(calls).toEqual([`${url}/auth/v1/admin/users?page=1&per_page=1`]);
  });

  it('service_role -> null (segue o handler) sem chamada de rede', async () => {
    let called = false;
    const fakeFetch = (async () => {
      called = true;
      return new Response('{}');
    }) as typeof fetch;
    const req = new Request(`${url}/functions/v1/x`, { headers: { Authorization: `Bearer ${SERVICE_KEY}` } });
    expect(await rejectUnlessServiceCaller(req, url, SERVICE_KEY, fakeFetch)).toBeNull();
    expect(called).toBe(false);
  });
});
