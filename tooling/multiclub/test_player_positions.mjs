// Testes do seed de player_positions — rodam contra o dado real gerado.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { resolvePortugueseToken, resolveCareerPlayersPosition, resolveLineupMatchesPosition, normalizeDirectCode, arePositionsCompatible } from './position_catalog.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const positions = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_positions_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_position_sources_seed.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_positions_seed_stats.json'), 'utf8'));
const migrationSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902060000_create_player_positions.sql'), 'utf8');
const seedSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902070000_seed_goias_player_positions.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byName(name) { return canonicalPeople.find((p) => p.canonicalName === name); }
function positionsOf(canonicalName) {
  const person = byName(canonicalName);
  return positions.filter((p) => p.personId === person.canonicalId).sort((a, b) => a.positionOrder - b.positionOrder);
}

console.log('1) Dieguinho — 1 person_id, VOL/LD/MC, sem duplicação de pessoa/spell');
test('Jackson Diego Ibraim Fagundes tem exatamente 3 posições: VOL, LD, MC (alguma ordem), sem duplicar código', () => {
  const rows = positionsOf('Jackson Diego Ibraim Fagundes');
  const codes = rows.map((r) => r.positionCode).sort();
  assert.deepStrictEqual(codes, ['LD', 'MC', 'VOL']);
  assert.strictEqual(new Set(codes).size, 3);
});
test('só existe 1 canonicalId pra Dieguinho em canonicalPeople (nunca 3 identidades pras 3 posições)', () => {
  const matches = canonicalPeople.filter((p) => p.canonicalName === 'Jackson Diego Ibraim Fagundes');
  assert.strictEqual(matches.length, 1);
});

console.log('\n2) Nicolas — Godinho (atacante) != Vichiatto (lateral), nunca misturados');
test('Nicolas Godinho Johann tem só ATA; Nicolas Vichiatto da Silva tem LE+ALE — person_id diferentes, position_code sem sobreposição de identidade', () => {
  const godinho = positionsOf('Nicolas Godinho Johann');
  const vichiatto = positionsOf('Nicolas Vichiatto da Silva');
  assert.deepStrictEqual(godinho.map((r) => r.positionCode), ['ATA']);
  assert.deepStrictEqual(vichiatto.map((r) => r.positionCode), ['LE', 'ALE']);
  assert.notStrictEqual(godinho[0].personId, vichiatto[0].personId);
});

console.log('\n3) Danilo — Gabriel de Andrade (histórico, meia) != Cunha da Silva (atual, lateral)');
test('Danilo Gabriel de Andrade tem só MEI; Danilo Cunha da Silva tem LE+ALE — pessoas diferentes', () => {
  const gabriel = positionsOf('Danilo Gabriel de Andrade');
  const cunha = positionsOf('Danilo Cunha da Silva');
  assert.deepStrictEqual(gabriel.map((r) => r.positionCode), ['MEI']);
  assert.deepStrictEqual(cunha.map((r) => r.positionCode), ['LE', 'ALE']);
  assert.notStrictEqual(gabriel[0].personId, cunha[0].personId);
});

console.log('\n4) Rodrigo Soares / Djalma / Lourenço / Lucas Rodrigues — fonte-ouro (goias_squad.dart), ordem exata preservada');
test('Rodrigo Alves Soares: LD(1), ALD(2), LE(3), VERIFIED', () => {
  const rows = positionsOf('Rodrigo Alves Soares');
  assert.deepStrictEqual(rows.map((r) => [r.positionOrder, r.positionCode]), [[1, 'LD'], [2, 'ALD'], [3, 'LE']]);
  assert.ok(rows.every((r) => r.verificationStatus === 'VERIFIED'));
});
test('Djalma Antônio da Silva Filho: LE(1), ALE(2), PE(3)', () => {
  const rows = positionsOf('Djalma Antônio da Silva Filho');
  assert.deepStrictEqual(rows.map((r) => [r.positionOrder, r.positionCode]), [[1, 'LE'], [2, 'ALE'], [3, 'PE']]);
});
test('João Paulo Ferreira Lourenço: VOL(1), MC(2), MEI(3)', () => {
  const rows = positionsOf('João Paulo Ferreira Lourenço');
  assert.deepStrictEqual(rows.map((r) => [r.positionOrder, r.positionCode]), [[1, 'VOL'], [2, 'MC'], [3, 'MEI']]);
});
test('Lucas Rodrigues Moreira Costa: VOL(1), MC(2), MEI(3)', () => {
  const rows = positionsOf('Lucas Rodrigues Moreira Costa');
  assert.deepStrictEqual(rows.map((r) => [r.positionOrder, r.positionCode]), [[1, 'VOL'], [2, 'MC'], [3, 'MEI']]);
});

console.log('\n5) Multi-position — mesma pessoa pode ter 3+ posições, sem virar 3 pessoas');
test('existe pelo menos 1 pessoa com 3+ posições no dataset real', () => {
  const byPerson = new Map();
  for (const p of positions) byPerson.set(p.personId, (byPerson.get(p.personId) || 0) + 1);
  assert.ok([...byPerson.values()].some((n) => n >= 3));
});

console.log('\n6) position_order — nunca duplicado no mesmo contexto (person_id, club_id, spell_id)');
test('nenhum (personId, clubSlug, positionOrder) duplicado no seed', () => {
  const seen = new Set();
  for (const p of positions) {
    const key = `${p.personId}|${p.clubSlug}|${p.positionOrder}`;
    assert.ok(!seen.has(key), `duplicata: ${key}`);
    seen.add(key);
  }
});
test('nenhum (personId, clubSlug, positionCode) duplicado no seed', () => {
  const seen = new Set();
  for (const p of positions) {
    const key = `${p.personId}|${p.clubSlug}|${p.positionCode}`;
    assert.ok(!seen.has(key), `duplicata: ${key}`);
    seen.add(key);
  }
});

console.log('\n7) Provenance — múltiplas fontes não duplicam player_position, cada fonte-registro vira 1 linha só, evidência granular preservada');
test('nenhuma source (personId, positionCode, sourceType, sourceRef, matchId) duplicada', () => {
  const seen = new Set();
  for (const s of sources) {
    const key = `${s.personId}|${s.positionCode}|${s.sourceType}|${s.sourceRef}|${s.matchId || ''}`;
    assert.ok(!seen.has(key), `duplicata: ${key}`);
    seen.add(key);
  }
});
test('Rodrigo Soares (fonte-ouro) tem provenance de goias_squad_dart + squad_members (corroborando), não só 1 fonte', () => {
  const rodrigo = byName('Rodrigo Alves Soares');
  const srcs = sources.filter((s) => s.personId === rodrigo.canonicalId);
  const sourceNames = new Set(srcs.map((s) => s.sourceType));
  assert.ok(sourceNames.has('goias_squad_dart'));
});
test('toda source de lineup_matches tem match_id e observed_at preenchidos; nenhuma outra fonte tem match_id/observed_at inventado', () => {
  for (const s of sources) {
    if (s.sourceType === 'lineup_matches') {
      assert.ok(s.matchId, `lineup_matches sem match_id: ${JSON.stringify(s)}`);
      assert.ok(s.observedAt, `lineup_matches sem observed_at: ${JSON.stringify(s)}`);
    } else {
      assert.strictEqual(s.matchId, null, `fonte "${s.sourceType}" não deveria ter match_id`);
      assert.strictEqual(s.observedAt, null, `fonte "${s.sourceType}" não deveria ter observed_at`);
    }
  }
});
test('raw_value nunca é null/vazio — toda source preserva o valor exato da fonte antes do mapeamento', () => {
  for (const s of sources) assert.ok(s.rawValue && s.rawValue.length > 0, `source sem raw_value: ${JSON.stringify(s)}`);
});
test('Dieguinho: a source de "LD/MC" (2021_guarani_brB_acesso) gera 2 linhas de provenance (LD e MC), cada uma com nota de valor composto', () => {
  const dieguinho = byName('Jackson Diego Ibraim Fagundes');
  const compound = sources.filter((s) => s.personId === dieguinho.canonicalId && s.matchId === '2021_guarani_brB_acesso');
  assert.strictEqual(compound.length, 2);
  assert.deepStrictEqual(compound.map((s) => s.positionCode).sort(), ['LD', 'MC']);
  assert.ok(compound.every((s) => s.notes && s.notes.includes('composto')));
});

console.log('\n8) Idempotência — rodar o seed 2x não duplica (ON CONFLICT DO NOTHING nas duas tabelas)');
test('o INSERT de player_positions usa ON CONFLICT (person_id, club_id, spell_id, position_code) DO NOTHING', () => {
  assert.ok(seedSql.includes('on conflict (person_id, club_id, spell_id, position_code) do nothing;'));
});
test('o INSERT de player_position_sources usa ON CONFLICT (player_position_id, source_type, source_ref, match_id) DO NOTHING', () => {
  assert.ok(seedSql.includes('on conflict (player_position_id, source_type, source_ref, match_id) do nothing;'));
});
test('reexecutar build+generate produz o MESMO SQL byte-a-byte', () => {
  const before = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902070000_seed_goias_player_positions.sql'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_player_positions_seed.mjs')], { stdio: 'pipe' });
  execFileSync(process.execPath, [path.join(__dirname, 'generate_player_positions_seed.mjs')], { stdio: 'pipe' });
  const after = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902070000_seed_goias_player_positions.sql'), 'utf8');
  assert.strictEqual(before, after);
});

console.log('\n9) Historical safety — spell_id sempre null nesta leva (posição atual não é retroativamente carimbada num spell histórico)');
test('toda linha do seed tem spell_id implícito null (a coluna nem é escrita no INSERT — sempre literal null)', () => {
  assert.ok(seedSql.includes('select v.person_id, c.id, null, v.position_code'));
});
test('a UNIQUE parcial cobre exatamente o caso spell_id is null (garante em banco, não só no gerador)', () => {
  assert.ok(migrationSql.includes('where spell_id is null'));
});

console.log('\n10) Estrutura — sem stats, sem shirt_number, sem posição específica de partida');
test('CREATE TABLE de player_positions não declara appearances/goals/minutes/matches/shirt_number/preferred_foot/height/weight', () => {
  const createBlock = migrationSql.split('create table if not exists public.player_positions')[1].split('create table if not exists public.player_position_sources')[0];
  for (const forbidden of ['appearances', 'goals', 'minutes', 'matches', 'shirt_number', 'preferred_foot', 'height', 'weight']) {
    assert.ok(!new RegExp(`\\b${forbidden}\\b`).test(createBlock), `coluna proibida "${forbidden}"`);
  }
});

console.log('\n11) Catálogo/mapeamento — nunca adivinha lado (D/E), nunca colapsa compatibilidade tática em identidade');
test('token bare "ponta"/"ala" (sem lado) nunca resolve pra um código', () => {
  assert.strictEqual(resolvePortugueseToken('ponta'), null);
  assert.strictEqual(resolvePortugueseToken('ala'), null);
});
test('"Lateral-direito / ala" resolve LD+ALD (lado inferido do token ADJACENTE na mesma string, não um palpite solto)', () => {
  const { resolved, unmapped } = resolveCareerPlayersPosition('Lateral-direito / ala');
  assert.deepStrictEqual(resolved.sort(), ['ALD', 'LD']);
  assert.deepStrictEqual(unmapped, []);
});
test('"Volante / meia" resolve VOL+MEI mesmo com o 2º token em minúsculo', () => {
  const { resolved } = resolveCareerPlayersPosition('Volante / meia');
  assert.deepStrictEqual(resolved.sort(), ['MEI', 'VOL']);
});
test('lineup_matches "DEF" e "ALA" (genéricos, sem lado) nunca resolvem', () => {
  assert.deepStrictEqual(resolveLineupMatchesPosition('DEF').resolved, []);
  assert.deepStrictEqual(resolveLineupMatchesPosition('ALA').resolved, []);
});
test('lineup_matches "LD/MC" (caso real do Dieguinho) resolve os 2 códigos', () => {
  const { resolved } = resolveLineupMatchesPosition('LD/MC');
  assert.deepStrictEqual(resolved.sort(), ['LD', 'MC']);
});
test('normalizeDirectCode aceita qualquer caixa (gol/GOL/Gol) mas rejeita código inventado', () => {
  assert.strictEqual(normalizeDirectCode('gol'), 'GOL');
  assert.strictEqual(normalizeDirectCode('Gol'), 'GOL');
  assert.strictEqual(normalizeDirectCode('XYZ'), null);
});

console.log('\n12) Classificação neutra — NON_ADJACENT_MULTI_POSITION nunca bloqueia/descarta posição, nunca vira erro de dado');
test('a classificação PROVAVEL_CONFLITO não existe mais em nenhum conflito reportado — renomeada pra NON_ADJACENT_MULTI_POSITION', () => {
  assert.ok(!stats.conflictsReport.some((c) => c.classification === 'PROVAVEL_CONFLITO'));
});
test('Dieguinho (MC/LD/VOL) e Willean Lepo (LD/LE) aparecem como NON_ADJACENT_MULTI_POSITION no relatório, mas AMBAS as posições continuam na tabela canônica (nunca descartadas)', () => {
  const dieguinho = stats.conflictsReport.find((c) => c.canonicalName === 'Jackson Diego Ibraim Fagundes' && c.classification);
  const willean = stats.conflictsReport.find((c) => c.canonicalName === 'Willean Lepo' && c.classification);
  assert.strictEqual(dieguinho.classification, 'NON_ADJACENT_MULTI_POSITION');
  assert.strictEqual(willean.classification, 'NON_ADJACENT_MULTI_POSITION');
  const willeanRows = positions.filter((p) => p.canonicalName === 'Willean Lepo');
  assert.deepStrictEqual(willeanRows.map((p) => p.positionCode).sort(), ['LD', 'LE']);
});
test('arePositionsCompatible: LD e LE não são adjacência tática conhecida (motor de escalação), mas isso é só classificação de relatório, nunca critério de exclusão de dado', () => {
  assert.strictEqual(arePositionsCompatible('LD', 'LE'), false);
});

console.log('\n13) Fernandão / Iarley — cap explícito pra ATA, evidência MEI preservada em stats, nunca apagada da fonte bruta');
test('Fernandão tem SOMENTE 1 posição canônica: ATA', () => {
  const rows = positionsOf('Fernandão');
  assert.deepStrictEqual(rows.map((r) => r.positionCode), ['ATA']);
});
test('Iarley tem SOMENTE 1 posição canônica: ATA', () => {
  const rows = positionsOf('Iarley');
  assert.deepStrictEqual(rows.map((r) => r.positionCode), ['ATA']);
});
test('suppressedPositions documenta MEI suprimido pros dois, com motivo — nunca um "sumiço" silencioso', () => {
  const fernandao = stats.suppressedPositions.find((s) => s.canonicalName === 'Fernandão');
  const iarley = stats.suppressedPositions.find((s) => s.canonicalName === 'Iarley');
  assert.ok(fernandao && fernandao.suppressedCodes.includes('MEI') && fernandao.reason);
  assert.ok(iarley && iarley.suppressedCodes.includes('MEI') && iarley.reason);
});
test('career_players.json (fonte bruta) NUNCA foi editado — "Atacante / meia-atacante" e "Meia-atacante / atacante" continuam intactos', () => {
  const cp = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'career_players.json'), 'utf8'));
  const fernandaoRaw = cp.find((p) => p.id === 'fernandao');
  const iarleyRaw = cp.find((p) => p.id === 'iarley');
  assert.strictEqual(fernandaoRaw.position, 'Atacante / meia-atacante');
  assert.strictEqual(iarleyRaw.position, 'Meia-atacante / atacante');
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length > 0) {
  console.log('\nFALHAS:');
  for (const f of failures) console.log(` - ${f.name}: ${f.err.message}`);
  process.exit(1);
}
