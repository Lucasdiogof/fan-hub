// Gera as 2 migrations ADITIVAS da Etapa F3 a partir de
// guess_players_person_mapping.json — NUNCA um `select ... where
// canonical_name ilike ...` dentro do SQL, sempre UUID literal já
// resolvido pelo mapping. Mesma disciplina endurecida da F1: sem índice
// redundante (UNIQUE já cria o seu), backfill com pré/pós-condição forte
// num DO block, RAISE EXCEPTION se a realidade não bater exatamente.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCHEMA_MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902160000_add_person_id_to_guess_players.sql');
const BACKFILL_MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902170000_backfill_guess_players_person_id.sql');

const mapping = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'guess_players_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'guess_players_person_mapping_stats.json'), 'utf8'));

const errors = [];
const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
for (const m of mapping) {
  if (m.status === 'RESOLVED') {
    if (!m.personId || !uuidRe.test(m.personId)) errors.push(`${m.guessPlayerId}: RESOLVED sem personId UUID válido.`);
  } else if (m.personId) {
    errors.push(`${m.guessPlayerId}: status=${m.status} mas personId preenchido — só RESOLVED pode ter personId.`);
  }
}
if (stats.personIdReusedAcrossRows.length > 0) {
  errors.push(`cardinalidade: ${stats.personIdReusedAcrossRows.length} person_id reusado(s) entre linhas RESOLVED — UNIQUE(person_id) NÃO seria seguro, gerador abortado, decisão precisa de revisão humana antes de gerar a migration.`);
}
if (errors.length) {
  console.error('ERROS — MIGRATION NÃO GERADA:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }

const resolved = mapping.filter((m) => m.status === 'RESOLVED').sort((a, b) => a.guessPlayerId.localeCompare(b.guessPlayerId));
const unresolvedCount = mapping.length - resolved.length;

// ---------------------------------------------------------------------------
// Migration 1 — schema (coluna aditiva, nullable, FK, UNIQUE, sem índice
// redundante — UNIQUE já cria seu próprio índice btree)
// ---------------------------------------------------------------------------
const schemaSql = `-- ============================================================================
-- Etapa F3 — adiciona identidade canônica a \`public.guess_players\` (Quem
-- Vestiu o Manto), SEM remover nada do modelo atual. \`guess_players\`
-- continua existindo e sendo lido normalmente pela feature — esta coluna
-- é só a ponte pra \`people\`, consumida quando fizer sentido, nunca
-- obrigatória pra a feature funcionar hoje.
--
-- person_id NULLABLE de propósito: ${unresolvedCount} de ${mapping.length} linhas ainda não
-- têm identidade canônica APROVADA o bastante pra persistir com segurança
-- (ver guess_players_person_mapping_stats.json). NUNCA forçar NOT NULL só
-- pra fechar a migration.
--
-- UNIQUE(person_id): auditado, não suposto — cardinalidade real verificada
-- nos 2 sentidos: (a) nenhuma das ${resolved.length} linhas RESOLVED reusa um
-- person_id já usado por outra (guess_players_person_mapping_stats.json.
-- personIdReusedAcrossRows, vazio); (b) nenhuma pessoa canônica tem 2+
-- members source='guess_players' em canonical_people_candidates.json
-- (checado diretamente, 0 casos). Reforçado por evidência estrutural do
-- próprio dataset: as 173 linhas têm 173 display_name distintos (0
-- duplicata) — não há "edições"/"eras" do mesmo jogador modeladas como
-- linhas separadas nesta feature, ao contrário do que se cogitou auditar.
--
-- SEM índice adicional: UNIQUE(person_id) já cria seu próprio índice
-- (btree) no Postgres.
--
-- Migration ADITIVA: não altera nenhuma linha, nenhuma RLS/policy/grant,
-- nenhuma outra tabela.
-- ============================================================================

alter table public.guess_players
  add column if not exists person_id uuid references public.people(id);

alter table public.guess_players
  add constraint guess_players_person_id_key unique (person_id);

comment on column public.guess_players.person_id is
  'Identidade canônica (Etapa F3) — aponta pra people.id quando existe
  exatamente 1 pessoa canônica APROVADA reconciliada pra este jogador
  (ver tooling/multiclub/guess_players_person_mapping.json). NULL quando
  ainda não há identidade segura o bastante (nunca resolvido por nome
  parecido) — guess_players.name/display_name continuam a fonte de
  exibição enquanto person_id for NULL. NUNCA usar guess_players.name como
  FK lógica pra decidir "é a mesma pessoa" em código novo — use person_id.';
`;

fs.mkdirSync(path.dirname(SCHEMA_MIGRATION_PATH), { recursive: true });
fs.writeFileSync(SCHEMA_MIGRATION_PATH, schemaSql);

// ---------------------------------------------------------------------------
// Migration 2 — backfill (UPDATE literal, só as RESOLVED) + validação forte
// ---------------------------------------------------------------------------
const expectedTotal = mapping.length;
const expectedResolved = resolved.length;
const expectedNull = expectedTotal - expectedResolved;

const expectedValuesLines = resolved.map((m, i) => `    (${sqlString(m.guessPlayerId)}, ${sqlString(m.personId)}::uuid)${i === resolved.length - 1 ? '' : ','} -- ${m.canonicalName}`);
const updateLines = resolved.map((m) => `  update public.guess_players set person_id = ${sqlString(m.personId)}::uuid where id = ${sqlString(m.guessPlayerId)}; -- ${m.canonicalName}`);

const backfillSql = `-- ============================================================================
-- Etapa F3 — backfill de \`guess_players.person_id\` pras ${expectedResolved} linhas
-- RESOLVED (de ${expectedTotal} totais — as outras ${expectedNull} ficam NULL, nunca um
-- palpite). GERADA por tooling/multiclub/generate_guess_players_person_
-- migration.mjs a partir de tooling/multiclub/build_guess_players_person_
-- mapping.mjs — NUNCA editar à mão, NUNCA um \`select ... where
-- canonical_name ilike\`, sempre UUID literal já resolvido pelo mapping.
--
-- Endurecido com PRÉ e PÓS-condição — mesma disciplina da Etapa F1, mais
-- 1 precondição nova pedida na revisão desta etapa — a migration FALHA
-- (RAISE EXCEPTION, rollback automático da transação inteira) se a
-- realidade do banco não bater EXATAMENTE com o que foi auditado:
--   PRÉ 1: guess_players tem exatamente ${expectedTotal} linhas.
--   PRÉ 2: cada um dos ${expectedResolved} ids esperados EXISTE na tabela antes do
--          backfill.
--   PRÉ 3: count(person_id IS NOT NULL) = 0 ANTES do backfill — person_id
--          acabou de ser criado na migration anterior, então QUALQUER
--          valor pré-existente é inesperado (indicaria a migration
--          anterior já ter sido re-executada com dado diferente, ou
--          alguém tendo escrito na coluna fora deste pipeline) — nunca
--          sobrescrever silenciosamente, aborta.
--   PÓS:   cada uma das ${expectedResolved} linhas termina com o person_id
--          EXATO esperado (não só "não-nulo"); contagem de person_id NOT
--          NULL = ${expectedResolved}; contagem NULL = ${expectedNull}; contagem de person_id
--          DISTINCT (não-nulo) = ${expectedResolved} (nenhuma duplicata). FK de
--          people(id) já é garantida estruturalmente pela constraint da
--          migration anterior.
--
-- Idempotente por construção: cada UPDATE seta o MESMO literal toda vez
-- que rodar — reprocessar não muda o resultado, e a pós-condição continua
-- batendo.
-- ============================================================================

do $$
declare
  v_expected_total integer := ${expectedTotal};
  v_expected_resolved integer := ${expectedResolved};
  v_expected_null integer := ${expectedNull};
  v_missing_before text;
  v_mismatched_after text;
  v_actual_total integer;
  v_actual_resolved integer;
  v_actual_null integer;
  v_actual_distinct integer;
  v_prefilled_before integer;
begin
  -- PRÉ 1: total de linhas bate com o auditado
  select count(*) into v_actual_total from public.guess_players;
  if v_actual_total != v_expected_total then
    raise exception 'guess_players tem % linhas, esperado % — auditoria desatualizada, backfill abortado', v_actual_total, v_expected_total;
  end if;

  -- PRÉ 2: cada um dos ${expectedResolved} ids esperados EXISTE antes do backfill
  -- (nunca resolver por name/display_name/ilike/aliases — sempre este par
  -- literal (id, person_id) vindo do mapping).
  select string_agg(e.id, ', ') into v_missing_before
  from (
    values
${expectedValuesLines.join('\n')}
  ) as e(id, person_id)
  left join public.guess_players gp on gp.id = e.id
  where gp.id is null;
  if v_missing_before is not null then
    raise exception 'guess_players.id esperado(s) ausente(s) ANTES do backfill: % — auditoria desatualizada, backfill abortado', v_missing_before;
  end if;

  -- PRÉ 3: person_id tem que estar 100% vazio ANTES do backfill — a
  -- coluna acabou de ser criada pela migration anterior, então qualquer
  -- valor não-nulo aqui é inesperado. Nunca sobrescrever silenciosamente.
  select count(*) into v_prefilled_before from public.guess_players where person_id is not null;
  if v_prefilled_before != 0 then
    raise exception 'guess_players.person_id já tem % linha(s) preenchida(s) ANTES do backfill — inesperado (a coluna acabou de ser criada), backfill abortado pra nunca sobrescrever silenciosamente', v_prefilled_before;
  end if;

  -- Backfill — UPDATE literal, um por linha RESOLVED, idempotente.
${updateLines.join('\n')}

  -- PÓS 1: cada linha esperada termina com o person_id EXATO esperado.
  select string_agg(e.id || ' esperado=' || e.person_id::text || ' obtido=' || coalesce(gp.person_id::text, 'NULL'), '; ')
  into v_mismatched_after
  from (
    values
${expectedValuesLines.join('\n')}
  ) as e(id, person_id)
  join public.guess_players gp on gp.id = e.id
  where gp.person_id is distinct from e.person_id;
  if v_mismatched_after is not null then
    raise exception 'backfill não bateu EXATAMENTE com o mapping esperado: % — backfill abortado, nenhuma linha parcialmente aplicada persiste', v_mismatched_after;
  end if;

  -- PÓS 2: contagens agregadas.
  select
    count(*) filter (where person_id is not null),
    count(*) filter (where person_id is null),
    count(distinct person_id) filter (where person_id is not null)
  into v_actual_resolved, v_actual_null, v_actual_distinct
  from public.guess_players;

  if v_actual_resolved != v_expected_resolved then
    raise exception 'person_id NOT NULL = %, esperado % — backfill abortado', v_actual_resolved, v_expected_resolved;
  end if;
  if v_actual_null != v_expected_null then
    raise exception 'person_id NULL = %, esperado % — backfill abortado', v_actual_null, v_expected_null;
  end if;
  if v_actual_distinct != v_expected_resolved then
    raise exception 'person_id distintos (não-nulos) = %, esperado % — indica duplicata, backfill abortado', v_actual_distinct, v_expected_resolved;
  end if;

  raise notice 'Etapa F3 backfill validado: % total, % resolved, % null, % distinct person_id — tudo bate exatamente com o mapping auditado.', v_actual_total, v_actual_resolved, v_actual_null, v_actual_distinct;
end $$;
`;

fs.writeFileSync(BACKFILL_MIGRATION_PATH, backfillSql);

console.log(JSON.stringify({
  schemaMigration: path.relative(ROOT, SCHEMA_MIGRATION_PATH).replace(/\\/g, '/'),
  backfillMigration: path.relative(ROOT, BACKFILL_MIGRATION_PATH).replace(/\\/g, '/'),
  resolvedRows: resolved.length,
  unresolvedRows: unresolvedCount,
}, null, 2));
console.log('\nSQL escrito em supabase/migrations/ (NÃO aplicado — item 18 do pedido)');
