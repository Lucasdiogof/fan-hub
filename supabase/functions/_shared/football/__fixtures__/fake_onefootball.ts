// Fetch falso do OneFootball: serve as páginas capturadas em 2026-11-20
// (`onefootball_pages_2026-11-20.json`, chave = path depois de /web-experience/pt-br/).
// Caminho ausente -> 404 (comportamento real pra jogos sem dado).
import pages from './onefootball_pages_2026-11-20.json';

const BASE = 'https://api.onefootball.com/web-experience/pt-br/';
type Pages = Record<string, unknown>;

export const PAGES = pages as Pages;

/** `mutate` deixa o teste alterar uma cópia da página (cenários SINTÉTICOS:
 * ao vivo, intervalo, adiado... não existem no snapshot real de 20/11). */
export function fakeFetch(mutate?: (path: string, body: unknown) => unknown): typeof fetch {
  return (async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    if (!url.startsWith(BASE)) return new Response('not found', { status: 404 });
    const path = url.slice(BASE.length);
    const page = PAGES[path];
    if (page === undefined) return new Response('not found', { status: 404 });
    const body = mutate ? mutate(path, structuredClone(page)) : page;
    return new Response(JSON.stringify(body), { headers: { 'content-type': 'application/json' } });
  }) as typeof fetch;
}

/** Aplica [fn] a todo objeto da árvore (usado pra trocar `period` etc.). */
export function visitAll(node: unknown, fn: (obj: Record<string, unknown>) => void): void {
  if (Array.isArray(node)) node.forEach((n) => visitAll(n, fn));
  else if (node && typeof node === 'object') {
    fn(node as Record<string, unknown>);
    Object.values(node).forEach((n) => visitAll(n, fn));
  }
}
