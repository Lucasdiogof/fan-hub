/** Traduz o status já semi-normalizado da campeonato-brasileiro-api
 * (`finished|scheduled|live`) pro nosso domínio. Cada provider tem seu
 * próprio mapper — a UI nunca vê o vocabulário de nenhum provider. */
export function mapBrasileiraoStatus(status: string): string {
  switch (status) {
    case 'finished':
      return 'finished';
    case 'live':
      return 'live';
    case 'scheduled':
      return 'scheduled';
    default:
      return 'unknown';
  }
}
