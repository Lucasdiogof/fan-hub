// M2.2A — combina o audit de tenant scope da M2.1
// (multiclub_tenant_constraints_audit.json) com o snapshot real de row
// counts (multiclub_m2_2a_row_counts.json, capturado via `supabase db
// query --linked`, NUNCA consultado ao vivo daqui) pra produzir o plano
// aditivo desta etapa: 1 coluna `club_id` por tabela elegível, agrupada em
// migrations menores e logicamente coerentes.
//
// Elegibilidade (nunca uma lista cega — derivada do output real da M2.1):
//   rowScopeProblem === true
//   E group !== tabelas que INHERIT via FK (tenantStrategy começa com
//     'INHERITS_FROM_')
//   E não é Passaporte (passport_matches/passport_attendances/
//     passport_memorable_matches — fora de escopo nesta rodada, item 33)
//   E não é KEEP_GLOBAL (user_notification_tokens)
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_tenant_constraints_audit.json'), 'utf8'));
const rowCounts = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_m2_2a_row_counts.json'), 'utf8'));

if (rowCounts.clubsTableRowCount !== 1) {
  console.error(`ABORTADO: clubs deveria ter exatamente 1 linha, snapshot registra ${rowCounts.clubsTableRowCount}. PARE — não gerar plano de backfill sobre um estado inesperado.`);
  process.exit(1);
}
const GOIAS_CLUB_ID = rowCounts.goiasClubId;

// mapeamento explícito table -> grupo de migration (granularidade segura,
// pedido item 24) — nunca derivado automaticamente do "group" da M2.1
// (CONTENT/PROGRESS/MEMBERSHIP/NOTIFICATIONS é grosso demais: PROGRESS
// sozinho tem 15 tabelas elegíveis, dividido aqui em 3 sub-grupos por área
// funcional pra manter rollback/debug por migration pequeno).
const MIGRATION_GROUPS = {
  A_content: ['career_players', 'guess_players', 'squad_members', 'lineup_matches', 'quiz_questions'],
  B1_arena_quiz_identity: ['user_game_item_progress', 'score_events', 'quiz_question_progress', 'quiz_active_session', 'arena_selected_content', 'arena_achievements', 'player_identity_results', 'tactical_identity_results'],
  B2_career_lineup_votes: ['career_path_progress', 'lineup_match_progress', 'match_lineup_votes'],
  B3_tickets_store: ['ticket_checkin_decisions', 'ticket_orders', 'tickets', 'store_orders'],
  C_membership: ['supporter_memberships'],
  D_notifications: ['user_notification_preferences', 'match_monitor_sessions', 'notification_events'],
};

const auditByTable = new Map(audit.tables.map((t) => [t.table, t]));

// --- elegibilidade derivada, nunca lista cega ---
const eligible = audit.tables.filter((t) => {
  if (!t.rowScopeProblem) return false;
  if (t.tenantStrategy && t.tenantStrategy.startsWith('INHERITS_FROM_')) return false;
  if (t.tenantStrategy === 'KEEP_GLOBAL') return false;
  if (t.table === 'passport_matches' || t.table === 'passport_attendances' || t.table === 'passport_memorable_matches') return false;
  return true;
});

const groupedTableNames = new Set(Object.values(MIGRATION_GROUPS).flat());
const eligibleTableNames = new Set(eligible.map((t) => t.table));

const missingFromGroups = [...eligibleTableNames].filter((t) => !groupedTableNames.has(t));
const extraInGroups = [...groupedTableNames].filter((t) => !eligibleTableNames.has(t));
if (missingFromGroups.length || extraInGroups.length) {
  console.error('ABORTADO: divergência entre a elegibilidade derivada da M2.1 e o agrupamento manual.');
  if (missingFromGroups.length) console.error('  elegíveis mas SEM grupo:', missingFromGroups);
  if (extraInGroups.length) console.error('  no grupo mas NÃO elegíveis:', extraInGroups);
  process.exit(1);
}

const plan = {
  goiasClubId: GOIAS_CLUB_ID,
  totalEligibleTables: eligible.length,
  groups: {},
  excludedTables: audit.tables
    .filter((t) => !eligibleTableNames.has(t.table))
    .map((t) => ({
      table: t.table,
      reason: !t.rowScopeProblem
        ? 'NO_ROW_SCOPE_PROBLEM'
        : t.table.startsWith('passport_')
          ? 'PASSPORT_OUT_OF_SCOPE_THIS_ROUND'
          : t.tenantStrategy?.startsWith('INHERITS_FROM_')
            ? t.tenantStrategy
            : t.tenantStrategy === 'KEEP_GLOBAL'
              ? 'KEEP_GLOBAL'
              : 'OTHER',
      tenantStrategy: t.tenantStrategy,
    })),
};

for (const [groupId, tableNames] of Object.entries(MIGRATION_GROUPS)) {
  plan.groups[groupId] = tableNames.map((tableName) => {
    const t = auditByTable.get(tableName);
    const rowCountBefore = rowCounts.counts[tableName];
    if (rowCountBefore === undefined) {
      throw new Error(`sem row count no snapshot pra ${tableName} — não posso gerar precondition sem o número real.`);
    }
    return {
      table: tableName,
      pk: t.pk,
      group: t.group,
      rowCountBefore,
      strategy: 'ADD_COLUMN_NOT_NULL_DEFAULT_GOIAS',
      // PG11+: ADD COLUMN ... DEFAULT <literal> NOT NULL não reescreve a
      // tabela (o default fica no catálogo pras linhas existentes) — seguro
      // e rápido mesmo nas maiores destas tabelas (score_events, 262 linhas
      // hoje). Ver item 8/29 do relatório pra justificativa completa.
    };
  });
}

fs.writeFileSync(path.join(RECON, 'multiclub_m2_2a_plan.json'), JSON.stringify(plan, null, 2) + '\n');
console.log(JSON.stringify({
  totalEligibleTables: plan.totalEligibleTables,
  groups: Object.fromEntries(Object.entries(plan.groups).map(([k, v]) => [k, v.map((x) => x.table)])),
  excludedCount: plan.excludedTables.length,
}, null, 2));
console.log('\nEscrito em:', RECON);
