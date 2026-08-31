import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { fetchCompetitionMatchLists, fetchTeamSeasonMatchCards } from './onefootball_provider';
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

/** O endpoint de TIME agrupa por mês (ex.: "outubro 2026"), não por rodada
 * — diferente de `roundList` acima. Cada card recebe um `matchId` próprio
 * pra poder testar dedupe entre páginas. */
function monthList(subtitle: string, matchIds: string[]): OneFootballMatchList {
  return {
    sectionHeader: { subtitle },
    matchCards: matchIds.map((id) => ({
      matchId: id,
      link: `/pt-br/match/${id}`,
      competitionName: 'Goiano',
      kickoff: '2026-03-10T00:00:00Z',
      period: 'FULL_TIME',
      homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
      awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
    })),
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

describe('fetchTeamSeasonMatchCards (via fetch mockado)', () => {
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

  it('junta as 4 páginas (jogos/resultados x base/loadmore) sem duplicar partida repetida entre elas', async () => {
    mockFetchByUrl({
      '/resultados': baseShapeResponse([monthList('março 2026', ['m1', 'm2'])]),
      '/resultados?loadmore=1': loadMoreShapeResponse([monthList('janeiro 2026', ['m0'])]),
      '/jogos': baseShapeResponse([monthList('outubro 2026', ['m3', 'm4'])]),
      // m3 aparece nas duas abas (rodada em andamento) — não pode duplicar.
      '/jogos?loadmore=1': loadMoreShapeResponse([monthList('novembro 2026', ['m3', 'm5'])]),
    });

    const cards = await fetchTeamSeasonMatchCards('goias-1863');

    expect(cards.map((c) => c.matchId).sort()).toEqual(['m0', 'm1', 'm2', 'm3', 'm4', 'm5']);
  });

  it('não quebra se alguma das 4 páginas falhar — usa o que conseguiu buscar', async () => {
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      if (url.endsWith('/resultados')) {
        return new Response(JSON.stringify(baseShapeResponse([monthList('março 2026', ['m1'])])), {
          status: 200,
        });
      }
      return new Response('erro', { status: 500 });
    }) as unknown as typeof fetch;

    const cards = await fetchTeamSeasonMatchCards('goias-1863');

    expect(cards.map((c) => c.matchId)).toEqual(['m1']);
  });

  it('lança erro só se as 4 páginas falharem', async () => {
    global.fetch = vi.fn(async () => new Response('erro', { status: 500 })) as unknown as typeof fetch;

    await expect(fetchTeamSeasonMatchCards('goias-1863')).rejects.toThrow();
  });
});
