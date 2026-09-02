// PERSON ALIASES — micro-etapa depois do seed de `people`. Constrói
// person_aliases_seed.json + person_alias_sources_seed.json a partir de:
//   canonical_people_candidates.json (295 pessoas, membros finais)
//   people_insert_plan.json (pra saber QUAIS das 295 já existem em people —
//     só as 94 APPROVED, nunca PROVISIONAL/BLOCKED_*)
//   people_registry.json (cross-validação de person_id, mesmo padrão do
//     gerador do seed de people — nunca confia cego no id do plano)
//   candidates.json (pra achar o texto de CADA alias com sua PROVENIÊNCIA
//     original — source:sourceId de onde ele veio)
//   canonical_aliases.json (cross-check: todo alias que já existe lá pras
//     94 pessoas precisa aparecer aqui também, senão é um alias perdido)
//
// NUNCA gera UUID (usa registry). NUNCA cria unique(normalized_alias)
// global — a ambiguidade é o comportamento correto (ver Nicolas/Danilo/
// Michael). Aliases só pras 94 pessoas que JÁ existem em people hoje.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { normalizeAlias } from './normalize_alias.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');

const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const plan = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'people_insert_plan.json'), 'utf8'));
const registry = JSON.parse(fs.readFileSync(path.join(TOOLING, 'people_registry.json'), 'utf8'));
const candidates = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'candidates.json'), 'utf8'));
const canonicalAliasesIndex = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_aliases.json'), 'utf8'));

const errors = [];
const warnings = [];

// ---------------------------------------------------------------------------
// 1. Índice source:sourceId -> {name, fullName, aliases[]} completo (não só
//    o primaryName usado em display_name.mjs — aqui precisamos de TODAS as
//    variantes de string que aquele registro conhece).
// ---------------------------------------------------------------------------

const sourceRecordByKey = new Map();
for (const c of candidates) {
  for (const s of c.sources) {
    sourceRecordByKey.set(`${s.source}:${s.sourceId}`, s);
  }
}

// ---------------------------------------------------------------------------
// 2. Só as pessoas já existentes em people (94 APPROVED) — cross-validadas
//    contra o registry, igual generate_people_seed.mjs.
// ---------------------------------------------------------------------------

const registryByKey = new Map(registry.entries.map((e) => [e.canonicalPersonKey, e]));
const approvedPlanById = new Map(plan.filter((p) => p.insert_status === 'APPROVED').map((p) => [p.canonical_person_id, p]));
const approvedPeople = [];

for (const person of canonicalPeople) {
  const planEntry = approvedPlanById.get(person.canonicalId);
  if (!planEntry) continue; // não é APPROVED — não existe em people ainda
  const regEntry = registryByKey.get(person.canonicalPersonKey);
  if (!regEntry || regEntry.personId !== person.canonicalId) {
    errors.push(`"${person.canonicalName}": person_id não confere com o registry — EXCLUÍDO.`);
    continue;
  }
  approvedPeople.push(person);
}

if (approvedPeople.length !== 94) warnings.push(`Esperava 94 pessoas APPROVED, achou ${approvedPeople.length}.`);

// ---------------------------------------------------------------------------
// 3. Pra cada pessoa, agrega TODAS as variantes de nome conhecidas (nunca
//    de alias -> nunca perde provenance), classifica alias_type, deduplica
//    por normalizedAlias (nunca 5 linhas iguais de "Tadeu").
// ---------------------------------------------------------------------------

function tokensOf(normalized) {
  return normalized.split(' ').filter(Boolean);
}

/** true se `subNorm` é composto só de tokens que também aparecem em
 * `fullNorm`, na mesma ordem relativa — ex.: "baier" ⊆ "paulo cesar
 * baier"; "cesar baier" ⊆ "paulo cesar baier"; mas "cesar paulo" NÃO
 * (ordem errada — tratado como NICKNAME, não SHORT_NAME, por segurança:
 * não presumir que é uma abreviação do mesmo nome se a ordem não bate). */
function isOrderedSubsequence(subTokens, fullTokens) {
  if (subTokens.length === 0 || subTokens.length >= fullTokens.length) return false;
  let i = 0;
  for (const t of fullTokens) {
    if (i < subTokens.length && subTokens[i] === t) i++;
  }
  return i === subTokens.length;
}

const aliasSeed = []; // person_aliases rows
const aliasSourceSeed = []; // person_alias_sources rows (referenciando índice de aliasSeed por enquanto)

for (const person of approvedPeople) {
  const canonicalNorm = normalizeAlias(person.canonicalName);
  const displayNorm = normalizeAlias(person.displayName);
  const canonicalTokens = tokensOf(canonicalNorm);
  const isLegalFullName = person.nameQuality === 'LEGAL_FULL_NAME';

  // normalizedAlias -> { raw, type, sourceKeys: Set }
  const byNorm = new Map();

  function addOccurrence(raw, sourceKey) {
    const norm = normalizeAlias(raw);
    if (!norm) return;
    if (!byNorm.has(norm)) byNorm.set(norm, { raw, sourceKeys: new Set() });
    const entry = byNorm.get(norm);
    if (raw.length > entry.raw.length) entry.raw = raw; // mantém a forma mais informativa (acentos/maiúsculas corretas)
    if (sourceKey) entry.sourceKeys.add(sourceKey);
  }

  // canonical_name e display_name SEMPRE entram (são a própria identidade
  // pública da pessoa em people) — sourceKey null aqui porque não vêm de
  // UM registro específico, vêm da decisão de reconciliação como um todo;
  // a proveniência real de CADA fonte que contribuiu pra esse texto já
  // aparece separadamente abaixo, via os source records dos membros.
  addOccurrence(person.canonicalName, null);
  addOccurrence(person.displayName, null);

  // todas as variantes conhecidas de CADA source record membro — aqui SIM
  // toda alias ganha proveniência real.
  for (const m of person.members) {
    const rec = sourceRecordByKey.get(`${m.source}:${m.sourceId}`);
    if (!rec) continue;
    const key = `${m.source}:${m.sourceId}`;
    if (rec.name) addOccurrence(rec.name, key);
    if (rec.fullName) addOccurrence(rec.fullName, key);
    for (const a of rec.aliases || []) addOccurrence(a, key);
  }

  for (const [norm, { raw, sourceKeys }] of byNorm) {
    let aliasType;
    let isPreferred = false;
    if (norm === canonicalNorm) {
      aliasType = isLegalFullName ? 'LEGAL_NAME' : 'FULL_NAME';
      if (norm === displayNorm) isPreferred = true; // canonical===display, mesma linha
    } else if (norm === displayNorm) {
      aliasType = 'DISPLAY_NAME';
      isPreferred = true;
    } else {
      const tokens = tokensOf(norm);
      if (isOrderedSubsequence(tokens, canonicalTokens)) {
        aliasType = 'SHORT_NAME';
      } else if (isOrderedSubsequence(canonicalTokens, tokens)) {
        // Caso inverso: o ALIAS é que estende o canonical_name atual
        // preservando ordem (ex.: canonical="Paulo Baier", alias="Paulo
        // César Baier" — achado real durante esta reconciliação: o motor
        // automático escolheu a forma curta porque a mais completa só
        // existia em accepted_answers/aliases, nunca num campo fullName
        // estruturado). Sinal ESTRUTURAL de nome mais completo — não é
        // extração de texto narrativo, é comparação de tokens. Fica
        // FULL_NAME (mesma categoria de "nome completo sem pesquisa
        // externa"); NÃO promove canonical_name/display_name aqui — isso
        // exigiria uma migration de correção separada em people, fora do
        // escopo desta etapa (sinalizado à parte).
        aliasType = 'FULL_NAME';
      } else {
        // SOURCE_VARIANT se bate EXATAMENTE com o primaryName de alguma
        // fonte que não seja a que já definiu display_name; senão NICKNAME.
        const matchesSomeSourcePrimaryName = person.members.some((m) => {
          const rec = sourceRecordByKey.get(`${m.source}:${m.sourceId}`);
          return rec?.name && normalizeAlias(rec.name) === norm;
        });
        aliasType = matchesSomeSourcePrimaryName ? 'SOURCE_VARIANT' : 'NICKNAME';
      }
    }

    const aliasIndex = aliasSeed.length;
    aliasSeed.push({
      personId: person.canonicalId,
      canonicalPersonKey: person.canonicalPersonKey,
      alias: raw,
      normalizedAlias: norm,
      aliasType,
      isPreferred,
    });
    for (const sourceKey of sourceKeys) {
      const [source, ...rest] = sourceKey.split(':');
      aliasSourceSeed.push({ aliasIndex, source, sourceRecordKey: sourceKey });
    }
  }
}

// ---------------------------------------------------------------------------
// 4. Cross-check contra canonical_aliases.json — todo alias que já existe
//    lá pras 94 pessoas precisa aparecer aqui também.
// ---------------------------------------------------------------------------

const approvedIds = new Set(approvedPeople.map((p) => p.canonicalId));
const producedPairs = new Set(aliasSeed.map((a) => `${a.personId}|${a.normalizedAlias}`));
let missingFromCanonicalAliases = 0;
for (const entry of canonicalAliasesIndex) {
  for (const ref of entry.refs) {
    if (!approvedIds.has(ref.canonicalId)) continue;
    const pair = `${ref.canonicalId}|${entry.normalizedAlias}`;
    if (!producedPairs.has(pair)) {
      missingFromCanonicalAliases++;
      warnings.push(`Alias "${entry.normalizedAlias}" -> pessoa ${ref.canonicalName} está em canonical_aliases.json mas NÃO foi gerado no seed de person_aliases — investigar.`);
    }
  }
}

// ---------------------------------------------------------------------------
// 5. Estatísticas + escreve
// ---------------------------------------------------------------------------

const uniqueNormalized = new Set(aliasSeed.map((a) => a.normalizedAlias));
const byNormCount = new Map();
for (const a of aliasSeed) byNormCount.set(a.normalizedAlias, (byNormCount.get(a.normalizedAlias) || 0) + 1);
const ambiguousNormalized = [...byNormCount.entries()].filter(([, n]) => n > 1).map(([norm]) => norm);

const peopleWithNoExtraAlias = approvedPeople.filter((p) => {
  const rows = aliasSeed.filter((a) => a.personId === p.canonicalId);
  return rows.length === 1; // só a linha canonical===display, nada mais
}).length;

const stats = {
  approvedPeopleCount: approvedPeople.length,
  totalAliasRows: aliasSeed.length,
  uniqueNormalizedAliases: uniqueNormalized.size,
  ambiguousNormalizedAliases: ambiguousNormalized.length,
  ambiguousList: ambiguousNormalized.map((norm) => ({
    normalizedAlias: norm,
    people: aliasSeed.filter((a) => a.normalizedAlias === norm).map((a) => ({ personId: a.personId, canonicalPersonKey: a.canonicalPersonKey })),
  })),
  peopleWithNoExtraAliasBeyondCanonicalDisplay: peopleWithNoExtraAlias,
  totalAliasSourceRows: aliasSourceSeed.length,
  byAliasType: aliasSeed.reduce((acc, a) => { acc[a.aliasType] = (acc[a.aliasType] || 0) + 1; return acc; }, {}),
  missingFromCanonicalAliasesCrossCheck: missingFromCanonicalAliases,
};

if (errors.length) {
  console.error('ERROS:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}
if (warnings.length) {
  console.warn('AVISOS:');
  for (const w of warnings) console.warn(' -', w);
}

fs.writeFileSync(path.join(IN_DIR, 'person_aliases_seed.json'), JSON.stringify(aliasSeed, null, 2) + '\n');
fs.writeFileSync(path.join(IN_DIR, 'person_alias_sources_seed.json'), JSON.stringify(aliasSourceSeed, null, 2) + '\n');
fs.writeFileSync(path.join(IN_DIR, 'person_aliases_seed_stats.json'), JSON.stringify(stats, null, 2) + '\n');

console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', IN_DIR);
