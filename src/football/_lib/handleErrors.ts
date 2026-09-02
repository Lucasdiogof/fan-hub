import { ConfigError } from './config';
import { UnknownClubError } from './club_server_config';
import { ProviderError } from './providerError';
import { errorResponse } from './respond';

/** Traduz erros internos em respostas HTTP controladas — nunca deixa uma
 * exception crua (nem stack trace) chegar no cliente. */
export async function withErrorHandling(handler: () => Promise<Response>): Promise<Response> {
  try {
    return await handler();
  } catch (err) {
    if (err instanceof UnknownClubError) {
      // Fail closed, nunca cai pro Goiás por omissão (NO_SERVER_CROSS_CLUB_FALLBACK).
      console.error('football.unknown_club', err.message);
      return errorResponse(err.message, 404);
    }
    if (err instanceof ConfigError) return errorResponse(err.message, 503);
    if (err instanceof ProviderError) {
      console.error('football.provider.error', err.provider, err.status);
      return errorResponse(err.message, err.status);
    }
    console.error('football.api.error', err instanceof Error ? err.message : String(err));
    return errorResponse('Erro inesperado ao consultar dados esportivos.', 500);
  }
}
