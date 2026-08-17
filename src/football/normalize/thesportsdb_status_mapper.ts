/** Traduz os códigos de status do TheSportsDB (`NS`, `FT`, `1H`...) pro
 * nosso domínio — mesmo vocabulário curto usado por várias fontes
 * esportivas, mas o mapper é específico desse provider mesmo assim. */
export function mapTheSportsDbStatus(status: string | null | undefined): string {
  switch (status) {
    case 'NS':
    case '':
    case null:
    case undefined:
      return 'scheduled';
    case '1H':
    case '2H':
    case 'ET':
      return 'live';
    case 'HT':
      return 'halftime';
    case 'FT':
    case 'AET':
    case 'PEN':
      return 'finished';
    case 'PST':
      return 'postponed';
    case 'CANC':
      return 'cancelled';
    case 'SUSP':
    case 'ABD':
      return 'suspended';
    default:
      return 'unknown';
  }
}
