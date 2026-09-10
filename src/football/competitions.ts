import type { Env } from './_lib/config';
import { loadConfig, requirePrimaryCompetitionDisplayName } from './_lib/config';
import { isRequestedClubServed } from './_lib/club_server_config';
import { jsonResponse } from './_lib/respond';
import { withErrorHandling } from './_lib/handleErrors';

/**
 * Lista as competições que o clube ativo pode escolher pra ver
 * classificação — sempre a principal (`id: "primary"`) primeiro, mais
 * qualquer uma configurada em `SECONDARY_COMPETITIONS` (ver `config.ts`).
 * Nunca inventa competição: só o que está configurado explicitamente no
 * deploy, confirmado ter dado real no OneFootball antes de entrar aqui
 * (auditoria 2026-09-09).
 */
export const onRequestGet = handleCompetitions;

export async function handleCompetitions(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    if (!isRequestedClubServed(request, env)) {
      return jsonResponse({ error: 'unknown club code' }, { status: 404 });
    }
    const config = loadConfig(env);
    const primaryName = requirePrimaryCompetitionDisplayName(config);

    return jsonResponse({
      competitions: [
        { id: 'primary', name: primaryName, format: 'LEAGUE_TABLE', isPrimary: true },
        ...config.secondaryCompetitions.map((c) => ({
          id: c.id,
          name: c.name,
          format: c.format,
          isPrimary: false,
        })),
      ],
    });
  });
}
