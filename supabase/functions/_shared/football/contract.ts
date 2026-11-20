// Contrato estável de `football_snapshots` (PK club_id + kind + key). O JSON
// em `payload` é o MESMO que o Worker devolvia — o app não conhece o
// OneFootball. Mudar o formato do payload = subir `CONTRACT_VERSION`.
export const CONTRACT_VERSION = 1;
export const SNAPSHOT_SOURCE = 'onefootball';

export const SNAPSHOT_KINDS = ['team', 'fixture', 'season', 'current_round', 'standings', 'competitions'] as const;
export type SnapshotKind = (typeof SNAPSHOT_KINDS)[number];

/** Snapshots singleton (um por clube) usam esta chave, nunca string vazia. */
export const SINGLETON_KEY = 'default';

export function isSnapshotKind(value: string): value is SnapshotKind {
  return (SNAPSHOT_KINDS as readonly string[]).includes(value);
}

export const roundKey = (offset: number): string => `offset:${offset}`;

/** Linha de `football_snapshots` como a Edge Function grava. */
export interface SnapshotRow {
  club_id: string;
  kind: SnapshotKind;
  key: string;
  payload: unknown;
  contract_version: number;
  source: string;
  fetched_at: string;
  next_refresh_at: string | null;
  expires_at: string;
  consecutive_failures: number;
  last_error: string | null;
  last_error_at: string | null;
}
