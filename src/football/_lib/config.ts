export interface Env {
  /** Código do clube que ESTE deploy serve — único allowlist de
   * `resolveClubServerConfig` (ver `club_server_config.ts`). Cada deploy
   * (`wrangler.toml`/`wrangler.bragantino.toml`/...) carrega seu próprio
   * valor; nunca uma lista com mais de um clube no mesmo Worker. */
  CLUB_CODE: string;
  /** Slug do time no OneFootball (`goias-1863`, `rb-bragantino-4734`...). */
  TEAM_ONEFOOTBALL_SLUG: string;
  /** Slug da competição principal no OneFootball — muda de temporada pra
   * temporada, e de clube pra clube (cada um disputa a sua). */
  PRIMARY_COMPETITION_SLUG: string;
  /** Nome de exibição da competição principal (`Brasileirão Série B`,
   * `Brasileirão Série A`...) — devolvido em `competition.name` pelos
   * endpoints que respondem com UMA competição no nível da resposta
   * (`/team/:code`, `/standings`, `/current-round`, `/fixtures/:id`). */
  PRIMARY_COMPETITION_DISPLAY_NAME: string;
  /** Salt da chave de cache — ver comentário no wrangler.toml. */
  CACHE_VERSION: string;
  /** Binding de assets estáticos (build/web do Flutter) — ver `[assets]` no wrangler.toml. */
  ASSETS: Fetcher;
}

export interface AppConfig {
  clubCode: string | null;
  teamOneFootballSlug: string | null;
  primaryCompetitionSlug: string | null;
  primaryCompetitionDisplayName: string | null;
  cacheVersion: string;
}

/** Erro de configuração ausente/incompleta. */
export class ConfigError extends Error {}

export function loadConfig(env: Env): AppConfig {
  return {
    clubCode: env.CLUB_CODE || null,
    teamOneFootballSlug: env.TEAM_ONEFOOTBALL_SLUG || null,
    primaryCompetitionSlug: env.PRIMARY_COMPETITION_SLUG || null,
    primaryCompetitionDisplayName: env.PRIMARY_COMPETITION_DISPLAY_NAME || null,
    cacheVersion: env.CACHE_VERSION || '1',
  };
}

export function requireTeamOneFootballSlug(config: AppConfig): string {
  if (!config.teamOneFootballSlug) {
    throw new ConfigError('TEAM_ONEFOOTBALL_SLUG não configurado no wrangler.toml.');
  }
  return config.teamOneFootballSlug;
}

export function requirePrimaryCompetitionSlug(config: AppConfig): string {
  if (!config.primaryCompetitionSlug) {
    throw new ConfigError('PRIMARY_COMPETITION_SLUG não configurado no wrangler.toml.');
  }
  return config.primaryCompetitionSlug;
}

export function requirePrimaryCompetitionDisplayName(config: AppConfig): string {
  if (!config.primaryCompetitionDisplayName) {
    throw new ConfigError('PRIMARY_COMPETITION_DISPLAY_NAME não configurado no wrangler.toml.');
  }
  return config.primaryCompetitionDisplayName;
}
