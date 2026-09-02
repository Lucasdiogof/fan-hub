// Constrói o seed de `matches` + `match_source_refs` a partir de
// lineup_matches.json — SOMENTE as partidas que já usamos como evidência
// (as 31 do Adivinhe a Escalação). Ponte pra passport_matches só quando
// existe candidato ÚNICO por (data, oponente) — ver audit_match_identity.mjs.
//
// matches.id é literal, resolvido via match_registry.mjs — NUNCA
// gen_random_uuid(). Resolução em 2 ETAPAS por partida:
//   1) resolveMatchAnchors — anchor exato (source_namespace+source_ref).
//      Pra este dataset, o anchor LINEUP_MATCH (namespace
//      'goias_lineup_curated') é sempre a evidência fundadora — por isso,
//      na prática, a etapa 1 sempre resolve pra este dataset (a etapa 2
//      existe pro cenário futuro de uma fonte SEM nenhum anchor
//      compartilhado, ex.: import do Juventude) — exercitada e testada
//      isoladamente em match_registry.mjs, não neste seed histórico.
//   2) resolveMatchCandidate — só chamada quando a etapa 1 não acha nada
//      (não deveria acontecer neste dataset, mas o código cobre o caso
//      defensivamente, igual a qualquer outra etapa).
//
// Prioridade de dado temporal: quando existe link passport ÚNICO,
// passport_matches é a fonte AUTORITATIVA de kickoff (date_precision +
// kickoff_at, já curados por aquele pipeline) — lineup_matches.match_date
// só é usado quando NÃO há link. O heurístico de "dia placeholder" (-01)
// só se aplica à data do lineup_matches (é uma característica conhecida
// SÓ daquele dataset) e NUNCA promove sozinho a precisão pra DATE — só um
// link passport com data confirmada pode fazer essa promoção. Nenhum
// sentinela de dia/mês é persistido — precisão YEAR/MONTH deixa
// kickoff_date genuinamente NULL (ver migration).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadClubRegistry, resolveClubId } from './club_registry.mjs';
import { loadMatchRegistry, saveMatchRegistry, resolveMatch, registerNewMatch, appendAnchors, refreshDescriptor, sideIdentity } from './match_registry.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const OUT_DIR = path.join(DATA, 'player_reconciliation');
const MATCH_REGISTRY_PATH = path.join(__dirname, 'matches_registry.json');
const CLUB_REGISTRY_PATH = path.join(__dirname, 'clubs_registry.json');

const CLUB_LOOKUP_KEY = 'goias';
const LINEUP_NAMESPACE = 'goias_lineup_curated';
const PASSPORT_NAMESPACE = 'goias_passport';

const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));
const passportMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'passport_matches.json'), 'utf8'));
const passportById = new Map(passportMatches.map((p) => [p.id, p]));

const clubRegistry = loadClubRegistry(CLUB_REGISTRY_PATH);
const clubResolved = resolveClubId(clubRegistry, CLUB_LOOKUP_KEY);
if (clubResolved.status !== 'matched') throw new Error('Clube "goias" não está no club registry.');
const CLUB_ID = clubResolved.clubId;
const CLUB_CANONICAL_KEY = clubResolved.canonicalClubKey;

const matchRegistry = loadMatchRegistry(MATCH_REGISTRY_PATH);

const matches = [];
const sourceRefs = [];
const blockedAmbiguousMatch = [];
const registryConflicts = [];
const blockedInsufficientMatchIdentity = [];

for (const m of lineupMatches) {
  const isHomeGoias = m.home_team === 'Goiás';
  const isAwayGoias = m.away_team === 'Goiás';
  if (!isHomeGoias && !isAwayGoias) continue; // nunca deveria acontecer neste dataset, defensivo

  const opponent = isHomeGoias ? m.away_team : m.home_team;
  const candidates = passportMatches.filter((p) => p.match_date === m.match_date && (p.opponent === opponent || p.home_team === opponent || p.away_team === opponent));

  const lineupAnchor = { sourceType: 'LINEUP_MATCH', sourceNamespace: LINEUP_NAMESPACE, sourceRef: m.id };
  let passportMatchId = null;
  if (candidates.length === 1) {
    passportMatchId = candidates[0].id;
  } else if (candidates.length > 1) {
    blockedAmbiguousMatch.push({ lineupMatchId: m.id, matchDate: m.match_date, opponent, candidateCount: candidates.length, candidateIds: candidates.map((c) => c.id), reason: 'BLOCKED_AMBIGUOUS_MATCH (etapa passport-link por data+oponente): 2+ candidatos em passport_matches — nenhum linkado automaticamente.' });
  }

  const anchors = [lineupAnchor];
  if (passportMatchId) anchors.push({ sourceType: 'PASSPORT_MATCH', sourceNamespace: PASSPORT_NAMESPACE, sourceRef: passportMatchId });

  // --- dado temporal: passport (quando linkado) é autoritativo ---
  let kickoffYear, kickoffMonth, kickoffDate, kickoffAt, kickoffPrecision, verificationStatus, dataNotes;
  // "YYYY-01-01" -> mês E dia fabricados (confirmado por auditoria: datas
  // de Brasileirão/Copa do Brasil em 1º de janeiro não fazem sentido de
  // calendário) -> precisão YEAR. "YYYY-MM-01" com MM != 01 -> só o dia é
  // placeholder, mês é plausível -> precisão MONTH. Nunca o contrário.
  const suspectPlaceholderYearOnly = /-01-01$/.test(m.match_date);
  const suspectPlaceholderDay = !suspectPlaceholderYearOnly && /-01$/.test(m.match_date);
  const passportRecord = passportMatchId ? passportById.get(passportMatchId) : null;

  if (passportRecord) {
    const [py, pm] = passportRecord.match_date.split('-').map(Number);
    kickoffYear = py;
    kickoffMonth = pm;
    kickoffDate = passportRecord.match_date;
    if (passportRecord.date_precision === 'datetime' && passportRecord.kickoff_at) {
      kickoffPrecision = 'DATETIME';
      kickoffAt = passportRecord.kickoff_at;
    } else {
      kickoffPrecision = 'DATE';
      kickoffAt = null;
    }
    verificationStatus = 'VERIFIED';
    dataNotes = (suspectPlaceholderDay || suspectPlaceholderYearOnly) && passportRecord.match_date !== m.match_date
      ? `lineup_matches.match_date ("${m.match_date}") tinha ${suspectPlaceholderYearOnly ? 'mês E dia' : 'dia'} placeholder — data real vem de passport_matches (${passportMatchId}): "${passportRecord.match_date}".`
      : null;
  } else {
    const [ly, lm] = m.match_date.split('-').map(Number);
    kickoffYear = ly;
    kickoffAt = null;
    if (suspectPlaceholderYearOnly) {
      kickoffPrecision = 'YEAR';
      kickoffMonth = null; // mês NÃO é confiável — nem tentar preservar o "01" fabricado
      kickoffDate = null; // NUNCA um sentinela "YYYY-01-01" persistido — genuinamente sem dia conhecido
      verificationStatus = 'PARTIAL';
      dataNotes = `Data em lineup_matches.match_date ("${m.match_date}") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).`;
    } else if (suspectPlaceholderDay) {
      kickoffPrecision = 'MONTH';
      kickoffMonth = lm;
      kickoffDate = null; // idem — dia não é fato, não é persistido
      verificationStatus = 'PARTIAL';
      dataNotes = `Dia do mês em lineup_matches.match_date ("${m.match_date}") tem padrão de placeholder (dia=01) e não há link passport_matches pra confirmar — precisão rebaixada pra MONTH, kickoff_date fica NULL (nunca um sentinela).`;
    } else {
      kickoffPrecision = 'DATE';
      kickoffMonth = lm;
      kickoffDate = m.match_date;
      verificationStatus = 'VERIFIED';
      dataNotes = null;
    }
  }

  const kickoff = { precision: kickoffPrecision, year: kickoffYear, month: kickoffMonth, date: kickoffDate, at: kickoffAt };
  const descriptor = {
    homeIdentity: sideIdentity({ clubCanonicalKey: isHomeGoias ? CLUB_CANONICAL_KEY : null, teamName: m.home_team }),
    awayIdentity: sideIdentity({ clubCanonicalKey: isAwayGoias ? CLUB_CANONICAL_KEY : null, teamName: m.away_team }),
    kickoff,
    competition: m.competition || null,
    season: m.season || null,
  };

  // resolve/registra no registry — 2 etapas (anchor exato, depois
  // candidato estrutural) — nunca escolhe sozinho em ambiguidade.
  const resolved = resolveMatch(matchRegistry, { anchors, descriptor });
  let entry;
  if (resolved.status === 'matched') {
    entry = resolved.entry;
    appendAnchors(entry, anchors); // idempotente — só acrescenta anchor novo
    refreshDescriptor(entry, descriptor); // mantém descriptor com o dado mais recente conhecido
  } else if (resolved.status === 'new') {
    entry = registerNewMatch(matchRegistry, anchors, { descriptor });
  } else if (resolved.status === 'insufficient') {
    // BLOCKED_INSUFFICIENT_MATCH_IDENTITY — 1 candidato estrutural, mas
    // precisão temporal insuficiente (YEAR/MONTH) de algum lado. NUNCA
    // resolvido sozinho como EXISTING_MATCH nem criado como NEW_MATCH
    // (já existe potencial colisão) — fica de fora, aguardando override
    // humano estruturado.
    blockedInsufficientMatchIdentity.push({ lineupMatchId: m.id, anchors, candidateCanonicalMatchKeys: resolved.matches.map((x) => x.canonicalMatchKey), reason: 'BLOCKED_INSUFFICIENT_MATCH_IDENTITY: 1 candidato estrutural (identidade de clube + sobreposição temporal batem), mas precisão temporal YEAR/MONTH de algum lado não é forte o bastante pra auto-resolver com segurança.' });
    continue;
  } else {
    // 'ambiguous' — em QUALQUER das 2 etapas. Nunca resolvido sozinho.
    registryConflicts.push({ lineupMatchId: m.id, stage: resolved.stage, anchors, matches: resolved.matches.map((x) => x.canonicalMatchKey) });
    continue;
  }

  matches.push({
    matchId: entry.matchId,
    canonicalMatchKey: entry.canonicalMatchKey,
    // NEW_MATCH = 1ª vez que esta partida é vista (nenhuma etapa "achou"
    // nada, correto). EXISTING_MATCH = uma 2ª/3ª fonte encontrou uma
    // partida JÁ registrada — `resolvedStage` só é significativo aqui
    // (ANCHOR = achou por anchor exato; CANDIDATE = achou só pelo
    // resolver estrutural, sem nenhum anchor em comum).
    resultKind: resolved.status === 'matched' ? 'EXISTING_MATCH' : 'NEW_MATCH',
    resolvedStage: resolved.status === 'matched' ? resolved.stage : null,
    lineupMatchId: m.id,
    homeClubSlug: isHomeGoias ? CLUB_LOOKUP_KEY : null,
    awayClubSlug: isAwayGoias ? CLUB_LOOKUP_KEY : null,
    homeTeamName: m.home_team,
    awayTeamName: m.away_team,
    kickoffYear,
    kickoffMonth,
    kickoffDate,
    kickoffAt,
    kickoffPrecision,
    competition: m.competition || null,
    season: m.season || null,
    homeScore: m.home_score ?? null,
    awayScore: m.away_score ?? null,
    passportMatchId,
    verificationStatus,
    dataNotes,
  });

  sourceRefs.push({ matchId: entry.matchId, sourceType: 'LINEUP_MATCH', sourceNamespace: LINEUP_NAMESPACE, sourceRef: m.id, sourceClubId: CLUB_ID });
  if (passportMatchId) {
    sourceRefs.push({ matchId: entry.matchId, sourceType: 'PASSPORT_MATCH', sourceNamespace: PASSPORT_NAMESPACE, sourceRef: passportMatchId, sourceClubId: CLUB_ID });
  }
}

saveMatchRegistry(MATCH_REGISTRY_PATH, matchRegistry);

const stats = {
  totalMatches: matches.length,
  withPassportLink: matches.filter((m) => m.passportMatchId).length,
  withoutPassportLink: matches.filter((m) => !m.passportMatchId).length,
  verified: matches.filter((m) => m.verificationStatus === 'VERIFIED').length,
  partial: matches.filter((m) => m.verificationStatus === 'PARTIAL').length,
  byKickoffPrecision: matches.reduce((acc, m) => { acc[m.kickoffPrecision] = (acc[m.kickoffPrecision] || 0) + 1; return acc; }, {}),
  sourceRefsTotal: sourceRefs.length,
  sourceRefsByNamespace: sourceRefs.reduce((acc, s) => { acc[s.sourceNamespace] = (acc[s.sourceNamespace] || 0) + 1; return acc; }, {}),
  matchesWith1Source: matches.filter((m) => sourceRefs.filter((s) => s.matchId === m.matchId).length === 1).length,
  matchesWith2PlusSources: matches.filter((m) => sourceRefs.filter((s) => s.matchId === m.matchId).length >= 2).length,
  byResultKind: matches.reduce((acc, m) => { acc[m.resultKind] = (acc[m.resultKind] || 0) + 1; return acc; }, {}),
  existingMatchByStage: matches.filter((m) => m.resultKind === 'EXISTING_MATCH').reduce((acc, m) => { acc[m.resolvedStage] = (acc[m.resolvedStage] || 0) + 1; return acc; }, {}),
  blockedAmbiguousMatch,
  registryConflicts,
  blockedInsufficientMatchIdentity,
};

fs.writeFileSync(path.join(OUT_DIR, 'matches_seed.json'), JSON.stringify(matches, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'match_source_refs_seed.json'), JSON.stringify(sourceRefs, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'matches_seed_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
