// Exportação reutilizável dos dados-seed do Goiás — lê os arquivos
// supabase/*.sql (fonte da verdade hoje, já que o app não tem acesso de
// escrita a um dump ao vivo daqui) e produz JSON estruturado em
// data_export/goias/. Reaproveitável: se os SQLs forem re-gerados a partir
// de um export real do Supabase no mesmo formato de INSERT, basta rodar
// `node tooling/multiclub/export_seed_data.mjs` de novo.
//
// NUNCA inventa dado — só reformata o que já está nos arquivos SQL. Onde
// duas versões existem (seed original + migration de correção), a versão
// mais recente prevalece via merge por `id`, documentado em cada bloco.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  parseInserts,
  parseUpdateFromValues,
  parseWithValuesCte,
  parseSingleRowUpdate,
} from './sql_insert_parser.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const SUPABASE = path.join(ROOT, 'supabase');
const OUT = path.join(ROOT, 'data_export', 'goias');

fs.mkdirSync(OUT, { recursive: true });

function readSql(rel) {
  return fs.readFileSync(path.join(SUPABASE, rel), 'utf8');
}

function insertRows(rel, table) {
  const found = parseInserts(readSql(rel)).filter((r) => r.table === table);
  if (found.length === 0) throw new Error(`Tabela ${table} não encontrada em ${rel}`);
  return found.flatMap((r) => r.rows);
}

function mergeById(baseRows, patchRows, idKey = 'id') {
  const map = new Map(baseRows.map((r) => [r[idKey], { ...r }]));
  for (const patch of patchRows) {
    const existing = map.get(patch[idKey]);
    if (existing) Object.assign(existing, patch);
    else map.set(patch[idKey], patch);
  }
  return [...map.values()];
}

function writeJson(name, data) {
  fs.writeFileSync(path.join(OUT, name), JSON.stringify(data, null, 2) + '\n');
  const count = Array.isArray(data) ? `${data.length} registros` : 'objeto único';
  console.log(`  ${name} — ${count}`);
}

console.log('Exportando dados do Goiás para data_export/goias/...\n');

// --- squad_members (elenco atual, 31 INSERTs individuais no arquivo) ---
writeJson('squad_members.json', insertRows('squad_members_seed.sql', 'squad_members'));

// --- career_players (base 26/08 + revalidação v2 31/08, merge por id) ---
{
  const base = insertRows('career_players.sql', 'career_players');
  const v2 = insertRows('migrations/20260831020000_career_players_revalidated_v2.sql', 'career_players');
  writeJson('career_players.json', mergeById(base, v2));
}

// --- guess_players ---
writeJson('guess_players.json', insertRows('guess_players.sql', 'guess_players'));

// --- lineup_matches ---
writeJson('lineup_matches.json', insertRows('lineup_matches.sql', 'lineup_matches'));

// --- quiz_questions ---
writeJson('quiz_questions.json', insertRows('quiz_questions.sql', 'quiz_questions'));

// --- club_board (diretoria) ---
writeJson('club_board_sections.json', insertRows('club_board.sql', 'club_board_sections'));
writeJson('club_board_members.json', insertRows('club_board.sql', 'club_board_members'));

// --- club_transparency ---
writeJson('club_transparency_topics.json', insertRows('club_transparency.sql', 'club_transparency_topics'));
writeJson('club_transparency_documents.json', insertRows('club_transparency.sql', 'club_transparency_documents'));

// --- membership_content (FAQ + regulamento) ---
writeJson('membership_faq_categories.json', insertRows('membership_content.sql', 'membership_faq_categories'));
writeJson('membership_faq_items.json', insertRows('membership_content.sql', 'membership_faq_items'));
writeJson('membership_regulation_versions.json', insertRows('membership_content.sql', 'membership_regulation_versions'));

// --- venues (seed só existe na migration de auditoria; schema-only antes disso) ---
{
  const venues = insertRows('migrations/20260831040000_passport_venue_audit.sql', 'venues');
  const rename = parseSingleRowUpdate(readSql('migrations/20260831050000_passport_venue_haile_pinheiro_name.sql'));
  const merged = rename ? mergeById(venues, [{ id: rename.id, ...rename.patch }]) : venues;
  writeJson('venues.json', merged);
}

// --- passport_matches (import 1697 base + correção de auditoria de estádio/data/placar) ---
{
  const base = parseWithValuesCte(readSql('passport_esmeraldino_import.sql')).rows;
  const audit = parseUpdateFromValues(readSql('migrations/20260831040000_passport_venue_audit.sql'));
  writeJson('passport_matches.json', mergeById(base, audit.rows));
}

console.log('\nExportação concluída. Nenhum dado foi inventado — tudo veio direto dos .sql em supabase/.');
console.log('Fontes hardcoded em Dart (não-SQL) ficam FORA deste script — ver docs/multiclub/02_goias_data_inventory.md.');
