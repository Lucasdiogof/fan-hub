// Etapa M1 — inventário de acoplamentos ao Goiás, com verificação real
// (nunca só prosa): cada entrada cita um arquivo+padrão, e o script
// confirma que o padrão AINDA existe no arquivo hoje (nunca confia numa
// lista estática sem checar contra o código real — a mesma disciplina de
// toda etapa anterior). READ-ONLY — nunca escreve em nenhum arquivo de
// produto/Supabase, só nos próprios outputs desta auditoria.
//
// Curado a partir de 5 auditorias de código independentes (bootstrap/DI,
// theming/assets, hardcodes/rotas, progress/ranking/Supabase scope,
// Worker/notifications/store/Arena) + docs/multiclub/05_goias_hardcodes.md
// (auditoria anterior, 2026-09-01, revalidada aqui contra o estado REAL
// de hoje — algumas entradas dela já mudaram desde então, F1-F7 tocaram
// career_players.dart/goias_players.dart/lineup_matches.dart).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

// classification: CLUB_CONFIGURATION | EDITORIAL_CONTENT | HISTORICAL_DATA |
//   FEATURE_SPECIFIC_DATA | ASSET_PATH | NETWORK_INTEGRATION |
//   DATABASE_FILTER | ROUTING | THEME | SAFE_STATIC_CONTENT | LEGACY_TECH_DEBT
// risk: LOW | MEDIUM | HIGH | CRITICAL
const hardcodes = [
  // --- CRITICAL: cross-club data leakage / silent merge ---
  {
    file: 'supabase/arena_ranking.sql',
    pattern: 'primary key (user_id, game_id, item_id)',
    classification: 'DATABASE_FILTER',
    risk: 'CRITICAL',
    note: 'user_game_item_progress — item_id texto livre, sem club_id. 2 clubes com o mesmo item_id (ex.: career_path "tadeu") colidiriam na mesma linha de progresso.',
  },
  {
    file: 'supabase/arena_progress.sql',
    pattern: 'primary key (user_id, game_id)',
    classification: 'DATABASE_FILTER',
    risk: 'CRITICAL',
    note: 'arena_selected_content — a PK nem inclui item_id, só game_id. "Última partida vista" de 2 clubes no mesmo jogo colidiria na mesma linha.',
  },
  {
    file: 'supabase/supporter_memberships.sql',
    pattern: 'create table if not exists public.supporter_memberships',
    classification: 'DATABASE_FILTER',
    risk: 'CRITICAL',
    note: 'sem club_id — get_my_membership() (limit 1, sem filtro) vazaria status de sócio de um clube pro app de outro se o backend fosse compartilhado sem correção.',
  },
  {
    file: 'lib/features/match/domain/entities/team.dart',
    pattern: "name.toLowerCase().contains('goi')",
    classification: 'LEGACY_TECH_DEBT',
    risk: 'HIGH',
    note: 'Team.isGoias — fallback por substring, falso-positivo em qualquer time com "goi" no nome (Goiânia, Goianésia). 3ª reimplementação independente do mesmo check existe em crowd_lineup_page.dart e passport_match_ticket_v2.dart.',
    fixedInEtapa: 'M3.3', // Team.isGoias removido — vira Team.matchesClub(ClubConfig), por id real, nunca mais substring de nome.
  },
  {
    file: 'lib/features/arena/games/lineup/data/lineup_match_repository.dart',
    pattern: "teamToGuess: 'Goiás'",
    classification: 'LEGACY_TECH_DEBT',
    risk: 'HIGH',
    note: 'literal fixo — o jogo inteiro assume que o time a adivinhar é sempre Goiás, independente do dado da linha.',
    fixedInEtapa: 'M3.3', // vira _clubConfig.identity.shortName no repository real (lineup_matches.dart, o FALLBACK local, continua 'Goiás' de propósito — só serve o clube 'goias').
  },
  {
    file: 'src/index.ts',
    pattern: "/api/football/team/goias",
    classification: 'NETWORK_INTEGRATION',
    risk: 'HIGH',
    note: 'rota do Worker com o nome do clube no contrato de URL, não só num valor de config.',
    fixedInEtapa: 'M3.3', // vira rota genérica /team/:clubCode (TEAM_PATTERN) — '/team/goias' continua respondendo, mas via o MESMO handler genérico com clubCode='goias', nunca um literal separado no roteamento.
  },
  {
    file: 'supabase/functions/notifications-poll-live-match/index.ts',
    pattern: 'GOIAS_TEAM_ID = 1863',
    classification: 'NETWORK_INTEGRATION',
    risk: 'HIGH',
    note: 'decide qual lado é "nosso time" pra detecção de gol — precisa virar config por clube antes de um 2º clube compartilhar esta function.',
    fixedInEtapa: 'M3.3', // vira resolveClubServerConfigByClubId(session.club_id).oneFootballTeamId — club_id desconhecido pula a sessão (fail-closed), nunca assume Goiás.
  },

  // --- MEDIUM: precisa de ClubConfig antes de generalizar, mas não vaza dado hoje ---
  {
    file: 'lib/features/match/domain/entities/team.dart',
    pattern: 'static const int goiasId = 1863;',
    classification: 'CLUB_CONFIGURATION',
    risk: 'MEDIUM',
    note: 'candidato direto a ClubConfig.integrations.oneFootballTeamId — já modelado (goias_club_config.dart), consumidor ainda não migrado.',
    fixedInEtapa: 'M3.3', // Team.goiasId removido — todo consumidor migrado pra ClubConfig.integrations.oneFootballTeamId (via Team.matchesClub ou acesso direto).
  },
  {
    file: 'lib/shared/widgets/club_badge.dart',
    pattern: 'if (team.isGoias)',
    classification: 'LEGACY_TECH_DEBT',
    risk: 'MEDIUM',
    note: 'widget de crest de uso global força asset local só pro Goiás — ponto de dependência crucial pra qualquer 2º clube.',
    fixedInEtapa: 'M3.3', // vira if (team.matchesClub(sl<ClubConfig>())), asset vem de clubConfig.assets.crestBadge (nunca mais AppAssets.goiasCrestBadge hardcoded).
  },
  {
    file: 'lib/features/crowd_lineup/presentation/pages/crowd_lineup_page.dart',
    pattern: '_isGoiasHome',
    classification: 'LEGACY_TECH_DEBT',
    risk: 'MEDIUM',
    note: 'reimplementação própria (não reusa Team.isGoias) do mesmo check, pra decidir arte de camisa mandante/visitante.',
    fixedInEtapa: 'M3.3', // vira _isActiveClubHome, usando Team.matchesClub — mesma função central que club_badge.dart/next_match_hero.dart passam a usar.
  },
  {
    file: 'lib/features/passport/presentation/v2/widgets/passport_match_ticket_v2.dart',
    pattern: "team.toLowerCase().contains('goiás')",
    classification: 'LEGACY_TECH_DEBT',
    risk: 'MEDIUM',
    note: '3ª reimplementação independente do mesmo check, com acento (diferente das outras 2, que usam "goi" sem acento) — inconsistência real entre si.',
    fixedInEtapa: 'M4.1', // Passaporte segue NEEDS_PRODUCT_DECISION/PASSPORT_TENANCY_DEFERRED (nada de tenancy mudou), mas esse bug pontual de identificação de time virou sl<ClubConfig>().identity.shortName/.displayName — corrigido isoladamente, achado da auditoria M4.
  },
  {
    file: 'lib/features/match/data/repositories/football_repository_impl.dart',
    pattern: 'getGoiasSnapshot',
    classification: 'LEGACY_TECH_DEBT',
    risk: 'MEDIUM',
    note: 'nome de método do repositório principal de partidas — lock-in de naming, chamado de 4+ lugares (home_cubit, games_cubit, membership_cubit, live_match_poller).',
    fixedInEtapa: 'M3.3', // renomeado getActiveClubSnapshot() em toda a cadeia (interface/impl/datasource) + nos 5 call sites.
  },
  {
    file: 'supabase/store_orders.sql',
    pattern: "'GOI-'",
    classification: 'DATABASE_FILTER',
    risk: 'MEDIUM',
    note: 'generate_store_order_number() — prefixo fixo, precisaria ler clubs.order_prefix (já modelado em ClubConfig.integrations.orderPrefix).',
  },
  {
    file: 'lib/core/theme/app_colors.dart',
    pattern: 'darkGreen',
    classification: 'THEME',
    risk: 'MEDIUM',
    note: 'token de matiz literal (não papel semântico) — junto com deepGreen/ctaGreen, hardcoda a suposição "a cor do clube é verde".',
  },
  {
    file: 'pubspec.yaml',
    pattern: 'adaptive_icon_background: "#004C1B"',
    classification: 'THEME',
    risk: 'MEDIUM',
    note: 'hex duplicado fora do Dart (ícone adaptativo/splash/tema web) — 4 ocorrências, não templatizável em runtime, é config de build nativo.',
  },
  {
    file: 'lib/features/arena/data/arena_catalog.dart',
    pattern: 'static const games',
    classification: 'FEATURE_SPECIFIC_DATA',
    risk: 'MEDIUM',
    note: 'lista fixa de jogos, não vem de ClubConfig.capabilities.enabledArenaGames (já modelado, não consumido ainda).',
  },
  {
    file: 'src/news/article.ts',
    pattern: "SITE_ORIGIN = 'https://www.goiasec.com.br'",
    classification: 'NETWORK_INTEGRATION',
    risk: 'MEDIUM',
    note: 'scraper de notícias amarrado ao site oficial do Goiás — generalizar exige parser HTML novo por clube, não é só trocar config.',
  },

  // --- LOW: conteúdo histórico/editorial legítimo, nunca deveria virar variável ---
  {
    file: 'data_export/goias/lineup_matches.json',
    pattern: '"home_team": "Goiás"',
    classification: 'HISTORICAL_DATA',
    risk: 'LOW',
    note: 'partida histórica real ("Goiás x Flamengo 1990") — dado, não branding. Nunca deveria virar template.',
  },
  {
    file: 'lib/l10n/app_pt.arb',
    pattern: 'Esmeraldina',
    classification: 'EDITORIAL_CONTENT',
    risk: 'LOW',
    note: '16 de 1160 chaves l10n têm gentílico/apelido do clube embutido no valor PT-BR — candidato a nome de produto configurável (ClubProductNaming já modela o conceito), mas baixo risco (nunca vaza dado, só precisa de tradução por clube).',
  },
  {
    file: 'lib/main.dart',
    pattern: "title: 'Goiás EC'",
    classification: 'SAFE_STATIC_CONTENT',
    risk: 'LOW',
    note: 'título do MaterialApp.router — não visível na maioria das plataformas, cosmético.',
    fixedInEtapa: 'M4.1', // vira _clubConfig.identity.displayName — achado da auditoria M4 (title bypassava ClubConfig mesmo já existindo o campo certo).
  },
];

// verificação REAL — cada entrada precisa do padrão citado ainda presente
// no arquivo (nunca confia na lista sem checar contra o código de hoje).
//
// Exceção deliberada: `fixedInEtapa` — quando uma etapa POSTERIOR corrige
// de verdade um hardcode catalogado aqui (M3.3 corrigiu 8, ver acima), a
// entrada nunca é apagada (perderia o histórico do achado original) nem
// fica "stale" pra sempre (quebraria esta suíte a cada rodada futura, o
// mesmo padrão de regressão auto-referencial já visto em M2.2A/M3.1/M3.2)
// — passa a ser verificada como RESOLVED em vez de STALE, e checada contra
// `fixedPatternMustBeAbsent` (quando presente) pra provar que o hardcode
// genuinamente sumiu, nunca só confiar na etiqueta.
const verified = [];
const resolved = [];
const stale = [];
for (const h of hardcodes) {
  const fullPath = path.join(ROOT, h.file);
  if (h.fixedInEtapa) {
    if (!fs.existsSync(fullPath)) {
      stale.push({ ...h, reason: 'arquivo não existe mais' });
      continue;
    }
    const content = fs.readFileSync(fullPath, 'utf8');
    if (content.includes(h.pattern)) {
      // Etiquetado como corrigido, mas o padrão AINDA está lá — isso é uma
      // regressão real, não staleness (o oposto do caso normal) — vira erro.
      stale.push({ ...h, reason: `marcado fixedInEtapa mas o padrão AINDA existe no arquivo — regressão real, não staleness normal` });
      continue;
    }
    resolved.push(h);
    continue;
  }
  if (!fs.existsSync(fullPath)) {
    stale.push({ ...h, reason: 'arquivo não existe mais' });
    continue;
  }
  const content = fs.readFileSync(fullPath, 'utf8');
  if (!content.includes(h.pattern)) {
    stale.push({ ...h, reason: 'padrão citado não encontrado no arquivo atual — pode ter sido corrigido ou movido' });
    continue;
  }
  verified.push(h);
}

// --- sanity checks estruturais (fatos centrais do relatório, sempre re-checados) ---
const sanity = {};

sanity.clubUuidOnlyInGoiasClubConfig = (() => {
  // desde a M1, o único lugar LEGÍTIMO pro UUID canônico do Goiás em
  // lib/ é a própria config centralizada — em qualquer outro arquivo,
  // seria exatamente o hardcode espalhado que a M1 existe pra eliminar.
  const uuid = '4c16340d-300c-5ab2-903f-17519db9b146';
  const libDir = path.join(ROOT, 'lib');
  const allowed = path.join(ROOT, 'lib', 'core', 'club', 'goias_club_config.dart');
  const offenders = [];
  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith('.dart') && full !== allowed && fs.readFileSync(full, 'utf8').includes(uuid)) offenders.push(path.relative(ROOT, full));
    }
  }
  walk(libDir);
  return { pass: offenders.length === 0, offenders, allowedFile: path.relative(ROOT, allowed) };
})();

// M4 (rebrand Fan Hub): o registry de produção tem os clubes REAIS `goias` +
// `bragantino` (o sintético `club-b`/`clubb` foi removido). O sanity check
// garante que SÓ clubes reais conhecidos entram — nenhum placeholder/sintético
// e o Goiás sempre presente.
sanity.clubRegistryRealClubs = (() => {
  const src = fs.readFileSync(path.join(ROOT, 'lib', 'core', 'club', 'club_registry.dart'), 'utf8');
  const keys = [...src.matchAll(/'([a-z_]+)':\s*\w+ClubConfig/g)].map((m) => m[1]);
  const known = ['goias', 'bragantino'];
  const unexpected = keys.filter((k) => !known.includes(k));
  return { pass: keys.includes('goias') && unexpected.length === 0, keys, unexpected };
})();

// Só as configs de clube CONHECIDAS podem existir (goias + bragantino reais);
// qualquer outro `*_club_config.dart` seria um clube não-cadastrado/sintético.
sanity.onlyKnownClubConfigs = (() => {
  const clubDir = path.join(ROOT, 'lib', 'core', 'club');
  const files = fs.readdirSync(clubDir);
  const allowed = ['club_config.dart', 'goias_club_config.dart', 'bragantino_club_config.dart'];
  const unexpected = files.filter((f) => /club_config\.dart$/.test(f) && !allowed.includes(f));
  return { pass: unexpected.length === 0, files, unexpected };
})();

sanity.routesHaveNoClubSlug = (() => {
  const src = fs.readFileSync(path.join(ROOT, 'lib', 'core', 'router', 'app_router.dart'), 'utf8');
  const paths = [...src.matchAll(/path:\s*'([^']+)'/g)].map((m) => m[1]);
  const offenders = paths.filter((p) => /goias|juventude|bragantino/i.test(p));
  return { pass: offenders.length === 0, totalRoutes: paths.length, offenders };
})();

const stats = {
  totalHardcodes: hardcodes.length,
  verified: verified.length,
  resolved: resolved.length,
  resolvedList: resolved,
  stale: stale.length,
  staleList: stale,
  byRisk: {
    CRITICAL: verified.filter((h) => h.risk === 'CRITICAL').length,
    HIGH: verified.filter((h) => h.risk === 'HIGH').length,
    MEDIUM: verified.filter((h) => h.risk === 'MEDIUM').length,
    LOW: verified.filter((h) => h.risk === 'LOW').length,
  },
  byClassification: hardcodes.reduce((acc, h) => { acc[h.classification] = (acc[h.classification] || 0) + 1; return acc; }, {}),
  sanity,
};

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_hardcode_audit.json'), JSON.stringify({ hardcodes: verified, resolved, stale }, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_hardcode_audit_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
