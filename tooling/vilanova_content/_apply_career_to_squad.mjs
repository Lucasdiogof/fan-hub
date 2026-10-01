// Aplica o club_history parseado do ogol.com.br (tooling/vilanova_content/
// _ogol_parsed.json) de volta no pacote de pesquisa
// (docs/vila_nova_data/data/squad_current.json), substituindo o
// club_history antigo (só nomes de clube, sem período/estatística) e
// marcando `is_club: true` na passagem pelo Vila Nova atual (chave que o
// gerador de SQL espera, mesmo padrão já usado em career_path.json).
import fs from 'fs';

const SQUAD_PATH = 'docs/vila_nova_data/data/squad_current.json';
const PARSED_PATH = 'tooling/vilanova_content/_ogol_parsed.json';
// Correções versionadas sobre o parse (ver `_doc` no arquivo): rótulo de
// temporada europeia que o texto do ogol perde e empréstimo parcial.
const CORRECTIONS_PATH = 'tooling/vilanova_content/_career_corrections.json';

const squad = JSON.parse(fs.readFileSync(SQUAD_PATH, 'utf8'));
const parsed = JSON.parse(fs.readFileSync(PARSED_PATH, 'utf8'));
const { corrections } = JSON.parse(fs.readFileSync(CORRECTIONS_PATH, 'utf8'));

// Aplica cada correção sobre a passagem identificada por team + period. Uma
// correção que não acha a passagem é erro (o parse mudou e a correção ficou
// obsoleta) — nunca ignorada em silêncio.
for (const c of corrections) {
  const entries = parsed[c.player_id];
  const idx = (entries ?? []).findIndex(
    (e) => e.team === c.match.team && e.period === c.match.period,
  );
  if (idx === -1) {
    throw new Error(`correção sem passagem: ${c.player_id} ${c.match.team} ${c.match.period}`);
  }
  if (c.field === '__split__') {
    entries.splice(idx, 1, ...c.to);
  } else {
    if (entries[idx][c.field] !== c.from) {
      throw new Error(`correção desatualizada: ${c.player_id} ${c.match.team} ${c.field}=${entries[idx][c.field]}, esperado ${c.from}`);
    }
    entries[idx] = { ...entries[idx], [c.field]: c.to };
  }
}
console.log(`Aplicadas ${corrections.length} correções de ${CORRECTIONS_PATH}.`);

let updated = 0;
for (const player of squad.players) {
  const entries = parsed[player.id];
  if (!entries) {
    console.warn(`sem dado parseado pra ${player.id} (${player.name}) — mantém como estava`);
    continue;
  }
  const withFlag = entries.map((e) => ({
    ...e,
    is_club: e.team === 'Vila Nova',
  }));
  if (!withFlag.some((e) => e.is_club)) {
    throw new Error(`${player.id}: nenhuma entrada "Vila Nova" (sem is_club=true) — parser pode ter falhado`);
  }
  player.club_history = withFlag;
  player.club_history_status = 'READY';
  updated++;
}

fs.writeFileSync(SQUAD_PATH, JSON.stringify(squad, null, 2) + '\n', 'utf8');
console.log(`Atualizados ${updated} jogadores em ${SQUAD_PATH}.`);
