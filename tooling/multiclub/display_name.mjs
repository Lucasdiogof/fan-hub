// Derivação ESTRUTURAL de display_name — nunca lê texto narrativo
// (`reason`, `liveDataBaseline`, `spellModelImplication`, `note`, etc.).
// Usado tanto por apply_overrides.mjs (pra popular canonical_people_
// candidates.json já com o display_name certo) quanto por
// generate_people_seed.mjs (que hoje só LÊ o valor já resolvido, não
// recalcula). Única fonte: o campo `name` (primaryName) de cada
// source record em candidates.json — nunca alias, nunca prosa.
export const DISPLAY_NAME_SOURCE_PRIORITY = [
  'squad_members', 'guess_players', 'career_players', 'lineup_matches',
  'player_identity_references', 'goias_players_dart',
];

export function buildPrimaryNameIndex(candidates) {
  const index = new Map();
  for (const c of candidates) {
    for (const s of c.sources) {
      index.set(`${s.source}:${s.sourceId}`, s.name || null);
    }
  }
  return index;
}

/** `members`: [{source, sourceId}], já os membros FINAIS de uma pessoa
 * canônica (pós-override). Prioriza squad_members > guess_players > ... —
 * cai pro `canonicalName` só se nenhuma fonte tiver um `name` utilizável. */
export function deriveDisplayName(primaryNameIndex, members, canonicalName) {
  for (const preferredSource of DISPLAY_NAME_SOURCE_PRIORITY) {
    const m = members.find((x) => x.source === preferredSource);
    if (!m) continue;
    const name = primaryNameIndex.get(`${m.source}:${m.sourceId}`);
    if (name) return name;
  }
  return canonicalName;
}
