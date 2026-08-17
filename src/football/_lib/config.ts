export interface Env {
  API_FOOTBALL_KEY: string;
  SERIE_B_LEAGUE_ID: string;
  GOIAS_TEAM_ID: string;
  SEASON: string;
  /** Binding de assets estáticos (build/web do Flutter) — ver `[assets]` no wrangler.toml. */
  ASSETS: Fetcher;
}

export interface FootballApiConfig {
  apiKey: string;
  baseUrl: string;
  leagueId: number;
  teamId: number;
  season: number;
}

/** Erro de configuração ausente/incompleta — nunca por falha da API-Football em si. */
export class ConfigError extends Error {}

/**
 * Centraliza a config server-side (liga, time, temporada). Os IDs não têm
 * valor padrão "chutado" de propósito — até serem confirmados via
 * `/api/football/discover`, a Function falha de forma clara em vez de
 * assumir um ID errado.
 */
export function loadConfig(env: Env): FootballApiConfig {
  const apiKey = env.API_FOOTBALL_KEY;
  if (!apiKey) {
    throw new ConfigError('API_FOOTBALL_KEY não configurada. Configure o secret no Cloudflare.');
  }

  const leagueId = Number(env.SERIE_B_LEAGUE_ID);
  const teamId = Number(env.GOIAS_TEAM_ID);
  const season = Number(env.SEASON || '2026');

  if (!leagueId || !teamId) {
    throw new ConfigError(
      'SERIE_B_LEAGUE_ID / GOIAS_TEAM_ID não configurados. Use GET /api/football/discover?search=... para descobrir os IDs reais e preencha o wrangler.toml.',
    );
  }

  return { apiKey, baseUrl: 'https://v3.football.api-sports.io', leagueId, teamId, season };
}
