export interface Env {
  SERIE_CODE: string;
  GOIAS_BRASILEIRAO_ID: string;
  GOIAS_THESPORTSDB_ID: string;
  /** Binding de assets estáticos (build/web do Flutter) — ver `[assets]` no wrangler.toml. */
  ASSETS: Fetcher;
}

export interface AppConfig {
  serieCode: string;
  goias: {
    /** id numérico do Goiás na campeonato-brasileiro-api (`equipe_id` do ge.globo). */
    brasileiraoId: number | null;
    /** id do time do Goiás no TheSportsDB. */
    thesportsdbId: string | null;
  };
}

/** Erro de configuração ausente/incompleta. */
export class ConfigError extends Error {}

export function loadConfig(env: Env): AppConfig {
  const serieCode = (env.SERIE_CODE || 'b').toLowerCase();
  const brasileiraoIdRaw = env.GOIAS_BRASILEIRAO_ID;
  const thesportsdbIdRaw = env.GOIAS_THESPORTSDB_ID;

  return {
    serieCode,
    goias: {
      brasileiraoId: brasileiraoIdRaw ? Number(brasileiraoIdRaw) : null,
      thesportsdbId: thesportsdbIdRaw || null,
    },
  };
}

/**
 * Usa em endpoints que realmente precisam saber quem é o Goiás (rodada
 * atual, time). Falha com uma mensagem clara em vez de assumir errado —
 * até isso ser confirmado via `/api/football/discover`.
 */
export function requireGoiasBrasileiraoId(config: AppConfig): number {
  if (!config.goias.brasileiraoId) {
    throw new ConfigError(
      'GOIAS_BRASILEIRAO_ID não configurado. Use GET /api/football/discover pra descobrir o id real e preencha o wrangler.toml.',
    );
  }
  return config.goias.brasileiraoId;
}

export function requireGoiasTheSportsDbId(config: AppConfig): string {
  if (!config.goias.thesportsdbId) {
    throw new ConfigError(
      'GOIAS_THESPORTSDB_ID não configurado. Use GET /api/football/discover pra descobrir o id real e preencha o wrangler.toml.',
    );
  }
  return config.goias.thesportsdbId;
}
