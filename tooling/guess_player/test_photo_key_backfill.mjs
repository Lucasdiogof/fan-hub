#!/usr/bin/env node
// Trava as 3 garantias pedidas na auditoria de 2026-09-05, pra sempre:
// 1) 0 asset órfão em guessPlayerPhotoAssets;
// 2) 0 referência quebrada (catálogo aponta pra chave inexistente);
// 3) o SQL de backfill nunca fica pra trás — se alguém adicionar um novo
//    jogador histórico com foto (guessPlayerPhotoAssets) e ele já existir
//    no seed com photo_key nulo, este teste FALHA até o backfill SQL ser
//    atualizado (nunca silenciosamente "esquece" um jogador novo).
import { readFileSync } from 'node:fs';
import { runAudit } from './audit_photo_key_backfill.mjs';

const BACKFILL_PATH = 'supabase/guess_players_photo_key_backfill.sql';

// Jogadores com tratamento PRÓPRIO no backfill (campos além de photo_key,
// ou INSERT novo) — nunca fazem parte do array genérico do PASSO 1.
const HANDLED_INDIVIDUALLY = new Set(['tadeu_antonio_ferreira', 'michael', 'marcelo_rangel', 'apodi', 'dill']);

let failures = 0;
function check(label, condition) {
  if (condition) {
    console.log(`PASS — ${label}`);
  } else {
    failures += 1;
    console.error(`FAIL — ${label}`);
  }
}

const audit = runAudit();
const backfillSrc = readFileSync(BACKFILL_PATH, 'utf8');

check('0 asset órfão em guessPlayerPhotoAssets', audit.orphanAssets.length === 0);
if (audit.orphanAssets.length > 0) console.error('  órfãos:', audit.orphanAssets);

check('0 referência quebrada (catálogo -> chave inexistente)', audit.brokenRefs.length === 0);
if (audit.brokenRefs.length > 0) console.error('  quebradas:', audit.brokenRefs);

check(
  'todo jogador com foto histórica já existe no seed OU está no INSERT do backfill (nenhum "esquecido")',
  audit.missingFromSeed.every((id) => backfillSrc.includes(`'${id}'`)),
);

// O array do PASSO 1 do backfill deve ser EXATAMENTE
// (jogadores com foto histórica presentes no seed) MENOS os tratados
// individualmente — nem mais (um id que não precisa mais existir), nem
// menos (um id novo esquecido).
const expectedGenericIds = audit.presentInSeedIds.filter((id) => !HANDLED_INDIVIDUALLY.has(id)).sort();
const arrayMatch = backfillSrc.match(/id = any\(array\(?\[([\s\S]*?)\]\)?\)/i) ?? backfillSrc.match(/id = any\(array\[([\s\S]*?)\]\)/i);
const actualGenericIds = arrayMatch
  ? [...arrayMatch[1].matchAll(/'([a-z0-9_]+)'/g)].map((m) => m[1]).sort()
  : [];

check(
  `o array do PASSO 1 do backfill bate exatamente com os ${expectedGenericIds.length} jogadores esperados (nem mais, nem menos)`,
  JSON.stringify(actualGenericIds) === JSON.stringify(expectedGenericIds),
);
if (JSON.stringify(actualGenericIds) !== JSON.stringify(expectedGenericIds)) {
  const missing = expectedGenericIds.filter((id) => !actualGenericIds.includes(id));
  const extra = actualGenericIds.filter((id) => !expectedGenericIds.includes(id));
  if (missing.length) console.error('  faltando no backfill:', missing);
  if (extra.length) console.error('  sobrando no backfill (não é mais necessário):', extra);
}

console.log();
console.log(`${failures === 0 ? 'TUDO OK' : `${failures} FALHA(S)`} — resumo:`, {
  totalGuessPhotoAssets: audit.totalGuessPhotoAssets,
  playersUsingGuessPhotos: audit.playersUsingGuessPhotos,
  presentInSeed: audit.presentInSeedIds.length,
  missingFromSeed: audit.missingFromSeed,
});

process.exit(failures === 0 ? 0 : 1);
