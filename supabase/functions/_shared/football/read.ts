// Leitura de snapshot pra OUTRAS Edge Functions (push) — mesma fonte que a Home
// lê pela RPC, sem HTTP interno. Se o snapshot não existe, expirou ou o refresh
// agendado atrasou, refaz via `refreshSnapshot` (a única implementação).
import type { ClubServerConfig } from '../club_server_config.ts';
import type { SnapshotKind } from './contract.ts';
import { refreshSnapshot, type RefreshDeps } from './refresh.ts';

// deno-lint-ignore no-explicit-any
type Admin = any;

/** `maxAgeMs`: idade máxima aceita do snapshot salvo antes de forçar refresh. */
export async function readSnapshotOrRefresh<T = unknown>(
  admin: Admin,
  club: ClubServerConfig,
  kind: SnapshotKind,
  key: string,
  deps: RefreshDeps,
  maxAgeMs: number,
): Promise<T | null> {
  const { data } = await admin
    .from('football_snapshots')
    .select('payload,fetched_at,expires_at')
    .eq('club_id', club.canonicalClubId)
    .eq('kind', kind)
    .eq('key', key)
    .maybeSingle();
  const now = (deps.now ?? (() => new Date()))().getTime();
  if (
    data &&
    now - Date.parse(data.fetched_at) <= maxAgeMs &&
    now <= Date.parse(data.expires_at)
  ) {
    return data.payload as T;
  }
  const refreshed = await refreshSnapshot(club, kind, key, deps);
  if (refreshed.ok) return refreshed.payload as T;
  // Refresh falhou: um snapshot antigo (ainda não expirado) vale mais que nada.
  return data && now <= Date.parse(data.expires_at) ? (data.payload as T) : null;
}
