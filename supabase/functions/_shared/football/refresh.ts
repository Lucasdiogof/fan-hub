// Orquestra um refresh: provider -> normalização -> imagens -> política ->
// upsert em `football_snapshots`. Uma única implementação (Home, Jogos e
// push usam isto). Em falha mantém o payload anterior (só atualiza controle).
import { stripPlaceholderPhotos } from './lineup_photos.ts';
import type { MatchLineupsJson } from './normalize.ts';
import type { ClubServerConfig } from '../club_server_config.ts';
import {
  buildCompetitionsSnapshot,
  buildCurrentRoundSnapshots,
  buildFixtureSnapshot,
  buildSeasonSnapshot,
  buildStandingsSnapshot,
  buildTeamSnapshot,
  standingsKeysForClub,
} from './builders.ts';
import {
  CONTRACT_VERSION,
  SINGLETON_KEY,
  SNAPSHOT_SOURCE,
  roundKey,
  type SnapshotKind,
  type SnapshotRow,
} from './contract.ts';
import { materializeImages, type ImageDeps } from './images.ts';
import { computeBackoff, computeRefresh } from './policy.ts';

export interface DueInfo {
  kind: SnapshotKind;
  key: string;
  next_refresh_at: string | null;
  consecutive_failures: number;
}

type FailurePatch = Pick<
  SnapshotRow,
  'consecutive_failures' | 'last_error' | 'last_error_at' | 'next_refresh_at'
>;

/** Acesso a dados mínimo — o adaptador Supabase está em `store.ts`. */
export interface SnapshotStore {
  list(clubId: string): Promise<DueInfo[]>;
  upsert(rows: SnapshotRow[]): Promise<void>;
  /** Só colunas de controle; NUNCA toca `payload` (mantém o último bom).
   * Devolve false quando não existe linha anterior. */
  markFailure(clubId: string, kind: SnapshotKind, key: string, patch: FailurePatch): Promise<boolean>;
}

export interface RefreshDeps {
  store: SnapshotStore;
  now?: () => Date;
  /** `null`/ausente = não materializa imagens (mantém URLs do OneFootball). */
  images?: ImageDeps | null;
}

export interface RefreshResult {
  club: string;
  kind: SnapshotKind;
  key: string;
  ok: boolean;
  error?: string;
  /** Payload do snapshot gerado (usado pra derivar fixtures do `team`). */
  payload?: unknown;
}

async function build(
  club: ClubServerConfig,
  kind: SnapshotKind,
  key: string,
): Promise<{ key: string; payload: unknown }[]> {
  switch (kind) {
    case 'team':
      return [{ key: SINGLETON_KEY, payload: await buildTeamSnapshot(club) }];
    case 'season':
      return [{ key: SINGLETON_KEY, payload: await buildSeasonSnapshot(club) }];
    case 'competitions':
      return [{ key: SINGLETON_KEY, payload: buildCompetitionsSnapshot(club) }];
    case 'standings':
      return [{ key, payload: await buildStandingsSnapshot(club, key === SINGLETON_KEY ? 'primary' : key) }];
    case 'fixture':
      return [{ key, payload: await buildFixtureSnapshot(key) }];
    case 'current_round': {
      const rounds = await buildCurrentRoundSnapshots(club);
      return [...rounds].map(([offset, payload]) => ({ key: roundKey(offset), payload }));
    }
  }
}

async function stripFixtureSilhouettes<T>(kind: SnapshotKind, payload: T): Promise<T> {
  const lineups = (payload as { lineups?: MatchLineupsJson | null }).lineups;
  if (kind !== 'fixture' || !lineups) return payload;
  return { ...payload, lineups: await stripPlaceholderPhotos(lineups) };
}

export async function refreshSnapshot(
  club: ClubServerConfig,
  kind: SnapshotKind,
  key: string,
  deps: RefreshDeps,
  previousFailures = 0,
): Promise<RefreshResult> {
  const now = (deps.now ?? (() => new Date()))();
  try {
    const built = await build(club, kind, key);
    const rows: SnapshotRow[] = [];
    for (const item of built) {
      // Flag de imagens só liga Storage; a regra silhueta x foto vale sempre.
      const payload = deps.images
        ? await materializeImages(item.payload, { ...deps.images, skipTeamId: club.oneFootballTeamId })
        : await stripFixtureSilhouettes(kind, item.payload);
      const plan = computeRefresh(kind, item.payload, now);
      rows.push({
        club_id: club.canonicalClubId,
        kind,
        key: item.key,
        payload,
        contract_version: CONTRACT_VERSION,
        source: SNAPSHOT_SOURCE,
        fetched_at: now.toISOString(),
        next_refresh_at: plan.nextRefreshAt?.toISOString() ?? null,
        expires_at: plan.expiresAt.toISOString(),
        consecutive_failures: 0,
        last_error: null,
        last_error_at: null,
      });
    }
    await deps.store.upsert(rows);
    return { club: club.code, kind, key, ok: true, payload: built[0]?.payload };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    const failures = previousFailures + 1;
    // Sem linha anterior não há o que "manter": markFailure devolve false e o
    // próximo ciclo tenta de novo (linha ausente = vencida).
    await deps.store
      .markFailure(club.canonicalClubId, kind, key, {
        consecutive_failures: failures,
        last_error: message.slice(0, 500),
        last_error_at: now.toISOString(),
        next_refresh_at: computeBackoff(failures, now).toISOString(),
      })
      .catch(() => false);
    return { club: club.code, kind, key, ok: false, error: message };
  }
}

/** O que cada clube precisa ter: [kind, key do snapshot de controle]. */
export function expectedSnapshots(club: ClubServerConfig): { kind: SnapshotKind; key: string }[] {
  return [
    { kind: 'team', key: SINGLETON_KEY },
    { kind: 'season', key: SINGLETON_KEY },
    { kind: 'current_round', key: roundKey(0) },
    ...standingsKeysForClub(club).map((key) => ({ kind: 'standings' as const, key })),
    { kind: 'competitions', key: SINGLETON_KEY },
  ];
}

interface TeamLike {
  nextMatch?: { id?: string } | null;
  recentResults?: { id?: string }[];
}

/** Atualiza o que está vencido (ou nunca existiu). `kinds` restringe. */
export async function refreshDue(
  club: ClubServerConfig,
  deps: RefreshDeps,
  kinds?: SnapshotKind[],
): Promise<RefreshResult[]> {
  const now = (deps.now ?? (() => new Date()))();
  const existing = await deps.store.list(club.canonicalClubId);
  const byId = new Map(existing.map((r) => [`${r.kind}|${r.key}`, r]));
  const isDue = (kind: SnapshotKind, key: string) => {
    const row = byId.get(`${kind}|${key}`);
    return !row || (row.next_refresh_at !== null && Date.parse(row.next_refresh_at) <= now.getTime());
  };
  const wanted = (kind: SnapshotKind) => !kinds || kinds.includes(kind);

  const results: RefreshResult[] = [];
  const run = async (kind: SnapshotKind, key: string) => {
    const r = await refreshSnapshot(club, kind, key, deps, byId.get(`${kind}|${key}`)?.consecutive_failures ?? 0);
    results.push(r);
    return r;
  };

  let teamPayload: TeamLike | undefined;
  for (const { kind, key } of expectedSnapshots(club)) {
    if (!wanted(kind) || !isDue(kind, key)) continue;
    const r = await run(kind, key);
    if (kind === 'team' && r.ok) teamPayload = r.payload as TeamLike;
  }

  // Detalhe (eventos/escalação/stats) do jogo em destaque e do último resultado:
  // é o que a Central da partida e o push leem — um refresh só, uma fonte só.
  if (wanted('fixture')) {
    const ids = new Set(
      [teamPayload?.nextMatch?.id, teamPayload?.recentResults?.[0]?.id].filter((id): id is string => !!id),
    );
    for (const id of ids) if (isDue('fixture', id)) await run('fixture', id);
    // Fixtures que já existem e venceram (ex.: jogo ao vivo que saiu do `team`).
    for (const row of existing) {
      if (row.kind === 'fixture' && !ids.has(row.key) && isDue('fixture', row.key)) await run('fixture', row.key);
    }
  }
  return results;
}
