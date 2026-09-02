// Etapa F4.5 — combina current_squad_canonical_gap_audit.json (fato: quais
// gaps existem) + current_squad_gap_evidence.json (evidência humana,
// estruturada e citável) pra produzir current_squad_canonical_gap_fix_
// plan.json — o ÚNICO arquivo que generate_current_squad_gap_migration.mjs
// consome. Nunca aplica direto — só monta o plano, auditável linha a
// linha, igual ao padrão overrides->canonical_people_candidates.json da
// v3.1.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const OUT_DIR = RECON;

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_audit.json'), 'utf8'));
const evidence = JSON.parse(fs.readFileSync(path.join(__dirname, 'current_squad_gap_evidence.json'), 'utf8'));

const spellCorrectionByKey = new Map(evidence.spellCorrections.map((c) => [c.squadMemberId, c]));
const statsAdditionByKey = new Map(evidence.statsAdditions.map((c) => [c.squadMemberId, c]));

// --- spells ---
const spellFixes = [];
const errors = [];
for (const gap of audit.spellGaps) {
  if (gap.gapType === 'MULTIPLE_ONGOING_SPELLS') {
    spellFixes.push({ squadMemberId: gap.squadMemberId, personId: gap.personId, canonicalName: gap.canonicalName, gapType: gap.gapType, resolution: 'AMBIGUOUS', reasoning: 'Múltiplos spells ongoing simultâneos — nunca escolhido sozinho, precisa revisão humana antes de qualquer fix.', action: null });
    continue;
  }
  const correction = spellCorrectionByKey.get(gap.squadMemberId);
  if (!correction) {
    spellFixes.push({ squadMemberId: gap.squadMemberId, personId: gap.personId, canonicalName: gap.canonicalName, gapType: gap.gapType, resolution: 'BLOCKED_INSUFFICIENT_EVIDENCE', reasoning: 'Nenhuma evidência estruturada em current_squad_gap_evidence.json pra este squad_member — permanece com o gap, nada fabricado.', action: null });
    continue;
  }
  if (gap.allGoiasSpells.length !== 1) {
    errors.push(`${gap.squadMemberId}: evidência aponta EXTEND_EXISTING_SPELL, mas o audit encontrou ${gap.allGoiasSpells.length} spells Goiás (esperado exatamente 1) — abortando, revisão manual necessária.`);
    continue;
  }
  const spell = gap.allGoiasSpells[0];
  // Gate 4 (revisão do usuário): a expiração contratual que estamos
  // removendo de end_* precisa continuar rastreável via provenance —
  // nunca apagar a única evidência da correção sem preservá-la em algum
  // lugar auditável primeiro.
  if (!spell.provenanceSourceCount || spell.provenanceSourceCount < 1) {
    errors.push(`${gap.squadMemberId}: spell ${spell.spellId} não tem NENHUMA linha em player_club_spell_sources — a evidência do vínculo (loan=true, expiração contratual) seria perdida completamente ao nular end_*. PARE — preserve a evidência em current_squad_gap_evidence.json antes de prosseguir.`);
    continue;
  }
  spellFixes.push({
    squadMemberId: gap.squadMemberId,
    personId: gap.personId,
    canonicalName: gap.canonicalName,
    gapType: gap.gapType,
    resolution: correction.classification,
    spellId: spell.spellId,
    canonicalSpellKey: spell.canonicalSpellKey,
    before: {
      personId: gap.personId,
      clubId: spell.clubId,
      isOngoing: spell.isOngoing,
      startYear: spell.startYear,
      startMonth: spell.startMonth,
      startDate: spell.startDate ?? null,
      startPrecision: spell.startPrecision,
      endYear: spell.endYear,
      endMonth: spell.endMonth,
      endDate: spell.endDate ?? null,
      endPrecision: spell.endPrecision,
      verificationStatus: spell.verificationStatus,
      provenanceSourceCount: spell.provenanceSourceCount,
    },
    after: {
      isOngoing: correction.action.isOngoing,
      startYear: correction.action.upgradeStart ? spell.startYear : spell.startYear,
      startMonth: correction.action.upgradeStart ? spell.startMonth : spell.startMonth,
      startPrecision: correction.action.upgradeStart ? correction.action.upgradeStart.precision : spell.startPrecision,
      startDate: correction.action.upgradeStart ? correction.action.upgradeStart.date : null,
      endYear: correction.action.clearEnd ? null : spell.endYear,
      endMonth: correction.action.clearEnd ? null : spell.endMonth,
      endPrecision: correction.action.clearEnd ? null : spell.endPrecision,
    },
    reasoning: correction.reasoning,
    evidence: correction.evidence,
  });
}

// --- stats ---
const statsFixes = [];
for (const gap of audit.statsGaps) {
  const addition = statsAdditionByKey.get(gap.squadMemberId);
  if (!addition) {
    statsFixes.push({ squadMemberId: gap.squadMemberId, personId: gap.personId, canonicalName: gap.canonicalName, gapType: gap.gapType, resolution: 'BLOCKED_INSUFFICIENT_EVIDENCE', reasoning: 'Nenhuma evidência estruturada em current_squad_gap_evidence.json pra este squad_member.', appearances: null, goals: null });
    continue;
  }
  statsFixes.push({
    squadMemberId: gap.squadMemberId,
    personId: gap.personId,
    canonicalName: gap.canonicalName,
    gapType: gap.gapType,
    resolution: addition.classification,
    appearances: addition.appearances,
    goals: addition.goals,
    verificationStatus: addition.verificationStatus,
    dataMode: 'SNAPSHOT',
    asOfDate: addition.asOfDate,
    asOfMatchId: null,
    reasoning: addition.reasoning,
    sources: addition.sources,
  });
}

if (errors.length) {
  console.error('ERROS — FIX PLAN NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

const plan = {
  goiasClubId: audit.goiasClubId,
  currentSquadPersonIds: audit.currentSquadPersonIds,
  totalPlayerClubSpellsBeforeFix: audit.totalPlayerClubSpellsBeforeFix,
  spellFixes,
  statsFixes,
  summary: {
    spellGapsTotal: audit.spellGaps.length,
    spellFixesFixable: spellFixes.filter((f) => f.resolution === 'EXTEND_EXISTING_SPELL' || f.resolution === 'NEW_SPELL').length,
    spellFixesBlocked: spellFixes.filter((f) => f.resolution === 'BLOCKED_INSUFFICIENT_EVIDENCE' || f.resolution === 'AMBIGUOUS').length,
    ongoingCoverageBefore: `${audit.spellOk}/${audit.resolvedSquadMembersTotal}`,
    ongoingCoverageAfterProposed: `${audit.spellOk + spellFixes.filter((f) => f.resolution === 'EXTEND_EXISTING_SPELL' || f.resolution === 'NEW_SPELL').length}/${audit.resolvedSquadMembersTotal}`,
    statsGapsTotal: audit.statsGaps.length,
    statsFixesFixable: statsFixes.filter((f) => f.resolution === 'FIXABLE').length,
    statsFixesBlocked: statsFixes.filter((f) => f.resolution === 'BLOCKED_INSUFFICIENT_EVIDENCE').length,
    clubTotalCoverageBefore: `${audit.statsOk}/${audit.resolvedSquadMembersTotal}`,
    clubTotalCoverageAfterProposed: `${audit.statsOk + statsFixes.filter((f) => f.resolution === 'FIXABLE').length}/${audit.resolvedSquadMembersTotal}`,
  },
};

fs.writeFileSync(path.join(OUT_DIR, 'current_squad_canonical_gap_fix_plan.json'), JSON.stringify(plan, null, 2) + '\n');
console.log(JSON.stringify(plan.summary, null, 2));
console.log('\nEscrito em:', OUT_DIR);
