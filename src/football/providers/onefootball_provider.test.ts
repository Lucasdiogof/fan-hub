import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { fetchCompetitionMatchLists } from './onefootball_provider';
import type { OneFootballMatchList } from './onefootball_provider';

/** Formato pequeno o bastante pra passar pelo `findNode` recursivo do
 * provider sem precisar replicar a árvore real inteira do OneFootball. */
function baseShapeResponse(lists: OneFootballMatchList[]) {
  return {
    containers: [{ component: { id: 'x', matchCardsListsAppender: { lists } } }],
  };
}

/** Formato real e confirmado da resposta `?loadmore=1` — achatado, sem
 * `containers` nem `matchCardsListsAppender`, só `{ lists: [...] }` direto
 * na raiz (ver o comentário em `fetchCompetitionTab`). */
function loadMoreShapeResponse(lists: OneFootballMatchList[]) {
  return { lists };
}

function roundList(subtitle: string): OneFootballMatchList {
  return {
    sectionHeader: { subtitle },
    matchCards: [
      {
        matchId: `${subtitle}-1`,
        link: '/pt-br/match/1',
        kickoff: '2026-01-01T00:00:00Z',
        period: 'FULL_TIME',
        homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
        awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
      },
    ],
  };
}

describe('fetchCompetitionTab / fetchCompetitionMatchLists (via fetch mockado)', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  function mockFetchByUrl(responses: Record<string, unknown>) {
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      for (const [suffix, body] of Object.entries(responses)) {
        if (url.endsWith(suffix)) {
          return new Response(JSON.stringify(body), { status: 200 });
        }
      }
      throw new Error(`URL não mockada: ${url}`);
    }) as unknown as typeof fetch;
  }

  it(
    'junta as rodadas da página base COM as da página ?loadmore=1 (formato achatado) — ' +
      'antes da correção, o loadmore virava [] silenciosamente e essas rodadas sumiam',
    async () => {
      mockFetchByUrl({
        '/resultados': baseShapeResponse([roundList('Rodada 25'), roundList('Rodada 24')]),
        '/resultados?loadmore=1': loadMoreShapeResponse([
          roundList('Rodada 23'),
          roundList('Rodada 22'),
          roundList('Rodada 1'),
        ]),
        '/jogos': baseShapeResponse([roundList('Rodada 25'), roundList('Rodada 26')]),
        '/jogos?loadmore=1': loadMoreShapeResponse([roundList('Rodada 27'), roundList('Rodada 38')]),
      });

      const lists = await fetchCompetitionMatchLists('brasileirao-serie-b-superbet-119');
      const subtitles = lists.map((l) => l.sectionHeader?.subtitle);

      // Rodadas que só existiam nas páginas ?loadmore=1 — é exatamente isso
      // que ficava faltando antes da correção.
      expect(subtitles).toContain('Rodada 1');
      expect(subtitles).toContain('Rodada 22');
      expect(subtitles).toContain('Rodada 23');
      expect(subtitles).toContain('Rodada 27');
      expect(subtitles).toContain('Rodada 38');
      // E as da página base continuam presentes.
      expect(subtitles).toContain('Rodada 24');
      expect(subtitles).toContain('Rodada 25');
      expect(subtitles).toContain('Rodada 26');

      // Ordem crescente por número de rodada, sem duplicar a rodada 25
      // (aparece nas duas abas — resultados E jogos — precisa virar uma só).
      expect(subtitles).toEqual([
        'Rodada 1',
        'Rodada 22',
        'Rodada 23',
        'Rodada 24',
        'Rodada 25',
        'Rodada 26',
        'Rodada 27',
        'Rodada 38',
      ]);
    },
  );

  it('lê corretamente uma resposta ?loadmore=1 vazia (fim/início de temporada), sem quebrar', async () => {
    mockFetchByUrl({
      '/resultados': baseShapeResponse([roundList('Rodada 1')]),
      '/resultados?loadmore=1': loadMoreShapeResponse([]),
      '/jogos': baseShapeResponse([roundList('Rodada 2')]),
      '/jogos?loadmore=1': loadMoreShapeResponse([]),
    });

    const lists = await fetchCompetitionMatchLists('brasileirao-serie-b-superbet-119');
    expect(lists.map((l) => l.sectionHeader?.subtitle)).toEqual(['Rodada 1', 'Rodada 2']);
  });
});
