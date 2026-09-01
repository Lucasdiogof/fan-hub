// Relatório de reconciliação de identidade de jogador — v3.1: separa
// IDENTIDADE (é a mesma pessoa?) de QUALIDADE DE DADO (os números/período
// batem?) como duas dimensões independentes, em vez de uma classificação
// única. NUNCA decide um conflito sozinho — só agrupa candidatos por
// nome/alias, mostra os dados de cada fonte lado a lado, classifica os dois
// eixos com a evidência que sustenta cada um, e sinaliza o que precisa de
// revisão humana. Nenhum INSERT é gerado aqui. Reaproveitável: roda de novo
// se os exports em data_export/goias/ mudarem.
//
// Fontes incluídas nesta passada (6, desde v3.1 — goias_players.dart deixou
// de ser uma auditoria paralela e virou uma fonte de primeira classe, pra
// que candidates.json represente o universo INTEIRO que vai pra `people`,
// não um subconjunto + um relatório solto por cima):
//   squad_members, career_players, guess_players, lineup_matches,
//   player_identity_references (Dart, parseado por regex), goias_players_dart
//   (Dart, 215 nomes de autocomplete — SEM período/posição/número, então
//   corrobora/estende clusters existentes mas raramente decide identidade
//   sozinho; quando não une com nada, vira SINGLE_SOURCE novo, exatamente
//   como qualquer outra fonte rasa).
//
// Fontes AINDA fora de escopo (ver seção "Fora de escopo" no relatório
// gerado, pra nunca ficar implícito):
//   - goias_squad.dart (Escalação da Torcida) — já verificado em auditoria
//     anterior (03_data_sources.md) como cópia 1:1 de squad_members
//     (mesmos ids/números de camisa), não reprocessado aqui;
//   - tactical_coach_references.dart — são TÉCNICOS, não jogadores.
//
// IMPORTANTE sobre "investigar fontes históricas/documentais": este script
// só usa dado que JÁ está no repositório (os próprios exports SQL, cruzados
// entre si). Ele não faz nenhuma busca externa/web — onde a evidência
// interna não é suficiente, o candidato fica marcado como tal (NEEDS_REVIEW
// ou AMBIGUOUS_IDENTITY), nunca "resolvido" por suposição.
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const EXPORT = path.join(ROOT, 'data_export', 'goias');
const LIB = path.join(ROOT, 'lib');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

fs.mkdirSync(OUT_DIR, { recursive: true });

// ---------------------------------------------------------------------------
// Utilitários
// ---------------------------------------------------------------------------

function normalize(str) {
  return String(str)
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** UUID PROVISÓRIO — determinístico (sha256 do texto), NÃO é um UUID real
 * gerado pelo banco. Só serve pra dar um identificador estável a cada
 * candidato entre execuções do script, pra facilitar revisão. O UUID
 * definitivo, se o mapeamento for aprovado, vem de `gen_random_uuid()` no
 * INSERT real (que esta etapa explicitamente NÃO gera). */
function provisionalUuid(key) {
  const hash = crypto.createHash('sha256').update(key).digest('hex');
  return [
    hash.slice(0, 8), hash.slice(8, 12), hash.slice(12, 16),
    hash.slice(16, 20), hash.slice(20, 32),
  ].join('-');
}

const CURRENT_YEAR = 2026;

/**
 * Extrai intervalos de ano de uma string de período livre em PT-BR — SEMPRE
 * devolve uma LISTA de intervalos, um por segmento separado por `/` ou `;`,
 * nunca um único min/max da string inteira (uma string tipo "2012–2013 /
 * 2019" tem DUAS passagens, não um intervalo contínuo 2012-2019).
 */
function extractYears(periodStr) {
  if (!periodStr) return [];
  const segments = periodStr.split(/[/;]/);
  const ranges = [];
  for (const segment of segments) {
    const years = [...segment.matchAll(/\b(19|20)\d{2}\b/g)].map((m) => parseInt(m[0], 10));
    if (years.length === 0) continue;
    const isOpenEnded = /atual|desde/i.test(segment);
    ranges.push({
      start: Math.min(...years),
      end: isOpenEnded ? CURRENT_YEAR : Math.max(...years),
      raw: segment.trim(),
    });
  }
  return ranges;
}

function rangesOverlapOrClose(rangesA, rangesB, toleranceYears) {
  for (const a of rangesA) {
    for (const b of rangesB) {
      const gap = a.end < b.start ? b.start - a.end : b.end < a.start ? a.start - b.end : 0;
      if (gap <= toleranceYears) return true;
    }
  }
  return false;
}

const POSITION_GROUPS = {
  goleiro: ['gol', 'goleiro', 'goalkeeper'],
  defesa: ['lateral', 'zagueiro', 'zaga', 'ld', 'le', 'zag', 'defesa', 'defensor', 'beque'],
  meio: ['volante', 'meia', 'meio', 'vol', 'mc', 'me', 'md', 'meio-campo', 'meio-campista'],
  ataque: ['atacante', 'ponta', 'centroavante', 'ata', 'pe', 'pd', 'sa', 'artilheiro'],
};

/** Devolve TODOS os grupos que uma string de posição toca (nunca só o
 * primeiro) — "Atacante / meia-atacante" é ataque+meio ao mesmo tempo. */
function positionGroups(pos) {
  if (!pos) return new Set();
  const n = normalize(pos);
  const groups = new Set();
  for (const [group, keywords] of Object.entries(POSITION_GROUPS)) {
    if (keywords.some((k) => n === k || n.includes(k))) groups.add(group);
  }
  return groups;
}

/**
 * "Candidatos a nome completo" de um registro — o campo `fullName`
 * explícito quando existe, MAIS qualquer alias de 2+ palavras. Isso importa
 * de verdade: `guess_players` guarda o nome completo só dentro de
 * `aliases` (nunca em `display_name`/`fullName`) — olhar só `fullName`
 * perdia esse sinal de corroboração inteiro pra qualquer cluster que
 * envolvesse essa fonte. Nomes de 1 palavra só (apelido/primeiro nome) não
 * contam aqui — esse já é o critério de AGRUPAMENTO (fraco por design),
 * não pode também ser o critério de CORROBORAÇÃO (forte), senão vira
 * círculo vicioso.
 */
function fullNameCandidates(record) {
  const candidates = [record.fullName, ...(record.aliases || [])].filter(Boolean);
  return candidates.filter((n) => normalize(n).split(' ').length >= 2).map(normalize);
}

function numbersClose(a, b, absTolerance = 3, relTolerance = 0.03) {
  if (a == null || b == null) return null;
  if (a === b) return true;
  const diff = Math.abs(a - b);
  return diff <= absTolerance || diff / Math.max(a, b, 1) <= relTolerance;
}

// ---------------------------------------------------------------------------
// Carregamento das fontes — um "record" por jogador dentro de cada fonte
// ---------------------------------------------------------------------------

function readJson(name) {
  return JSON.parse(fs.readFileSync(path.join(EXPORT, name), 'utf8'));
}

function loadSquad() {
  return readJson('squad_members.json').map((r) => ({
    source: 'squad_members', sourceId: r.id, primaryName: r.name, fullName: r.full_name,
    aliases: [r.full_name].filter(Boolean), position: r.position, shirtNumber: r.shirt_number,
    birthDate: r.birth_date,
    goiasSpells: (r.club_history || []).filter((h) => h.is_goias)
      .map((h) => ({ period: h.period, appearances: h.appearances, goals: h.goals, loan: h.loan })),
    raw: r,
  }));
}

function loadCareer() {
  return readJson('career_players.json').map((r) => ({
    source: 'career_players', sourceId: r.id, primaryName: r.answer, fullName: null,
    aliases: r.accepted_answers || [], position: r.position, shirtNumber: null, birthDate: null,
    goiasSpells: (r.club_career || []).filter((h) => h.is_goias)
      .map((h) => ({ period: h.period, appearances: h.appearances, goals: h.goals, loan: h.loan })),
    raw: r,
  }));
}

function loadGuess() {
  return readJson('guess_players.json').map((r) => ({
    source: 'guess_players', sourceId: r.id, primaryName: r.name,
    fullName: r.display_name && r.display_name !== r.name ? r.display_name : null,
    aliases: r.aliases || [], position: r.position, shirtNumber: r.shirt_number, birthDate: null,
    goiasDebutYear: r.goias_debut_year, goiasSpells: [], raw: r,
  }));
}

function loadLineup() {
  const matches = readJson('lineup_matches.json');
  const byName = new Map();
  for (const m of matches) {
    for (const slot of m.lineup || []) {
      const key = normalize(slot.name || slot.answer || '');
      if (!key) continue;
      if (!byName.has(key)) {
        byName.set(key, {
          source: 'lineup_matches', sourceId: key, primaryName: slot.name, fullName: null,
          aliases: slot.aliases || [], position: slot.pos, shirtNumber: slot.no, birthDate: null,
          goiasSpells: [], matchAppearances: [], raw: slot,
        });
      }
      byName.get(key).matchAppearances.push({
        matchId: m.id, competition: m.competition, season: m.season,
        date: m.match_date, pos: slot.pos, shirtNumber: slot.no,
      });
    }
  }
  return [...byName.values()];
}

function loadPlayerIdentityReferences() {
  const file = path.join(LIB, 'features/arena/games/player_identity/domain/player_identity_references.dart');
  const src = fs.readFileSync(file, 'utf8');
  const re = /PlayerIdentityReference\(\s*id:\s*'([^']*)',\s*name:\s*'([^']*)',\s*period:\s*'([^']*)'/g;
  const out = [];
  let m;
  while ((m = re.exec(src)) !== null) {
    out.push({
      source: 'player_identity_references', sourceId: m[1], primaryName: m[2], fullName: null,
      aliases: [], position: null, shirtNumber: null, birthDate: null,
      goiasSpells: [{ period: m[3], appearances: null, goals: null, loan: null }],
      raw: { id: m[1], name: m[2], period: m[3] },
    });
  }
  return out;
}

/** goias_players.dart (autocomplete, 215 nomes) — SEM período/posição/
 * número/nascimento, mesmo parser por regex já usado pra
 * player_identity_references.dart. sourceId é o índice de declaração no
 * arquivo (estável entre execuções, já que a lista não é reordenada). */
function loadGoiasPlayersDart() {
  const file = path.join(LIB, 'features/arena/games/career_path/goias_players.dart');
  const src = fs.readFileSync(file, 'utf8');
  const re = /GoiasPlayer\(\s*name:\s*'([^']*)'(?:,\s*aliases:\s*\[([^\]]*)\])?/g;
  const out = [];
  let m;
  let i = 0;
  while ((m = re.exec(src)) !== null) {
    const aliasesRaw = m[2] || '';
    const aliases = [...aliasesRaw.matchAll(/'([^']*)'/g)].map((x) => x[1]);
    out.push({
      source: 'goias_players_dart', sourceId: String(i), primaryName: m[1], fullName: null,
      aliases, position: null, shirtNumber: null, birthDate: null,
      goiasSpells: [], raw: { name: m[1], aliases },
    });
    i++;
  }
  return out;
}

const allRecords = [
  ...loadSquad(), ...loadCareer(), ...loadGuess(), ...loadLineup(), ...loadPlayerIdentityReferences(),
  ...loadGoiasPlayersDart(),
];

// ---------------------------------------------------------------------------
// Clustering — union-find sobre STRINGS COMPLETAS normalizadas (nunca
// fragmento/palavra isolada), pra não juntar gente por sobrenome comum.
// ---------------------------------------------------------------------------

function nameTokens(record) {
  const names = [record.primaryName, record.fullName, ...(record.aliases || [])].filter(Boolean);
  return [...new Set(names.map(normalize).filter(Boolean))];
}

class DSU {
  constructor(n) { this.parent = Array.from({ length: n }, (_, i) => i); }
  find(x) { while (this.parent[x] !== x) { this.parent[x] = this.parent[this.parent[x]]; x = this.parent[x]; } return x; }
  union(a, b) { const ra = this.find(a); const rb = this.find(b); if (ra !== rb) this.parent[ra] = rb; }
}

const dsu = new DSU(allRecords.length);
const tokenOwner = new Map();
allRecords.forEach((rec, i) => {
  for (const tok of nameTokens(rec)) {
    if (tokenOwner.has(tok)) dsu.union(i, tokenOwner.get(tok));
    else tokenOwner.set(tok, i);
  }
});

const clustersByRoot = new Map();
allRecords.forEach((rec, i) => {
  const root = dsu.find(i);
  if (!clustersByRoot.has(root)) clustersByRoot.set(root, []);
  clustersByRoot.get(root).push(rec);
});

// ---------------------------------------------------------------------------
// Classificação — DOIS EIXOS INDEPENDENTES: identidade × qualidade de dado
// ---------------------------------------------------------------------------

const DATA_SEVERITY = ['POSITION_CONFLICT', 'STATS_CONFLICT', 'PERIOD_CONFLICT', 'INCOMPLETE', 'NEEDS_REVIEW', 'CONSISTENT'];

function classifyCluster(records) {
  const sources = [...new Set(records.map((r) => r.source))];
  const conflicts = [];
  const evidence = [];
  const dataFlags = new Set();

  if (sources.length === 1) {
    return {
      identity: 'SINGLE_SOURCE', identityConfidence: null, identityReason: 'Só existe um registro-fonte — não há nada pra reconciliar.',
      dataStatus: ['SINGLE_SOURCE'], dataConfidence: null, conflicts, evidence,
    };
  }

  // --- sinal: nome completo idêntico entre 2+ REGISTROS DIFERENTES
  // (corroboração forte) — olha `fullName` E aliases de 2+ palavras, já
  // que `guess_players` só guarda o nome completo em `aliases`.
  const fullNameOwners = new Map(); // nome completo normalizado -> Set de sources que o citam
  for (const r of records) {
    for (const cand of fullNameCandidates(r)) {
      if (!fullNameOwners.has(cand)) fullNameOwners.set(cand, new Set());
      fullNameOwners.get(cand).add(r.source);
    }
  }
  const corroboratedFullNames = [...fullNameOwners.entries()].filter(([, sources]) => sources.size >= 2);
  const hasMatchingFullName = corroboratedFullNames.length > 0;
  if (hasMatchingFullName) {
    for (const [name, sources] of corroboratedFullNames) evidence.push(`Nome completo "${name}" corrobora entre ${[...sources].join(', ')}`);
  }

  // --- sinal: número de camisa consistente (só usado como corroboração
  // positiva — números legitimamente mudam entre temporadas, então
  // divergência sozinha NÃO é usada como evidência negativa) ---
  const shirts = records.map((r) => r.shirtNumber).filter((n) => n != null);
  const shirtConsistent = shirts.length >= 2 && new Set(shirts).size === 1;
  if (shirtConsistent) evidence.push(`Número de camisa consistente em ${shirts.length} fonte(s): #${shirts[0]}`);

  // --- corroboração POR PAR (não por cluster inteiro) — precisa saber
  // exatamente QUAIS DOIS registros concordam em nome completo/camisa, pra
  // distinguir "conflito de posição entre dois registros que uma OUTRA
  // evidência forte já liga" (isso é só confusão de rótulo de posição —
  // ponta/meia-atacante é notoriamente ambíguo entre bases de dados — não
  // prova gente diferente) de "conflito de posição sem NENHUMA
  // corroboração independente" (esse sim é sinal real de identidade).
  function pairCorroborated(a, b) {
    const namesA = fullNameCandidates(a);
    const namesB = fullNameCandidates(b);
    if (namesA.some((n) => namesB.includes(n))) return true;
    if (a.shirtNumber != null && b.shirtNumber != null && a.shirtNumber === b.shirtNumber) return true;
    return false;
  }

  // --- sinal: posição — conflito só quando os grupos não têm NENHUMA
  // interseção. Guarda separadamente quais conflitos são CORROBORADOS por
  // outra evidência forte no mesmo par (viram só POSITION_CONFLICT de
  // dado) e quais são conflitos SEM NENHUMA corroboração (esses sim pesam
  // pro eixo de identidade).
  let positionConflict = false;
  let uncorroboratedPositionConflict = false;
  const uncorroboratedConflictPairs = [];
  const positionsKnown = records.filter((r) => positionGroups(r.position).size > 0);
  for (let i = 0; i < positionsKnown.length; i++) {
    for (let j = i + 1; j < positionsKnown.length; j++) {
      const gA = positionGroups(positionsKnown[i].position);
      const gB = positionGroups(positionsKnown[j].position);
      if (![...gA].some((g) => gB.has(g))) {
        positionConflict = true;
        const corroborated = pairCorroborated(positionsKnown[i], positionsKnown[j]);
        const msg = `Posição incompatível: ${positionsKnown[i].source} diz "${positionsKnown[i].position}" (${[...gA].join('+')}), ${positionsKnown[j].source} diz "${positionsKnown[j].position}" (${[...gB].join('+')})` + (corroborated ? ' [par já corroborado por nome completo/camisa — tratado como confusão de rótulo de posição, não como prova de identidade diferente]' : ' [SEM corroboração — sinal real de possível identidade diferente]');
        conflicts.push(msg); evidence.push(msg);
        if (!corroborated) {
          uncorroboratedPositionConflict = true;
          uncorroboratedConflictPairs.push([positionsKnown[i], positionsKnown[j]]);
        }
      }
    }
  }

  // --- sinal: nascimento vs período em Goiás (idade mínima ~14 anos) ---
  let birthImpossibility = false;
  for (const person of records.filter((r) => r.birthDate)) {
    const birthYear = parseInt(person.birthDate.slice(0, 4), 10);
    for (const other of records) {
      for (const spell of other.goiasSpells || []) {
        for (const range of extractYears(spell.period)) {
          if (range.start < birthYear + 14) {
            birthImpossibility = true;
            const msg = `Impossível cronologicamente: ${person.source} diz nascimento em ${person.birthDate}, mas ${other.source} registra passagem pelo Goiás em "${spell.period}" (jogador teria ${range.start - birthYear} anos em ${range.start})`;
            conflicts.push(msg); evidence.push(msg);
          }
        }
      }
    }
  }

  // --- sinal: período — análise por "órfão", não pairwise cru. Um trecho
  // de período só conta como conflito se NÃO encontrar NENHUM
  // correspondente em NENHUMA outra fonte. Se só UMA fonte tem trechos
  // órfãos (e as outras batem 100% entre si), isso é só INCOMPLETUDE
  // daquela fonte (ela simplesmente não menciona aquele trecho) — não é
  // evidência de identidade diferente nem de dado errado. Só quando 2+
  // FONTES DIFERENTES têm trechos órfãos entre si é que é conflito real
  // (cada uma afirma algo que a outra não sustenta).
  const sourceSpells = records
    .filter((r) => (r.goiasSpells || []).length > 0)
    .map((r) => ({ source: r.source, spells: (r.goiasSpells || []).map((s) => ({ ...s, years: extractYears(s.period) })) }));

  let anyPeriodOverlap = false;
  const sourcesWithOrphanSpell = new Set();
  const statsConflictMsgs = [];
  for (let i = 0; i < sourceSpells.length; i++) {
    for (const spellA of sourceSpells[i].spells) {
      let matched = false;
      for (let j = 0; j < sourceSpells.length; j++) {
        if (i === j) continue;
        for (const spellB of sourceSpells[j].spells) {
          if (rangesOverlapOrClose(spellA.years, spellB.years, 1)) {
            matched = true; anyPeriodOverlap = true;
            const appOk = numbersClose(spellA.appearances, spellB.appearances);
            const goalOk = numbersClose(spellA.goals, spellB.goals);
            if (appOk === false) statsConflictMsgs.push(`Jogos divergem (${spellA.period} vs ${spellB.period}): ${sourceSpells[i].source}="${spellA.appearances}" vs ${sourceSpells[j].source}="${spellB.appearances}"`);
            if (goalOk === false) statsConflictMsgs.push(`Gols divergem (${spellA.period} vs ${spellB.period}): ${sourceSpells[i].source}="${spellA.goals}" vs ${sourceSpells[j].source}="${spellB.goals}"`);
          }
        }
      }
      if (!matched && sourceSpells.length > 1) {
        sourcesWithOrphanSpell.add(sourceSpells[i].source);
        conflicts.push(`${sourceSpells[i].source} reivindica período "${spellA.period}" sem correspondência em nenhuma outra fonte com dado de período`);
      }
    }
  }
  const periodConflict = sourcesWithOrphanSpell.size >= 2;
  const periodIncomplete = sourcesWithOrphanSpell.size === 1;
  const statsConflict = statsConflictMsgs.length > 0;
  statsConflictMsgs.forEach((m) => { conflicts.push(m); evidence.push(m); });
  const noCorroboratingPeriodAtAll = sourceSpells.length >= 2 && !anyPeriodOverlap;

  // --- fontes rasas (sem posição, sem período, sem partida) ---
  // `goias_players_dart` é estruturalmente rasa SEMPRE (o arquivo Dart só
  // tem name/aliases, nunca vai ter posição/período/partida) — deixá-la
  // contar aqui rebaixaria QUALQUER cluster já bem corroborado por outras
  // fontes só porque o autocomplete também cita o nome, o que é o oposto do
  // efeito desejado (mais uma fonte concordando deveria no mínimo manter a
  // confiança, nunca reduzir). Um registro de `goias_players_dart` sozinho
  // (SINGLE_SOURCE) ainda cai corretamente nesse caminho antes daqui — este
  // filtro só evita que ele CONTAMINE a classificação de um cluster
  // multi-fonte que já tinha corroboração real.
  const hasThinSource = records
    .filter((r) => r.source !== 'goias_players_dart')
    .some((r) => !r.position && (!r.goiasSpells || r.goiasSpells.length === 0) && !r.matchAppearances);

  const wordCounts = records.flatMap((r) => nameTokens(r)).map((t) => t.split(' ').length);
  const lowSpecificity = Math.max(...wordCounts, 0) <= 1;

  // ---------------------------------------------------------------------
  // EIXO 1 — IDENTIDADE
  // ---------------------------------------------------------------------
  let identity, identityConfidence, identityReason;
  const hasAnyStrongCorroboration = hasMatchingFullName || shirtConsistent || (sourceSpells.length >= 2 && anyPeriodOverlap);
  if (birthImpossibility) {
    identity = 'DISTINCT_PEOPLE';
    identityConfidence = 0.05;
    identityReason = 'Data de nascimento torna cronologicamente impossível ser a mesma pessoa que a passagem registrada em outra fonte.';
  } else if (uncorroboratedPositionConflict && hasAnyStrongCorroboration) {
    // Existe um núcleo corroborado (nome/camisa/período) E, separadamente,
    // um conflito de posição que NADA corrobora — o registro discordante
    // provavelmente não pertence ao mesmo núcleo. Recomenda desmembrar em
    // vez de aceitar tudo como 1 pessoa só.
    identity = 'DISTINCT_PEOPLE';
    identityConfidence = 0.2;
    identityReason = 'Há um núcleo de registros corroborados entre si (nome completo/camisa/período), mas pelo menos um registro diverge de posição SEM nenhuma corroboração própria — provavelmente não pertence ao mesmo núcleo.';
  } else if (uncorroboratedPositionConflict) {
    // Conflito de posição sem corroboração NEM contra-corroboração em
    // lugar nenhum do cluster — não dá pra confirmar nem refutar.
    identity = 'AMBIGUOUS_IDENTITY';
    identityConfidence = 0.3;
    identityReason = 'Posição diverge entre fontes, mas nenhuma delas tem nome completo/camisa/período pra confirmar ou refutar se é a mesma pessoa — pode ser confusão de rótulo OU homônimo, dado insuficiente pra decidir.';
  } else if (hasMatchingFullName || (sourceSpells.length >= 2 && anyPeriodOverlap) || shirtConsistent) {
    identity = hasThinSource ? 'PROBABLE_IDENTITY' : 'EXACT_IDENTITY';
    identityConfidence = hasThinSource ? 0.8 : 0.95;
    identityReason = hasMatchingFullName
      ? 'Nome completo idêntico corrobora entre fontes.'
      : shirtConsistent
        ? 'Número de camisa consistente corrobora entre fontes.'
        : 'Pelo menos um período em Goiás se sobrepõe/é compatível entre fontes.';
  } else if (noCorroboratingPeriodAtAll || (sources.length >= 2 && !hasMatchingFullName && !shirtConsistent && sourceSpells.length < 2)) {
    identity = 'AMBIGUOUS_IDENTITY';
    identityConfidence = lowSpecificity ? 0.25 : 0.4;
    identityReason = sourceSpells.length >= 2
      ? 'Nenhum período se sobrepõe entre as fontes com dado de período — nada além do nome corrobora ser a mesma pessoa.'
      : 'Só o nome bate; nenhuma fonte tem período/posição/camisa suficiente pra corroborar ou refutar.';
  } else {
    identity = 'PROBABLE_IDENTITY';
    identityConfidence = 0.6;
    identityReason = 'Nenhum sinal contraditório encontrado, mas a corroboração positiva é fraca (fontes rasas).';
  }

  // ---------------------------------------------------------------------
  // EIXO 2 — QUALIDADE DE DADO (pode ter mais de uma bandeira)
  // ---------------------------------------------------------------------
  if (positionConflict) dataFlags.add('POSITION_CONFLICT');
  if (statsConflict) dataFlags.add('STATS_CONFLICT');
  if (periodConflict) dataFlags.add('PERIOD_CONFLICT');
  if (periodIncomplete || hasThinSource) dataFlags.add('INCOMPLETE');
  if (dataFlags.size === 0 && identity === 'AMBIGUOUS_IDENTITY') dataFlags.add('NEEDS_REVIEW');
  if (dataFlags.size === 0) dataFlags.add('CONSISTENT');

  const dataStatusList = [...dataFlags].sort((a, b) => DATA_SEVERITY.indexOf(a) - DATA_SEVERITY.indexOf(b));
  const primaryDataStatus = dataStatusList[0];
  const dataConfidence = primaryDataStatus === 'CONSISTENT' ? 0.95
    : primaryDataStatus === 'INCOMPLETE' ? 0.7
      : primaryDataStatus === 'NEEDS_REVIEW' ? 0.3
        : 0.5;

  return {
    identity, identityConfidence, identityReason,
    dataStatus: dataStatusList, primaryDataStatus, dataConfidence,
    conflicts, evidence, lowSpecificity,
  };
}

// ---------------------------------------------------------------------------
// Monta os candidatos
// ---------------------------------------------------------------------------

const candidates = [...clustersByRoot.values()].map((records) => {
  const result = classifyCluster(records);
  const namesByLength = records
    .flatMap((r) => [r.fullName, r.primaryName, ...(r.aliases || [])])
    .filter(Boolean).sort((a, b) => b.length - a.length);
  const proposedCanonicalName = namesByLength[0] || '(sem nome)';
  const key = records.map((r) => `${r.source}:${r.sourceId}`).sort().join('|');

  let recommendation, recommendationReason;
  if (result.identity === 'SINGLE_SOURCE') {
    recommendation = 'Criar 1 pessoa quando o mapeamento for aprovado — nada a reconciliar.';
    recommendationReason = 'Único registro-fonte.';
  } else if (result.identity === 'DISTINCT_PEOPLE') {
    recommendation = 'Desmembrar em pessoas SEPARADAS — nunca uma linha só em `people`.';
    recommendationReason = result.identityReason;
  } else if (result.identity === 'AMBIGUOUS_IDENTITY') {
    recommendation = 'NÃO decidir automaticamente — revisão humana obrigatória antes do INSERT.';
    recommendationReason = result.identityReason;
  } else {
    recommendation = `Tratar como 1 pessoa (${result.identity}).` + (result.primaryDataStatus !== 'CONSISTENT' ? ` Dado precisa de revisão (${result.primaryDataStatus}) antes de definir o valor canônico de qualquer campo numérico/período — mas isso NÃO afeta a identidade.` : '');
    recommendationReason = result.identityReason;
  }

  return {
    provisionalId: provisionalUuid(key),
    proposedCanonicalName,
    aliases: [...new Set(records.flatMap((r) => [r.primaryName, r.fullName, ...(r.aliases || [])]).filter(Boolean))],
    sources: records.map((r) => ({
      source: r.source, sourceId: r.sourceId, name: r.primaryName, fullName: r.fullName,
      aliases: r.aliases || [],
      position: r.position, shirtNumber: r.shirtNumber, birthDate: r.birthDate,
      goiasSpells: r.goiasSpells,
      matchAppearances: r.matchAppearances ? r.matchAppearances.length : undefined,
      matchAppearanceSample: r.matchAppearances ? r.matchAppearances.slice(0, 3) : undefined,
    })),
    identity: result.identity,
    identityConfidence: result.identityConfidence,
    identityReason: result.identityReason,
    dataStatus: result.dataStatus,
    primaryDataStatus: result.primaryDataStatus,
    dataConfidence: result.dataConfidence,
    lowSpecificity: !!result.lowSpecificity,
    conflicts: result.conflicts,
    evidence: result.evidence,
    recommendation, recommendationReason,
  };
});

// ---------------------------------------------------------------------------
// Segunda passagem — sub-agrupa e tenta promover NEEDS_REVIEW/AMBIGUOUS com
// segurança (evidência real, nunca "match pra diminuir número").
// ---------------------------------------------------------------------------

function reasonTagsFor(candidate) {
  const tags = [];
  const sourceNames = candidate.sources.map((s) => s.source);
  if (sourceNames.every((s) => s === 'lineup_matches' || s === 'guess_players') && sourceNames.includes('lineup_matches')) tags.push('so_lineup_matches_ou_guess');
  if (candidate.lowSpecificity) tags.push('nome_ou_apelido_isolado');
  if (!candidate.sources.some((s) => s.position)) tags.push('sem_posicao_em_nenhuma_fonte');
  if (candidate.dataStatus.includes('PERIOD_CONFLICT')) tags.push('periodo_incompativel');
  if (candidate.identity === 'DISTINCT_PEOPLE') tags.push('possivel_homonimo_confirmado');
  if (!candidate.sources.some((s) => s.fullName)) tags.push('sem_nome_completo_em_nenhuma_fonte');
  if (tags.length === 0) tags.push('outros');
  return tags;
}

const needsReviewOrAmbiguous = candidates.filter((c) => c.identity === 'AMBIGUOUS_IDENTITY' || c.primaryDataStatus === 'NEEDS_REVIEW');
let promotedExact = 0;
let promotedProbable = 0;
for (const c of needsReviewOrAmbiguous) {
  c.reasonTags = reasonTagsFor(c);
  // Promoção SEGURA: só quando existe corroboração POSITIVA de verdade
  // (nome completo idêntico OU camisa consistente) — nunca só porque o
  // nome normalizado bateu (isso já é o critério de agrupamento, não pode
  // também ser o critério de promoção, senão é círculo vicioso).
  const fullNameOwners = new Map();
  for (const s of c.sources) {
    for (const cand of fullNameCandidates(s)) {
      if (!fullNameOwners.has(cand)) fullNameOwners.set(cand, new Set());
      fullNameOwners.get(cand).add(s.source);
    }
  }
  const hasMatchingFullName = [...fullNameOwners.values()].some((sources) => sources.size >= 2);
  const shirts = c.sources.map((s) => s.shirtNumber).filter((n) => n != null);
  const shirtConsistent = shirts.length >= 2 && new Set(shirts).size === 1;

  if (hasMatchingFullName) {
    c.identity = 'EXACT_IDENTITY';
    c.identityConfidence = 0.85;
    c.identityReason = '[promovido na 2ª passagem] Nome completo idêntico encontrado entre fontes — corroboração forte o bastante mesmo sem período/posição.';
    c.recommendation = 'Tratar como 1 pessoa (EXACT_IDENTITY, promovido na 2ª passagem).';
    promotedExact++;
  } else if (shirtConsistent) {
    c.identity = 'PROBABLE_IDENTITY';
    c.identityConfidence = 0.65;
    c.identityReason = '[promovido na 2ª passagem] Número de camisa consistente entre fontes, sem nenhum sinal contraditório.';
    c.recommendation = 'Tratar como provável 1 pessoa (PROBABLE_IDENTITY, promovido na 2ª passagem) — confirmar se possível.';
    promotedProbable++;
  }
}

// ---------------------------------------------------------------------------
// Estatísticas
// ---------------------------------------------------------------------------

candidates.sort((a, b) => (a.identityConfidence ?? 1) - (b.identityConfidence ?? 1));

const stats = {
  totalCandidates: candidates.length,
  bySources: allRecords.reduce((acc, r) => { acc[r.source] = (acc[r.source] || 0) + 1; return acc; }, {}),
  byIdentity: candidates.reduce((acc, c) => { acc[c.identity] = (acc[c.identity] || 0) + 1; return acc; }, {}),
  byPrimaryDataStatus: candidates.reduce((acc, c) => { acc[c.primaryDataStatus || c.dataStatus[0]] = (acc[c.primaryDataStatus || c.dataStatus[0]] || 0) + 1; return acc; }, {}),
  secondPass: {
    totalNeedsReviewOrAmbiguousBefore: needsReviewOrAmbiguous.length,
    promotedToExact: promotedExact,
    promotedToProbable: promotedProbable,
    stillPending: needsReviewOrAmbiguous.length - promotedExact - promotedProbable,
    reasonTagCounts: needsReviewOrAmbiguous.reduce((acc, c) => {
      for (const t of c.reasonTags) acc[t] = (acc[t] || 0) + 1;
      return acc;
    }, {}),
  },
};

fs.writeFileSync(path.join(OUT_DIR, 'candidates.json'), JSON.stringify(candidates, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'stats.json'), JSON.stringify(stats, null, 2) + '\n');

console.log('Total de candidatos:', stats.totalCandidates);
console.log('Por identidade:', stats.byIdentity);
console.log('Por status de dado (primário):', stats.byPrimaryDataStatus);
console.log('2ª passagem (NEEDS_REVIEW/AMBIGUOUS):', stats.secondPass);
console.log('\nEscrito em:', OUT_DIR);
console.log('Gerar o .md com: node tooling/multiclub/render_reconciliation_report.mjs');
