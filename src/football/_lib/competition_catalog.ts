import type { CompetitionFormat } from './config';

/**
 * Catálogo GLOBAL de competições — compartilhado por TODOS os deploys
 * (Goiás, Bragantino, qualquer clube futuro). Nunca duplicado por clube:
 * um Bundesliga/Libertadores/etc. existe uma vez só aqui, independente de
 * quem disputa o quê (ver `CLUB_PARTICIPATION` abaixo pra isso).
 *
 * Cada entrada foi confirmada navegando o OneFootball ao vivo
 * (2026-09-10) — nunca um slug/formato inventado. `region` já usa o
 * rótulo de agrupamento que a tela "Outros Campeonatos" mostra (Brasil,
 * América do Sul, Europa, Inglaterra, Itália, Alemanha, França).
 *
 * `format`:
 * - LEAGUE_TABLE: tabela única, achatada.
 * - GROUP_STAGE: vários grupos, cada um com a própria tabela.
 * - KNOCKOUT: só mata-mata, sem tabela nenhuma (Copa do Brasil) — sem
 *   renderer ainda (Fase C da rearquitetura multi-competição); até lá o
 *   endpoint devolve `dataGap: true`, nunca um erro de rede.
 */
export interface CatalogCompetition {
  id: string;
  name: string;
  region: string;
  slug: string;
  format: CompetitionFormat;
}

export const GLOBAL_COMPETITION_CATALOG: CatalogCompetition[] = [
  { id: 'brasileirao-serie-a', name: 'Brasileirão Série A', region: 'Brasil', slug: 'brasileirao-betano-16', format: 'LEAGUE_TABLE' },
  { id: 'brasileirao-serie-b', name: 'Brasileirão Série B', region: 'Brasil', slug: 'brasileirao-serie-b-superbet-119', format: 'LEAGUE_TABLE' },
  { id: 'brasileirao-serie-c', name: 'Brasileirão Série C', region: 'Brasil', slug: 'brasileirao-serie-c-195', format: 'GROUP_STAGE' },
  { id: 'brasileirao-serie-d', name: 'Brasileirão Série D', region: 'Brasil', slug: 'brasileirao-serie-d-216', format: 'GROUP_STAGE' },
  { id: 'copa-do-brasil', name: 'Copa do Brasil', region: 'Brasil', slug: 'copa-betano-do-brasil-137', format: 'KNOCKOUT' },
  { id: 'libertadores', name: 'CONMEBOL Libertadores', region: 'América do Sul', slug: 'conmebol-libertadores-76', format: 'GROUP_STAGE' },
  { id: 'sudamericana', name: 'CONMEBOL Sudamericana', region: 'América do Sul', slug: 'conmebol-sudamericana-102', format: 'GROUP_STAGE' },
  { id: 'champions-league', name: 'UEFA Champions League', region: 'Europa', slug: 'uefa-liga-dos-campeoes-5', format: 'LEAGUE_TABLE' },
  { id: 'premier-league', name: 'Premier League', region: 'Inglaterra', slug: 'premier-league-9', format: 'LEAGUE_TABLE' },
  { id: 'serie-a-italia', name: 'Serie A', region: 'Itália', slug: 'serie-a-13', format: 'LEAGUE_TABLE' },
  { id: 'bundesliga', name: 'Bundesliga', region: 'Alemanha', slug: 'bundesliga-1', format: 'LEAGUE_TABLE' },
  { id: 'ligue-1', name: 'Ligue 1', region: 'França', slug: 'ligue-1-23', format: 'LEAGUE_TABLE' },
  { id: 'la-liga', name: 'LaLiga', region: 'Espanha', slug: 'laliga-10', format: 'LEAGUE_TABLE' },
];

/**
 * Quais competições do catálogo cada clube disputa de verdade — SEPARADO
 * da existência da competição no catálogo (spec multi-competição, item
 * 16: `isClubParticipating` nunca decide se a competição pode ser
 * consultada, só se ela ganha destaque/linha marcada). Confirmado real
 * por clube:
 * - Goiás: só a Série B.
 * - Bragantino: Série A + Sudamericana (fase de grupos encerrada em
 *   1º-09, hoje na fase eliminatória contra o Atlético-MG).
 * - Vila Nova: Série B (a mesma do Goiás em 2026; Copa do Brasil é
 *   KNOCKOUT e Goiano/Copa Verde não estão no catálogo).
 */
export const CLUB_PARTICIPATION: Record<string, string[]> = {
  goias: ['brasileirao-serie-b'],
  bragantino: ['brasileirao-serie-a', 'sudamericana'],
  vilanova: ['brasileirao-serie-b'],
};

export function findCatalogCompetition(id: string): CatalogCompetition | undefined {
  return GLOBAL_COMPETITION_CATALOG.find((c) => c.id === id);
}

export function competitionIdsForClub(clubCode: string): string[] {
  return CLUB_PARTICIPATION[clubCode] ?? [];
}
