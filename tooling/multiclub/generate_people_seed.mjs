// PEOPLE SEED GENERATOR — transforma people_insert_plan.json numa migration
// SQL determinística. NUNCA escrito à mão, NUNCA gera UUID (usa
// EXATAMENTE os ids já persistidos em people_registry.json), NUNCA insere
// dado que não pertence a `people` (sem club_id/jogos/posição/período —
// isso é player_club_spells/player_positions/player_club_stats, ainda não
// criados). Só os 94 APPROVED entram — PROVISIONAL/BLOCKED_* ficam de fora
// deste seed, preservados nos JSONs pra enriquecimento futuro.
//
// Reprodutibilidade: escreve SEMPRE no mesmo caminho de migration (nome
// fixo abaixo, nunca um timestamp gerado em tempo de execução) — apagar o
// .sql e rodar de novo produz o MESMO conteúdo byte-a-byte, porque a única
// entrada é people_insert_plan.json + people_registry.json (já
// determinísticos) e a ordenação de saída é fixa (por canonical_person_key
// numérico).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');
const MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260901010000_seed_goias_people.sql');

const plan = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'people_insert_plan.json'), 'utf8'));
const registry = JSON.parse(fs.readFileSync(path.join(TOOLING, 'people_registry.json'), 'utf8'));

const errors = [];
const warnings = [];

// ---------------------------------------------------------------------------
// 1. Filtra os APPROVED, cruza cada um contra o registry (nunca confia cego
//    no canonicalId já presente no plano — reconfirma contra a fonte de
//    verdade dos ids). display_name já vem RESOLVIDO em
//    people_insert_plan.json (calculado estruturalmente em
//    apply_overrides.mjs/display_name.mjs, nunca de texto narrativo) — este
//    gerador só lê, não recalcula, pra não duplicar a lógica em 2 lugares.
// ---------------------------------------------------------------------------

const approved = plan.filter((p) => p.insert_status === 'APPROVED');

const registryByKey = new Map(registry.entries.map((e) => [e.canonicalPersonKey, e]));

const rows = [];
for (const p of approved) {
  const regEntry = registryByKey.get(p.canonical_person_key);
  if (!regEntry) {
    errors.push(`"${p.canonical_name}" (${p.canonical_person_key}): chave não encontrada em people_registry.json — id não confiável, EXCLUÍDO do seed.`);
    continue;
  }
  if (regEntry.personId !== p.canonical_person_id) {
    errors.push(`"${p.canonical_name}": canonical_person_id do plano (${p.canonical_person_id}) diverge do registry (${regEntry.personId}) — EXCLUÍDO do seed.`);
    continue;
  }
  rows.push({
    id: regEntry.personId,
    canonicalPersonKey: p.canonical_person_key,
    canonicalName: p.canonical_name,
    displayName: p.display_name,
    nameQualityBucket: p.name_quality_bucket,
    identityStatus: p.identity_status,
  });
}

// ordenação determinística — por número sequencial do canonicalPersonKey
rows.sort((a, b) => {
  const na = parseInt(a.canonicalPersonKey.split(':').pop(), 10);
  const nb = parseInt(b.canonicalPersonKey.split(':').pop(), 10);
  return na - nb;
});

// ---------------------------------------------------------------------------
// 2. Validações — antes de escrever qualquer SQL.
// ---------------------------------------------------------------------------

if (rows.length !== 94) warnings.push(`Esperava 94 APPROVED, achou ${rows.length} — conferir se people_insert_plan.json mudou.`);

const idSet = new Set(rows.map((r) => r.id));
if (idSet.size !== rows.length) errors.push(`UUIDs duplicados no seed: ${rows.length - idSet.size} colisão(ões).`);

const planApprovedIds = new Set(approved.map((p) => p.canonical_person_id));
const seedIds = new Set(rows.map((r) => r.id));
const missingFromSeed = [...planApprovedIds].filter((id) => !seedIds.has(id));
const extraInSeed = [...seedIds].filter((id) => !planApprovedIds.has(id));
if (missingFromSeed.length) errors.push(`${missingFromSeed.length} id(s) do plano APPROVED NÃO estão no seed: ${missingFromSeed.join(', ')}`);
if (extraInSeed.length) errors.push(`${extraInSeed.length} id(s) no seed NÃO estão no plano APPROVED: ${extraInSeed.join(', ')}`);

const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
for (const r of rows) {
  if (!uuidRe.test(r.id)) errors.push(`"${r.canonicalName}": id "${r.id}" não é um UUIDv5 válido.`);
}

if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}
if (warnings.length) {
  console.warn('AVISOS:');
  for (const w of warnings) console.warn(' -', w);
}

// ---------------------------------------------------------------------------
// 3. Gera o SQL — VALUES-list única, ON CONFLICT (id) DO NOTHING.
// ---------------------------------------------------------------------------

function sqlString(s) {
  return `'${String(s).replace(/'/g, "''")}'`;
}

const header = `-- ============================================================================
-- Seed de \`public.people\` — SOMENTE os ${rows.length} candidatos canônicos
-- classificados APPROVED em data_export/goias/player_reconciliation/
-- people_insert_plan.json (v3.1 da reconciliação de jogadores, ver
-- docs/multiclub/15_player_reconciliation_report.md). PROVISIONAL (99),
-- BLOCKED_AMBIGUOUS (83) e BLOCKED_INSUFFICIENT_IDENTITY (19) ficam de fora
-- de propósito — preservados nos JSONs pra enriquecimento futuro, nunca
-- forçados a virar pessoa só pra "fechar o banco".
--
-- GERADA por tooling/multiclub/generate_people_seed.mjs — NUNCA editar à
-- mão. Rodar o gerador de novo produz este arquivo byte-a-byte idêntico
-- (entrada determinística: people_insert_plan.json + people_registry.json).
--
-- IDs vêm EXATAMENTE de tooling/multiclub/people_registry.json — nunca
-- gen_random_uuid(), nunca recalculado aqui. Cada id já foi cross-validado
-- contra o registry antes deste arquivo ser escrito (ver o gerador).
--
-- Escopo deliberadamente mínimo — só identidade (id/canonical_name/
-- display_name), nada de clube/jogos/posição/período/estatística. Isso
-- pertence a player_club_spells/player_positions/player_club_stats,
-- migrations futuras ainda não criadas (ver docs/multiclub/
-- 16_live_data_architecture.md).
--
-- Idempotência: ON CONFLICT (id) DO NOTHING, de propósito — este é um seed
-- HISTÓRICO de identidade inicial. Uma correção de nome descoberta depois
-- (ex.: o caso Fabiano, pesquisado nesta mesma reconciliação) deve vir numa
-- migration EXPLÍCITA e posterior com UPDATE, nunca reaplicando este
-- arquivo por cima — DO NOTHING evita que rodar este seed de novo (por
-- engano, ou numa nova instância do banco já corrigida manualmente)
-- sobrescreva silenciosamente uma correção mais recente.
-- ============================================================================

insert into public.people (id, canonical_name, display_name)
values
`;

const valuesLines = rows.map((r, i) => {
  const comma = i === rows.length - 1 ? '' : ',';
  return `  (${sqlString(r.id)}, ${sqlString(r.canonicalName)}, ${sqlString(r.displayName)})${comma}`;
});

const footer = `\non conflict (id) do nothing;\n`;

const sql = header + valuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

// ---------------------------------------------------------------------------
// 4. Relatório da geração
// ---------------------------------------------------------------------------

const report = {
  migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'),
  totalRows: rows.length,
  uniqueIds: idSet.size,
  planIdsMatchSeedIds: missingFromSeed.length === 0 && extraInSeed.length === 0,
  byNameQualityBucket: rows.reduce((acc, r) => { acc[r.nameQualityBucket] = (acc[r.nameQualityBucket] || 0) + 1; return acc; }, {}),
  byIdentityStatus: rows.reduce((acc, r) => { acc[r.identityStatus] = (acc[r.identityStatus] || 0) + 1; return acc; }, {}),
  sample: rows.slice(0, 5).map((r) => ({ id: r.id, canonical_name: r.canonicalName, display_name: r.displayName })),
};

console.log(JSON.stringify(report, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
