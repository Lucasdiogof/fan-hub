import type { SocialEnv } from './social/config';
import { handleStandings } from './football/standings';
import { handleCurrentRound } from './football/currentRound';
import { handleTeam } from './football/team';
import { handleTeamSeason } from './football/teamSeason';
import { handleFixtureDetails } from './football/fixtureDetails';
import { handleSocialFeed } from './social/feed';
import { handleNewsList } from './news/list';
import { handleNewsArticle } from './news/article';
import { syncInstagram } from './social/instagram_sync';
import { handleImageProxy } from './media/imageProxy';

const FIXTURE_DETAILS_PATTERN = /^\/api\/football\/fixtures\/([^/]+)\/?$/;
const NEWS_ARTICLE_PATTERN = /^\/api\/news\/([^/]+)\/?$/;
// M3.3 — rota genérica `/team/:clubCode(/season)`. `handleTeam`/
// `handleTeamSeason` resolvem `clubCode` via `resolveClubServerConfig`
// (`_lib/club_server_config.ts`) — código desconhecido nunca cai pro
// Goiás, vira 404 controlado (`UnknownClubError`, ver `handleErrors.ts`).
const TEAM_SEASON_PATTERN = /^\/api\/football\/team\/([^/]+)\/season\/?$/;
const TEAM_PATTERN = /^\/api\/football\/team\/([^/]+)\/?$/;

export default {
  async fetch(request: Request, env: SocialEnv, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;

    if (pathname === '/api/football/standings') {
      return handleStandings(request, env);
    }

    if (pathname === '/api/football/current-round') {
      return handleCurrentRound(request, env);
    }

    // `/team/goias`/`/team/goias/season` continuam funcionando pro app já
    // publicado — nunca uma rota especial separada, só o MESMO padrão
    // genérico resolvendo `clubCode='goias'` (M3.3). Season checado
    // primeiro: sua regex é mais específica (tem `/season` no fim), então
    // nunca conflita com `TEAM_PATTERN`, mas checar antes deixa a
    // intenção clara.
    const teamSeasonMatch = pathname.match(TEAM_SEASON_PATTERN);
    if (teamSeasonMatch) {
      return handleTeamSeason(request, env, decodeURIComponent(teamSeasonMatch[1]));
    }

    const teamMatch = pathname.match(TEAM_PATTERN);
    if (teamMatch) {
      return handleTeam(request, env, decodeURIComponent(teamMatch[1]));
    }

    const fixtureMatch = pathname.match(FIXTURE_DETAILS_PATTERN);
    if (fixtureMatch) {
      return handleFixtureDetails(request, env, decodeURIComponent(fixtureMatch[1]));
    }

    if (pathname === '/api/social/feed') {
      return handleSocialFeed(request, env);
    }

    // Sync manual do Instagram (só admin) — usado uma vez após o primeiro
    // deploy pra popular o KV antes do primeiro Cron. NUNCA é chamado pelo app.
    if (pathname === '/api/social/instagram/sync') {
      return handleInstagramAdminSync(request, env);
    }

    if (pathname === '/api/news') {
      return handleNewsList(request, env);
    }

    const newsArticleMatch = pathname.match(NEWS_ARTICLE_PATTERN);
    if (newsArticleMatch) {
      return handleNewsArticle(request, env, decodeURIComponent(newsArticleMatch[1]));
    }

    if (pathname === '/api/image-proxy') {
      return handleImageProxy(request, env);
    }

    return env.ASSETS.fetch(request);
  },

  /** Cron Trigger (a cada 8h — ver `crons` no wrangler.toml) — única fonte
   * automática de atualização do Instagram. Roda 3x/dia, independente de
   * acesso de usuário. */
  async scheduled(
    _controller: ScheduledController,
    env: SocialEnv,
    ctx: ExecutionContext,
  ): Promise<void> {
    ctx.waitUntil(syncInstagram(env));
  },
};

/** POST /api/social/instagram/sync com header `x-sync-key` = INSTAGRAM_SYNC_KEY.
 * Sem a secret configurada ou com chave errada, responde 404 (não vaza a rota). */
async function handleInstagramAdminSync(request: Request, env: SocialEnv): Promise<Response> {
  const notFound = new Response('Not found', { status: 404 });
  const key = env.INSTAGRAM_SYNC_KEY;
  if (!key || request.method !== 'POST' || request.headers.get('x-sync-key') !== key) {
    return notFound;
  }
  const outcome = await syncInstagram(env);
  return new Response(JSON.stringify(outcome), {
    headers: { 'content-type': 'application/json' },
  });
}
