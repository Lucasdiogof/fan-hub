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
  /**
   * Competições ADICIONAIS que o clube disputa além da principal — JSON
   * array de `{"id","name","slug","format"}` (`format`: `"LEAGUE_TABLE"` ou
   * `"GROUP_STAGE"`, ver `CompetitionFormat`). Opcional — a maioria dos
   * clubes só tem a principal. `id` é o que o app manda em
   * `?competition=<id>` pro `/standings`; `slug` é o path real no
   * OneFootball (`/competicao/<slug>/tabela`), confirmado navegando o site,
   * nunca inventado. Auditoria 2026-09-09: RB Bragantino disputa a
   * CONMEBOL Sudamericana AO MESMO TEMPO que o Brasileirão — a única
   * competição real hoje que justifica isto (ver wrangler.bragantino.toml).
   */
  SECONDARY_COMPETITIONS?: string;
}

export type CompetitionFormat = 'LEAGUE_TABLE' | 'GROUP_STAGE';

export interface SecondaryCompetitionConfig {
  id: string;
  name: string;
  slug: string;
  format: CompetitionFormat;
}

export interface AppConfig {
  clubCode: string | null;
  teamOneFootballSlug: string | null;
  primaryCompetitionSlug: string | null;
  primaryCompetitionDisplayName: string | null;
  cacheVersion: string;
  secondaryCompetitions: SecondaryCompetitionConfig[];
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
    secondaryCompetitions: parseSecondaryCompetitions(env.SECONDARY_COMPETITIONS),
  };
}

/** JSON malformado/ausente nunca derruba o Worker — cai em `[]` (só a
 * competição principal aparece), nunca inventa uma entrada. */
function parseSecondaryCompetitions(raw: string | undefined): SecondaryCompetitionConfig[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(
      (entry): entry is SecondaryCompetitionConfig =>
        typeof entry?.id === 'string' &&
        typeof entry?.name === 'string' &&
        typeof entry?.slug === 'string' &&
        (entry?.format === 'LEAGUE_TABLE' || entry?.format === 'GROUP_STAGE'),
    );
  } catch {
    return [];
  }
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
