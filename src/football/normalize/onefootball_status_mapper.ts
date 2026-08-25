/**
 * Só `PRE_MATCH` e `FULL_TIME` foram confirmados observando partidas reais
 * (nenhum jogo ao vivo do Goiás durante essa investigação) — os demais
 * são o vocabulário típico desse tipo de API, prováveis mas não
 * confirmados. Se o app mostrar "unknown" durante uma partida ao vivo,
 * comece por aqui.
 */
export function mapOneFootballStatus(period: string): string {
  switch (period) {
    case 'PRE_MATCH':
      return 'scheduled';
    case 'FULL_TIME':
      return 'finished';
    case 'FIRST_HALF':
    case 'SECOND_HALF':
    case 'EXTRA_TIME':
    case 'PENALTY_SHOOTOUT':
    case 'LIVE':
      return 'live';
    case 'HALF_TIME':
      return 'halftime';
    case 'POSTPONED':
      return 'postponed';
    case 'CANCELLED':
    case 'CANCELED':
      return 'cancelled';
    case 'SUSPENDED':
    case 'ABANDONED':
      return 'suspended';
    default:
      return 'unknown';
  }
}
