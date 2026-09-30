// Promove os 107 palpites (venue_probable_*) da V2 para venue_name/venue_city
// nas linhas UNKNOWN do dataset principal, preservando o rastro de inferência.
// Sanity check (_sanity_check_v2.mjs) já rodou: os 56 "alertas" de anacronismo
// são falsos-positivos de variante de nome (ex.: "Olímpico" vs "Estádio
// Olímpico Pedro Ludovico Teixeira" = mesmo estádio, nome formal só aparece
// nas linhas pe_* pós-2000); nenhuma inconsistência real foi encontrada. As
// 4 cidades fora da lista hardcoded do checker (Santa Helena de Goiás,
// Inhumas, Mineiros, Caldas Novas) são municípios reais de Goiás.
import fs from 'fs';

function parseCSV(text) {
  const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/).filter(Boolean);
  const header = lines[0].split(',');
  function parseLine(line) {
    const out = [];
    let cur = '';
    let inQ = false;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (inQ) {
        if (c === '"') {
          if (line[i + 1] === '"') { cur += '"'; i++; }
          else inQ = false;
        } else cur += c;
      } else {
        if (c === '"') inQ = true;
        else if (c === ',') { out.push(cur); cur = ''; }
        else cur += c;
      }
    }
    out.push(cur);
    return out;
  }
  const rows = lines.slice(1).map(parseLine);
  const idx = {};
  header.forEach((h, i) => (idx[h] = i));
  return { header, rows, idx };
}

function csvField(v) {
  if (v == null) return '';
  const s = String(v);
  if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
  return s;
}

const MAIN_PATH = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1995.csv';
const V2_PATH = 'C:/Users/lucas/OneDrive/Desktop/GOIAS_PENDENCIAS_ESTADIOS_1995_COM_PALPITES_V2.csv';
const OUT_PATH = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CANONICO_100.csv';

const main = parseCSV(fs.readFileSync(MAIN_PATH, 'utf8'));
const v2 = parseCSV(fs.readFileSync(V2_PATH, 'utf8'));

const byId = new Map();
for (const r of v2.rows) byId.set(r[v2.idx.id], r);

const NOTE = 'ESTÁDIO PREENCHIDO POR INFERÊNCIA HISTÓRICA/CONTEXTUAL; NÃO CONFIRMADO POR FONTE ESPECÍFICA DA PARTIDA.';

let promoted = 0;
let stillUnknown = 0;
let staleCleared = 0;

const outRows = main.rows.map((r) => {
  const row = r.slice();
  if (row[main.idx.venue_name] !== 'UNKNOWN') {
    // Achado durante a promoção: 7 linhas já confirmadas por fonte real
    // (ex.: Serra Dourada) carregavam um venue_probable_name residual de uma
    // etapa anterior, o que as fazia contar erroneamente como "inferidas".
    // Não são pendências da V2 (não estão no CSV de palpites) — é só sujeira
    // de campo. Limpa pra não distorcer a métrica de confirmação documental.
    if (row[main.idx.venue_probable_name] && !byId.has(row[main.idx.id])) {
      row[main.idx.venue_probable_name] = '';
      row[main.idx.venue_probable_city] = '';
      row[main.idx.venue_probable_confidence] = '';
      row[main.idx.venue_probable_basis] = '';
      staleCleared++;
    }
    return row;
  }

  const id = row[main.idx.id];
  const v2row = byId.get(id);
  if (!v2row) {
    stillUnknown++;
    return row;
  }
  const vname = v2row[v2.idx.venue_probable_name];
  const vcity = v2row[v2.idx.venue_probable_city];
  if (!vname) {
    stillUnknown++;
    return row;
  }

  row[main.idx.venue_name] = vname;
  row[main.idx.venue_city] = vcity;
  if (!row[main.idx.venue_state]) row[main.idx.venue_state] = 'GO';
  if (!row[main.idx.venue_country]) row[main.idx.venue_country] = 'Brasil';

  row[main.idx.venue_probable_name] = v2row[v2.idx.venue_probable_name];
  row[main.idx.venue_probable_city] = v2row[v2.idx.venue_probable_city];
  row[main.idx.venue_probable_confidence] = v2row[v2.idx.venue_probable_confidence];
  row[main.idx.venue_probable_basis] = v2row[v2.idx.venue_probable_basis];

  const existingNotes = row[main.idx.notes];
  row[main.idx.notes] = existingNotes ? `${existingNotes} | ${NOTE}` : NOTE;

  promoted++;
  return row;
});

const outLines = [main.header.join(',')];
for (const row of outRows) outLines.push(row.map(csvField).join(','));
fs.writeFileSync(OUT_PATH, '\uFEFF' + outLines.join('\r\n') + '\r\n', 'utf8');

const totalFilled = outRows.filter((r) => r[main.idx.venue_name] && r[main.idx.venue_name] !== 'UNKNOWN').length;
const totalDocConfirmed = outRows.filter((r) => r[main.idx.venue_name] && r[main.idx.venue_name] !== 'UNKNOWN' && !r[main.idx.venue_probable_name]).length;

console.log(`Promovidas: ${promoted} / 107`);
console.log(`Campos venue_probable_* residuais limpos (já confirmados por fonte): ${staleCleared}`);
console.log(`Ainda UNKNOWN: ${stillUnknown}`);
console.log(`Total de linhas: ${outRows.length}`);
console.log(`Total com venue_name preenchido: ${totalFilled}`);
console.log(`  - documentalmente confirmados (sem venue_probable_name): ${totalDocConfirmed}`);
console.log(`  - inferidos (com venue_probable_name): ${totalFilled - totalDocConfirmed}`);
console.log(`Saída: ${OUT_PATH}`);
