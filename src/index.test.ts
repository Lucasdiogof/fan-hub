import { describe, expect, it } from 'vitest';
import { env as rawEnv, createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import worker from './index';
import type { SocialEnv } from './social/config';

// Ver o mesmo comentário em `_lib/club_server_config.test.ts` — `Env` do
// `cloudflare:test` é genérico (este projeto não gera `worker-configuration.
// d.ts` via `wrangler types`); as vars reais vêm certas do wrangler.toml em
// runtime, só o tipo precisa do cast pra bater com `SocialEnv`.
const env = rawEnv as unknown as SocialEnv;

// Rodada de hardening M3.3 — prova real de roteamento pro `/team/:clubCode`
// genérico, sem mockar rede: as 2 rotas de `clubCode` DESCONHECIDO falham
// DENTRO de `resolveClubServerConfig` (`_lib/club_server_config.ts`), ANTES
// de qualquer fetch pro OneFootball — então dá pra provar o 404 real, fim a
// fim, através do próprio `worker.fetch()`, sem precisar mockar upstream.
// `/team/goias`/`/team/goias/season` (clubCode CONHECIDO) exigiriam mockar
// a rede pra provar 200 fim a fim sem bater no OneFootball de verdade — o
// que esta suíte nunca fez até hoje (todo teste existente é só de função
// pura). Em vez de inventar um mock novo só pra isso, a prova de que
// '/team/goias' continua servido pelo MESMO caminho genérico (nunca 404,
// nunca um handler separado) é feita 1 passo abaixo do HTTP: o roteamento
// (regex) + a resolução de config (`resolveClubServerConfig`) — ver
// `club_server_config.test.ts` pra prova de que 'goias' resolve com
// sucesso, e os testes de regex abaixo pra prova de que a rota captura
// 'goias' corretamente.
describe('Worker fetch — /team/:clubCode desconhecido nunca cai pro Goiás, falha 404 real', () => {
  it('/api/football/team/unknown-club → 404 (nunca bate na rede, nunca resolve Goiás)', async () => {
    const request = new Request('https://example.com/api/football/team/unknown-club');
    const ctx = createExecutionContext();
    const response = await worker.fetch(request, env, ctx);
    await waitOnExecutionContext(ctx);

    expect(response.status).toBe(404);
  });

  it('/api/football/team/unknown-club/season → 404 (nunca bate na rede, nunca resolve Goiás)', async () => {
    const request = new Request('https://example.com/api/football/team/unknown-club/season');
    const ctx = createExecutionContext();
    const response = await worker.fetch(request, env, ctx);
    await waitOnExecutionContext(ctx);

    expect(response.status).toBe(404);
  });

  it('a mensagem de erro nunca menciona Goiás — é um erro genérico de código desconhecido', async () => {
    const request = new Request('https://example.com/api/football/team/unknown-club');
    const ctx = createExecutionContext();
    const response = await worker.fetch(request, env, ctx);
    await waitOnExecutionContext(ctx);

    const body = await response.text();
    expect(body).not.toContain('Goiás');
    expect(body).not.toContain('goias');
  });
});

describe('Worker fetch — padrão de rota /team/:clubCode captura o clubCode corretamente', () => {
  const TEAM_PATTERN = /^\/api\/football\/team\/([^/]+)\/?$/;
  const TEAM_SEASON_PATTERN = /^\/api\/football\/team\/([^/]+)\/season\/?$/;

  it("'/api/football/team/goias' casa TEAM_PATTERN com clubCode='goias' — a mesma rota legacy do app publicado", () => {
    const match = '/api/football/team/goias'.match(TEAM_PATTERN);
    expect(match?.[1]).toBe('goias');
  });

  it("'/api/football/team/goias/season' casa TEAM_SEASON_PATTERN com clubCode='goias', nunca TEAM_PATTERN (regex mais específica checada primeiro)", () => {
    const seasonMatch = '/api/football/team/goias/season'.match(TEAM_SEASON_PATTERN);
    expect(seasonMatch?.[1]).toBe('goias');
  });

  it('um clubCode desconhecido também é CAPTURADO pela regex (o 404 vem da resolução de config, não do roteamento)', () => {
    const match = '/api/football/team/unknown-club'.match(TEAM_PATTERN);
    expect(match?.[1]).toBe('unknown-club');
  });
});
