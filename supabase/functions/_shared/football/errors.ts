/** Erro vindo de uma fonte esportiva externa (OneFootball). Carrega o nome
 * do provider só pra log, nunca pra resposta. */
export class ProviderError extends Error {
  constructor(
    message: string,
    public status: number,
    public provider: string,
  ) {
    super(message);
  }
}
