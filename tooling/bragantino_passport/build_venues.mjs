// Monta o catálogo `venues` do Passaporte do Bragantino a partir das 186
// partidas já validadas e gera `supabase/bragantino_passport_venues_seed.sql`.
//
//   node tooling/bragantino_passport/build_venues.mjs
//
// A fonte traz 62 grafias distintas de estádio para ~40 estádios reais:
// mesma casa aparece ora com "Estádio" na frente, ora com o apelido entre
// parênteses, ora com o nome comercial do patrocinador do ano.
//
// REGRA DE NORMALIZAÇÃO — só agrupo quando eu SEI que é a mesma casa, e a
// decisão fica escrita aqui, uma linha por grupo. Nada de agrupar por
// semelhança de string: "Estadio Monumental Banco Pichincha" (Guayaquil) e
// "Estadio Monumental" (Buenos Aires) compartilham a palavra e são estádios
// diferentes, em países diferentes. Grafia que eu não consigo casar com
// certeza vira um venue próprio — catálogo com uma linha a mais é um
// detalhe; duas casas fundidas erradas corrompem "estádio mais visitado".
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const SOURCE_DIR = path.join(ROOT, 'tooling/bragantino_passport/source');
const OUT_SQL = path.join(ROOT, 'supabase/bragantino_passport_venues_seed.sql');

/// Grupos confirmados: mesma casa escrita de mais de um jeito na fonte.
/// `canonical` é o nome oficial; `display` é como aparece no app; `variants`
/// são as grafias EXATAS que a fonte usou (é por elas que o UPDATE casa).
const MERGE_GROUPS = [
  {
    canonical: 'Estádio Jornalista Mário Filho',
    display: 'Maracanã',
    // "Estadio" sem acento é erro de digitação da própria fonte.
    variants: [
      'Estádio Jornalista Mário Filho (Maracanã)',
      'Estadio Jornalista Mário Filho (Maracanã)',
    ],
  },
  {
    canonical: 'Estádio Olímpico Nilton Santos',
    display: 'Estádio Nilton Santos',
    variants: [
      'Estádio Olímpico Nilton Santos (Engenhão)',
      'Estádio Olímpico Nilton Santos',
    ],
  },
  {
    canonical: 'Neo Química Arena',
    display: 'Neo Química Arena',
    variants: ['Neo Química Arena (Arena Corinthians)', 'Neo Química Arena'],
  },
  {
    canonical: 'Estádio Urbano Caldeira',
    display: 'Vila Belmiro',
    variants: ['Urbano Caldeira (Vila Belmiro)', 'Estádio Urbano Caldeira'],
  },
  {
    canonical: 'Estádio José Maria de Campos Maia',
    display: 'Estádio Maião',
    variants: [
      'Estádio José Maria de Campos Maia',
      'José Maria de Campos Maia (Maião)',
    ],
  },
  {
    canonical: 'Estádio Cícero Pompeu de Toledo',
    display: 'MorumBIS',
    variants: ['Cícero Pompeu de Toledo (Morumbis)', 'MorumBIS'],
  },
  {
    canonical: 'Estádio Joaquim Américo Guimarães',
    display: 'Arena da Baixada',
    // A fonte nomeia pelo nome comercial (Mário Celso Petraglia).
    variants: [
      'Estádio Mário Celso Petraglia (Arena da Baixada)',
      'Estádio Mário Celso Petraglia',
    ],
  },
  {
    canonical: 'Estádio José Pinheiro Borda',
    display: 'Beira-Rio',
    variants: ['José Pinheiro Borda (Beira-Rio)', 'Estádio José Pinheiro Borda'],
  },
  {
    canonical: 'Estádio Manoel Barradas',
    display: 'Barradão',
    variants: ['Manoel Barradas (Barradão)', 'Estádio Manoel Barradas'],
  },
  {
    canonical: 'Estádio Vasco da Gama',
    display: 'São Januário',
    variants: ['Estádio Vasco da Gama (São Januário)', 'Estádio São Januário'],
  },
  {
    canonical: 'Complexo Esportivo Cultural Octávio Mangabeira',
    display: 'Arena Fonte Nova',
    // "Casa de Apostas Arena Fonte Nova" é o naming rights do período.
    variants: ['Arena Fonte Nova', 'Casa de Apostas Arena Fonte Nova'],
  },
  {
    canonical: 'Arena do Grêmio',
    display: 'Arena do Grêmio',
    // Uma das duas ocorrências veio com espaço sobrando no fim.
    variants: ['Arena do Grêmio', 'Arena do Grêmio '],
  },
  {
    canonical: 'Estádio Governador Magalhães Pinto',
    display: 'Mineirão',
    variants: [
      'Estádio Gov. Magalhães Pinto (Mineirão)',
      'Estádio Governador Magalhães Pinto',
    ],
  },
];

/// Estádios que ficam sozinhos mas cujo nome de exibição merece o apelido
/// pelo qual são realmente conhecidos. Só renomeia exibição — não funde nada.
const DISPLAY_OVERRIDES = {
  'Estádio Municipal Cícero de Souza Marques': 'Estádio Cícero de Souza Marques',
  'Nabi Abi Chedid': 'Estádio Nabi Abi Chedid',
  'Governador Plácido Aderaldo Castelo (Castelão)': 'Castelão',
  'Antônio Marques da Silva Mariz (Marizão)': 'Marizão',
  'Doutor Jorge Ismael de Biasi (Jorjão)': 'Estádio Jorjão',
  'Oswaldo Teixeira Duarte (Canindé)': 'Canindé',
  'Raimundo Sampaio (Arena Independência)': 'Arena Independência',
  'Presidente Perón (El Cilindro)': 'El Cilindro',
  'José Batista Pereira Fernandes (Distrital do Inamar)':
    'Distrital do Inamar',
  'Adelmar da Costa Carvalho (Ilha do Retiro)': 'Ilha do Retiro',
  'Estádio Major Antônio Couto Pereira': 'Couto Pereira',
  'Brinco de Ouro da Princesa': 'Brinco de Ouro da Princesa',
  'Santa Cruz': 'Estádio Santa Cruz',
};

/// Cidade que a fonte gravou e que eu SEI estar errada, mas cuja correção
/// eu não confirmei com fonte própria neste bloco. Vira null + aviso: melhor
/// o app não mostrar cidade nenhuma do que mostrar a cidade errada, e
/// "chutar" a certa seria exatamente a invenção que este projeto proíbe.
const SUSPECT_CITY = {
  'Estádio Dr. Alfredo de Castilho':
    'a fonte (OneFootball) gravou "Novo Horizonte", mas este é o estádio do ' +
    'EC Noroeste, que não é de Novo Horizonte — cidade real não confirmada ' +
    'neste bloco, fica null até ter fonte',
};

function slugify(text) {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 48);
}

function q(value) {
  if (value == null) return 'null';
  return `'${String(value).replace(/'/g, "''")}'`;
}

export function buildVenues(matches) {
  const variantToGroup = new Map();
  for (const group of MERGE_GROUPS) {
    for (const variant of group.variants) {
      if (variantToGroup.has(variant)) {
        throw new Error(`grafia em 2 grupos de merge: ${variant}`);
      }
      variantToGroup.set(variant, group);
    }
  }

  const venues = new Map();
  const mapping = [];
  const warnings = [];

  for (const match of matches) {
    if (!match.stadium) continue;
    const raw = match.stadium;
    const group = variantToGroup.get(raw);
    const canonical = group?.canonical ?? raw.trim();
    const id = `venue_${slugify(canonical)}`;

    let venue = venues.get(id);
    if (!venue) {
      venue = {
        id,
        canonical_name: canonical,
        display_name: group?.display ?? DISPLAY_OVERRIDES[raw] ?? raw.trim(),
        city: match.venue_city ?? null,
        state: match.venue_state ?? null,
        country: match.venue_country ?? null,
        aliases: new Set(),
        match_count: 0,
      };
      venues.set(id, venue);
    }

    // Cidade/estado divergentes para a MESMA casa é sinal de dado suspeito
    // na fonte — reporto em vez de escolher um silenciosamente.
    for (const field of ['city', 'state', 'country']) {
      const incoming = match[`venue_${field}`] ?? null;
      if (incoming != null && venue[field] != null && incoming !== venue[field]) {
        warnings.push(
          `${venue.display_name}: ${field} divergente entre partidas ` +
            `("${venue[field]}" vs "${incoming}") — conferir a fonte`,
        );
      }
      venue[field] ??= incoming;
    }

    const suspect = SUSPECT_CITY[canonical];
    if (suspect && venue.city != null) {
      warnings.push(`${venue.display_name}: cidade descartada — ${suspect}`);
      venue.city = null;
      venue.state = null;
    }

    if (raw.trim() !== venue.canonical_name) venue.aliases.add(raw.trim());
    venue.match_count += 1;
    mapping.push({ raw, venue_id: id });
  }

  return {
    venues: [...venues.values()].sort((a, b) => b.match_count - a.match_count),
    mapping,
    warnings,
  };
}

function loadMatches() {
  return fs
    .readdirSync(SOURCE_DIR)
    .filter((f) => /^bragantino_passport_\d{4}\.json$/.test(f))
    .sort()
    .flatMap(
      (f) => JSON.parse(fs.readFileSync(path.join(SOURCE_DIR, f), 'utf8')).matches,
    );
}

function renderSql({ venues, mapping }) {
  const lines = [];
  lines.push(
    '-- Catálogo de estádios do Passaporte do Bragantino + ligação das',
    '-- partidas. GERADO por `node tooling/bragantino_passport/build_venues.mjs`',
    '-- — não edite à mão, edite os grupos de normalização no script.',
    '--',
    '-- Rode no projeto Supabase do BRAGANTINO, DEPOIS de',
    '-- `bragantino_passport_infra.sql` e dos seeds de partida.',
    '-- Idempotente: reexecutar apenas reescreve os mesmos valores.',
    '--',
    `-- ${venues.length} estádios, a partir de ${mapping.length} partidas com`,
    '-- estádio confirmado na ficha (evidência MATCH_SPECIFIC).',
    '',
    'insert into public.venues',
    '  (id, canonical_name, display_name, city, state, country, aliases)',
    'values',
  );

  const rows = venues.map((v) => {
    const aliases = [...v.aliases].sort();
    const arr = aliases.length
      ? `array[${aliases.map(q).join(', ')}]`
      : "'{}'::text[]";
    return (
      `  (${q(v.id)}, ${q(v.canonical_name)}, ${q(v.display_name)}, ` +
      `${q(v.city)}, ${q(v.state)}, ${q(v.country)}, ${arr})`
    );
  });
  lines.push(rows.join(',\n'));

  lines.push(
    'on conflict (id) do update set',
    '  canonical_name = excluded.canonical_name,',
    '  display_name = excluded.display_name,',
    '  city = excluded.city,',
    '  state = excluded.state,',
    '  country = excluded.country,',
    '  aliases = excluded.aliases,',
    '  updated_at = now();',
    '',
    '-- Rede de segurança: o seed de partidas já grava `venue_id` direto, mas',
    '-- linhas importadas antes deste catálogo existir ficariam sem ligação.',
    '-- O casamento é pelo TEXTO EXATO gravado em `passport_matches.stadium`,',
    '-- que segue intacto como provenance.',
  );

  const byVenue = new Map();
  for (const { raw, venue_id } of mapping) {
    if (!byVenue.has(venue_id)) byVenue.set(venue_id, new Set());
    byVenue.get(venue_id).add(raw);
  }
  for (const [venueId, raws] of byVenue) {
    const list = [...raws].sort().map(q).join(', ');
    lines.push(
      `update public.passport_matches set venue_id = ${q(venueId)}`,
      `  where stadium in (${list});`,
    );
  }

  lines.push('');

  return lines.join('\n');
}

const isMain =
  process.argv[1] &&
  import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (isMain) {
  const matches = loadMatches();
  const result = buildVenues(matches);

  fs.writeFileSync(OUT_SQL, renderSql(result), 'utf8');

  const grafias = new Set(matches.filter((m) => m.stadium).map((m) => m.stadium));
  console.log(`partidas com estádio: ${result.mapping.length}/${matches.length}`);
  console.log(`grafias na fonte:     ${grafias.size}`);
  console.log(`estádios no catálogo: ${result.venues.length}`);
  console.log(`\ntop 10 por partidas:`);
  for (const v of result.venues.slice(0, 10)) {
    const alias = v.aliases.size ? `  (${v.aliases.size} variante(s))` : '';
    console.log(
      `  ${String(v.match_count).padStart(3)}  ${v.display_name} — ${v.city ?? '?'}${alias}`,
    );
  }
  if (result.warnings.length) {
    console.log(`\nAVISOS (${result.warnings.length}):`);
    for (const w of result.warnings) console.log(`  ${w}`);
  }
  console.log(`\nescrito: ${path.relative(ROOT, OUT_SQL)}`);
}
