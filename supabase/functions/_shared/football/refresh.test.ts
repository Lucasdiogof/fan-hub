import { beforeEach, describe, expect, it, vi } from 'vitest';
import * as lineup from './lineup_photos';
import { resolveClubServerConfigByCode } from '../club_server_config';
import { fakeFetch } from './__fixtures__/fake_onefootball';
import type { SnapshotRow } from './contract';
import { setFetcher } from './provider';
import { expectedSnapshots, refreshDue, refreshSnapshot, type DueInfo, type SnapshotStore } from './refresh';

const NOW = new Date('2026-11-20T23:00:00Z');
const goias = resolveClubServerConfigByCode('goias')!;

function fakeStore(existing: DueInfo[] = []) {
  const rows: SnapshotRow[] = [];
  const failures: unknown[] = [];
  let hasPrevious = true;
  const store: SnapshotStore = {
    list: async () => existing,
    upsert: async (r) => void rows.push(...r),
    markFailure: async (...args) => {
      failures.push(args);
      return hasPrevious;
    },
  };
  return { store, rows, failures, setHasPrevious: (v: boolean) => (hasPrevious = v) };
}

beforeEach(() => setFetcher(fakeFetch()));

describe('refreshSnapshot', () => {
  it('sucesso: upsert com metadados completos e política aplicada', async () => {
    const { store, rows } = fakeStore();
    const r = await refreshSnapshot(goias, 'team', 'default', { store, now: () => NOW });
    expect(r.ok).toBe(true);
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      club_id: goias.canonicalClubId,
      kind: 'team',
      key: 'default',
      contract_version: 1,
      source: 'onefootball',
      fetched_at: NOW.toISOString(),
      consecutive_failures: 0,
      last_error: null,
      last_error_at: null,
    });
    expect(Date.parse(rows[0].expires_at)).toBeGreaterThan(NOW.getTime());
    expect(rows[0].next_refresh_at).not.toBeNull();
  });

  it('current_round: uma busca materializa várias chaves offset:N', async () => {
    const { store, rows } = fakeStore();
    await refreshSnapshot(goias, 'current_round', 'offset:0', { store, now: () => NOW });
    expect(rows.length).toBeGreaterThan(1);
    expect(rows.map((x) => x.key)).toContain('offset:0');
    expect(rows.every((x) => /^offset:-?\d+$/.test(x.key))).toBe(true);
  });

  it('falha: não faz upsert (mantém payload), incrementa falhas e aplica backoff', async () => {
    setFetcher((async () => new Response('x', { status: 500 })) as unknown as typeof fetch);
    const { store, rows, failures } = fakeStore();
    const r = await refreshSnapshot(goias, 'team', 'default', { store, now: () => NOW }, 2);
    expect(r.ok).toBe(false);
    expect(rows).toHaveLength(0);
    const patch = (failures[0] as unknown[])[3] as Record<string, unknown>;
    expect(patch.consecutive_failures).toBe(3);
    expect(patch.last_error).toEqual(expect.any(String));
    expect(patch.next_refresh_at).toBe(new Date(NOW.getTime() + 20 * 60_000).toISOString());
    expect(Object.keys(patch)).not.toContain('payload');
  });

  it('falha sem linha anterior e store quebrando não lança', async () => {
    setFetcher((async () => new Response('x', { status: 500 })) as unknown as typeof fetch);
    const { store, setHasPrevious } = fakeStore();
    setHasPrevious(false);
    store.markFailure = async () => {
      throw new Error('db fora');
    };
    const r = await refreshSnapshot(goias, 'season', 'default', { store, now: () => NOW });
    expect(r.ok).toBe(false);
  });

  it('standings de id inexistente falha de forma controlada', async () => {
    const { store, rows } = fakeStore();
    const r = await refreshSnapshot(goias, 'standings', 'nao-existe', { store, now: () => NOW });
    expect(r.ok).toBe(false);
    expect(rows).toHaveLength(0);
  });

  it('imagens: usa deps.images e reescreve o payload', async () => {
    const { store, rows } = fakeStore();
    const images = {
      publicBase: 'https://s/p',
      fetch: (async () => new Response(new Uint8Array([1]), { headers: { 'content-type': 'image/png' } })) as unknown as typeof fetch,
      storage: { exists: async () => false, upload: async () => undefined },
    };
    await refreshSnapshot(goias, 'team', 'default', { store, now: () => NOW, images });
    const text = JSON.stringify(rows[0].payload);
    expect(text).toContain('https://s/p/');
    // Só escudos de rivais viram URL nossa; o do próprio clube (1863) segue local no app.
    const left = text.split('"').filter((u) => u.startsWith('https://images.onefootball.com/icons/teams/'));
    expect(left.every((u) => u.includes('/1863.'))).toBe(true);
  });
});

describe('refreshDue', () => {
  it('banco vazio: cria tudo que o clube precisa + fixtures derivadas do team', async () => {
    const { store, rows } = fakeStore();
    const results = await refreshDue(goias, { store, now: () => NOW });
    expect(results.every((r) => r.ok)).toBe(true);
    const kinds = new Set(rows.map((r) => r.kind));
    for (const k of ['team', 'season', 'current_round', 'standings', 'competitions', 'fixture']) expect(kinds).toContain(k);
    expect(rows.filter((r) => r.kind === 'fixture').length).toBeGreaterThanOrEqual(1);
  });

  it('nada vencido: não busca nada', async () => {
    const future = new Date(NOW.getTime() + 3_600_000).toISOString();
    const existing: DueInfo[] = expectedSnapshots(goias).map((e) => ({ ...e, next_refresh_at: future, consecutive_failures: 0 }));
    existing.push({ kind: 'competitions', key: 'default', next_refresh_at: null, consecutive_failures: 0 });
    const { store, rows } = fakeStore(existing);
    // fixtures derivadas só entram quando o team foi atualizado
    const results = await refreshDue(goias, { store, now: () => NOW });
    expect(results).toEqual([]);
    expect(rows).toHaveLength(0);
  });

  it('só o vencido é atualizado e as falhas anteriores viram backoff', async () => {
    const future = new Date(NOW.getTime() + 3_600_000).toISOString();
    const existing: DueInfo[] = expectedSnapshots(goias).map((e) => ({
      ...e,
      next_refresh_at: e.kind === 'standings' ? new Date(NOW.getTime() - 1000).toISOString() : future,
      consecutive_failures: 0,
    }));
    const { store, rows } = fakeStore(existing);
    const results = await refreshDue(goias, { store, now: () => NOW });
    expect(new Set(results.map((r) => r.kind))).toEqual(new Set(['standings']));
    expect(new Set(rows.map((r) => r.kind))).toEqual(new Set(['standings']));
  });

  it('kinds restringe o que roda', async () => {
    const { store, rows } = fakeStore();
    await refreshDue(goias, { store, now: () => NOW }, ['competitions']);
    expect(rows.map((r) => r.kind)).toEqual(['competitions']);
  });

  it('um kind falhando não impede os outros', async () => {
    const base = fakeFetch();
    setFetcher(((url: string, init?: RequestInit) =>
      String(url).includes('tabela') ? Promise.resolve(new Response('x', { status: 500 })) : base(url, init)) as unknown as typeof fetch);
    const { store, rows } = fakeStore();
    const results = await refreshDue(goias, { store, now: () => NOW });
    expect(results.some((r) => !r.ok && r.kind === 'standings')).toBe(true);
    expect(rows.some((r) => r.kind === 'team')).toBe(true);
  });
});

describe('silhueta x foto: a flag de imagens só liga o Storage', () => {
  const FIX = 'onef-2669610';
  const withPhotos = () => {
    const base = fakeFetch();
    setFetcher((async (u: string, i: RequestInit) =>
      String(u).includes('/players/')
        ? new Response(new Uint8Array(6004), { headers: { 'content-type': 'image/png' } })
        : base(u, i)) as unknown as typeof fetch);
  };
  const photos = (rows: SnapshotRow[]) =>
    JSON.stringify(rows[0].payload).split('"photo":"').slice(1).map((x) => x.split('"')[0]);

  it('FOOTBALL_IMAGES off: silhueta continua sendo removida do payload (regra anterior)', async () => {
    withPhotos();
    // 6004 bytes + SHA-1 6c00c23b = a silhueta real (digest simulado só pro SHA-1).
    const real = crypto.subtle.digest.bind(crypto.subtle);
    vi.spyOn(crypto.subtle, 'digest').mockImplementation(((alg: string, data: BufferSource) =>
      alg === 'SHA-1' ? Promise.resolve(new Uint8Array([0x6c, 0x00, 0xc2, 0x3b, 0, 0]).buffer) : real(alg, data)) as typeof crypto.subtle.digest);
    const { store, rows } = fakeStore();
    await refreshSnapshot(goias, 'fixture', FIX, { store, now: () => NOW });
    const p = photos(rows);
    expect(p.length).toBeGreaterThan(0);
    expect(p.every((x) => x === '')).toBe(true);
    vi.restoreAllMocks();
  });
  it('FOOTBALL_IMAGES on: foto real vai pro Storage; silhueta não', async () => {
    withPhotos();
    const spy = vi.spyOn(lineup, 'isPlaceholderPhoto');
    const stored: string[] = [];
    const images = {
      publicBase: 'https://s/p',
      fetch: (async () => new Response(new Uint8Array(10), { headers: { 'content-type': 'image/jpeg' } })) as unknown as typeof fetch,
      storage: { exists: async () => false, upload: async (p: string) => void stored.push(p) },
    };
    spy.mockResolvedValue(false);
    const real = fakeStore();
    await refreshSnapshot(goias, 'fixture', FIX, { store: real.store, now: () => NOW, images });
    expect(photos(real.rows).every((x) => x.startsWith('https://s/p/players/'))).toBe(true);
    spy.mockResolvedValue(true);
    const sil = fakeStore();
    await refreshSnapshot(goias, 'fixture', FIX, { store: sil.store, now: () => NOW, images });
    expect(photos(sil.rows).every((x) => x === '')).toBe(true);
    vi.restoreAllMocks();
  });
  it('fixture encerrado antigo segue com next_refresh_at NULL depois de materializar imagens', async () => {
    withPhotos();
    const images = {
      publicBase: 'https://s/p',
      fetch: (async () => new Response(new Uint8Array(10), { headers: { 'content-type': 'image/jpeg' } })) as unknown as typeof fetch,
      storage: { exists: async () => false, upload: async () => undefined },
    };
    const { store, rows } = fakeStore();
    await refreshSnapshot(goias, 'fixture', FIX, { store, now: () => new Date('2027-06-01T00:00:00Z'), images });
    expect(rows[0].next_refresh_at).toBeNull();
  });
});
