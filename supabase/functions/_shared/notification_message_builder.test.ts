import { describe, expect, it } from 'vitest';
import { buildNotificationMessage } from './notification_message_builder';
import type { ClubServerConfig } from './club_server_config';

// Mesma config REAL usada em produção — nunca uma cópia com valores
// diferentes, senão o teste provaria uma copy que não é a que roda de
// verdade (rodada de hardening: um bug real já aconteceu assim, reusando
// `fanDemonym` pra um campo que não devia).
const GOIAS: ClubServerConfig = {
  code: 'goias',
  canonicalClubId: '4c16340d-300c-5ab2-903f-17519db9b146',
  oneFootballTeamId: 1863,
  oneFootballTeamPath: 'goias',
  shortName: 'Goiás',
  notificationGoalClubName: 'Goiás',
  notificationVictoryNickname: 'Verdão',
};

// Fixture SINTÉTICA, só neste arquivo de teste — nunca registrada em
// SERVER_CLUB_REGISTRY, nunca um clube real nomeado (mesmo espírito de
// `syntheticClubBConfig` no Flutter).
const CLUB_B: ClubServerConfig = {
  code: 'club-b',
  canonicalClubId: 'deadbeef-0000-0000-0000-000000000000',
  oneFootballTeamId: 999999,
  oneFootballTeamPath: 'club-b',
  shortName: 'Clube B',
  notificationGoalClubName: 'Clube B',
  notificationVictoryNickname: 'Time B',
};

describe('buildNotificationMessage — copy do Goiás preservada exatamente', () => {
  it('goal title == "GOOOOOOL DO GOIÁS!" — nunca "ESMERALDINO" (bug real corrigido nesta rodada)', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('GOOOOOOL DO GOIÁS! ⚽💚');
  });

  it('victory title == "VITÓRIA DO VERDÃO!" — nunca "ESMERALDINO"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 2, awayScore: 0, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('VITÓRIA DO VERDÃO! 💚');
  });

  it('a copy vem do ClubServerConfig, nunca de um literal dentro do builder — provado trocando os campos e vendo o título mudar junto', () => {
    const alteredConfig: ClubServerConfig = {
      ...GOIAS,
      notificationGoalClubName: 'Outro Nome',
      notificationVictoryNickname: 'Outro Apelido',
    };
    const goal = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0 },
      alteredConfig,
      { isActiveMember: false },
    );
    const victory = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 0, activeClubSide: 'home' },
      alteredConfig,
      { isActiveMember: false },
    );
    expect(goal.title).toBe('GOOOOOOL DO OUTRO NOME! ⚽💚');
    expect(victory.title).toBe('VITÓRIA DO OUTRO APELIDO! 💚');
  });

  it('empate/derrota nunca vira "VITÓRIA" — título cai pra "Fim de jogo"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe('Fim de jogo');
  });
});

// ============================================================================
// Golden compatibility — comparado string a string contra a implementação
// REAL pré-M3.3, lida direto via `git show 7316afc:supabase/functions/
// notifications-dispatch/index.ts` (HEAD antes de qualquer edição da M3.3),
// nunca por inferência/memória. Os 5 literais abaixo são cópia exata do que
// esse comando retornou — se algum divergir aqui, a M3.3 mudou copy real do
// app publicado, não só renomeou campo interno.
// ============================================================================
const GOLDEN_PRE_M33 = {
  checkinTitle: 'Check-in aberto',
  checkinBody: (opponent: string) => `O check-in pra ${opponent} já está disponível.`,
  ticketsTitle: 'Ingressos disponíveis',
  ticketsBody: (opponent: string) => `Os ingressos pra ${opponent} já estão à venda.`,
  goalTitle: 'GOOOOOOL DO GOIÁS! ⚽💚',
  goalBody: (home: string, homeScore: number, awayScore: number, away: string) =>
    `${home} ${homeScore} x ${awayScore} ${away}`,
  victoryTitle: 'VITÓRIA DO VERDÃO! 💚',
  fullTimeNonVictoryTitle: 'Fim de jogo',
  fullTimeBodyVictorySuffix: ' Fim de jogo!',
  fullTimeBodyNonVictorySuffix: '.',
};

describe('buildNotificationMessage — golden compatibility contra o código real pré-M3.3 (git show 7316afc)', () => {
  it('goal: title e body byte-idênticos ao original', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 2, awayScore: 1 },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe(GOLDEN_PRE_M33.goalTitle);
    expect(message.body).toBe(GOLDEN_PRE_M33.goalBody('Goiás', 2, 1, 'Vila Nova'));
    expect(message.type).toBe('goal');
  });

  it('full_time vitória: title e body (com sufixo " Fim de jogo!") byte-idênticos ao original', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 2, awayScore: 0, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe(GOLDEN_PRE_M33.victoryTitle);
    expect(message.body).toBe(`Goiás 2 x 0 Vila Nova${GOLDEN_PRE_M33.fullTimeBodyVictorySuffix}`);
    expect(message.type).toBe('full_time');
  });

  it('full_time empate: title "Fim de jogo" e body com sufixo "." byte-idênticos ao original', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 1, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe(GOLDEN_PRE_M33.fullTimeNonVictoryTitle);
    expect(message.body).toBe(`Goiás 1 x 1 Vila Nova${GOLDEN_PRE_M33.fullTimeBodyNonVictorySuffix}`);
  });

  it('full_time derrota: mesmo título/sufixo de empate ("Fim de jogo" / ".") — nunca vira "VITÓRIA"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova', homeScore: 0, awayScore: 1, activeClubSide: 'home' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe(GOLDEN_PRE_M33.fullTimeNonVictoryTitle);
    expect(message.body).toBe(`Goiás 0 x 1 Vila Nova${GOLDEN_PRE_M33.fullTimeBodyNonVictorySuffix}`);
  });

  it('match_access_open sócio (checkin): title/body byte-idênticos ao original', () => {
    const message = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova' },
      GOIAS,
      { isActiveMember: true },
    );
    expect(message.title).toBe(GOLDEN_PRE_M33.checkinTitle);
    expect(message.body).toBe(GOLDEN_PRE_M33.checkinBody('Vila Nova'));
    expect(message.type).toBe('checkin');
  });

  it('match_access_open não-sócio (tickets): title/body byte-idênticos ao original', () => {
    const message = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Goiás', awayTeamName: 'Vila Nova' },
      GOIAS,
      { isActiveMember: false },
    );
    expect(message.title).toBe(GOLDEN_PRE_M33.ticketsTitle);
    expect(message.body).toBe(GOLDEN_PRE_M33.ticketsBody('Vila Nova'));
    expect(message.type).toBe('tickets');
  });

  it('match_access_open com Goiás mandante e visitante: opponent é sempre o adversário, nunca "Goiás" — mesmo ternário de 3 vias do original preservado', () => {
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
    expect(home.body).toBe(GOLDEN_PRE_M33.checkinBody('Vila Nova'));
    expect(away.body).toBe(GOLDEN_PRE_M33.checkinBody('Vila Nova'));
  });

  it('homeTeamName undefined: opponent cai pro terceiro ramo do ternário (string vazia), body com espaço duplo — comportamento ORIGINAL preservado exatamente, mesmo sendo uma peculiaridade pré-existente', () => {
    const message = buildNotificationMessage(
      'match_access_open',
      { awayTeamName: 'Vila Nova' },
      GOIAS,
      { isActiveMember: true },
    );
    // opponent = '' (não undefined) — '' ?? fallback NÃO ativa o fallback,
    // então o body original tinha esse espaço duplo real. Preservado.
    expect(message.body).toBe('O check-in pra  já está disponível.');
  });
});

describe('buildNotificationMessage — clube sintético produz sua própria copy, nunca "Goiás"/"Verdão"', () => {
  it('goal title do club-b usa o nome do club-b, nunca "GOIÁS"', () => {
    const message = buildNotificationMessage(
      'goal',
      { homeTeamName: 'Clube B', awayTeamName: 'Adversário', homeScore: 1, awayScore: 0 },
      CLUB_B,
      { isActiveMember: false },
    );
    expect(message.title).toBe('GOOOOOOL DO CLUBE B! ⚽💚');
    expect(message.title).not.toContain('GOIÁS');
  });

  it('victory title do club-b usa o apelido do club-b, nunca "VERDÃO"', () => {
    const message = buildNotificationMessage(
      'full_time',
      { homeTeamName: 'Clube B', awayTeamName: 'Adversário', homeScore: 2, awayScore: 0, activeClubSide: 'home' },
      CLUB_B,
      { isActiveMember: false },
    );
    expect(message.title).toBe('VITÓRIA DO TIME B! 💚');
    expect(message.title).not.toContain('VERDÃO');
  });

  it('match_access_open: opponent é resolvido comparando contra clubConfig.shortName do PRÓPRIO clube, nunca "Goiás" fixo', () => {
    const message = buildNotificationMessage(
      'match_access_open',
      { homeTeamName: 'Clube B', awayTeamName: 'Adversário' },
      CLUB_B,
      { isActiveMember: true },
    );
    expect(message.body).toContain('Adversário');
    expect(message.body).not.toContain('Clube B');
  });
});
