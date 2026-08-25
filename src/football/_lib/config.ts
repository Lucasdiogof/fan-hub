export interface Env {
  GOIAS_ONEFOOTBALL_SLUG: string;
  ONEFOOTBALL_COMPETITION_SLUG: string;
  /** Salt da chave de cache — ver comentário no wrangler.toml. */
  CACHE_VERSION: string;
  /** Binding de assets estáticos (build/web do Flutter) — ver `[assets]` no wrangler.toml. */
  ASSETS: Fetcher;
}

export interface AppConfig {
  goias: {
    /** slug do Goiás no OneFootball (`goias-1863`, do path `/pt-br/time/<slug>`). */
    onefootballSlug: string | null;
  };
  /** slug da competição no OneFootball (`brasileirao-serie-b-superbet-119`) — muda de temporada pra temporada. */
  onefootballCompetitionSlug: string | null;
  cacheVersion: string;
}

/** Erro de configuração ausente/incompleta. */
export class ConfigError extends Error {}

export function loadConfig(env: Env): AppConfig {
  return {
    goias: {
      onefootballSlug: env.GOIAS_ONEFOOTBALL_SLUG || null,
    },
    onefootballCompetitionSlug: env.ONEFOOTBALL_COMPETITION_SLUG || null,
    cacheVersion: env.CACHE_VERSION || '1',
  };
}

export function requireGoiasOneFootballSlug(config: AppConfig): string {
  if (!config.goias.onefootballSlug) {
    throw new ConfigError('GOIAS_ONEFOOTBALL_SLUG não configurado no wrangler.toml.');
  }
  return config.goias.onefootballSlug;
}

export function requireOneFootballCompetitionSlug(config: AppConfig): string {
  if (!config.onefootballCompetitionSlug) {
    throw new ConfigError('ONEFOOTBALL_COMPETITION_SLUG não configurado no wrangler.toml.');
  }
  return config.onefootballCompetitionSlug;
}
