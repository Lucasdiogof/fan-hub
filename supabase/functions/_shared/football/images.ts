// Materializa imagens de FUTEBOL (OneFootball, que não manda CORS) no Supabase
// Storage do clube e reescreve o payload pra URLs nossas. Três categorias, uma
// pasta cada no mesmo bucket: `teams/`, `competitions/`, `players/`.
// Chave do arquivo = sha256(URL normalizada, sem querystring/hash) -> nunca
// baixa a mesma imagem 2x, mesmo com querystring variável.
// Foto de jogador: UM download serve pra detectar a silhueta genérica
// (lineup_photos.ts) e pra salvar; silhueta NÃO vai pro Storage e o campo vira ''
// (o app já mostra o círculo com o número).
// Falha em qualquer imagem mantém a URL original: NUNCA derruba o refresh.
// Pure + deps injetáveis (fetch/storage) pra testar sem rede.
import { isPlaceholderPhoto } from './lineup_photos.ts';

export const IMAGE_BUCKET = 'football-images';
const ALLOWED_HOSTS = new Set(['images.onefootball.com']);
export type ImageCategory = 'teams' | 'competitions' | 'players';
// Ordem = prioridade quando o teto de downloads por execução estoura.
const CATEGORIES: [ImageCategory, RegExp][] = [
  ['teams', /^\/icons\/teams\//],
  ['competitions', /^\/icons\/leagueColoredCompetition\//],
  ['players', /^\/players\//],
];
const MAX_BYTES = 2 * 1024 * 1024;
// Teto GLOBAL de downloads novos por chamada (escudos + competição + jogadores).
// Um fixture com escalação cheia = ~44 fotos + ~3 escudos/ícones: 60 cobre uma
// execução normal; backfill grande vira várias execuções, nunca uma explosão.
const MAX_NEW_PER_RUN = 60;
const CONCURRENCY = 6;

export interface ImageStorage {
  exists(path: string): Promise<boolean>;
  upload(path: string, bytes: ArrayBuffer, contentType: string): Promise<void>;
}

export interface ImageDeps {
  fetch: typeof fetch;
  storage: ImageStorage;
  /** `${SUPABASE_URL}/storage/v1/object/public/football-images` */
  publicBase: string;
  /** Id OneFootball do próprio clube: o app já tem o escudo oficial local,
   * então esse não é baixado. */
  skipTeamId?: number;
}

/** Querystring/hash não mudam a identidade da imagem. */
export function normalizeImageUrl(value: string): string {
  const u = new URL(value);
  return `${u.origin}${u.pathname}`;
}

const isOwnCrest = (value: string, teamId?: number): boolean =>
  teamId !== undefined && new RegExp(`/${teamId}\\.[a-z0-9]+$`, 'i').test(new URL(value).pathname);

/** Categoria da imagem, ou `null` se não é imagem de futebol de host permitido. */
export function imageCategory(value: string): ImageCategory | null {
  if (!value.startsWith('https://')) return null;
  try {
    const u = new URL(value);
    if (!ALLOWED_HOSTS.has(u.host)) return null;
    return CATEGORIES.find(([, re]) => re.test(u.pathname))?.[0] ?? null;
  } catch {
    return null;
  }
}

/** Todas as URLs de imagem de futebol (host permitido) presentes no payload. */
export function collectImageUrls(payload: unknown, out = new Set<string>()): Set<string> {
  if (typeof payload === 'string') {
    if (imageCategory(payload)) out.add(payload);
  } else if (Array.isArray(payload)) {
    for (const item of payload) collectImageUrls(item, out);
  } else if (payload && typeof payload === 'object') {
    for (const value of Object.values(payload)) collectImageUrls(value, out);
  }
  return out;
}

async function fileName(url: string): Promise<string> {
  const normalized = normalizeImageUrl(url);
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(normalized));
  const hash = [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
  const ext = /\.(png|jpe?g|webp|svg|gif|avif)$/i.exec(new URL(normalized).pathname)?.[1]?.toLowerCase() ?? 'png';
  return `${hash}.${ext}`;
}

/** `<categoria>/<sha256>.<ext>` — categorias nunca colidem. */
export async function imagePath(url: string): Promise<string> {
  const category = imageCategory(url);
  if (!category) throw new Error('imagem fora do escopo');
  return `${category}/${await fileName(url)}`;
}

/** Reescreve toda string presente em [map]; o resto do payload fica intocado. */
export function rewriteImageUrls<T>(payload: T, map: Map<string, string>): T {
  const walk = (node: unknown): unknown => {
    if (typeof node === 'string') return map.get(node) ?? node;
    if (Array.isArray(node)) return node.map(walk);
    if (node && typeof node === 'object') {
      return Object.fromEntries(Object.entries(node).map(([k, v]) => [k, walk(v)]));
    }
    return node;
  };
  return walk(payload) as T;
}

const MARKER_TYPE = 'image/x-silhouette';
const markerPath = (name: string) => `markers/${name.split('.')[0]}.none`;

/** URL nova, '' (silhueta: sem foto) ou null (falhou: mantém a original). */
async function materializeOne(url: string, deps: ImageDeps, canDownload: () => boolean): Promise<string | null> {
  try {
    const category = imageCategory(url)!;
    const name = await fileName(url);
    const path = `${category}/${name}`;
    const ours = `${deps.publicBase}/${path}`;
    if (await deps.storage.exists(path)) return ours;
    // Escudos materializados antes das pastas ficam na raiz: reaproveita, sem baixar de novo.
    if (category === 'teams' && (await deps.storage.exists(name))) return `${deps.publicBase}/${name}`;
    if (category === 'players' && (await deps.storage.exists(markerPath(name)))) return '';
    if (!canDownload()) return null;
    const res = await deps.fetch(normalizeImageUrl(url), { headers: { accept: 'image/*' } });
    const type = res.headers.get('content-type') ?? '';
    if (!res.ok || !type.startsWith('image/')) return null;
    const bytes = await res.arrayBuffer();
    if (bytes.byteLength === 0 || bytes.byteLength > MAX_BYTES) return null;
    if (category === 'players' && (await isPlaceholderPhoto(bytes))) {
      // Cache negativo: marcador de 1 byte (não é foto, nada o referencia) evita
      // baixar a mesma silhueta a cada refresh. Falha ao gravar não é fatal.
      await deps.storage.upload(markerPath(name), new Uint8Array([48]).buffer, MARKER_TYPE).catch(() => {});
      return '';
    }
    await deps.storage.upload(path, bytes, type);
    return ours;
  } catch {
    return null;
  }
}

/** Devolve o payload com as imagens trocadas pelas URLs do Storage (as que
 * falharem, ou passarem do teto por execução, ficam com a URL original; foto
 * de silhueta vira ''). Variantes da mesma imagem (querystring) dividem um
 * único arquivo. Prioridade sob o teto: teams > competitions > players. */
export async function materializeImages<T>(payload: T, deps: ImageDeps): Promise<T> {
  const urls = [...collectImageUrls(payload)].filter((u) => !isOwnCrest(u, deps.skipTeamId));
  if (urls.length === 0) return payload;
  // Uma tentativa por imagem normalizada; todas as variantes recebem o resultado.
  const groups = new Map<string, string[]>();
  for (const url of urls) {
    const key = normalizeImageUrl(url);
    groups.set(key, [...(groups.get(key) ?? []), url]);
  }
  const rank = (normalized: string) => CATEGORIES.findIndex(([c]) => c === imageCategory(normalized));
  const map = new Map<string, string>();
  let downloads = 0;
  const canDownload = () => downloads++ < MAX_NEW_PER_RUN;
  const entries = [...groups.entries()].sort((a, b) => rank(a[0]) - rank(b[0]));
  for (let i = 0; i < entries.length; i += CONCURRENCY) {
    await Promise.all(
      entries.slice(i, i + CONCURRENCY).map(async ([normalized, variants]) => {
        const ours = await materializeOne(normalized, deps, canDownload);
        if (ours !== null) for (const v of variants) map.set(v, ours);
      }),
    );
  }
  return rewriteImageUrls(payload, map);
}
