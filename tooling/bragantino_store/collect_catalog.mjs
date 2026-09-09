// Coleta o catálogo REAL do Red Bull Bragantino na Red Bull Shop
// (redbullshop.com.br), via a mesma API GraphQL/VTEX que o storefront usa —
// nunca chamado pelo app em runtime, só para gerar o fixture local
// (lib/assets/content/bragantino/store_products.json). Ver auditoria no
// header do JSON gerado / relatório final da sessão.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'lib', 'assets', 'content', 'bragantino');
const RAW_DIR = path.join(__dirname, 'raw');

const BASE = 'https://www.redbullshop.com.br';
const CHANNEL = '{"salesChannel":"5","regionId":""}';
const MANY_PRODUCTS_HASH = 'b21dd1ccfa0a8fb6473297e28a922996477a3898';

async function fetchJson(url) {
  const res = await fetch(url, { headers: { 'user-agent': 'Mozilla/5.0' } });
  if (!res.ok) throw new Error(`${res.status} ${url}`);
  return res.json();
}

async function searchPage(after) {
  const variables = {
    first: 100, after: String(after), sort: 'score_desc', term: 'Red Bull Bragantino',
    selectedFacets: [
      { key: 'channel', value: CHANNEL },
      { key: 'locale', value: 'pt-BR' },
    ],
    sponsoredCount: 0,
  };
  const url = `${BASE}/api/graphql?operationName=ClientManyProductsQuery&operationHash=${MANY_PRODUCTS_HASH}&variables=${encodeURIComponent(JSON.stringify(variables))}`;
  const data = await fetchJson(url);
  return data.data.search.products;
}

async function fetchAllSearchNodes() {
  const first = await searchPage(0);
  const total = first.pageInfo.totalCount;
  let nodes = first.edges.map(e => e.node);
  let after = 100;
  while (nodes.length < total) {
    const page = await searchPage(after);
    nodes = nodes.concat(page.edges.map(e => e.node));
    after += 100;
  }
  return { nodes, total };
}

// Descobre o buildId atual do Next.js olhando a home (evita cravar um id
// fixo que expira quando a loja republica).
async function discoverBuildId() {
  const res = await fetch(`${BASE}/`, { headers: { 'user-agent': 'Mozilla/5.0' } });
  const html = await res.text();
  const m = html.match(/"buildId":"([^"]+)"/);
  if (!m) throw new Error('buildId não encontrado no HTML da home');
  return m[1];
}

async function fetchPdp(buildId, slug) {
  const url = `${BASE}/_next/data/${buildId}/pt-BR/${slug}/p.json?slug=${slug}`;
  const data = await fetchJson(url);
  return data.pageProps.data.product;
}

async function fetchAllPdps(buildId, slugs) {
  const results = [];
  const errors = [];
  const chunkSize = 10;
  for (let i = 0; i < slugs.length; i += chunkSize) {
    const chunk = slugs.slice(i, i + chunkSize);
    const settled = await Promise.allSettled(chunk.map(s => fetchPdp(buildId, s)));
    settled.forEach((r, idx) => {
      if (r.status === 'fulfilled') results.push(r.value);
      else errors.push({ slug: chunk[idx], error: String(r.reason) });
    });
  }
  return { results, errors };
}

function stripHtml(html) {
  return (html || '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/\n{2,}/g, '\n')
    .trim();
}

function classify(name, breadcrumbNames) {
  const n = name.toUpperCase();
  const bc = breadcrumbNames.join(' > ').toUpperCase();
  const isGoleiro = n.includes('GOLEIRO');
  const isFutebol = bc.includes('FUTEBOL') || n.includes('CAMISA') || n.includes('CALÇÃO') || n.includes('MEIÃO');
  let productType, categoryIds = [], collectionIds = [];
  if (isGoleiro) { productType = 'goalkeeper'; categoryIds.push('uniforms'); collectionIds.push('goalkeeper'); }
  else if (n.includes('TREINO')) { productType = 'training'; categoryIds.push('training'); }
  else if (n.includes('CAMISA') && isFutebol) { productType = 'matchJersey'; categoryIds.push('uniforms'); collectionIds.push('fan'); }
  else if (n.includes('CALÇÃO') || n.includes('MEIÃO')) { productType = 'matchJersey'; categoryIds.push('uniforms'); }
  else if (/(COPO|CANECA|GARRAFA|SQUEEZE|CHAVEIRO|BONÉ|MOCHILA|BOLSA|MALA|CACHECOL|CANELEIRA|FL[ÂA]MULA|GORRO|TOUCA|KIT QUEIJO|PORTA CANELEIRA|GUARDA CHUVA|TRENA)/.test(n)) { productType = 'accessory'; categoryIds.push('accessories'); }
  else if (/(MOLETOM|CALÇA |JAQUETA|POLO|CAMISETA|REGATA|SHORT|BERMUDA)/.test(n)) { productType = 'casual'; collectionIds.push('casual'); }
  else { productType = 'souvenir'; categoryIds.push('souvenirs'); collectionIds.push('fan'); }
  return { productType, categoryIds, collectionIds };
}

function audienceFor(n, additionalProps) {
  const genero = (additionalProps.find(p => p.name === 'Gênero') || {}).value;
  const n_ = n.toUpperCase();
  if (n_.includes('JUVENIL') || n_.includes('INFANTIL')) return 'kids';
  if (genero === 'Feminino' || n_.includes('FEMININA')) return 'feminine';
  if (genero === 'Masculino' || n_.includes('MASCULINO')) return 'masculine';
  return 'unisex';
}

function propVal(props, name) { return (props.find(p => p.name === name) || {}).value; }

function buildProduct(p) {
  const groupName = p.isVariantOf.name;
  const gid = p.isVariantOf.productGroupID;
  const breadcrumb = p.breadcrumbList.itemListElement.map(i => i.name);
  const cls = classify(groupName, breadcrumb);
  const audience = audienceFor(groupName, p.additionalProperty || []);
  const colorsSet = new Set();
  const variations = [];
  const variants = (p.isVariantOf.hasVariant && p.isVariantOf.hasVariant.length) ? p.isVariantOf.hasVariant : [p];
  for (const v of variants) {
    const props = v.additionalProperty || [];
    const size = propVal(props, 'Tamanhos') || 'ÚNICO';
    const color = propVal(props, 'Cor');
    if (color) colorsSet.add(color);
    const offer = v.offers?.offers?.[0];
    const avail = offer?.availability === 'https://schema.org/InStock';
    variations.push({
      sku: v.sku || v.id || p.sku,
      size,
      colorLabel: color || null,
      // Estoque granular real por SKU não é exposto pela loja (o campo
      // "quantity" da VTEX é um sentinel fixo de 10000, não inventário de
      // verdade) — usamos aqui só o sinal REAL de disponibilidade
      // (schema.org InStock/OutOfStock), nunca uma contagem inventada.
      stock: avail ? 1 : 0,
    });
  }
  const multiColor = colorsSet.size > 1;
  if (!multiColor) for (const v of variations) v.colorLabel = null;
  const priceRoot = p.fullSellers?.[0]?.commertialOffer?.Price ?? p.offers?.lowPrice;
  const listPriceRoot = p.fullSellers?.[0]?.commertialOffer?.ListPrice ?? priceRoot;
  const installmentsArr = p.fullSellers?.[0]?.commertialOffer?.Installments || [];
  const maxInst = installmentsArr.filter(i => i.InterestRate === 0).reduce((m, i) => Math.max(m, i.NumberOfInstallments), 1);
  const desc = stripHtml(p.description);
  return {
    id: `bragantino_${gid}`,
    slug: p.slug,
    name: groupName,
    shortDescription: (desc.split(/\n|(?<=\.) /)[0] || desc).slice(0, 180),
    description: desc,
    brand: p.brand?.name || p.brand?.brandName || '',
    reference: p.productReference || p.sku,
    categories: cls.categoryIds,
    collections: cls.collectionIds,
    audience,
    productType: cls.productType,
    price: priceRoot,
    originalPrice: (listPriceRoot && priceRoot && listPriceRoot > priceRoot) ? listPriceRoot : null,
    installments: maxInst || 1,
    // `images`/`thumbnail` aqui ainda são URLs remotas da VTEX — trocadas
    // por paths locais depois do download dos assets (ver
    // download_assets.mjs), igual ao Goiás.
    images: (p.image || []).map(im => im.url),
    thumbnail: (p.image || [])[0]?.url,
    variations,
    isFeatured: false,
    isNew: false,
    personalizationOptions: null,
    relatedProductIds: [],
    specifications: [],
    sourceUrl: `${BASE}/${p.slug}/p`,
    _gid: gid,
  };
}

async function main() {
  fs.mkdirSync(RAW_DIR, { recursive: true });
  fs.mkdirSync(OUT_DIR, { recursive: true });

  console.log('Descobrindo buildId atual...');
  const buildId = await discoverBuildId();
  console.log('buildId:', buildId);

  console.log('Buscando todos os nós de "Red Bull Bragantino"...');
  const { nodes, total } = await fetchAllSearchNodes();
  console.log(`total (facet): ${total} | nós recebidos: ${nodes.length}`);

  const nameOk = n => /bragantino|massa bruta|\bbraga\b/i.test(n);
  const inScope = nodes.filter(n => nameOk(n.isVariantOf.name) || nameOk(n.name));
  const outOfScope = nodes.filter(n => !(nameOk(n.isVariantOf.name) || nameOk(n.name)));
  console.log(`em escopo (nome contém Bragantino/Braga/Massa Bruta): ${inScope.length}`);
  console.log(`fora de escopo: ${outOfScope.length}`, outOfScope.map(n => n.isVariantOf.name));

  const byGroup = new Map();
  for (const n of inScope) byGroup.set(n.isVariantOf.productGroupID, n);
  const uniqueGroups = [...byGroup.values()];
  console.log(`grupos únicos (produtos): ${uniqueGroups.length}`);

  const slugs = uniqueGroups.map(n => n.slug);
  fs.writeFileSync(path.join(RAW_DIR, 'search_nodes.json'), JSON.stringify(uniqueGroups, null, 1));

  console.log(`Buscando ${slugs.length} PDPs completas...`);
  const { results: pdps, errors: pdpErrors } = await fetchAllPdps(buildId, slugs);
  console.log(`PDPs ok: ${pdps.length} | erros: ${pdpErrors.length}`);
  if (pdpErrors.length) console.log(pdpErrors);
  fs.writeFileSync(path.join(RAW_DIR, 'pdps.json'), JSON.stringify(pdps, null, 1));

  const products = pdps.map(buildProduct);

  // Sanidade
  const ids = products.map(p => p.id);
  const dupIds = ids.filter((id, i) => ids.indexOf(id) !== i);
  const allSkus = products.flatMap(p => p.variations.map(v => v.sku));
  const dupSkus = allSkus.filter((s, i) => allSkus.indexOf(s) !== i);
  const noImage = products.filter(p => !p.images.length);
  const noPrice = products.filter(p => p.price == null);
  const noDesc = products.filter(p => !p.description);

  const byCategory = {};
  for (const p of products) {
    const key = p.categories[0] || p.collections[0] || 'none';
    byCategory[key] = (byCategory[key] || 0) + 1;
  }

  const audit = {
    totalUniqueProducts: products.length,
    totalSkus: allSkus.length,
    uniqueSkus: new Set(allSkus).size,
    duplicateIds: dupIds,
    duplicateSkus: dupSkus,
    productsWithoutImage: noImage.map(p => p.id),
    productsWithoutPrice: noPrice.map(p => p.id),
    productsWithoutDescription: noDesc.map(p => p.id),
    byCategory,
    outOfScopeExcluded: outOfScope.map(n => n.isVariantOf.name),
    pdpFetchErrors: pdpErrors,
    totalImages: products.reduce((s, p) => s + p.images.length, 0),
  };
  fs.writeFileSync(path.join(RAW_DIR, 'collection_audit.json'), JSON.stringify(audit, null, 2));
  fs.writeFileSync(path.join(RAW_DIR, 'products_remote_images.json'), JSON.stringify(products, null, 1));

  console.log('\n=== AUDITORIA DA COLETA ===');
  console.log(JSON.stringify(audit, null, 2));
}

main().catch(err => { console.error(err); process.exit(1); });
