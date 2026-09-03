import { describe, expect, it, vi } from 'vitest';
import {
  fetchRecipientTokens,
  isActiveMember,
  preferenceColumnFor,
  type RecipientEligibilitySource,
  type TokenRow,
} from './recipient_eligibility';

const CLUB_A = '4c16340d-300c-5ab2-903f-17519db9b146';
// Fixture SINTÉTICA, só neste arquivo de teste — nunca registrada em
// SERVER_CLUB_REGISTRY, nunca um clube real nomeado (mesmo espírito de
// `syntheticClubBConfig` no Flutter).
const CLUB_B = 'deadbeef-0000-0000-0000-000000000000';

const TOKEN_A: TokenRow = {
  id: 'tok-a',
  user_id: 'user-a',
  fcm_token: 'fcm-a',
  platform: 'android',
  club_id: CLUB_A,
};
const TOKEN_B: TokenRow = {
  id: 'tok-b',
  user_id: 'user-b',
  fcm_token: 'fcm-b',
  platform: 'ios',
  club_id: CLUB_B,
};
const TOKEN_LEGACY: TokenRow = {
  id: 'tok-legacy',
  user_id: 'user-legacy',
  fcm_token: 'fcm-legacy',
  platform: 'android',
  club_id: CLUB_A,
};

/** Fake in-memory de `RecipientEligibilitySource` — nunca dispara FCM real,
 * nunca fala com Postgres real. `activeTokensForClub` já filtra por
 * `club_id`, igual a query real faria (M4.1c) — o fake não recebe a lista
 * inteira de tokens do sistema, só o que a fonte real devolveria. */
function fakeSource(opts: {
  preferences: Array<{ userId: string; clubId: string; column: 'matches_enabled' | 'tickets_enabled'; enabled: boolean }>;
  tokens: TokenRow[];
  memberships?: Array<{ userId: string; clubId: string }>;
}): RecipientEligibilitySource {
  return {
    async explicitlyEligibleUserIds(clubId, prefColumn) {
      return opts.preferences
        .filter((p) => p.clubId === clubId && p.column === prefColumn && p.enabled)
        .map((p) => p.userId);
    },
    async usersWithAnyPreferenceRow() {
      return [...new Set(opts.preferences.map((p) => p.userId))];
    },
    async activeTokensForClub(clubId) {
      return opts.tokens.filter((t) => t.club_id === clubId);
    },
    async activeMembershipCount(userId, clubId) {
      return (opts.memberships ?? []).filter((m) => m.userId === userId && m.clubId === clubId).length;
    },
  };
}

describe('preferenceColumnFor', () => {
  it('match_access_open -> tickets_enabled, goal/full_time -> matches_enabled', () => {
    expect(preferenceColumnFor('match_access_open')).toBe('tickets_enabled');
    expect(preferenceColumnFor('goal')).toBe('matches_enabled');
    expect(preferenceColumnFor('full_time')).toBe('matches_enabled');
  });
});

describe('fetchRecipientTokens — elegibilidade por usuário (M4.1, camada 1)', () => {
  it('event clubA + user A subscribed clubA -> recebe', async () => {
    const source = fakeSource({
      preferences: [{ userId: 'user-a', clubId: CLUB_A, column: 'matches_enabled', enabled: true }],
      tokens: [TOKEN_A],
    });
    const recipients = await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(recipients.map((r) => r.id)).toEqual(['tok-a']);
  });

  it('event clubA + user B só tem preferência configurada em clubB -> NÃO recebe', async () => {
    // TOKEN_B pertence a clubB — mesmo que existisse um token de user-b
    // registrado em clubA, a preferência dele (só configurada em clubB)
    // já bastaria pra excluir; aqui provamos a camada de ELEGIBILIDADE
    // isolada, dando ao fake um token que JÁ é de clubA pra esse user,
    // pra garantir que é a checagem de preferência (não a de token) que
    // está barrando.
    const tokenBUserInClubA: TokenRow = { ...TOKEN_B, id: 'tok-b-in-a', club_id: CLUB_A };
    const source = fakeSource({
      preferences: [{ userId: 'user-b', clubId: CLUB_B, column: 'matches_enabled', enabled: true }],
      tokens: [tokenBUserInClubA],
    });
    const recipients = await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(recipients).toEqual([]);
  });

  it('mesmo modelo -> usuário nunca configurado em NENHUM clube ainda recebe (default legado, sem regressão pros usuários reais de hoje)', async () => {
    const source = fakeSource({
      preferences: [],
      tokens: [TOKEN_LEGACY],
    });
    const recipients = await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(recipients.map((r) => r.id)).toEqual(['tok-legacy']);
  });

  it('usuário que opta explicitamente por sair do clubA continua fora (opt-out original preservado, escopado)', async () => {
    const source = fakeSource({
      preferences: [{ userId: 'user-a', clubId: CLUB_A, column: 'matches_enabled', enabled: false }],
      tokens: [TOKEN_A],
    });
    const recipients = await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(recipients).toEqual([]);
  });

  it('coluna certa por tipo de evento: tickets_enabled=false não bloqueia goal/full_time (matches_enabled continua true)', async () => {
    const source = fakeSource({
      preferences: [
        { userId: 'user-a', clubId: CLUB_A, column: 'matches_enabled', enabled: true },
        { userId: 'user-a', clubId: CLUB_A, column: 'tickets_enabled', enabled: false },
      ],
      tokens: [TOKEN_A],
    });
    const goalRecipients = await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(goalRecipients.map((r) => r.id)).toEqual(['tok-a']);

    const ticketRecipients = await fetchRecipientTokens(source, CLUB_A, 'match_access_open');
    expect(ticketRecipients).toEqual([]);
  });
});

describe('fetchRecipientTokens — entrega por TOKEN (M4.1c, camada 2 — o gap real da auditoria M4.1b)', () => {
  it('CENÁRIO OBRIGATÓRIO: mesmo user, token-goias em clubA + token-clubb em clubB -> event clubA só entrega no token-goias', async () => {
    const sameUserId = 'user-multi-club';
    const tokenGoias: TokenRow = {
      id: 'token-goias',
      user_id: sameUserId,
      fcm_token: 'fcm-goias',
      platform: 'android',
      club_id: CLUB_A,
    };
    const tokenClubB: TokenRow = {
      id: 'token-clubb',
      user_id: sameUserId,
      fcm_token: 'fcm-clubb',
      platform: 'android',
      club_id: CLUB_B,
    };
    const source = fakeSource({
      preferences: [], // nunca configurou preferência em nenhum clube -> default legado, elegível pros dois
      tokens: [tokenGoias, tokenClubB],
    });

    const clubAResult = await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(clubAResult.map((r) => r.id)).toEqual(['token-goias']);
    expect(clubAResult.some((r) => r.id === 'token-clubb')).toBe(false);
  });

  it('CENÁRIO OBRIGATÓRIO: o mesmo user, o mesmo par de tokens -> event clubB só entrega no token-clubb', async () => {
    const sameUserId = 'user-multi-club';
    const tokenGoias: TokenRow = {
      id: 'token-goias',
      user_id: sameUserId,
      fcm_token: 'fcm-goias',
      platform: 'android',
      club_id: CLUB_A,
    };
    const tokenClubB: TokenRow = {
      id: 'token-clubb',
      user_id: sameUserId,
      fcm_token: 'fcm-clubb',
      platform: 'android',
      club_id: CLUB_B,
    };
    const source = fakeSource({
      preferences: [],
      tokens: [tokenGoias, tokenClubB],
    });

    const clubBResult = await fetchRecipientTokens(source, CLUB_B, 'goal');
    expect(clubBResult.map((r) => r.id)).toEqual(['token-clubb']);
    expect(clubBResult.some((r) => r.id === 'token-goias')).toBe(false);
  });

  it('0 preferences em nenhum clube -> default legado continua funcionando, MAS só dentro do club_id do token/evento (as duas camadas juntas)', async () => {
    const sameUserId = 'user-never-configured';
    const tokenGoias: TokenRow = {
      id: 'token-goias-only',
      user_id: sameUserId,
      fcm_token: 'fcm-goias-only',
      platform: 'android',
      club_id: CLUB_A,
    };
    const source = fakeSource({ preferences: [], tokens: [tokenGoias] });

    // Elegível por default legado E tem token do clube certo -> recebe.
    expect((await fetchRecipientTokens(source, CLUB_A, 'goal')).map((r) => r.id)).toEqual([
      'token-goias-only',
    ]);
    // Elegível por default legado (nunca configurou nada) MAS não tem
    // NENHUM token de clubB -> 0 destinatários, nunca um vazamento pro
    // token de outro clube.
    expect(await fetchRecipientTokens(source, CLUB_B, 'goal')).toEqual([]);
  });

  it('FABRICADO: reproduz o bug real da M4.1b — uma fonte que devolve TODOS os tokens (sem filtrar por clube) vaza token de clubB pro evento de clubA', async () => {
    const sameUserId = 'user-multi-club';
    const tokenGoias: TokenRow = {
      id: 'token-goias',
      user_id: sameUserId,
      fcm_token: 'fcm-goias',
      platform: 'android',
      club_id: CLUB_A,
    };
    const tokenClubB: TokenRow = {
      id: 'token-clubb',
      user_id: sameUserId,
      fcm_token: 'fcm-clubb',
      platform: 'android',
      club_id: CLUB_B,
    };
    // Fonte QUEBRADA de propósito — reproduz o comportamento pré-M4.1c
    // (`activeTokensForClub` ignora o `clubId` recebido, devolve tudo).
    const brokenSource: RecipientEligibilitySource = {
      async explicitlyEligibleUserIds() {
        return [];
      },
      async usersWithAnyPreferenceRow() {
        return [];
      },
      async activeTokensForClub() {
        return [tokenGoias, tokenClubB]; // ignora clubId — o bug
      },
      async activeMembershipCount() {
        return 0;
      },
    };
    const clubAResult = await fetchRecipientTokens(brokenSource, CLUB_A, 'goal');
    // Com a fonte quebrada, o token de clubB vaza pro evento de clubA —
    // prova que é `activeTokensForClub` filtrando de verdade (não algo
    // em `fetchRecipientTokens`) que impede o vazamento na implementação
    // real.
    expect(clubAResult.some((r) => r.id === 'token-clubb')).toBe(true);
  });

  it('FABRICADO: nenhum FCM real é chamado — o fake source nunca faz fetch/rede', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const source = fakeSource({
      preferences: [{ userId: 'user-a', clubId: CLUB_A, column: 'matches_enabled', enabled: true }],
      tokens: [TOKEN_A],
    });
    await fetchRecipientTokens(source, CLUB_A, 'goal');
    expect(fetchSpy).not.toHaveBeenCalled();
    fetchSpy.mockRestore();
  });
});

describe('isActiveMember — sempre club_id + user_id, nunca membership de outro clube (achado crítico da auditoria)', () => {
  it('membership clubB não deve afetar a checagem de clubA (mesmo usuário, clubes diferentes)', async () => {
    const source = fakeSource({
      preferences: [],
      tokens: [],
      memberships: [{ userId: 'user-a', clubId: CLUB_B }],
    });
    expect(await isActiveMember(source, 'user-a', CLUB_A)).toBe(false);
    expect(await isActiveMember(source, 'user-a', CLUB_B)).toBe(true);
  });

  it('membership clubB não deve influenciar a COPY da notificação de clubA (isActiveMember de clubA fica false, mesmo com membership ativa em clubB)', async () => {
    const source = fakeSource({
      preferences: [],
      tokens: [],
      memberships: [{ userId: 'user-b', clubId: CLUB_B }],
    });
    const isMemberOfA = await isActiveMember(source, 'user-b', CLUB_A);
    expect(isMemberOfA).toBe(false);
  });

  it('sem nenhuma membership em lugar nenhum -> false', async () => {
    const source = fakeSource({ preferences: [], tokens: [] });
    expect(await isActiveMember(source, 'user-x', CLUB_A)).toBe(false);
  });
});
