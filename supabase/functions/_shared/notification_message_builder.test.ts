import { describe, expect, it } from 'vitest';
import { buildNotificationMessage } from './notification_message_builder';
import type { NotificationEventPayload, NotificationEventTypeInput } from './notification_message_builder';
import type { ClubServerConfig } from './club_server_config';

// Configs REAIS de produção (mesmos valores de club_server_config.ts) —
// nunca uma cópia com valores diferentes, senão o teste provaria uma copy
// que não é a que roda de verdade.
const GOIAS: ClubServerConfig = {
  code: 'goias',
  canonicalClubId: '4c16340d-300c-5ab2-903f-17519db9b146',
  oneFootballTeamId: 1863,
  oneFootballTeamPath: 'goias',
  shortName: 'Goiás',
  workerBaseUrl: 'https://goias-app.lucasdiogo1234.workers.dev',
};

const BRAGANTINO: ClubServerConfig = {
  code: 'bragantino',
  canonicalClubId: '51683d2a-ea1d-57c6-8014-996146f242e7',
  oneFootballTeamId: 4734,
  oneFootballTeamPath: 'bragantino',
  shortName: 'Bragantino',
  workerBaseUrl: 'https://bragantino-app.lucasdiogo1234.workers.dev',
};

// Fixture SINTÉTICA, só neste arquivo de teste — nunca registrada em
// SERVER_CLUB_REGISTRY, nunca um clube real nomeado.
const CLUB_B: ClubServerConfig = {
  code: 'club-b',
  canonicalClubId: 'deadbeef-0000-0000-0000-000000000000',
  oneFootballTeamId: 999999,
  oneFootballTeamPath: 'club-b',
  shortName: 'Clube B',
  workerBaseUrl: 'https://club-b.example.workers.dev',
};

const COLOR_EMOJIS = ['💚', '❤️', '🟢', '🔴'];

describe('KICKOFF', () => {
  it('título fixo "Começou! ⚽", corpo SEM placar (só times)', () => {
    const message = buildNotificationMessage(
      'kickoff',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 0, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Começou! ⚽');
    expect(message.body).toBe('Goiás x Vila Nova');
  });

  it('Bragantino: mesmo título fixo, corpo com os times reais do Bragantino', () => {
    const message = buildNotificationMessage(
      'kickoff',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Começou! ⚽');
    expect(message.body).toBe('RB Bragantino x Palmeiras');
  });
});

describe('GOAL_FOR', () => {
  it('Goiás: "GOOOOOOL DO GOIÁS! ⚽" com placar', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('GOOOOOOL DO GOIÁS! ⚽');
    expect(message.body).toBe('Goiás 1 x 0 Vila Nova');
  });

  it('Bragantino: "GOOOOOOL DO BRAGANTINO! ⚽" com placar — nunca reusa cópia do Goiás', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 0 },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('GOOOOOOL DO BRAGANTINO! ⚽');
    expect(message.body).toBe('RB Bragantino 1 x 0 Palmeiras');
  });

  it('título vem de clubConfig.shortName, nunca de um literal no builder', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Clube B', awayTeamName: 'Adversário', homeScore: 1, awayScore: 0 },
      CLUB_B,
      { isActiveMember: false },
    );
    expect(message.title).toBe('GOOOOOOL DO CLUBE B! ⚽');
  });

  it('nenhum emoji de cor (💚/❤️/🟢/🔴) no título', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    for (const emoji of COLOR_EMOJIS) expect(message.title).not.toContain(emoji);
  });
});

describe('GOAL_AGAINST — adversaryName sempre por activeClubSide, nunca por home/away isolado', () => {
  it('Goiás mandante (Goiás 1 x 1 Vila Nova): adversário é o visitante', () => {
    const message = buildNotificationMessage(
      'goal_against',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Gol do Vila Nova');
    expect(message.body).toBe('Goiás 1 x 1 Vila Nova');
  });

  it('Goiás visitante (Vila Nova 1 x 1 Goiás): adversário é o mandante — nunca "Gol do Goiás"', () => {
    const message = buildNotificationMessage(
      'goal_against',
      { homeTeamName: 'Vila Nova', awayTeamName: 'Goiás', homeScore: 1, awayScore: 1, activeClubSide: 'away' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Gol do Vila Nova');
  });

  it('Bragantino mandante (RB Bragantino 1 x 1 Palmeiras): adversário é o visitante', () => {
    const message = buildNotificationMessage(
      'goal_against',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Gol do Palmeiras');
    expect(message.body).toBe('RB Bragantino 1 x 1 Palmeiras');
  });

  it('Bragantino visitante (Palmeiras 1 x 1 RB Bragantino): adversário é o mandante — nunca "Gol do Bragantino"', () => {
    const message = buildNotificationMessage(
      'goal_against',
      { homeTeamName: 'Palmeiras', awayTeamName: 'RB Bragantino', homeScore: 1, awayScore: 1, activeClubSide: 'away' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Gol do Palmeiras');
  });

  it('nenhum emoji no título (nem neutro, nem de cor) — só o nome do adversário', () => {
    const message = buildNotificationMessage(
      'goal_against',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Gol do Vila Nova');
  });
});

describe('HALF_TIME', () => {
  it('Goiás: "Intervalo ⏸️" com placar parcial', () => {
    const message = buildNotificationMessage(
      'half_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Intervalo ⏸️');
    expect(message.body).toBe('Goiás 1 x 0 Vila Nova');
  });

  it('Bragantino: mesmo título, placar do Bragantino', () => {
    const message = buildNotificationMessage(
      'half_time',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 1 },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Intervalo ⏸️');
    expect(message.body).toBe('RB Bragantino 1 x 1 Palmeiras');
  });
});

describe('SECOND_HALF_STARTED', () => {
  it('Goiás: "Começou o segundo tempo ▶️" com placar parcial', () => {
    const message = buildNotificationMessage(
      'second_half_started',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Começou o segundo tempo ▶️');
    expect(message.body).toBe('Goiás 1 x 0 Vila Nova');
  });

  it('Bragantino: mesmo título, placar do Bragantino', () => {
    const message = buildNotificationMessage(
      'second_half_started',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 1 },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Começou o segundo tempo ▶️');
    expect(message.body).toBe('RB Bragantino 1 x 1 Palmeiras');
  });
});

describe('FULL_TIME — resultado sempre calculado por activeClubSide', () => {
  it('Goiás mandante, vitória: "VITÓRIA DO GOIÁS! 🏁"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 2, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('VITÓRIA DO GOIÁS! 🏁');
    expect(message.body).toBe('Goiás 2 x 1 Vila Nova');
  });

  it('Goiás visitante, vitória (Vila Nova 1 x 2 Goiás): ainda "VITÓRIA DO GOIÁS!" — nunca assume mandante', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Vila Nova', awayTeamName: 'Goiás', homeScore: 1, awayScore: 2, activeClubSide: 'away' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('VITÓRIA DO GOIÁS! 🏁');
  });

  it('Goiás mandante, empate: "Fim de jogo 🏁", nunca "VITÓRIA"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Fim de jogo 🏁');
  });

  it('Goiás mandante, derrota: "Fim de jogo 🏁", nunca "VITÓRIA"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 0, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Fim de jogo 🏁');
  });

  it('Goiás visitante, derrota (Vila Nova 2 x 0 Goiás): "Fim de jogo 🏁" — nunca "VITÓRIA DO VILA NOVA" nem do Goiás', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Vila Nova', awayTeamName: 'Goiás', homeScore: 2, awayScore: 0, activeClubSide: 'away' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Fim de jogo 🏁');
    expect(message.title).not.toContain('VITÓRIA');
  });

  it('Bragantino mandante, vitória: "VITÓRIA DO BRAGANTINO! 🏁" — nunca reusa cópia do Goiás', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 2, awayScore: 0, activeClubSide: 'home' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('VITÓRIA DO BRAGANTINO! 🏁');
    expect(message.body).toBe('RB Bragantino 2 x 0 Palmeiras');
  });

  it('Bragantino visitante, vitória (Palmeiras 0 x 1 RB Bragantino): ainda "VITÓRIA DO BRAGANTINO!"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Palmeiras', awayTeamName: 'RB Bragantino', homeScore: 0, awayScore: 1, activeClubSide: 'away' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('VITÓRIA DO BRAGANTINO! 🏁');
  });

  it('Bragantino, empate: "Fim de jogo 🏁"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Fim de jogo 🏁');
  });

  it('Bragantino, derrota: "Fim de jogo 🏁"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 0, awayScore: 1, activeClubSide: 'home' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Fim de jogo 🏁');
  });

  it('nenhum título (vitória, empate ou derrota) usa emoji de cor', () => {
    const scenarios: Array<NotificationEventPayload> = [
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 2, awayScore: 0, activeClubSide: 'home' },
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 0, awayScore: 1, activeClubSide: 'home' },
    ];
    for (const payload of scenarios) {
      const message = buildNotificationMessage('full_time', payload, GOIAS, { isActiveMember: false });
      for (const emoji of COLOR_EMOJIS) expect(message.title).not.toContain(emoji);
    }
  });
});

describe('multi-clube — nenhum clube reutiliza texto/emoji de outro, 100% via registry (zero hardcode)', () => {
  it('goal e full_time do Bragantino nunca contêm "GOIÁS"/"VERDÃO"', () => {
    const goal = buildNotificationMessage(
      'goal',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 0 },
      BRAGANTINO,
      { isActiveMember: false },
    );
    const victory = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'RB Bragantino', awayTeamName: 'Palmeiras', homeScore: 1, awayScore: 0, activeClubSide: 'home' },
      BRAGANTINO,
      { isActiveMember: false },
    );
    expect(goal.title).not.toContain('GOIÁS');
    expect(victory.title).not.toContain('GOIÁS');
    expect(victory.title).not.toContain('VERDÃO');
  });

  it('goal e full_time do Goiás nunca contêm "BRAGANTINO"', () => {
    const goal = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    const victory = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(goal.title).not.toContain('BRAGANTINO');
    expect(victory.title).not.toContain('BRAGANTINO');
  });

  it('clube sintético (nunca registrado em produção) produz sua própria copy — prova que é 100% data-driven, não hardcode', () => {
    const goal = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Clube B', awayTeamName: 'Adversário', homeScore: 1, awayScore: 0 },
      { ...GOIAS, code: 'club-b', shortName: 'Time Trocado' },
      { isActiveMember: false },
    );
    expect(goal.title).toBe('GOOOOOOL DO TIME TROCADO! ⚽');
  });
});

describe('nenhum dos 6 eventos de partida usa emoji de cor/identidade em nenhum clube', () => {
  const cases: Array<[NotificationEventTypeInput, NotificationEventPayload]> = [
    ['kickoff', { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova' }],
    ['goal', { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 }],
    ['goal_against', { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' }],
    ['half_time', { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1 }],
    ['second_half_started', { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1 }],
    ['full_time', { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' }],
  ];

  for (const clubConfig of [GOIAS, BRAGANTINO]) {
    it(`${clubConfig.code}: nenhum título contém 💚/❤️/🟢/🔴`, () => {
      for (const [eventType, payload] of cases) {
        const message = buildNotificationMessage(eventType, payload, clubConfig, { isActiveMember: false });
        for (const emoji of COLOR_EMOJIS) expect(message.title).not.toContain(emoji);
      }
    });
  }
});

describe('match_access_open (Ingressos/Check-in) — comportamento preservado, categoria separada dos 6 eventos de jogo', () => {
  it('sócio ativo -> check-in; não-sócio -> ingressos', () => {
    const checkin = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova' },
      GOIAS,
      { isActiveMember: true },
    );
    const tickets = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(checkin.title).toBe('Check-in aberto');
    expect(checkin.body).toBe('O check-in pra Vila Nova já está disponível.');
    expect(tickets.title).toBe('Ingressos disponíveis');
    expect(tickets.body).toBe('Os ingressos pra Vila Nova já estão à venda.');
  });

  it('opponent é sempre o adversário do clube ativo (comparado por shortName), nunca o próprio clube', () => {
    const home = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova' },
      GOIAS,
      { isActiveMember: true },
    );
    const away = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Vila Nova', awayTeamName: 'Goiás' },
      GOIAS,
      { isActiveMember: true },
    );
    expect(home.body).toContain('Vila Nova');
    expect(away.body).toContain('Vila Nova');
    expect(away.body).not.toContain('pra Goiás');
  });
});
