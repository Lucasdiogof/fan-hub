// Sanity check dos 107 palpites da V2 antes de promover: acha, pra cada
// estádio provável, a data mais antiga em que ELE MESMO já foi usado como
// venue_name CONFIRMADO (não provável) em qualquer linha do dataset — serve
// de "piso" empírico. Se um palpite tiver data ANTERIOR a esse piso, é
// bandeira vermelha de anacronismo (estádio provavelmente não existia
// ainda). Também lista cidade x estado de cada palpite pra checar
// incompatibilidade óbvia.
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

const main = parseCSV(fs.readFileSync('passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1995.csv', 'utf8'));
const v2 = parseCSV(fs.readFileSync('C:/Users/lucas/OneDrive/Desktop/GOIAS_PENDENCIAS_ESTADIOS_1995_COM_PALPITES_V2.csv', 'utf8'));

// Piso empírico: data mais antiga que cada estádio aparece CONFIRMADO
// (venue_name preenchido, venue_probable_name vazio => veio de fonte real).
const floor = {};
for (const r of main.rows) {
  const vn = r[main.idx.venue_name];
  const vprob = r[main.idx.venue_probable_name];
  if (!vn || vn === 'UNKNOWN' || vprob) continue; // só confirmados de verdade
  const d = r[main.idx.effective_date];
  if (!d) continue;
  if (!floor[vn] || d < floor[vn].date) {
    floor[vn] = { date: d, id: r[main.idx.id] };
  }
}

console.log('=== PISO EMPÍRICO POR ESTÁDIO (1ª confirmação real no dataset) ===');
for (const [venue, info] of Object.entries(floor).sort((a, b) => a[1].date.localeCompare(b[1].date))) {
  console.log(`  ${venue.padEnd(45)} ${info.date}  (${info.id})`);
}

console.log('\n=== CHECANDO OS 107 PALPITES CONTRA O PISO ===');
let flagged = 0;
for (const r of v2.rows) {
  const id = r[v2.idx.id];
  const date = r[v2.idx.effective_date];
  const vname = r[v2.idx.venue_probable_name];
  const vcity = r[v2.idx.venue_probable_city];
  if (!vname) { console.log(`  ⚠ ${id}: SEM venue_probable_name`); flagged++; continue; }
  const f = floor[vname];
  if (f && date < f.date) {
    console.log(`  🚩 ${id} (${date}): "${vname}" só confirmado a partir de ${f.date} (${f.id}) — possível anacronismo`);
    flagged++;
  }
}
console.log(`\nTotal de linhas com alerta: ${flagged} / ${v2.rows.length}`);

// Cidade x estado grosseiro: cidades conhecidas fora de GO.
console.log('\n=== CIDADES FORA DE GOIÁS NOS PALPITES ===');
for (const r of v2.rows) {
  const city = r[v2.idx.venue_probable_city];
  if (city && !/goi[aâ]/i.test(city) && !['Goiânia', 'Anápolis', 'Itumbiara', 'Ceres', 'Jataí', 'Rio Verde', 'Goiatuba', 'Catalão', 'Formosa', 'Luziânia', 'Goianésia', 'Morrinhos'].includes(city)) {
    console.log(`  ${r[v2.idx.id]}: cidade "${city}"`);
  }
}
