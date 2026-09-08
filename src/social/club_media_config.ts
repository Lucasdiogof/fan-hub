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

/** Qual parser de notícias usar — o HTML de cada site é diferente. */
export type NewsParserId = 'goias';

/** Qual arquivo de dados do X carregar (bundle estático por clube). */
export type XDataFileId = 'goias';

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
  /** Handle público do canal (ex.: `@TVGoias`). Não é secret. */
  channelHandle: string;
  authorName: string;
  authorHandle: string;
}

export interface ClubInstagramConfig {
  /** Chave do Workers KV onde o Cron deste deploy grava/lê. Não é secret. */
  kvKey: string;
}

export interface ClubXConfig {
  dataFile: XDataFileId;
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

  // Bragantino: TODAS as fontes reais são WAITING_EXTERNAL_CONFIG — nada é
  // inventado aqui (fonte de notícias oficial não determinada com segurança,
  // canal do YouTube não confirmado, handle do X sem pipeline). Só o Instagram
  // tem a CHAVE de KV estruturada (não é secret e não é dado) pra o Cron do
  // deploy do Bragantino escrever no namespace DELE quando a Apify task for
  // configurada (WAITING_EXTERNAL_TASK_CONFIG). Enquanto não houver dado, o KV
  // fica vazio -> provider devolve `[]`, sem cross-club.
  bragantino: {
    code: 'bragantino',
    instagram: { kvKey: instagramKvKey('bragantino') },
  },
};

/** Config de Mídia do clube deste deploy — `null` pra clube sem entrada
 * (nunca cai pro Goiás). */
export function clubMediaConfig(clubCode: string): ClubMediaConfig | null {
  return CLUB_MEDIA_CONFIG[clubCode] ?? null;
}
