// M2.2A — gera (NÃO aplica) as migrations aditivas que dão `club_id` às 24
// tabelas elegíveis (multiclub_m2_2a_plan.json), agrupadas em 6 arquivos
// menores por área funcional. Cada tabela recebe:
//   club_id uuid not null default '<goias>'::uuid references public.clubs(id)
// PG11+: DEFAULT com literal constante evita o heap rewrite tradicional de
// ADD COLUMN — ainda é um DDL com lock breve, nunca "instantâneo garantido"
// (ver relatório §24). NUNCA remove/altera PK ou UNIQUE existente (isso é
// M2.2B). NUNCA toca dado de negócio — só a coluna nova.
//
// Endurecimento da rodada de revisão (2026-09-02): as preconditions/
// postconditions NUNCA comparam count(*) contra o snapshot literal de
// multiclub_m2_2a_row_counts.json — essas tabelas são vivas (progresso/
// votos/scores mudam a cada uso do app), então uma precondition de row
// count exato faria a migration falhar por causa de atividade normal do
// usuário entre a geração e o push, não por corrupção real. O snapshot
// continua existindo como AUDITORIA/evidência (data_export/...), nunca
// como guard executável. As checagens que sobram são semânticas — válidas
// não importa quantas linhas existam no momento real do deploy: clubs=1 +
// slug=goias, coluna ainda não existe (idempotência), e pós-condição
// current-state (0 NULL, 0 órfão, 100% = Goiás) usando count(*) do
// momento real da transação, nunca um número congelado.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATIONS = path.join(ROOT, 'supabase', 'migrations');

const plan = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_m2_2a_plan.json'), 'utf8'));
const GOIAS = plan.goiasClubId;

function sqlLiteral(v) {
  return `'${String(v).replace(/'/g, "''")}'`;
}

function tableBlock(entry) {
  const { table, rowCountBefore } = entry;
  return `  -- ${table} (${rowCountBefore} linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = ${sqlLiteral(table)} and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', ${sqlLiteral(table)};
  end if;

  alter table public.${table}
    add column club_id uuid not null default ${sqlLiteral(GOIAS)}::uuid
    references public.clubs (id);

  create index if not exists ${table}_club_id_idx on public.${table} (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.${table} where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', ${sqlLiteral(table)}, v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.${table} t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', ${sqlLiteral(table)}, v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.${table} where club_id <> ${sqlLiteral(GOIAS)}::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', ${sqlLiteral(table)}, v_non_goias_count;
  end if;
`;
}

function generateGroupSql(groupTitle, groupComment, tables) {
  const blocks = tables.map(tableBlock).join('\n');
  const tableNamesList = tables.map((t) => t.table).join(', ');
  return `-- M2.2A — Additive Tenant Schema — ${groupTitle}
-- ${groupComment}
--
-- Aditivo, backward-compatible: club_id uuid NOT NULL DEFAULT Goiás
-- REFERENCES public.clubs(id), em cada uma das tabelas abaixo
-- (${tableNamesList}). O app publicado atual, que nunca manda club_id,
-- continua funcionando sem nenhuma mudança — toda linha nova cai
-- automaticamente em Goiás via DEFAULT.
--
-- TRANSITIONAL_COMPATIBILITY_DEFAULT: o DEFAULT Goiás é deliberadamente
-- temporário — existe só enquanto há 1 clube real. Precisa ser reavaliado/
-- removido na M2.2B (Tenant Enforcement), depois da M3 (Tenant-Aware
-- Runtime) fazer o app sempre mandar club_id explícito.
--
-- NÃO faz nesta migration (fora de escopo da M2.2A, ver relatório):
--   * nenhuma PK/UNIQUE alterada ou removida (KEY_SCOPE é M2.2B);
--   * nenhum dado de negócio tocado — só a coluna club_id é escrita;
--   * nenhuma RLS/policy alterada;
--   * nenhuma tabela de Passaporte (NEEDS_PRODUCT_DECISION, fora desta rodada).
--
-- PG11+: ADD COLUMN ... DEFAULT <literal> NOT NULL evita o heap rewrite
-- tradicional (o default fica resolvido no catálogo pras linhas já
-- existentes) — mas continua sendo um DDL de lock breve orientado a
-- metadado nesta escala atual, nunca "zero lock" ou "instantâneo
-- garantido". A FK contra clubs(id) precisa validar cada valor já
-- existente na tabela referenciante — hoje isso é rápido só porque a
-- maior tabela candidata tem 262 linhas, não porque clubs ter 1 linha
-- torna a validação grátis por si só.
--
-- Nenhuma precondition/postcondition aqui compara count(*) contra um
-- número congelado — estas tabelas são vivas. Ver comentário do módulo.
--
-- Plano auditável: data_export/goias/player_reconciliation/multiclub_m2_2a_plan.json
-- Snapshot de auditoria (contexto, não guard): data_export/goias/player_reconciliation/multiclub_m2_2a_row_counts.json

do $$
declare
  v_null_count int;
  v_orphan_count int;
  v_non_goias_count int;
  v_clubs_count int;
begin
  -- PRÉ-condição global: exatamente 1 clube, e ele precisa ser exatamente
  -- Goiás (id E slug, não só o UUID isolado) — nunca gerar backfill sobre
  -- um estado de clubs diferente do esperado.
  select count(*) into v_clubs_count from public.clubs;
  if v_clubs_count <> 1 then
    raise exception 'PRÉ-condição falhou: esperava exatamente 1 linha em public.clubs, achou %', v_clubs_count;
  end if;
  if not exists (
    select 1 from public.clubs where id = ${sqlLiteral(GOIAS)}::uuid and slug = 'goias'
  ) then
    raise exception 'PRÉ-condição falhou: club Goiás (id=%, slug=goias) não encontrado exatamente assim em public.clubs', ${sqlLiteral(GOIAS)};
  end if;

${blocks}
end $$;
`;
}

const GROUP_DEFS = [
  {
    key: 'A_content',
    ts: '20260902220000',
    file: 'add_multiclub_content_tenant_scope',
    title: 'Conteúdo editorial (Grupo A)',
    comment: 'career_players, guess_players, squad_members, lineup_matches, quiz_questions — as 5 tabelas de conteúdo do F-series (id text legado preservado, UNIQUE(person_id) das 3 com F1/F3/F4 preservado intocado).',
  },
  {
    key: 'B1_arena_quiz_identity',
    ts: '20260902230000',
    file: 'add_multiclub_arena_quiz_progress_tenant_scope',
    title: 'Progresso Arena/Quiz/Identidade (Grupo B1)',
    comment: 'user_game_item_progress, score_events, quiz_question_progress, quiz_active_session, arena_selected_content, arena_achievements, player_identity_results, tactical_identity_results — progresso genérico de jogo + resultados dos 2 "testes de identidade" (Que Torcedor/Que Craque).',
  },
  {
    key: 'B2_career_lineup_votes',
    ts: '20260902240000',
    file: 'add_multiclub_career_lineup_progress_tenant_scope',
    title: 'Progresso Carreira/Escalação + votos (Grupo B2)',
    comment: 'career_path_progress, lineup_match_progress, match_lineup_votes — progresso específico do Adivinhe o Jogador/Adivinhe a Escalação e os votos da Escalação da Torcida.',
  },
  {
    key: 'B3_tickets_store',
    ts: '20260902250000',
    file: 'add_multiclub_tickets_store_tenant_scope',
    title: 'Ingressos/Loja (Grupo B3)',
    comment: 'ticket_checkin_decisions, ticket_orders, tickets, store_orders — order_number de store_orders continua UNIQUE GLOBAL (M2.1 classificou KEEP_GLOBAL), sequence intocada.',
  },
  {
    key: 'C_membership',
    ts: '20260902260000',
    file: 'add_multiclub_membership_tenant_scope',
    title: 'Sócio Torcedor (Grupo C — achado CRITICAL da M2.1)',
    comment: 'supporter_memberships — hoje 0 linhas em produção. get_my_membership() continua com a mesma assinatura/comportamento (nenhuma RPC alterada nesta rodada, ver relatório §16).',
  },
  {
    key: 'D_notifications',
    ts: '20260902270000',
    file: 'add_multiclub_notifications_tenant_scope',
    title: 'Notificações (Grupo D)',
    comment: 'user_notification_preferences, match_monitor_sessions, notification_events — user_notification_tokens (GLOBAL) e notification_deliveries (herda via event_id) ficam de fora, sem club_id direto.',
  },
];

for (const def of GROUP_DEFS) {
  const tables = plan.groups[def.key];
  if (!tables || tables.length === 0) {
    console.log(`Grupo ${def.key} vazio — migration NÃO gerada (regra: não criar migration vazia).`);
    continue;
  }
  const sql = generateGroupSql(def.title, def.comment, tables);
  const filename = `${def.ts}_${def.file}.sql`;
  fs.writeFileSync(path.join(MIGRATIONS, filename), sql);
  console.log('Gerado (não aplicado):', filename, `(${tables.length} tabelas)`);
}
