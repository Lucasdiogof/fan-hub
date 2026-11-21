// Handler puro do `news-article` (deps injetadas -> testável sem Deno).
// Exige sessão de usuário: `Authorization: Bearer <access_token>` validado pelo
// Supabase Auth. A publishable key não é prova de identidade (não é um token de
// usuário, então o Auth a recusa) e service role vinda do cliente também não passa.
import type { ClubServerConfig } from '../club_server_config.ts';
import type { ImageDeps } from '../football/images.ts';
import { extractBearerToken } from '../service_caller_auth.ts';
import { getNewsArticle } from './article.ts';
import type { NewsItem } from './types.ts';

export interface NewsArticleHandlerDeps {
  /** true só se o token é de um usuário autenticado válido. */
  verifyUser: (accessToken: string) => Promise<boolean>;
  /** Clubes deste projeto que têm fonte de notícias. */
  clubs: () => Promise<ClubServerConfig[]>;
  readList: (clubId: string) => Promise<NewsItem[] | null>;
  images: ImageDeps | null;
  fetch: typeof fetch;
}

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });
const unavailable = () => json({ available: false, url: null });

export async function handleNewsArticle(req: Request, deps: NewsArticleHandlerDeps): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const token = extractBearerToken(req.headers.get('authorization'));
  let authed = false;
  try {
    authed = token !== null && (await deps.verifyUser(token));
  } catch {
    authed = false;
  }
  if (!authed) return json({ error: 'unauthorized' }, 401);

  try {
    const body = (await req.json().catch(() => ({}))) as { id?: unknown; club?: unknown };
    if (typeof body.id !== 'string' || body.id.length === 0 || body.id.length > 300) return unavailable();
    // Clube do PROJETO; `club` do cliente só pode confirmar, nunca escolher outro.
    const club = (await deps.clubs()).find((c) => c.news && (body.club === undefined || body.club === c.code));
    if (!club?.news) return unavailable();
    const list = await deps.readList(club.canonicalClubId);
    return json(await getNewsArticle(club.news, body.id, list, deps.fetch, deps.images));
  } catch (err) {
    console.error('news-article', err instanceof Error ? err.message : String(err));
    return unavailable();
  }
}
