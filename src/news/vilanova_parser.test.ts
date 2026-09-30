import { describe, expect, it } from 'vitest';
import { parseVilaNovaArticle, parseVilaNovaDate, parseVilaNovaNewsList, VILANOVA_SITE_ORIGIN } from './vilanova_parser';

// Trechos reais de vilanovafc.com.br (2026-09-30), só encurtados.
const LIST_HTML = `
<ul class="row j-center itensLoadMore">
  <li class="grid-4 box-news">
    <a href="/noticias/550-venda-de-ingressos-vila-nova-x-londrina-serie-b-2026" class="card-news">
      <div class="card-news_img">
        <img src="data:image/png;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=" data-src="/imgs/370/210/images/venda-de-ingressos-vila-nova-x-londrina-serie-b-2026-284.png" width="370" height="210" alt="VENDA DE INGRESSOS">
      </div>
      <div class="card-news_body">
        <span class="card-news_date">Postado em: 20/09/2026 às 09h25 </span>
        <h3 class="card-news_title"> VENDA DE INGRESSOS - VILA NOVA X LONDRINA - SÉRIE B 2026 </h3>
        <p>  </p>
      </div>
    </a>
  </li>
  <li class="grid-4 box-news">
    <a href="/noticias/549-venda-de-ingressos-vila-nova-x-america-mg-serie-b-2026" class="card-news">
      <div class="card-news_img">
        <img src="data:image/png;base64,R0lGOD" data-src="/imgs/370/210/images/america-283.png" width="370" height="210" alt="">
      </div>
      <div class="card-news_body">
        <span class="card-news_date">Postado em: 15/09/2026 às 08h23 </span>
        <h3 class="card-news_title"> VENDA DE INGRESSOS - VILA NOVA X AMÉRICA-MG - SÉRIE B 2026 </h3>
      </div>
    </a>
  </li>
  <li class="grid-4 box-news">
  </li>
</ul>
<script type="text/template" class="template templateNoticias">
  <a href="<%= itens[i].autoLink %>" class="card-news">
    <h3 class="card-news_title"> <%= itens[i].titulo %> </h3>
  </a>
</script>`;

const ARTICLE_HTML = `
<article class="news-details mt-40">
  <span class="news-details_date">Postado em: 05/09/2026 às 09h05 </span>
  <header>
    <h1 class="news-details_title"> VENDA DE INGRESSOS - VILA NOVA X GOIÁS - SÉRIE B 2026 </h1>
    <p class="news-details_author">Publicado por Matheus Alves, da Assessoria de Imprensa VNFC </p>
  </header>
  <figure class="news-details_img">
    <img src="data:image/png;base64,R0lGOD" data-src="/imgs/670/375/images/venda-543.png" width="670" height="375" alt="">
  </figure>
  <section class="box-retize"><div class='rtz-banner'></div></section>
  <div class="single-details"> <p><strong>VILA NOVA F.C. X GOIÁS – 27ª RODADA<br />
DATA: </strong>10 DE SETEMBRO DE 2026 (QUINTA-FEIRA)<br />
<strong>HORÁRIO: </strong>19h30</p>

<p>VENDAS ONLINE: Site - <strong><a href="https://www.ingressosa.com/10-09-vila-nova-x-goias-ec-brasileiro-serie-b-2026">https://www.ingressosa.com/10-09-vila-nova-x-goias-ec-brasileiro-serie-b-2026</a></strong></p>

<p><strong>#TIMEDOPOVO</strong></p>
 </div>
  <div class="news-share">
    <h6 class="news-share_title">Compartilhe</h6>
  </div>
  <span class="card-news_date"> Postado em: 20/09/2026 às 09h25 </span>
</article>`;

describe('parseVilaNovaDate', () => {
  it('converte o formato do site pra ISO', () => {
    expect(parseVilaNovaDate('Postado em: 20/09/2026 às 09h25 ')).toBe('2026-09-20');
  });

  it('devolve null quando não reconhece, nunca inventa', () => {
    expect(parseVilaNovaDate('ontem')).toBeNull();
    expect(parseVilaNovaDate('40/13/2026')).toBeNull();
  });
});

describe('parseVilaNovaNewsList', () => {
  const items = parseVilaNovaNewsList(LIST_HTML, VILANOVA_SITE_ORIGIN);

  it('lê os cards renderizados no servidor e ignora o template do "Carregar Mais"', () => {
    expect(items.map((i) => i.id)).toEqual([
      '550-venda-de-ingressos-vila-nova-x-londrina-serie-b-2026',
      '549-venda-de-ingressos-vila-nova-x-america-mg-serie-b-2026',
    ]);
  });

  it('usa o data-src (lazy-load) como imagem, absoluta, nunca o GIF placeholder', () => {
    expect(items[0].imageUrl).toBe(
      'https://www.vilanovafc.com.br/imgs/370/210/images/venda-de-ingressos-vila-nova-x-londrina-serie-b-2026-284.png',
    );
  });

  it('título, data, URL absoluta e categoria vazia (o site não publica)', () => {
    expect(items[1]).toMatchObject({
      title: 'VENDA DE INGRESSOS - VILA NOVA X AMÉRICA-MG - SÉRIE B 2026',
      publishedAt: '2026-09-15',
      category: '',
      url: 'https://www.vilanovafc.com.br/noticias/549-venda-de-ingressos-vila-nova-x-america-mg-serie-b-2026',
    });
  });
});

describe('parseVilaNovaArticle', () => {
  const pageUrl = 'https://www.vilanovafc.com.br/noticias/548-venda-de-ingressos-vila-nova-x-goias-serie-b-2026';
  const article = parseVilaNovaArticle(ARTICLE_HTML, pageUrl, VILANOVA_SITE_ORIGIN);

  it('extrai título, data da própria notícia (não das relacionadas) e imagem', () => {
    expect(article).not.toBeNull();
    expect(article!.title).toBe('VENDA DE INGRESSOS - VILA NOVA X GOIÁS - SÉRIE B 2026');
    expect(article!.publishedAt).toBe('2026-09-05');
    expect(article!.imageUrl).toBe('https://www.vilanovafc.com.br/imgs/670/375/images/venda-543.png');
    expect(article!.id).toBe('548-venda-de-ingressos-vila-nova-x-goias-serie-b-2026');
  });

  it('corpo: <br> separa parágrafos, <a> vira bloco de link, nada do rodapé de compartilhar', () => {
    expect(article!.content).toEqual([
      { type: 'paragraph', text: 'VILA NOVA F.C. X GOIÁS – 27ª RODADA' },
      { type: 'paragraph', text: 'DATA: 10 DE SETEMBRO DE 2026 (QUINTA-FEIRA)' },
      { type: 'paragraph', text: 'HORÁRIO: 19h30' },
      { type: 'paragraph', text: 'VENDAS ONLINE: Site -' },
      {
        type: 'link',
        text: 'https://www.ingressosa.com/10-09-vila-nova-x-goias-ec-brasileiro-serie-b-2026',
        url: 'https://www.ingressosa.com/10-09-vila-nova-x-goias-ec-brasileiro-serie-b-2026',
      },
      { type: 'paragraph', text: '#TIMEDOPOVO' },
    ]);
  });

  it('devolve null sem título ou sem corpo (o app cai pro link externo)', () => {
    expect(parseVilaNovaArticle('<html></html>', pageUrl, VILANOVA_SITE_ORIGIN)).toBeNull();
    expect(
      parseVilaNovaArticle(ARTICLE_HTML.replace('single-details', 'outra-coisa'), pageUrl, VILANOVA_SITE_ORIGIN),
    ).toBeNull();
  });
});
