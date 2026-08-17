import type { FootballApiConfig } from './config';

/** Erro vindo da própria API-Football (rate limit, indisponibilidade, etc). */
export class ApiFootballError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}

/**
 * Única função que efetivamente fala com a API-Football. A key é lida da
 * config e usada só no header — nunca é logada, nunca volta na resposta.
 */
export async function apiFootballGet(
  config: FootballApiConfig,
  path: string,
  params: Record<string, string | number>,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): Promise<any> {
  const url = new URL(config.baseUrl + path);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, String(value));
  }

  const response = await fetch(url.toString(), {
    headers: { 'x-apisports-key': config.apiKey },
  });

  if (response.status === 429) {
    throw new ApiFootballError('Limite de requisições da API-Football atingido.', 429);
  }
  if (!response.ok) {
    throw new ApiFootballError(`API-Football retornou status ${response.status}.`, 502);
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const body = (await response.json()) as any;
  const errors = body?.errors;
  const hasErrors = Array.isArray(errors) ? errors.length > 0 : errors && Object.keys(errors).length > 0;
  if (hasErrors) {
    throw new ApiFootballError('API-Football retornou erro na resposta.', 502);
  }

  return body;
}
