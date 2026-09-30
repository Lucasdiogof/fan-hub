// Configuração de Mídia (Notícias + redes sociais) POR CLUBE, resolvida
// centralmente pelo `clubCode`. Substitui os hardcodes de Goiás que estavam
// espalhados (URL do site, `@TVGoias`, chave de KV `instagram:goias:latest`,
// arquivo do X, fallbacks `goiasoficial`).
//
// REGRAS (as mesmas do resto do Worker multiclube):
//  - nada de `if (club === 'goias')` espalhado — tudo sai daqui;
//  - clube sem entrada -> `null` (feed vazio/capability off), NUNCA fallback
//    pro Goiás;
//  - ausência de uma fonte específica (ex.: `news` undefined) -> aquela fonte
//    fica indisponível, sem derrubar as outras;
//  - NENHUM secret aqui (token do Apify, API key do YouTube seguem em
//    env/wrangler secrets). Só o que é público/estrutural: URL do site,
//    handle público do canal, NOME da chave de KV (não é secret), seletor do
//    arquivo de dados do X.
//
// Este é um deploy-por-clube (cada Worker carrega seu `CLUB_CODE`), então o
// handler resolve sempre `clubMediaConfig(env.CLUB_CODE)` — a config do
// PRÓPRIO clube do deploy.

import { xKvKey } from './x_sync';

/** Qual parser de notícias usar — cada site tem sua própria fonte/formato
 * (o Goiás raspa HTML; o Bragantino é uma SPA sem HTML raspável e consome
 * uma API JSON interna pública, ver `news/bragantino_parser.ts`). */
export type NewsParserId = 'goias' | 'bragantino' | 'vilanova';

/** Qual arquivo de dados do X carregar (bundle estático por clube). */
export type XDataFileId = 'goias' | 'bragantino';

export interface ClubNewsConfig {
  /** Página de listagem raspada. */
  sourceUrl: string;
  /** Origem pra resolver URLs relativas + montar a URL de artigo. */
  siteOrigin: string;
  /** Artigo individual: `${siteOrigin}${articlePathPrefix}/${slug}`. */
  articlePathPrefix: string;
  parser: NewsParserId;
}

export interface ClubYouTubeConfig {
  /** Handle público do canal (ex.: `@TVGoias`) — metadata/config, nunca
   * usado sozinho pra decisão de identidade. Não é secret. */
  channelHandle: string;
  /** Id canônico do canal (`UC...`, nunca muda — ao contrário do handle,
   * que pode ser renomeado). OPCIONAL: quando presente, o provider resolve
   * a playlist de uploads por id (`channels?id=`, mais robusto); quando
   * ausente, cai pro lookup por handle (`channels?forHandle=`, o
   * comportamento de sempre — nunca alterado pra quem já está em produção
   * sem essa config). Nunca inventar: só popular com um id confirmado
   * navegando o canal de verdade. */
  channelId?: string;
  authorName: string;
  authorHandle: string;
}

export interface ClubInstagramConfig {
  /** Chave do Workers KV onde o Cron deste deploy grava/lê. Não é secret. */
  kvKey: string;
  /** Identidade a estampar em CADA post normalizado, substituindo
   * `ownerFullName`/`ownerUsername` crus do Apify — necessário porque a
   * Task raspa o GRID do perfil-alvo, que inclui posts colaborativos
   * (Instagram "collab post") onde o dado bruto do Apify aponta o OUTRO
   * parceiro do post (ex.: patrocinador, Red Bull Brasil) como "owner",
   * mesmo o post aparecendo no grid oficial do clube. OPCIONAL: ausente
   * (caso do Goiás, nunca alterado) preserva o comportamento de sempre —
   * author/username crus do Apify, byte a byte. Só populado quando a Task
   * deste clube é conhecida por trazer posts colaborativos (Bragantino,
   * 2026-09-08). */
  authorName?: string;
  authorHandle?: string;
}

/** Exatamente UMA fonte: `dataFile` (bundle estático commitado — Goiás,
 * Bragantino) OU `kvKey` (Workers KV alimentado pela rota admin
 * `POST /api/social/x/sync` — Vila Nova, ver `x_sync.ts`). */
export interface ClubXConfig {
  dataFile?: XDataFileId;
  kvKey?: string;
  /** Handle oficial (sem @). Com `kvKey`, a rota de sync só aceita posts
   * desta conta. */
  handle?: string;
}

export interface ClubMediaConfig {
  code: string;
  news?: ClubNewsConfig;
  youtube?: ClubYouTubeConfig;
  instagram?: ClubInstagramConfig;
  x?: ClubXConfig;
}

/** Nome da chave de KV do Instagram por clube — `instagram:<code>:latest`.
 * Fonte única, usada pelo Cron (escrita) e pelo provider (leitura), pra
 * o deploy de um clube NUNCA tocar a chave de outro. */
export function instagramKvKey(clubCode: string): string {
  return `instagram:${clubCode}:latest`;
}

export const CLUB_MEDIA_CONFIG: Record<string, ClubMediaConfig> = {
  goias: {
    code: 'goias',
    news: {
      sourceUrl: 'https://www.goiasec.com.br/noticias',
      siteOrigin: 'https://www.goiasec.com.br',
      articlePathPrefix: '/noticias',
      parser: 'goias',
    },
    youtube: {
      channelHandle: '@TVGoias',
      authorName: 'TV Goiás',
      authorHandle: 'TVGoias',
    },
    instagram: { kvKey: instagramKvKey('goias') },
    x: { dataFile: 'goias' },
  },

  // Bragantino: notícias confirmadas em 2026-09-08 (API JSON interna da SPA
  // oficial, sem chave — ver `news/bragantino_parser.ts`); YouTube confirmado
  // em 2026-09-08 (canal oficial dado pelo usuário, `@MassaBrutaTV` — id e
  // metadados abaixo verificados navegando `youtube.com/@MassaBrutaTV`, nunca
  // inventados). X confirmado em 2026-09-08: handle `RedBullBraga`
  // triangulado por duas fontes oficiais independentes (a página "Sobre" do
  // canal oficial do YouTube lista `twitter.com/RedBullBraga` entre os
  // links do canal; o próprio perfil se declara "Perfil oficial do Red Bull
  // Bragantino", localização e link de site batendo com o oficial) — nunca
  // as fan pages/contas antigas que aparecem numa busca qualquer
  // (`@bragabull`, `@rbbragainfo`, `@BragantinoRed`). 20 posts reais
  // coletados pelo mesmo pipeline do Goiás (`sync_x_posts.py --club
  // bragantino`), auditados individualmente antes de entrar aqui.
  // Instagram só tem a CHAVE de KV estruturada (não é secret e não é dado)
  // pra o Cron do deploy do Bragantino escrever no namespace DELE quando a
  // Apify task for configurada (WAITING_EXTERNAL_TASK_CONFIG). Enquanto não
  // houver dado, o KV fica vazio -> provider devolve `[]`, sem cross-club.
  bragantino: {
    code: 'bragantino',
    news: {
      // Já é a URL completa da API (feed "stories" ordenado por frescor, no
      // schema `structuredData` — schema.org/NewsArticle pronto: título,
      // resumo, imagem, data, URL do artigo, tudo numa chamada só). Nunca a
      // URL humana da SPA (`/br-pt/noticias`), que não tem HTML raspável.
      sourceUrl:
        'https://www.redbullbragantino.com/v3/api/graphql/v1/v3/feed/pt-BR' +
        '?filter[type]=stories&scoring=freshness&rb3Schema=v1:structuredData' +
        '&rb3Locale=br-pt&page[limit]=20&disableUsageRestrictions=true',
      siteOrigin: 'https://www.redbullbragantino.com',
      articlePathPrefix: '/br-pt/noticias',
      parser: 'bragantino',
    },
    youtube: {
      channelHandle: '@MassaBrutaTV',
      // Confirmado via `<link rel="canonical">` +
      // `channelMetadataRenderer.externalId` da própria página do canal —
      // `vanityChannelUrl` bate exatamente com `@MassaBrutaTV`.
      channelId: 'UC0x9Ypk2Z1lUdR4a88jMC2Q',
      // Nome de exibição registrado é "Massa Bruta TV | Red Bull Bragantino"
      // (confirmado em `channelMetadataRenderer.title`) — `authorName` usa só
      // a parte curta/humana, mesmo critério já aplicado ao Goiás (canal
      // registrado como "Goiás Esporte Clube", `authorName` é "TV Goiás").
      authorName: 'Massa Bruta TV',
      authorHandle: 'MassaBrutaTV',
    },
    // Conta oficial confirmada em 2026-09-08 (username `redbullbragantino`
    // — mesma checagem cruzada do X: config `social-follow-panel` do
    // próprio site oficial + perfil verificado, bio "Perfil oficial do Red
    // Bull Bragantino"). Task Apify dedicada
    // `rb-bragantino-instagram-latest` (`APIFY_INSTAGRAM_TASK_ID` em
    // `wrangler.bragantino.toml`) raspa o grid desse perfil; posts
    // colaborativos nele (Puma Brasil, Red Bull Brasil) vêm com o
    // `ownerUsername` cru apontando pro OUTRO parceiro — daí precisar do
    // override abaixo (ver doc em `ClubInstagramConfig`).
    instagram: {
      kvKey: instagramKvKey('bragantino'),
      authorName: 'Red Bull Bragantino',
      authorHandle: 'redbullbragantino',
    },
    x: { dataFile: 'bragantino' },
  },

  // Vila Nova: notícias confirmadas em 2026-09-30 (HTML renderizado no
  // servidor pelo CMS do site oficial, ver `news/vilanova_parser.ts`).
  // YouTube, Instagram e X ainda não: sem fonte configurada neste deploy
  // (Instagram depende de cron, e a conta Cloudflare já usa os 5 do plano
  // Free) — cada fonte ausente fica indisponível, nunca cai pra outro clube.
  vilanova: {
    code: 'vilanova',
    news: {
      sourceUrl: 'https://www.vilanovafc.com.br/noticias',
      siteOrigin: 'https://www.vilanovafc.com.br',
      articlePathPrefix: '/noticias',
      parser: 'vilanova',
    },
    // Contas oficiais listadas no rodapé de vilanovafc.com.br (2026-09-30):
    // youtube.com/vilanovafcoficial, instagram.com/vilanovafc e
    // twitter.com/vilanovafc.
    youtube: {
      // `youtube.com/vilanovafcoficial` resolve pro canal "TigrãoTV"
      // (`<link rel="canonical">` + `externalId` da própria página). Só
      // entra no feed quando o deploy tiver `YOUTUBE_API_KEY` (secret).
      channelHandle: '@TigrãoTV-u8h',
      channelId: 'UCyzEjyFAs3vIrqIm_i0RB8g',
      authorName: 'TigrãoTV',
      authorHandle: 'vilanovafcoficial',
    },
    // Sem cron (a conta Free já usa os 5): o KV é atualizado pelo GitHub
    // Action chamando `POST /api/social/instagram/sync` (INSTAGRAM_SYNC_KEY).
    // Enquanto a Task do Apify não existir, o KV fica vazio -> `[]`.
    instagram: {
      kvKey: instagramKvKey('vilanova'),
      authorName: 'Vila Nova F.C.',
      authorHandle: 'vilanovafc',
    },
    x: { kvKey: xKvKey('vilanova'), handle: 'vilanovafc' },
  },
};

/** Config de Mídia do clube deste deploy — `null` pra clube sem entrada
 * (nunca cai pro Goiás). */
export function clubMediaConfig(clubCode: string): ClubMediaConfig | null {
  return CLUB_MEDIA_CONFIG[clubCode] ?? null;
}
