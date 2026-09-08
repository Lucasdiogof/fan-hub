import { describe, expect, it } from 'vitest';
import { parseNewsList } from './parsers';

// Fixture mínima no formato do site do Goiás (Next.js: `<article>` com
// `article > a` envolvendo a imagem, título em `<h2>`, categoria em
// `a[href*="/categorias/"]`).
const GOIAS_LIST_FIXTURE = `
<main>
  <article>
    <a href="/noticias/vitoria-importante"><img src="/img/1.jpg" /></a>
    <div>
      <a href="/categorias/futebol">Futebol</a>
      <h2>Vitória importante</h2>
      <time>26 de agosto de 2026</time>
    </div>
  </article>
</main>`;

describe('parseNewsList — parser goias + siteOrigin parametrizado (não mais hardcoded)', () => {
  it('extrai a notícia (id/título/categoria) do HTML do Goiás', async () => {
    const items = await parseNewsList(GOIAS_LIST_FIXTURE, 'goias', 'https://www.goiasec.com.br');
    expect(items).toHaveLength(1);
    expect(items[0].id).toBe('vitoria-importante');
    expect(items[0].title).toBe('Vitória importante');
    expect(items[0].category).toBe('Futebol');
  });

  it('resolve URL relativa com o siteOrigin RECEBIDO — não um goiasec cravado', async () => {
    const goias = await parseNewsList(GOIAS_LIST_FIXTURE, 'goias', 'https://www.goiasec.com.br');
    expect(goias[0].url).toBe('https://www.goiasec.com.br/noticias/vitoria-importante');

    // Mesmo parser, outra origem -> a URL segue a origem passada, provando que
    // o `siteOrigin` deixou de ser hardcoded (é o que permite um clube futuro
    // reusar a mecânica sem herdar o domínio do Goiás).
    const outro = await parseNewsList(GOIAS_LIST_FIXTURE, 'goias', 'https://exemplo.test');
    expect(outro[0].url).toBe('https://exemplo.test/noticias/vitoria-importante');
  });
});
