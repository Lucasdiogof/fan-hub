/** Erro vindo de uma fonte esportiva externa (Brasileirão-api, TheSportsDB —
 * qualquer uma). Carrega o nome do provider só pra log, nunca pra resposta. */
export class ProviderError extends Error {
  constructor(
    message: string,
    public status: number,
    public provider: string,
  ) {
    super(message);
  }
}
