// Etapa F5 — endurecimento: audita drift real (name/shirtNumber) entre
// `goiasSquad` (lib/features/crowd_lineup/domain/goias_squad.dart) e
// `squad_members` (data_export/goias/squad_members.json, a MESMA fonte já
// validada pela F4 — nunca refeita/reimportada aqui). Pareamento é sempre
// slug->slug (SquadPlayer.id === squad_members.id), NUNCA por nome.
//
// Puro/testável, sem side-effects — só compara o que já existe nas duas
// fontes. Nunca corrige goiasSquad nem squad_members: achou divergência,
// reporta; não escolhe qual lado está "certo".
export function normalizeNameForComparison(name) {
  return name
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '') // remove diacríticos (acentuação)
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * NAME_MATCH — string idêntica, byte a byte.
 * NAME_FORMAT_ONLY — só difere em acentuação/caixa/espaçamento (mesma
 *   forma normalizada) — NUNCA abreviação "claramente equivalente": essa
 *   heurística é subjetiva demais pra automatizar sem risco de esconder
 *   uma divergência real, então uma abreviação vira NAME_DIVERGENCE e é
 *   reportada pra julgamento humano, nunca auto-classificada.
 * NAME_DIVERGENCE — qualquer outra diferença real.
 */
export function classifyNameDrift(goiasSquadName, squadMembersName) {
  if (goiasSquadName === squadMembersName) return 'NAME_MATCH';
  if (normalizeNameForComparison(goiasSquadName) === normalizeNameForComparison(squadMembersName)) return 'NAME_FORMAT_ONLY';
  return 'NAME_DIVERGENCE';
}

export function classifyShirtDrift(goiasSquadShirt, squadMembersShirt) {
  return goiasSquadShirt === squadMembersShirt ? 'SHIRT_MATCH' : 'SHIRT_DIVERGENCE';
}

/** Extrai {id, personId, name, shirtNumber} de cada bloco `SquadPlayer(...)`
 * do goias_squad.dart real — nunca confia num JSON intermediário pra essa
 * auditoria, sempre lê o `.dart` que roda de verdade. */
export function extractSquadPlayerFields(dartSrc) {
  const blockRe = /SquadPlayer\(\s*id: '([a-z0-9_]+)',\s*personId: '([0-9a-f-]{36})',\s*name: '([^']*)',\s*shirtNumber: (\d+),/g;
  return [...dartSrc.matchAll(blockRe)].map((m) => ({
    id: m[1],
    personId: m[2],
    name: m[3],
    shirtNumber: Number(m[4]),
  }));
}

/**
 * @param {{id:string, name:string, shirtNumber:number}[]} goiasSquadEntries
 * @param {{id:string, name:string, shirt_number:number}[]} squadMembers
 */
export function computeSquadDrift(goiasSquadEntries, squadMembers) {
  const squadMembersById = new Map(squadMembers.map((s) => [s.id, s]));
  const rows = [];
  for (const g of goiasSquadEntries) {
    const s = squadMembersById.get(g.id);
    if (!s) { rows.push({ id: g.id, missingInSquadMembers: true }); continue; }
    rows.push({
      id: g.id,
      goiasSquadName: g.name,
      squadMembersName: s.name,
      nameClassification: classifyNameDrift(g.name, s.name),
      goiasSquadShirt: g.shirtNumber,
      squadMembersShirt: s.shirt_number,
      shirtClassification: classifyShirtDrift(g.shirtNumber, s.shirt_number),
    });
  }
  const stats = {
    total: rows.length,
    NAME_MATCH: rows.filter((r) => r.nameClassification === 'NAME_MATCH').length,
    NAME_FORMAT_ONLY: rows.filter((r) => r.nameClassification === 'NAME_FORMAT_ONLY').length,
    NAME_DIVERGENCE: rows.filter((r) => r.nameClassification === 'NAME_DIVERGENCE').length,
    SHIRT_MATCH: rows.filter((r) => r.shirtClassification === 'SHIRT_MATCH').length,
    SHIRT_DIVERGENCE: rows.filter((r) => r.shirtClassification === 'SHIRT_DIVERGENCE').length,
    nameDivergences: rows.filter((r) => r.nameClassification === 'NAME_DIVERGENCE'),
    shirtDivergences: rows.filter((r) => r.shirtClassification === 'SHIRT_DIVERGENCE'),
  };
  return { rows, stats };
}
