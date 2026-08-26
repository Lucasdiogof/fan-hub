/**
 * OneFootball às vezes acrescenta um desambiguador ao nome do time (ex.:
 * "SJ" de São João del-Rei, pra não confundir com outro "Athletic") que deixa
 * o nome longo demais pra UI. Mapa exato (nunca uma regra genérica de
 * "cortar a última palavra") — cada entrada precisa ser conferida antes de
 * entrar aqui, senão corre o risco de cortar um sufixo que faz parte do nome
 * de verdade de outro time (ex.: "... FC"/"... EC").
 */
const TEAM_NAME_OVERRIDES: Record<string, string> = {
  'Athletic Club SJ': 'Athletic Club',
};

export function normalizeTeamName(name: string): string {
  return TEAM_NAME_OVERRIDES[name] ?? name;
}
