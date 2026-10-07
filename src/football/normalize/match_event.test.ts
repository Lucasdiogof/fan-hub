import { describe, expect, it } from 'vitest';
import { normalizeOneFootballMatchEvent } from './match_event';

describe('normalizeOneFootballMatchEvent — substituição', () => {
  it('payload real de hoje (só nome): sem IDs, nome preservado', () => {
    const e = normalizeOneFootballMatchEvent({
      name: 'Substituição',
      timeline: "58'",
      teamSide: 'TEAM_SIDE_AWAY',
      substitution: { playerIn: { name: 'Danilo' }, playerOut: { name: 'Djalma' } },
    });
    expect(e).toMatchObject({ type: 'substitution', side: 'away', player: 'Danilo', detail: 'Djalma' });
    expect(e.playerInId).toBeNull();
    expect(e.playerOutId).toBeNull();
  });

  it('se o provedor mandar o link do jogador, devolve playerInId/playerOutId', () => {
    const e = normalizeOneFootballMatchEvent({
      name: 'Substituição',
      timeline: "70'",
      substitution: {
        playerIn: { name: 'Tadeu', link: { urlPath: '/pt-br/jogador/tadeu-48597' } },
        playerOut: { name: 'Outro', link: { urlPath: '/pt-br/jogador/outro-111' } },
      },
    });
    expect(e.playerInId).toBe(48597);
    expect(e.playerOutId).toBe(111);
  });
});
