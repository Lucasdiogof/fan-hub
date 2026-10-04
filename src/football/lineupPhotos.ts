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

// Cada fetch é um subrequest (limite de 50 por invocação no plano gratuito,
// e a Cache API também conta). Por isso: 1 fetch por foto única, o cache fica
// por conta da borda da Cloudflare (`cf`) e há um teto — acima dele as fotos
// excedentes ficam como vieram (nunca estourar o limite e derrubar o detalhe).
const EDGE_TTL_SECONDS = 60 * 60 * 24;
const MAX_CHECKS = 36;

async function sha1Prefix(bytes: ArrayBuffer): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-1', bytes);
  return [...new Uint8Array(digest)]
    .slice(0, 4)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** Só `true` quando a imagem é COMPROVADAMENTE a silhueta. Qualquer dúvida
 * (erro de rede, status != 200, host desconhecido) mantém a foto: pior caso
 * é mostrar o que mostrávamos antes. */
export async function isPlaceholderPhoto(url: string): Promise<boolean> {
  if (!url.startsWith(PLAYER_PHOTO_PREFIX)) return false;
  try {
    const response = await fetch(url, {
      headers: { accept: 'image/*' },
      cf: { cacheEverything: true, cacheTtl: EDGE_TTL_SECONDS },
    });
    if (response.status !== 200) return false;
    const bytes = await response.arrayBuffer();
    return bytes.byteLength === PLACEHOLDER_BYTES && (await sha1Prefix(bytes)) === PLACEHOLDER_SHA1;
  } catch {
    return false;
  }
}

/** Troca por `''` a foto de quem só tem a silhueta — o Flutter já trata
 * `photo` vazio com o círculo de número. */
export async function stripPlaceholderPhotos(lineups: MatchLineupsJson): Promise<MatchLineupsJson> {
  const urls = new Set<string>();
  for (const team of [lineups.home, lineups.away]) {
    for (const player of team.rows.flat()) if (player.photo) urls.add(player.photo);
  }
  const toCheck = [...urls].slice(0, MAX_CHECKS);
  const verdicts = new Map<string, boolean>(
    await Promise.all(toCheck.map(async (url): Promise<[string, boolean]> => [url, await isPlaceholderPhoto(url)])),
  );
  const clean = (team: TeamLineupJson): TeamLineupJson => ({
    ...team,
    rows: team.rows.map((row) =>
      row.map((player) => (verdicts.get(player.photo) ? { ...player, photo: '' } : player)),
    ),
  });
  return { home: clean(lineups.home), away: clean(lineups.away) };
}
