// Aplica o club_history parseado do ogol.com.br (tooling/vilanova_content/
// _ogol_parsed.json) de volta no pacote de pesquisa
// (docs/vila_nova_data/data/squad_current.json), substituindo o
// club_history antigo (só nomes de clube, sem período/estatística) e
// marcando `is_club: true` na passagem pelo Vila Nova atual (chave que o
// gerador de SQL espera, mesmo padrão já usado em career_path.json).
import fs from 'fs';

const SQUAD_PATH = 'docs/vila_nova_data/data/squad_current.json';
const PARSED_PATH = 'tooling/vilanova_content/_ogol_parsed.json';

const squad = JSON.parse(fs.readFileSync(SQUAD_PATH, 'utf8'));
const parsed = JSON.parse(fs.readFileSync(PARSED_PATH, 'utf8'));

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
