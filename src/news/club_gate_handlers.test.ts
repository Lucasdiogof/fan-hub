import { describe, expect, it } from 'vitest';
import { handleNewsList } from './list';
import { handleNewsArticle } from './article';
import { handleSocialFeed } from '../social/feed';
import type { Env } from '../football/_lib/config';
import type { SocialEnv } from '../social/config';

// Gate de clube (achado crítico M4): as 3 rotas devolvem "unavailable"
// ANTES de qualquer fetch/cache pro site do Goiás — por isso um `env`
// mínimo (sem KV real) já basta pra provar o short-circuit. `club-b` é
// SEMPRE sintético, nunca cadastrado em SERVER_CLUB_CODES/registry real.
const fakeEnv = {} as Env;
const fakeSocialEnv = {} as SocialEnv;

describe('News/Social club gate — clubB sintético nunca vê conteúdo do Goiás (achado crítico M4)', () => {
  it('handleNewsList com ?club=club-b -> 404 unavailable, nunca a lista real do Goiás', async () => {
    const request = new Request('https://example.com/api/news?club=club-b');
    const response = await handleNewsList(request, fakeEnv);
    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body).toEqual({ items: [], available: false });
  });

  it('handleNewsList sem ?club= continua servindo o Goiás normalmente (compat) — não passa pelo gate, chega no fetch real', async () => {
    const request = new Request('https://example.com/api/news');
    // Sem mock de fetch/KV aqui de propósito: só provamos que o gate NÃO
    // interceptou (não devolveu o corpo `{ items: [], available: false }`
    // sincronamente) — a chamada real de rede pode falhar neste ambiente
    // de teste, o que é esperado e não é o que este teste verifica.
    const response = await handleNewsList(request, fakeEnv).catch(() => null);
    if (response) {
      const body = await response.json().catch(() => null);
      expect(body).not.toEqual({ items: [], available: false });
    }
  });

  it('handleNewsArticle com ?club=club-b -> 404 unavailable, url null (nunca a URL real do site do Goiás)', async () => {
    const request = new Request('https://example.com/api/news/alguma-noticia?club=club-b');
    const response = await handleNewsArticle(request, fakeEnv, 'alguma-noticia');
    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body).toEqual({ available: false, url: null });
  });

  it('handleSocialFeed com ?club=club-b -> 404 unavailable, feed vazio, nunca posts do Goiás', async () => {
    const request = new Request('https://example.com/api/social/feed?club=club-b');
    const response = await handleSocialFeed(request, fakeSocialEnv);
    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body).toEqual({ posts: [], available: false });
  });

  it('FABRICADO: ?club=goias explícito passa pelo gate igual ausência de ?club= (mesmo código de qualquer forma)', async () => {
    const withClub = new Request('https://example.com/api/news/x?club=goias');
    const withoutClub = new Request('https://example.com/api/news/x');
    const responseWithClub = await handleNewsArticle(withClub, fakeEnv, 'x').catch(() => null);
    const responseWithoutClub = await handleNewsArticle(withoutClub, fakeEnv, 'x').catch(() => null);
    // Nenhum dos dois deveria ser interceptado pelo gate (404 unavailable) —
    // se falhar depois disso é por causa da chamada de rede real, não do gate.
    if (responseWithClub) expect(responseWithClub.status).not.toBe(404);
    if (responseWithoutClub) expect(responseWithoutClub.status).not.toBe(404);
  });
});
