// M3.2 — audita, lendo os arquivos .dart/.sql REAIS (nunca uma lista
// assumida), se as tabelas de estado por usuário/infra (progresso, score,
// conquistas, identidades, votos, ingressos, loja, sócio, preferências de
// notificação) e as RPCs correspondentes estão genuinamente tenant-scoped
// no runtime Flutter: leitura/escrita direta filtra por club_id, DI injeta
// ClubConfig, RPC nova recebe p_club_id, RPC legacy continua intacta e
// nunca mais chamada pelo Flutter novo, nenhum UUID hardcoded fora de
// goias_club_config.dart.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const SUPABASE_DIR = path.join(ROOT, 'supabase');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const GOIAS_UUID = '4c16340d-300c-5ab2-903f-17519db9b146';

// Tabelas com leitura/escrita direta a partir do Flutter nesta etapa.
// keyScopeBlocked=true significa: a PK/UNIQUE física da tabela NÃO inclui
// club_id ainda (M2.2B resolve) — club_id é escrito/filtrado (ROW_SCOPE),
// mas o onConflict continua na chave antiga.
const DIRECT_TABLES = {
  quiz_question_progress: {
    repos: ['features/arena/games/quiz/data/quiz_progress_repository.dart'],
    keyScopeBlocked: true,
  },
  quiz_active_session: {
    repos: ['features/arena/games/quiz/data/quiz_progress_repository.dart'],
    keyScopeBlocked: true,
  },
  career_path_progress: {
    repos: ['features/arena/games/career_path/data/supabase_career_path_storage.dart'],
    keyScopeBlocked: true,
  },
  lineup_match_progress: {
    repos: ['features/arena/games/lineup/data/supabase_lineup_storage.dart'],
    keyScopeBlocked: true,
  },
  arena_selected_content: {
    repos: [
      'features/arena/games/career_path/data/supabase_career_path_storage.dart',
      'features/arena/games/lineup/data/supabase_lineup_storage.dart',
    ],
    keyScopeBlocked: true,
  },
  arena_achievements: {
    repos: ['features/arena/data/arena_progress_repository.dart'],
    keyScopeBlocked: true,
  },
  player_identity_results: {
    repos: ['features/arena/games/player_identity/data/supabase_player_identity_repository.dart'],
    keyScopeBlocked: true,
  },
  tactical_identity_results: {
    repos: ['features/arena/games/tactical_identity/data/supabase_tactical_identity_repository.dart'],
    keyScopeBlocked: true,
  },
  match_lineup_votes: {
    repos: ['features/crowd_lineup/data/supabase_crowd_lineup_repository.dart'],
    keyScopeBlocked: false, // UNIQUE(match_id, user_id) já é composta, mas sem club_id — ainda assim colisão é teórica (ver comentário no repo)
  },
  ticket_checkin_decisions: {
    repos: ['features/ticket/data/mock_ticket_repository.dart'],
    keyScopeBlocked: true,
  },
  ticket_orders: {
    repos: ['features/ticket/data/mock_ticket_repository.dart'],
    keyScopeBlocked: false, // PK é id (uuid), sem UNIQUE em number — não há chave física pra colidir
  },
  tickets: {
    repos: ['features/ticket/data/mock_ticket_repository.dart'],
    keyScopeBlocked: true, // só o índice parcial (user_id, match_id) WHERE origin='membership_check_in'
    // M3.4: o check-in de sócio passou a gravar via RPC dedicada
    // (upsert_membership_checkin_ticket_for_club, p_club_id) porque o índice
    // é PARCIAL e o onConflict do PostgREST não expressa o predicate; a
    // compra (purchase) continua gravando club_id direto em cada linha.
    checkinRpc: 'upsert_membership_checkin_ticket_for_club',
  },
  store_orders: {
    repos: ['features/store/data/supabase_store_orders_repository.dart'],
    keyScopeBlocked: false, // PK é id (uuid); order_number é UNIQUE GLOBAL de propósito (KEEP_GLOBAL)
    writeVia: 'rpc', // grava via create_store_order_for_club, nunca .insert()/.upsert() direto — ver RPCS abaixo
  },
  user_notification_preferences: {
    repos: ['features/notifications/data/supabase_notification_repository.dart'],
    keyScopeBlocked: true,
  },
};

// Tabelas explicitamente FORA do escopo Flutter desta rodada — só
// Edge Functions (Deno) tocam, sem ClubConfig equivalente no servidor
// (M3.3 é quem generaliza o Worker/pipeline de notificações). Documentado,
// não esquecido.
//
// Correção da rodada de revisão de segurança: `user_notification_tokens`
// NÃO pertence aqui — ela TEM owner Dart real
// (`supabase_notification_repository.dart`, `registerToken`/
// `deactivateToken`), só nunca foi (nem deve ser) tenant-scoped porque o
// token FCM é do APARELHO, não do clube. Classificação correta:
// USER_GLOBAL (ver GLOBAL_TABLES abaixo) — as 3 REALMENTE Edge-Function-only
// continuam aqui.
const EDGE_FUNCTION_ONLY_TABLES = {
  match_monitor_sessions: {
    reason: 'só Edge Functions (Deno) escrevem — 0 owner Dart. Server-side ainda 100% hardcoded pro Goiás (GOIAS_TEAM_ID=1863 em notifications-poll-live-match); club-aware aí é M3.3.',
    hasClubIdColumn: true,
  },
  notification_events: {
    reason: 'mesma razão de match_monitor_sessions — só Edge Functions.',
    hasClubIdColumn: true,
  },
  notification_deliveries: {
    reason: 'herda tenancy via event_id (FK pra notification_events) — nunca ganhou club_id próprio, por decisão explícita da M2.2A.',
    hasClubIdColumn: false,
  },
};

// Tabelas com owner Dart real, mas DELIBERADAMENTE fora de tenant-scope —
// dado do usuário/dispositivo que nunca depende do clube ativo.
const GLOBAL_TABLES = {
  user_notification_tokens: {
    reason: 'GLOBAL de propósito — token FCM é do APARELHO, não do clube (owner: supabase_notification_repository.dart, registerToken/deactivateToken). Nunca deve ganhar club_id.',
    ownerRepo: 'features/notifications/data/supabase_notification_repository.dart',
    hasClubIdColumn: false,
  },
};

// Migration de correção pós-push (achado real: `pg_default_acl` do projeto
// Supabase tem `ALTER DEFAULT PRIVILEGES ... GRANT EXECUTE ON FUNCTIONS TO
// postgres, anon, authenticated, service_role` no nível do projeto — toda
// `CREATE FUNCTION` nova em `public` já nasce com EXECUTE pra anon/
// authenticated/service_role automaticamente, um mecanismo separado do
// grant implícito a PUBLIC. `REVOKE ALL FROM PUBLIC` sozinho NUNCA remove
// isso — confirmado ao vivo via `pg_proc.proacl` logo após o push das 4
// migrations originais, que só revogavam de PUBLIC). Esta migration
// endurece as mesmas 8 RPCs, sem tocar nas 4 originais nem na legacy.
const HARDENING_MIGRATION = '20260903040000_harden_tenant_rpc_execute_grants.sql';

// Estado inicial REAL confirmado ao vivo (pg_default_acl + proacl das RPCs
// legacy e das 8 novas antes desta 2ª correção) — toda função nova em
// `public` nasce com EXECUTE pra estes 4 roles simultaneamente, nunca só
// PUBLIC. Usado como ponto de partida da simulação de grants efetivos.
const DEFAULT_ACL_ROLES_ON_CREATE = ['public', 'anon', 'authenticated', 'service_role'];

// RPCs novas tenant-aware — cada uma tem uma legacy homônima (sem
// "_for_club") que precisa continuar intocada E nunca mais chamada pelo
// Flutter novo (item 36 do pedido).
const RPCS = {
  arena_record_score_for_club: {
    legacy: 'arena_record_score',
    callerRepo: 'features/arena/ranking/data/supabase_arena_ranking_repository.dart',
    migration: '20260903000000_add_arena_tenant_aware_rpcs.sql',
    legacySqlFile: 'arena_ranking.sql',
    signature: 'uuid, text, text, text, int, text, int, int, int, boolean, boolean',
    securityDefiner: true,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  arena_ranking_for_club: {
    legacy: 'arena_ranking',
    callerRepo: 'features/arena/ranking/data/supabase_arena_ranking_repository.dart',
    migration: '20260903000000_add_arena_tenant_aware_rpcs.sql',
    legacySqlFile: 'arena_ranking.sql',
    signature: 'uuid, text, int',
    securityDefiner: true,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  arena_my_rank_for_club: {
    legacy: 'arena_my_rank',
    callerRepo: 'features/arena/ranking/data/supabase_arena_ranking_repository.dart',
    migration: '20260903000000_add_arena_tenant_aware_rpcs.sql',
    legacySqlFile: 'arena_ranking.sql',
    signature: 'uuid, text',
    securityDefiner: true,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  arena_user_detail_for_club: {
    legacy: 'arena_user_detail',
    callerRepo: 'features/arena/ranking/data/supabase_arena_ranking_repository.dart',
    migration: '20260903000000_add_arena_tenant_aware_rpcs.sql',
    legacySqlFile: 'arena_ranking.sql',
    signature: 'uuid, uuid',
    securityDefiner: true,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  get_my_membership_for_club: {
    legacy: 'get_my_membership',
    callerRepo: 'features/membership/data/supabase_membership_repository.dart',
    migration: '20260903010000_add_membership_tenant_aware_rpcs.sql',
    legacySqlFile: 'supporter_memberships.sql',
    signature: 'uuid',
    securityDefiner: true,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  subscribe_to_plan_for_club: {
    legacy: 'subscribe_to_plan',
    callerRepo: 'features/membership/data/supabase_membership_repository.dart',
    migration: '20260903010000_add_membership_tenant_aware_rpcs.sql',
    legacySqlFile: null, // legacy vive só em supabase/migrations/20260830220002_subscribe_to_plan_rpc.sql
    signature: 'uuid, text',
    securityDefiner: true,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  crowd_lineup_for_club: {
    legacy: 'crowd_lineup',
    callerRepo: 'features/crowd_lineup/data/supabase_crowd_lineup_repository.dart',
    migration: '20260903020000_add_crowd_lineup_tenant_aware_rpc.sql',
    legacySqlFile: 'crowd_lineup.sql',
    signature: 'uuid, text',
    securityDefiner: true,
    // Achado real (auth-guard): a tela está 100% atrás do redirect global
    // de login — mesmo a legacy concedendo `anon` explicitamente, nenhum
    // caller anônimo alcança esta RPC hoje. Least-privilege pro que
    // realmente é usado.
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
  create_store_order_for_club: {
    legacy: 'create_store_order',
    callerRepo: 'features/store/data/supabase_store_orders_repository.dart',
    migration: '20260903030000_add_store_tenant_aware_rpc.sql',
    legacySqlFile: 'store_orders.sql',
    signature: 'uuid, text, text, jsonb, jsonb, jsonb, jsonb, jsonb, numeric, numeric,\n  numeric, text, jsonb',
    securityDefiner: false,
    expectedRoles: ['authenticated'],
    hardeningMigration: HARDENING_MIGRATION,
  },
};

function stripComments(src) {
  return src
    .split('\n')
    .filter((l) => !l.trim().startsWith('//') && !l.trim().startsWith('///'))
    .join('\n');
}

// Tabelas reais cujo nome, se aparecer SEM o prefixo `public.` dentro do
// corpo de uma função SECURITY DEFINER, é um problema de qualificação de
// schema (risco de resolução via pg_temp) — nunca um falso-positivo de CTE
// local (v/fc/sc/window_events/totals/... nunca estão nesta lista).
const KNOWN_REAL_TABLES = [
  'clubs', 'score_events', 'user_game_item_progress', 'supporter_memberships',
  'match_lineup_votes', 'profiles', 'quiz_questions', 'career_players',
  'guess_players', 'lineup_matches', 'store_orders', 'store_order_items',
];

// Isola o corpo de UMA função dentro de um arquivo de migration que pode
// ter várias — do `create or replace function public.<name>(` até o `$$;`
// de fechamento (nenhuma das funções desta etapa usa dollar-quoting
// aninhado, então o primeiro `$$;` depois do `as $$` de abertura é sempre
// o fechamento certo).
function extractFunctionBlock(migSrc, name) {
  const startIdx = migSrc.indexOf(`create or replace function public.${name}(`);
  if (startIdx === -1) return null;
  const asIdx = migSrc.indexOf('as $$', startIdx);
  if (asIdx === -1) return null;
  const endIdx = migSrc.indexOf('$$;', asIdx + 5);
  if (endIdx === -1) return null;
  return migSrc.slice(startIdx, endIdx + 3);
}

// Extrai toda declaração `revoke ... from <roles>;` / `grant ... to <roles>;`
// que referencia a função `rpc` num arquivo de migration — usado pra simular
// o estado EFETIVO do ACL somando várias migrations em ordem (nunca confiar
// só na migration original, que sozinha já se provou insuficiente — ver
// HARDENING_MIGRATION acima).
function extractGrantRevokeStatements(src, rpc) {
  const statements = [];
  const re = new RegExp(
    `revoke (?:all|execute) on function public\\.${rpc}\\([\\s\\S]*?\\)\\s*from\\s+([a-z_,\\s]+);|` +
    `grant execute on function public\\.${rpc}\\([\\s\\S]*?\\)\\s*to\\s+([a-z_,\\s]+);`,
    'g'
  );
  let m;
  while ((m = re.exec(src)) !== null) {
    if (m[1]) statements.push({ type: 'revoke', roles: m[1].split(',').map((r) => r.trim()).filter(Boolean) });
    else statements.push({ type: 'grant', roles: m[2].split(',').map((r) => r.trim()).filter(Boolean) });
  }
  return statements;
}

// Simula o ACL efetivo de `rpc` somando, EM ORDEM, todas as migrations que a
// tocam (a de criação + a(s) de hardening subsequentes, se houver) —
// partindo do estado REAL confirmado ao vivo no momento da criação
// (DEFAULT_ACL_ROLES_ON_CREATE, nunca um estado assumido/ideal).
function computeEffectiveGrants(rpc, cfg) {
  const files = [cfg.migration, cfg.hardeningMigration].filter(Boolean);
  const roles = new Set(DEFAULT_ACL_ROLES_ON_CREATE);
  const timeline = [];
  for (const file of files) {
    const p = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', file);
    if (!fs.existsSync(p)) continue;
    const src = fs.readFileSync(p, 'utf8');
    for (const stmt of extractGrantRevokeStatements(src, rpc)) {
      timeline.push({ file, ...stmt });
      for (const r of stmt.roles) {
        if (stmt.type === 'revoke') roles.delete(r);
        else roles.add(r);
      }
    }
  }
  return { effectiveRoles: [...roles].sort(), timeline };
}

function checkSchemaQualification(functionBlock) {
  const problems = [];
  for (const table of KNOWN_REAL_TABLES) {
    // só é problema se a ocorrência de `from/into/update/join <table>` NÃO
    // for precedida por "public." (ex.: "public.clubs" está ok).
    const re = new RegExp(`(from|into|update|join)\\s+${table}\\b`, 'gi');
    let match;
    while ((match = re.exec(functionBlock)) !== null) {
      const before = functionBlock.slice(Math.max(0, match.index - 8), match.index);
      if (!/public\.\s*$/i.test(before)) problems.push(`${match[0]} (sem public.)`);
    }
  }
  return { schemaQualified: problems.length === 0, problems };
}

const directTableResults = {};
for (const [table, cfg] of Object.entries(DIRECT_TABLES)) {
  let hasClubIdInReads = false;
  let hasClubIdInWrites = false;
  let hasClubConfigCtorParam = false;
  let hardcodedGoiasUuid = false;
  for (const repoRelPath of cfg.repos) {
    const src = fs.readFileSync(path.join(LIB, repoRelPath), 'utf8');
    const body = stripComments(src);
    if (new RegExp(`from\\('${table}'\\)[\\s\\S]{0,400}?\\.eq\\('club_id'`).test(body)) {
      hasClubIdInReads = true;
    }
    if (
      new RegExp(`from\\('${table}'\\)[\\s\\S]{0,60}?\\.(upsert|insert|update)\\([\\s\\S]{0,400}?'club_id':`).test(body) ||
      // janela maior pro caso do purchase: monta uma lista de linhas (com
      // 'club_id') e depois insere a variável em .from('tickets').insert(rows)
      new RegExp(`'club_id':\\s*_clubId[\\s\\S]{0,1600}?from\\('${table}'\\)`).test(body)
    ) {
      hasClubIdInWrites = true;
    }
    // M3.4: caminho de escrita tenant-aware via RPC dedicada (ex.: check-in
    // de sócio, cujo índice é parcial e não vai por onConflict de colunas).
    if (cfg.checkinRpc && new RegExp(`${cfg.checkinRpc}[\\s\\S]{0,400}?'p_club_id':`).test(body)) {
      hasClubIdInWrites = true;
    }
    if (/this\._clubConfig\)/.test(body) || /,\s*this\._clubConfig\s*[,)]/.test(body) || /required this\._clubConfig/.test(body)) {
      hasClubConfigCtorParam = true;
    }
    if (body.includes(GOIAS_UUID)) hardcodedGoiasUuid = true;
  }
  const writeViaRpc = cfg.writeVia === 'rpc';
  directTableResults[table] = {
    repos: cfg.repos,
    keyScopeBlocked: cfg.keyScopeBlocked,
    writeVia: cfg.writeVia ?? 'direct',
    hasClubIdInReads,
    hasClubIdInWrites,
    hasClubConfigCtorParam,
    hardcodedGoiasUuid,
    rowScopeReady:
      hasClubIdInReads &&
      (writeViaRpc || hasClubIdInWrites) &&
      hasClubConfigCtorParam &&
      !hardcodedGoiasUuid,
  };
}

const rpcResults = {};
for (const [rpc, cfg] of Object.entries(RPCS)) {
  const repoSrc = fs.readFileSync(path.join(LIB, cfg.callerRepo), 'utf8');
  const body = stripComments(repoSrc);

  const newRpcCallSitePresent = body.includes(`'${rpc}'`);
  const hasClubIdParam = new RegExp(`'${rpc}'[\\s\\S]{0,200}?'p_club_id':\\s*_clubId`).test(body);

  // legacy nunca mais chamado pelo Flutter novo: procura `'<legacy>'` que
  // NÃO seja imediatamente seguido de `_for_club'` (ou seja, o nome exato
  // da RPC antiga usado como STRING de chamada `.rpc('<legacy>'`).
  const legacyCallPattern = new RegExp(`'${cfg.legacy}'(?!_for_club)`);
  const legacyStillCalledInFlutter = legacyCallPattern.test(body);

  const migrationPath = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', cfg.migration);
  const migrationExists = fs.existsSync(migrationPath);
  let migrationValidatesClubId = false;
  let migrationIsAdditiveOnly = true;
  if (migrationExists) {
    const migSrc = fs.readFileSync(migrationPath, 'utf8');
    migrationValidatesClubId =
      migSrc.includes(`create or replace function public.${rpc}(`) &&
      /p_club_id is null then\s*\n\s*raise exception/.test(migSrc) &&
      /not exists \(select 1 from public\.clubs where id = p_club_id\)/.test(migSrc);
    // aditiva-only: nunca DROP FUNCTION da legacy, nunca ALTER/DROP em PK/UNIQUE/DEFAULT.
    migrationIsAdditiveOnly =
      !new RegExp(`drop function[\\s\\S]*?public\\.${cfg.legacy}\\(`, 'i').test(migSrc) &&
      !/drop\s+(primary key|constraint|default)/i.test(migSrc) &&
      !/\balter\s+table[\s\S]*?\balter\s+column[\s\S]*?drop\s+default\b/i.test(migSrc);
  }

  let legacySqlStillDefined = true; // default true quando não há arquivo-fonte único conhecido (ex.: subscribe_to_plan)
  if (cfg.legacySqlFile) {
    const legacyPath = path.join(SUPABASE_DIR, cfg.legacySqlFile);
    if (fs.existsSync(legacyPath)) {
      const legacySrc = fs.readFileSync(legacyPath, 'utf8');
      legacySqlStillDefined = legacySrc.includes(`create or replace function public.${cfg.legacy}(`);
    } else {
      legacySqlStillDefined = false;
    }
  }

  // ==========================================================================
  // Hardening de segurança (rodada de revisão pós-M3.2): REVOKE PUBLIC
  // explícito, grant allowlist exata, search_path seguro (só nas
  // SECURITY DEFINER) e qualificação de schema em toda relação real
  // referenciada.
  // ==========================================================================
  let revokePublicPresent = false;
  let grantAllowlistMatches = false;
  let grantedRoles = [];
  let safeSearchPath = !cfg.securityDefiner; // não aplicável a SECURITY INVOKER
  let schemaQualified = false;
  let isSecurityDefiner = null;
  let schemaQualificationProblems = [];
  if (migrationExists) {
    const migSrc = fs.readFileSync(migrationPath, 'utf8');

    revokePublicPresent = new RegExp(
      `revoke all on function public\\.${rpc}\\(`
    ).test(migSrc);

    const grantMatch = migSrc.match(
      new RegExp(`grant execute on function public\\.${rpc}\\([\\s\\S]{0,400}?\\)\\s*to\\s+([a-z_,\\s]+);`)
    );
    if (grantMatch) {
      grantedRoles = grantMatch[1].split(',').map((r) => r.trim()).filter(Boolean).sort();
      const expected = [...cfg.expectedRoles].sort();
      grantAllowlistMatches =
        grantedRoles.length === expected.length &&
        grantedRoles.every((r, i) => r === expected[i]);
    }

    const functionBlock = extractFunctionBlock(migSrc, rpc);
    if (functionBlock) {
      isSecurityDefiner = /\bsecurity definer\b/i.test(functionBlock);
      if (cfg.securityDefiner) {
        safeSearchPath = /set search_path = pg_catalog, public, pg_temp/.test(functionBlock);
      }
      const qualCheck = checkSchemaQualification(functionBlock);
      schemaQualified = qualCheck.schemaQualified;
      schemaQualificationProblems = qualCheck.problems;
    }
  }
  const securityDefinerMatchesExpected = isSecurityDefiner === cfg.securityDefiner;

  // Estado EFETIVO do ACL (migration de criação + hardening subsequente,
  // simulado em ordem a partir do default real do projeto — nunca só o
  // texto da migration original, que já se provou insuficiente ao vivo).
  const { effectiveRoles, timeline: grantTimeline } = computeEffectiveGrants(rpc, cfg);
  const effectivePublicGranted = effectiveRoles.includes('public');
  const effectiveRealRoles = effectiveRoles.filter((r) => r !== 'public').sort();
  const expectedSorted = [...cfg.expectedRoles].sort();
  const effectiveGrantAllowlistMatches =
    !effectivePublicGranted &&
    effectiveRealRoles.length === expectedSorted.length &&
    effectiveRealRoles.every((r, i) => r === expectedSorted[i]);

  rpcResults[rpc] = {
    legacy: cfg.legacy,
    callerRepo: cfg.callerRepo,
    newRpcCallSitePresent,
    hasClubIdParam,
    legacyStillCalledInFlutter,
    migrationExists,
    migrationValidatesClubId,
    migrationIsAdditiveOnly,
    legacySqlStillDefined,
    expectedRoles: cfg.expectedRoles,
    grantedRoles,
    revokePublicPresent,
    grantAllowlistMatches,
    hardeningMigration: cfg.hardeningMigration ?? null,
    effectiveRoles,
    effectivePublicGranted,
    effectiveAnonGranted: effectiveRoles.includes('anon'),
    effectiveServiceRoleGranted: effectiveRoles.includes('service_role'),
    effectiveGrantAllowlistMatches,
    grantTimeline,
    expectedSecurityDefiner: cfg.securityDefiner,
    isSecurityDefiner,
    securityDefinerMatchesExpected,
    safeSearchPath,
    schemaQualified,
    schemaQualificationProblems,
    securityHardeningReady:
      revokePublicPresent &&
      effectiveGrantAllowlistMatches &&
      securityDefinerMatchesExpected &&
      safeSearchPath &&
      schemaQualified,
    tenantAwareReady:
      newRpcCallSitePresent &&
      hasClubIdParam &&
      !legacyStillCalledInFlutter &&
      migrationExists &&
      migrationValidatesClubId &&
      migrationIsAdditiveOnly &&
      legacySqlStillDefined &&
      revokePublicPresent &&
      effectiveGrantAllowlistMatches &&
      securityDefinerMatchesExpected &&
      safeSearchPath &&
      schemaQualified,
  };
}

// UUID hardcoded — varre TODOS os arquivos de repository tocados nesta
// etapa (direct tables + RPC callers), nunca confia numa lista prévia.
const touchedRepoFiles = new Set([
  ...Object.values(DIRECT_TABLES).flatMap((c) => c.repos),
  ...Object.values(RPCS).map((c) => c.callerRepo),
  'core/di/injection_container.dart',
]);
const goiasUuidHardcodedInTouchedFiles = [...touchedRepoFiles].filter((f) =>
  fs.readFileSync(path.join(LIB, f), 'utf8').includes(GOIAS_UUID)
);

const securityDefinerCount = Object.values(RPCS).filter((c) => c.securityDefiner).length;
const securityInvokerCount = Object.values(RPCS).filter((c) => !c.securityDefiner).length;

const audit = {
  directTables: directTableResults,
  rpcs: rpcResults,
  edgeFunctionOnlyTables: EDGE_FUNCTION_ONLY_TABLES,
  globalTables: GLOBAL_TABLES,
  goiasUuidHardcodedInTouchedFiles,
  allDirectTablesRowScopeReady: Object.values(directTableResults).every((r) => r.rowScopeReady),
  allRpcsTenantAwareReady: Object.values(rpcResults).every((r) => r.tenantAwareReady),
  allRpcsSecurityHardeningReady: Object.values(rpcResults).every((r) => r.securityHardeningReady),
  summary: {
    directTablesCount: Object.keys(DIRECT_TABLES).length,
    rpcsCount: Object.keys(RPCS).length,
    edgeFunctionOnlyTablesCount: Object.keys(EDGE_FUNCTION_ONLY_TABLES).length,
    globalTablesCount: Object.keys(GLOBAL_TABLES).length,
    securityDefinerCount,
    securityInvokerCount,
  },
};

fs.writeFileSync(
  path.join(RECON, 'multiclub_runtime_user_state_scope_audit.json'),
  JSON.stringify(audit, null, 2) + '\n'
);
console.log(JSON.stringify({
  allDirectTablesRowScopeReady: audit.allDirectTablesRowScopeReady,
  allRpcsTenantAwareReady: audit.allRpcsTenantAwareReady,
  allRpcsSecurityHardeningReady: audit.allRpcsSecurityHardeningReady,
  securityDefinerCount,
  securityInvokerCount,
  goiasUuidHardcodedInTouchedFiles: audit.goiasUuidHardcodedInTouchedFiles,
  directTables: Object.fromEntries(Object.entries(directTableResults).map(([t, r]) => [t, {
    hasClubIdInReads: r.hasClubIdInReads,
    hasClubIdInWrites: r.hasClubIdInWrites,
    hasClubConfigCtorParam: r.hasClubConfigCtorParam,
    rowScopeReady: r.rowScopeReady,
    keyScopeBlocked: r.keyScopeBlocked,
  }])),
  rpcs: Object.fromEntries(Object.entries(rpcResults).map(([r, v]) => [r, {
    tenantAwareReady: v.tenantAwareReady,
    securityHardeningReady: v.securityHardeningReady,
    grantedRoles: v.grantedRoles,
    isSecurityDefiner: v.isSecurityDefiner,
    safeSearchPath: v.safeSearchPath,
    schemaQualified: v.schemaQualified,
    schemaQualificationProblems: v.schemaQualificationProblems,
    legacyStillCalledInFlutter: v.legacyStillCalledInFlutter,
    legacySqlStillDefined: v.legacySqlStillDefined,
  }])),
}, null, 2));
console.log('\nEscrito em:', RECON);
