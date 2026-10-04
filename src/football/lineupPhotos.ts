import type { MatchLineupsJson, TeamLineupJson } from './normalize/match_lineup';

/**
 * O OneFootball devolve `image.path` para TODO jogador, mas quem não tem foto
 * cadastrada recebe, nessa mesma URL (HTTP 200, `image/png` mesmo com
 * extensão `.jpg`), uma silhueta genérica: círculo preto com um boneco,
 * 6004 bytes, SHA-1 abaixo. Medido em 2026-10: 77 de 176 titulares em 8
 * partidas. Sem detectar isso, o app mostra a silhueta como se fosse foto
 * e o fallback com número (que é mais legível) nunca dispara.
 */
export const PLACEHOLDER_SHA1 = '6c00c23b';
const PLACEHOLDER_BYTES = 6004;
const PLAYER_PHOTO_PREFIX = 'https://images.onefootball.com/players/';

// Foto de jogador quase nunca muda; quem ganha foto nova aparece em até 1 dia.
const VERDICT_TTL_SECONDS = 60 * 60 * 24;

async function sha1Prefix(bytes: ArrayBuffer): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-1', bytes);
  return [...new Uint8Array(digest)]
    .slice(0, 4)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** Só `true` quando a imagem é COMPROVADAMENTE a silhueta. Qualquer dúvida
 * (erro de rede, status != 200, host desconhecido) mantém a foto: pior caso
 * é mostrar o que mostrávamos antes. Dúvida não é cacheada. */
export async function isPlaceholderPhoto(url: string): Promise<boolean> {
  if (!url.startsWith(PLAYER_PHOTO_PREFIX)) return false;

  const cache = (caches as unknown as { default: Cache }).default;
  const cacheKey = new Request(`https://photo-verdict.internal/?u=${encodeURIComponent(url)}`);
  const cached = await cache.match(cacheKey);
  if (cached) return (await cached.text()) === '1';

  let verdict: boolean;
  try {
    const response = await fetch(url, { headers: { accept: 'image/*' } });
    if (response.status !== 200) return false;
    const bytes = await response.arrayBuffer();
    verdict = bytes.byteLength === PLACEHOLDER_BYTES && (await sha1Prefix(bytes)) === PLACEHOLDER_SHA1;
  } catch {
    return false;
  }

  await cache.put(
    cacheKey,
    new Response(verdict ? '1' : '0', { headers: { 'cache-control': `public, max-age=${VERDICT_TTL_SECONDS}` } }),
  );
  return verdict;
}

async function stripTeam(team: TeamLineupJson): Promise<TeamLineupJson> {
  const rows = await Promise.all(
    team.rows.map((row) =>
      Promise.all(
        row.map(async (player) =>
          player.photo && (await isPlaceholderPhoto(player.photo)) ? { ...player, photo: '' } : player,
        ),
      ),
    ),
  );
  return { ...team, rows };
}

/** Troca por `''` a foto de quem só tem a silhueta — o Flutter já trata
 * `photo` vazio com o círculo de número. */
export async function stripPlaceholderPhotos(lineups: MatchLineupsJson): Promise<MatchLineupsJson> {
  const [home, away] = await Promise.all([stripTeam(lineups.home), stripTeam(lineups.away)]);
  return { home, away };
}
