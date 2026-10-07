import { describe, expect, it } from 'vitest';
import type { OneFootballMatchLineup } from '../providers/onefootball_provider';
import { normalizeOneFootballMatchLineups, playerIdFromLink } from './match_lineup';

describe('playerIdFromLink', () => {
  it('extrai o ID do fim de /jogador/<slug>-<id>', () => {
    expect(playerIdFromLink('/pt-br/jogador/tadeu-48597')).toBe(48597);
    expect(playerIdFromLink('/pt-br/jogador/djalma-antonio-da-silva-filho-1234567/')).toBe(1234567);
  });

  it('devolve null quando não há link ou o formato é outro', () => {
    expect(playerIdFromLink(undefined)).toBeNull();
    expect(playerIdFromLink('')).toBeNull();
    expect(playerIdFromLink('/pt-br/time/goias-123')).toBeNull();
    expect(playerIdFromLink('/pt-br/jogador/sem-id')).toBeNull();
  });
});

describe('normalizeOneFootballMatchLineups', () => {
  const team = (name: string, players: OneFootballMatchLineup['homeTeam']['formation']['rows'][number]['players']) => ({
    teamName: name,
    formation: { rows: [{ players }] },
  });

  it('inclui o playerId de quem tem link e null de quem não tem', () => {
    const result = normalizeOneFootballMatchLineups({
      homeTeam: team('Casa', [
        { name: 'Tadeu', jerseyNumber: 23, image: { path: 'https://x/1.jpg' }, link: { urlPath: '/pt-br/jogador/tadeu-48597' } },
        { name: 'Sem Link', jerseyNumber: 9, image: { path: '' } },
      ]),
      awayTeam: team('Fora', []),
    });
    expect(result.home.rows[0]).toEqual([
      { name: 'Tadeu', jerseyNumber: 23, photo: 'https://x/1.jpg', playerId: 48597 },
      { name: 'Sem Link', jerseyNumber: 9, photo: '', playerId: null },
    ]);
  });
});
