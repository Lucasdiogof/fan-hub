// Busca location/startDate (JSON-LD schema.org/SportsEvent) de cada ficha
// de partida via fetch() direto do Node — mais rápido que o fluxo anterior
// via navegador (não precisa mais, o bloqueio 403 não se repetiu desde
// 2026-09-18, ver README). Uso:
//   node _fetch_match_venues.mjs <ano>
// Lê source/bragantino_<ano>_master_raw.json, escreve
// source/ogol_<ano>_venues_b1.json (todas as partidas, um arquivo só —
// o nome com "_b1" é só pra bater com o formato que _build_year_final.mjs
// já espera, não precisa mais dividir em lotes de 5).
import fs from 'fs';

const year = process.argv[2];
if (!year) {
  console.error('uso: node _fetch_match_venues.mjs <ano>');
  process.exit(1);
}

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36';

const master = JSON.parse(
  fs.readFileSync(`source/bragantino_${year}_master_raw.json`, 'utf8'),
);

function extractLdJson(html) {
  const m = html.match(
    /<script type="application\/ld\+json">([\s\S]*?)<\/script>/,
  );
  if (!m) return null;
  const raw = m[1].trim();
  try {
    return JSON.parse(raw);
  } catch {
    // Fichas de pênaltis/prorrogação às vezes têm HTML cru (ex.:
    // `<span class="prol">(N-N)g.p.</span>`) dentro do campo "name",
    // com aspas não escapadas que quebram o JSON.parse do bloco
    // inteiro (ver README, lote 2023). location/startDate continuam
    // bem formados — extrai só o que precisa via regex, sem depender
    // do resto do objeto parsear.
    const loc = raw.match(/"location":\s*\{\s*"@type":\s*"Place",\s*"name":\s*"([^"]*)"/);
    const date = raw.match(/"startDate":\s*"([^"]*)"/);
    if (!loc && !date) return null;
    return {
      location: { name: loc ? loc[1] : '' },
      startDate: date ? date[1] : '',
      _recoveredViaRegex: true,
    };
  }
}

async function fetchOne(url, attempt = 1) {
  try {
    const r = await fetch(url, { headers: { 'User-Agent': UA } });
    if (r.status !== 200) {
      return { url, status: r.status, location: null, startDate: null };
    }
    const html = await r.text();
    const ld = extractLdJson(html);
    if (!ld) {
      return { url, status: r.status, location: null, startDate: null, note: 'ld+json não encontrado/ilegível' };
    }
    const result = {
      url,
      status: r.status,
      location: ld.location?.name || null,
      startDate: ld.startDate || null,
    };
    if (ld._recoveredViaRegex) {
      result.note = 'JSON-LD recuperado via regex (HTML cru de pênaltis quebrava o parse padrão)';
    }
    return result;
  } catch (error) {
    if (attempt < 3) {
      await new Promise((res) => setTimeout(res, 1000 * attempt));
      return fetchOne(url, attempt + 1);
    }
    return { url, status: 0, location: null, startDate: null, note: `fetch falhou: ${error.message}` };
  }
}

const results = [];
for (const m of master) {
  const result = await fetchOne(m.source_url);
  results.push(result);
  const tag = result.location ? result.location : `SEM LOCATION (status ${result.status})`;
  console.log(`${m.date} ${m.opponent.padEnd(20)} -> ${tag}`);
  // Pausa curta entre requisições — nunca martelar o servidor, mesmo que o
  // bloqueio de 2026-09-07 não tenha se repetido até agora.
  await new Promise((res) => setTimeout(res, 250));
}

fs.writeFileSync(
  `source/ogol_${year}_venues_b1.json`,
  JSON.stringify(results),
);

const failed = results.filter((r) => !r.location);
console.log(`\n${results.length - failed.length}/${results.length} com estádio confirmado.`);
if (failed.length) {
  console.log('SEM location:', failed.map((f) => f.url));
}
