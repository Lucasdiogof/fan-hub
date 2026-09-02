// PEOPLE INSERT PREPARATION — micro-etapa depois da reconciliação v3.1.
// NÃO gera INSERT. Só decide, pra cada uma das 295 pessoas canônicas, se
// ela está pronta pra virar uma linha em `people` (APPROVED), se precisa de
// confirmação humana leve (PROVISIONAL), ou se deve ficar de fora por
// enquanto (BLOCKED_AMBIGUOUS / BLOCKED_INSUFFICIENT_IDENTITY).
//
// Regra central: SINGLE_SOURCE não vira APPROVED automaticamente só por
// existir — a QUALIDADE do identificador é que decide, e a qualidade é
// julgada por EVIDÊNCIA/TIPO de campo, nunca por contagem de palavras
// (revisão desta rodada: "Leão da Serra" venceu "Lincoln" só por ser mais
// comprido — bug corrigido em reconcile_players.mjs/pickCanonicalName — e
// "multi-word" sozinho não provava nome completo, só corroboração fraca).
//
// Hierarquia de qualidade de nome (da mais forte pra mais fraca):
//   LEGAL_FULL_NAME    — nome civil pesquisado/confirmado por humano com
//                         evidência externa registrada (override HUMAN_VERIFIED).
//   FULL_NAME          — campo estruturado `fullName` da própria fonte
//                         (squad_members.full_name/guess_players.display_name),
//                         nunca um alias solto — OU nome de 3+ palavras com
//                         conector patronímico (da/de/do/dos/das), padrão
//                         estrutural forte de nome completo real.
//   PUBLIC_NAME         — nome de 2+ palavras vindo do `primaryName` (como a
//                         PRÓPRIA fonte identifica a pessoa, nunca um alias),
//                         sem conector nem confirmação externa — o "nome
//                         pelo qual o jogador é conhecido", plausível mas
//                         sem corroboração independente.
//   COMPOUND_NICKNAME   — reservado pra quando houver evidência específica
//                         de que um nome de 2+ palavras é apelido composto,
//                         não nome+sobrenome (nenhum caso automático
//                         classificado assim nesta rodada — exigiria
//                         pesquisa por pessoa, não inventado).
//   BARE_NICKNAME       — 1 palavra, não é primeiro nome comum (lista curada).
//   BARE_FIRST_NAME     — 1 palavra, primeiro nome comum — risco real de
//                         homônimo, nunca vira pessoa global sozinho.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));

function normalize(str) {
  return String(str)
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const PATRONYMIC_CONNECTORS = new Set(['da', 'de', 'do', 'das', 'dos']);

// ---------------------------------------------------------------------------
// Lista curada de primeiros nomes comuns no futebol brasileiro — JUÍZO
// EDITORIAL, não uma fonte de verdade demográfica. Propositalmente
// GENEROSA (prefere marcar como arriscado a menos) — revisável a qualquer
// momento sem afetar nenhum outro dado (só muda insert_status de
// SINGLE_SOURCE bare, nunca identidade nem person_id).
// ---------------------------------------------------------------------------
const COMMON_FIRST_NAMES = new Set([
  'fernando', 'henrique', 'felipe', 'bernardo', 'jackson', 'clayton', 'moises',
  'marcio', 'ivan', 'fred', 'sandro', 'patrick', 'wendel', 'wendell', 'romulo',
  'rafael', 'marcelo', 'anderson', 'ricardo', 'eduardo', 'roberto', 'ronaldo',
  'renato', 'rodrigo', 'leonardo', 'andre', 'alexandre', 'alex', 'diego', 'diogo',
  'daniel', 'david', 'douglas', 'bruno', 'gabriel', 'gustavo', 'guilherme',
  'gilberto', 'hugo', 'igor', 'joao', 'jorge', 'jose', 'juan', 'julio', 'leandro',
  'lucas', 'luis', 'luiz', 'marcos', 'mateus', 'matheus', 'miguel', 'nathan',
  'paulo', 'pedro', 'raul', 'sergio', 'thiago', 'tiago', 'victor', 'vitor',
  'vinicius', 'wesley', 'william', 'wellington', 'junior', 'iago', 'yago',
  'artur', 'arthur', 'samuel', 'sidney', 'sidnei', 'regis', 'claudio', 'emilio',
  'rinaldo', 'heron', 'jhonatan', 'jonathan', 'kaio', 'kayo', 'luan', 'luciano',
  'juninho', 'zezinho', 'netinho', 'toninho', 'carlinhos', 'robinho',
]);

/** Qualidade do nome de uma pessoa AUTOMÁTICA (não tocada por override) —
 * usa SÓ `canonicalName` (já escolhido por pickCanonicalName em
 * reconcile_players.mjs a partir de fullName/primaryName, NUNCA de alias)
 * + `canonicalNameSource`, que diz qual campo venceu. */
function classifyAutomaticNameQuality(person) {
  const norm = normalize(person.canonicalName);
  if (!norm) return { bucket: 'OTHER', tokenCount: 0 };
  const tokens = norm.split(' ');
  const hasConnector = tokens.some((t) => PATRONYMIC_CONNECTORS.has(t));

  if (person.canonicalNameSource === 'fullNameField') {
    return { bucket: 'FULL_NAME', tokenCount: tokens.length };
  }
  if (tokens.length >= 3 && hasConnector) {
    return { bucket: 'FULL_NAME', tokenCount: tokens.length };
  }
  if (tokens.length >= 2) {
    return { bucket: 'PUBLIC_NAME', tokenCount: tokens.length };
  }
  if (tokens.length === 1) {
    return { bucket: COMMON_FIRST_NAMES.has(tokens[0]) ? 'BARE_FIRST_NAME' : 'BARE_NICKNAME', tokenCount: 1 };
  }
  return { bucket: 'OTHER', tokenCount: 0 };
}

const NAME_QUALITY_CONFIDENCE = {
  LEGAL_FULL_NAME: 0.9,
  FULL_NAME: 0.75,
  PUBLIC_NAME: 0.55,
  COMPOUND_NICKNAME: 0.45,
  BARE_NICKNAME: 0.4,
  BARE_FIRST_NAME: 0.2,
  OTHER: 0.1,
};

function reviewStatusFor(person) {
  if (person.origin === 'HUMAN_VERIFIED') return 'HUMAN_VERIFIED';
  if (person.humanReviewed) return 'HUMAN_ANNOTATED';
  return 'AUTOMATIC_UNREVIEWED';
}

const plan = canonicalPeople.map((person) => {
  let insertStatus, reason, confidence, nameQualityBucket;

  // Prioridade explícita (nunca inferida de prosa): se o override já
  // declarou nameQuality em canonicalIdentity, é isso que vale — o
  // classificador estrutural (fullName/primaryName/conector) só entra
  // quando NENHUM humano se pronunciou sobre a qualidade do nome.
  const humanDeclaredLegalFullName = person.nameQuality === 'LEGAL_FULL_NAME' && person.identity !== 'PROBABLE_IDENTITY';

  if (person.identity === 'AMBIGUOUS_IDENTITY') {
    nameQualityBucket = null;
    insertStatus = 'BLOCKED_AMBIGUOUS';
    reason = 'Motor automático não conseguiu confirmar nem refutar se as fontes envolvidas são a mesma pessoa (sem nome completo/camisa/período que corrobore ou contradiga). Preservar a ambiguidade é melhor que fundir errado — fica pendente até enriquecimento (fonte externa, dado adicional) ou revisão humana explícita.';
    confidence = person.identityConfidence;
  } else if (person.identity === 'DISTINCT_PEOPLE') {
    nameQualityBucket = null;
    insertStatus = 'BLOCKED_AMBIGUOUS';
    reason = 'DISTINCT_PEOPLE sem override de split — não deveria existir no dataset canônico (invariante violada, ver canonical_stats.json). NUNCA inserir como 1 linha.';
    confidence = person.identityConfidence;
  } else if (person.identity === 'PROBABLE_IDENTITY') {
    nameQualityBucket = null;
    insertStatus = 'PROVISIONAL';
    reason = `Identidade provável mas não confirmada com certeza alta (confiança ${person.identityConfidence}) — nome canônico é descritivo/placeholder ("${person.canonicalName}"), não um nome completo determinado. Pode entrar como pessoa provisória (people.verified_at = null) se o produto aceitar isso, ou aguardar mais evidência.`;
    confidence = person.identityConfidence;
  } else if (humanDeclaredLegalFullName) {
    // EXACT_IDENTITY vindo de override humano com pesquisa registrada
    // (Danilo/Nicolas/Michael pós-split, Dieguinho, Erik, Fabiano).
    nameQualityBucket = 'LEGAL_FULL_NAME';
    insertStatus = 'APPROVED';
    reason = `Nome civil pesquisado e confirmado com evidência externa registrada no override (confiança ${person.identityConfidence}).`;
    confidence = NAME_QUALITY_CONFIDENCE.LEGAL_FULL_NAME;
  } else if (person.identity === 'EXACT_IDENTITY') {
    nameQualityBucket = person.canonicalNameSource === 'fullNameField' ? 'FULL_NAME' : 'PUBLIC_NAME';
    insertStatus = 'APPROVED';
    reason = `Identidade confirmada pelo motor automático por corroboração forte entre fontes (nome completo idêntico, camisa consistente ou período sobreposto — confiança ${person.identityConfidence}).`;
    confidence = person.identityConfidence;
  } else if (person.identity === 'SINGLE_SOURCE') {
    const q = classifyAutomaticNameQuality(person);
    nameQualityBucket = q.bucket;
    confidence = NAME_QUALITY_CONFIDENCE[q.bucket];
    if (q.bucket === 'FULL_NAME') {
      insertStatus = 'APPROVED';
      reason = person.canonicalNameSource === 'fullNameField'
        ? `Fonte única, mas o nome ("${person.canonicalName}") vem de um campo estruturado de nome completo (não um alias) — sinal forte o bastante mesmo sozinho.`
        : `Fonte única, mas o nome ("${person.canonicalName}") tem ${q.tokenCount} palavras com conector patronímico (da/de/do/dos/das) — padrão estrutural forte de nome completo real, não apenas "várias palavras".`;
    } else if (q.bucket === 'PUBLIC_NAME') {
      insertStatus = 'PROVISIONAL';
      reason = `Fonte única, nome de ${q.tokenCount} palavras ("${person.canonicalName}") vindo de \`primaryName\` (como a própria fonte chama a pessoa, nunca um alias) — plausível como identificador de uma pessoa específica, mas SEM corroboração independente de nenhuma outra fonte. Justificativa é o TIPO de campo (primaryName, não alias) e a especificidade do nome, não a contagem de palavras — ainda assim, sem 2ª fonte, fica provisório até confirmação humana leve.`;
    } else if (q.bucket === 'BARE_NICKNAME') {
      insertStatus = 'PROVISIONAL';
      reason = `Fonte única, apelido/mononimo curto ("${person.canonicalName}") não é um primeiro nome comum (lista curada), risco de colisão moderado-baixo — mas ainda vale confirmação humana leve antes do INSERT definitivo, não é automático.`;
    } else if (q.bucket === 'BARE_FIRST_NAME') {
      insertStatus = 'BLOCKED_INSUFFICIENT_IDENTITY';
      reason = `Fonte única, só um primeiro nome comum ("${person.canonicalName}") sem período/posição/clube anterior/partida que desambigue — risco real de representar QUALQUER jogador histórico homônimo do Goiás com esse nome. NUNCA virar pessoa global só com essa string.`;
    } else {
      insertStatus = 'BLOCKED_INSUFFICIENT_IDENTITY';
      reason = 'Identificador insuficiente pra classificar com confiança (nome vazio ou não reconhecido pelo classificador).';
    }
  } else {
    nameQualityBucket = null;
    insertStatus = 'BLOCKED_INSUFFICIENT_IDENTITY';
    reason = `Identidade "${person.identity}" não reconhecida pelo classificador.`;
    confidence = person.identityConfidence;
  }

  return {
    canonical_person_id: person.canonicalId,
    canonical_person_key: person.canonicalPersonKey,
    canonical_name: person.canonicalName,
    display_name: person.displayName,
    identity_status: person.identity,
    insert_status: insertStatus,
    reason,
    source_records: person.members,
    aliases: person.aliases,
    confidence,
    name_quality_bucket: nameQualityBucket,
    review_status: reviewStatusFor(person),
  };
});

// ---------------------------------------------------------------------------
// Estatísticas
// ---------------------------------------------------------------------------

function count(pred) { return plan.filter(pred).length; }

const byNameQuality = plan.reduce((acc, p) => {
  if (!p.name_quality_bucket) return acc;
  acc[p.name_quality_bucket] = (acc[p.name_quality_bucket] || 0) + 1;
  return acc;
}, {});

const allSourceRecordsInPlan = plan.reduce((sum, p) => sum + p.source_records.length, 0);
const sourceRecordsWithPersonId = plan.filter((p) => p.insert_status === 'APPROVED').reduce((sum, p) => sum + p.source_records.length, 0);
const sourceRecordsWithoutPersonIdYet = allSourceRecordsInPlan - sourceRecordsWithPersonId;

const summary = {
  totalCanonicalCandidates: plan.length,
  byInsertStatus: {
    APPROVED: count((p) => p.insert_status === 'APPROVED'),
    PROVISIONAL: count((p) => p.insert_status === 'PROVISIONAL'),
    BLOCKED_AMBIGUOUS: count((p) => p.insert_status === 'BLOCKED_AMBIGUOUS'),
    BLOCKED_INSUFFICIENT_IDENTITY: count((p) => p.insert_status === 'BLOCKED_INSUFFICIENT_IDENTITY'),
  },
  byIdentityStatus: {
    EXACT_IDENTITY: count((p) => p.identity_status === 'EXACT_IDENTITY'),
    PROBABLE_IDENTITY: count((p) => p.identity_status === 'PROBABLE_IDENTITY'),
    AMBIGUOUS_IDENTITY: count((p) => p.identity_status === 'AMBIGUOUS_IDENTITY'),
    SINGLE_SOURCE: count((p) => p.identity_status === 'SINGLE_SOURCE'),
  },
  byNameQuality: {
    LEGAL_FULL_NAME: byNameQuality.LEGAL_FULL_NAME || 0,
    FULL_NAME: byNameQuality.FULL_NAME || 0,
    PUBLIC_NAME: byNameQuality.PUBLIC_NAME || 0,
    COMPOUND_NICKNAME: byNameQuality.COMPOUND_NICKNAME || 0,
    BARE_NICKNAME: byNameQuality.BARE_NICKNAME || 0,
    BARE_FIRST_NAME: byNameQuality.BARE_FIRST_NAME || 0,
    OTHER: byNameQuality.OTHER || 0,
  },
  singleSourceByNameQuality: (() => {
    const s = plan.filter((p) => p.identity_status === 'SINGLE_SOURCE');
    const acc = {};
    for (const p of s) acc[p.name_quality_bucket] = (acc[p.name_quality_bucket] || 0) + 1;
    return { FULL_NAME: acc.FULL_NAME || 0, PUBLIC_NAME: acc.PUBLIC_NAME || 0, BARE_NICKNAME: acc.BARE_NICKNAME || 0, BARE_FIRST_NAME: acc.BARE_FIRST_NAME || 0, OTHER: acc.OTHER || 0 };
  })(),
  sourceRecordAccounting: {
    totalSourceRecordsAcrossAllCandidates: allSourceRecordsInPlan,
    sourceRecordsGettingAPersonIdInFirstInsert: sourceRecordsWithPersonId,
    sourceRecordsWithoutPersonIdForNow: sourceRecordsWithoutPersonIdYet,
  },
};

fs.writeFileSync(path.join(IN_DIR, 'people_insert_plan.json'), JSON.stringify(plan, null, 2) + '\n');
fs.writeFileSync(path.join(IN_DIR, 'people_insert_plan_summary.json'), JSON.stringify(summary, null, 2) + '\n');

console.log(JSON.stringify(summary, null, 2));
console.log('\nEscrito em:', IN_DIR);
