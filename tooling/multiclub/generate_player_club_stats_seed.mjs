// Transforma player_club_stats_seed.json + player_club_stat_sources_seed
// .json numa migration SQL determinística.
//
// player_club_stats.id usa DEFAULT gen_random_uuid() — chave natural
// (person_id, club_id, spell_id) genuinamente estável, sem registry. Pra
// linhas SPELL, club_id e person_id são resolvidos por JOIN em
// player_club_spells (via spell_id), garantindo coerência em vez de
// confiar em literais desalinhados — nunca uma FK composta declarada (não
// alteramos a tabela já aplicada da Etapa B), mas o INSERT em si só é
// possível se o spell_id existir e pertencer ao person_id/club_id certos.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATION_PATH = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902090000_seed_goias_player_club_stats.sql');

const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_stats_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_stat_sources_seed.json'), 'utf8'));

const errors = [];
const validScope = new Set(['CLUB_TOTAL', 'SPELL']);
const validVerification = new Set(['VERIFIED', 'PARTIAL']);
const validRole = new Set(['PRIMARY', 'CORROBORATING', 'DERIVED_COMPONENT', 'BASELINE']);
for (const s of sources) {
  if (!validRole.has(s.sourceRole)) errors.push(`Source ${s.canonicalName || s.personId}/${s.sourceType}:${s.sourceRef}: source_role inválido "${s.sourceRole}".`);
}
for (const s of stats) {
  if (!validScope.has(s.statsScope)) errors.push(`${s.canonicalName}: stats_scope inválido "${s.statsScope}".`);
  if (!validVerification.has(s.verificationStatus)) errors.push(`${s.canonicalName}: verification_status inválido "${s.verificationStatus}".`);
  if (s.statsScope === 'CLUB_TOTAL' && s.spellId != null) errors.push(`${s.canonicalName}: CLUB_TOTAL com spell_id preenchido.`);
  if (s.statsScope === 'SPELL' && s.spellId == null) errors.push(`${s.canonicalName}: SPELL sem spell_id.`);
  if (s.appearances == null && s.goals == null) errors.push(`${s.canonicalName}: linha 100% vazia (appearances e goals nulos).`);
}
// nenhum CLUB_TOTAL duplicado por pessoa, nenhum spell_id duplicado
const seenTotal = new Set();
const seenSpell = new Set();
for (const s of stats) {
  if (s.statsScope === 'CLUB_TOTAL') {
    const key = `${s.personId}|${s.clubSlug}`;
    if (seenTotal.has(key)) errors.push(`CLUB_TOTAL duplicado: ${key}`);
    seenTotal.add(key);
  } else {
    if (seenSpell.has(s.spellId)) errors.push(`SPELL duplicado pro mesmo spell_id: ${s.spellId}`);
    seenSpell.add(s.spellId);
  }
}
if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }
function sqlText(s) { return s === null || s === undefined ? 'null' : sqlString(s); }
function sqlInt(n) { return n === null || n === undefined ? 'null' : String(n); }
function sqlJsonb(v) { return `${sqlString(JSON.stringify(v))}::jsonb`; }
// Cast ::uuid aplicado DENTRO da própria tupla VALUES (não só no uso mais
// tarde) — sem isso, o tipo da coluna derivada do VALUES pode resolver
// pra text e uma comparação "uuid = text" no JOIN falhar. Explícito desde
// a origem, nunca dependendo de cast implícito do Postgres.
function sqlUuid(s) { return s === null || s === undefined ? 'null::uuid' : `${sqlString(s)}::uuid`; }

// ordena determinístico: CLUB_TOTAL antes de SPELL, por nome, por spellOrder
const sortedStats = [...stats].sort((a, b) => a.canonicalName.localeCompare(b.canonicalName) || (a.statsScope === b.statsScope ? (a.spellOrder || 0) - (b.spellOrder || 0) : a.statsScope === 'CLUB_TOTAL' ? -1 : 1));
const sortedSources = [...sources].sort((a, b) => {
  const na = stats.find((s) => s.personId === a.personId && s.statsScope === a.statsScope && s.spellId === a.spellId)?.canonicalName || '';
  const nb = stats.find((s) => s.personId === b.personId && s.statsScope === b.statsScope && s.spellId === b.spellId)?.canonicalName || '';
  return na.localeCompare(nb) || a.sourceType.localeCompare(b.sourceType) || a.sourceRef.localeCompare(b.sourceRef);
});

const header = `-- ============================================================================
-- Seed de \`public.player_club_stats\` + \`public.player_club_stat_sources\`
-- — SOMENTE Goiás, SOMENTE pessoas já em \`public.people\` (96 APPROVED),
-- SOMENTE onde existe evidência resolvível (ver
-- player_club_stats_seed_stats.json pra auditoria completa).
--
-- GERADA por tooling/multiclub/generate_player_club_stats_seed.mjs a
-- partir de tooling/multiclub/build_player_club_stats_seed.mjs — NUNCA
-- editar à mão.
--
-- CLUB_TOTAL (spell_id null) nunca é dividido entre passagens. SPELL
-- (spell_id preenchido) só existe quando a fonte realmente dá o número
-- daquela passagem, casado por sobreposição de período contra os spells
-- reais — nunca um palpite. NULL != 0: ausência de dado nunca vira zero
-- (ver Walter 2019 = 0 jogos, um fato real, humano-verificado).
--
-- club_id/person_id de linhas SPELL são resolvidos por JOIN em
-- player_club_spells via spell_id — reforçado por FK composta no schema
-- (spell_id, person_id, club_id), nunca só literais soltos.
--
-- source_role (PRIMARY/CORROBORATING/DERIVED_COMPONENT/BASELINE) marca
-- explicitamente o papel de cada linha de provenance — um CLUB_TOTAL
-- derivado por soma tem 1 linha DERIVED_COMPONENT por segmento somado
-- (nunca um blob opaco), e o baseline do Tadeu tem source_role=BASELINE
-- (a Etapa E acha isso pelo campo, nunca por nome de source/notes).
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.player_club_stats (person_id, club_id, spell_id, stats_scope, appearances, goals, verification_status, as_of_date, as_of_match_id)
select
  case when v.stats_scope = 'SPELL' then pcs.person_id else v.person_id end,
  case when v.stats_scope = 'SPELL' then pcs.club_id else c.id end,
  v.spell_id,
  v.stats_scope, v.appearances, v.goals, v.verification_status, v.as_of_date, v.as_of_match_id
from (
  values
`;

const statsValuesLines = sortedStats.map((s, i) => {
  const comma = i === sortedStats.length - 1 ? '' : ',';
  return `    (${sqlUuid(s.personId)}, ${sqlString(s.clubSlug)}, ${sqlUuid(s.spellId)}, ${sqlString(s.statsScope)}, ${sqlInt(s.appearances)}, ${sqlInt(s.goals)}, ${sqlString(s.verificationStatus)}, ${sqlText(s.asOfDate)}::date, ${sqlText(s.asOfMatchId)})${comma}`;
});

const midSection = `
) as v(person_id, club_slug, spell_id, stats_scope, appearances, goals, verification_status, as_of_date, as_of_match_id)
left join public.clubs c on c.slug = v.club_slug
left join public.player_club_spells pcs on pcs.id = v.spell_id
on conflict do nothing;

insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date)
select pcstat.id, v.source_type, v.source_ref, v.raw_value, v.source_role, v.as_of_date
from (
  values
`;

const sourceValuesLines = sortedSources.map((s, i) => {
  const comma = i === sortedSources.length - 1 ? '' : ',';
  return `    (${sqlUuid(s.personId)}, ${sqlString(s.clubSlug)}, ${sqlUuid(s.spellId)}, ${sqlString(s.statsScope)}, ${sqlString(s.sourceType)}, ${sqlString(s.sourceRef)}, ${sqlJsonb(s.rawValue)}, ${sqlString(s.sourceRole)}, ${sqlText(s.asOfDate)}::date)${comma}`;
});

const footer = `
) as v(person_id, club_slug, spell_id, stats_scope, source_type, source_ref, raw_value, source_role, as_of_date)
left join public.clubs c on c.slug = v.club_slug
join public.player_club_stats pcstat
  on pcstat.stats_scope = v.stats_scope
  and (v.stats_scope = 'SPELL' and pcstat.spell_id = v.spell_id
       or v.stats_scope = 'CLUB_TOTAL' and pcstat.person_id = v.person_id and pcstat.club_id = c.id)
on conflict (player_club_stat_id, source_type, source_ref) do nothing;
`;

const sql = header + statsValuesLines.join('\n') + midSection + sourceValuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

console.log(JSON.stringify({
  migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'),
  statRows: sortedStats.length,
  sourceRows: sortedSources.length,
  distinctPeople: new Set(sortedStats.map((s) => s.personId)).size,
}, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
