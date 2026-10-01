// Aplica tooling/esmeraldino_passport/research/_career_players_corrections.json
// em cima do estado atual de data_export/goias/career_players.json (espelho
// do que está no banco real) e gera uma migration SQL com 1 UPDATE por
// jogador afetado, substituindo o club_career INTEIRO (mais auditável que
// jsonb_set encadeado) + PRÉ/PÓS condição comparando com o snapshot antes/
// depois.
import fs from 'fs';

const corrections = JSON.parse(
  fs.readFileSync('tooling/esmeraldino_passport/research/_career_players_corrections.json', 'utf8'),
);
const players = JSON.parse(fs.readFileSync('data_export/goias/career_players.json', 'utf8'));
const byId = new Map(players.map((p) => [p.id, p]));

const affectedIds = new Set();
const beforeById = new Map();

for (const fix of corrections.fixes) {
  const player = byId.get(fix.id);
  if (!player) throw new Error(`jogador não encontrado: ${fix.id}`);
  if (!beforeById.has(fix.id)) beforeById.set(fix.id, JSON.stringify(player.club_career));
  const entry = player.club_career.find((e) => e.period === fix.period && e.team === fix.team);
  if (!entry) throw new Error(`entrada não encontrada: ${fix.id} / ${fix.period} / ${fix.team}`);
  if (fix.appearances !== undefined && fix.appearances !== null) entry.appearances = fix.appearances;
  if (fix.goals !== undefined && fix.goals !== null) entry.goals = fix.goals;
  entry.data_quality = 'verified';
  entry.notes = fix.note;
  if (fix.set_period) entry.period = fix.set_period;
  affectedIds.add(fix.id);
}

for (const add of corrections.new_entries) {
  const player = byId.get(add.id);
  if (!player) throw new Error(`jogador não encontrado: ${add.id}`);
  if (!beforeById.has(add.id)) beforeById.set(add.id, JSON.stringify(player.club_career));
  const already = player.club_career.some(
    (e) => e.period === add.entry.period && e.team === add.entry.team,
  );
  if (!already) {
    player.club_career.push({ ...add.entry, data_quality: 'verified', notes: null });
  }
  affectedIds.add(add.id);
}

const lines = [];
lines.push(
  `-- ============================================================================`,
  `-- Correção em lote de career_players.club_career — pesquisa ogol.com.br`,
  `-- (2026-09-30), ver tooling/esmeraldino_passport/research/_career_players_corrections.json`,
  `-- pro detalhe de cada campo e a fonte. Preenche só o que a fonte confirma`,
  `-- (appearances/goals), nunca estima; onde a soma das temporadas bate exato`,
  `-- com o agregado oficial já existente no projeto, isso é citado na nota de`,
  `-- cada entrada como evidência de reconciliação.`,
  `--`,
  `-- Estratégia: substitui o club_career INTEIRO de cada jogador afetado (mais`,
  `-- fácil de auditar que jsonb_set encadeado) com PRÉ-condição comparando`,
  `-- com o estado documentado antes da correção.`,
  ``,
);

for (const id of affectedIds) {
  const player = byId.get(id);
  const before = beforeById.get(id);
  const after = JSON.stringify(player.club_career);
  const literal = (s) => `'${s.replace(/'/g, "''")}'::jsonb`;
  lines.push(
    `-- ${id} (${player.answer})`,
    `do $$`,
    `declare`,
    `  v_current jsonb;`,
    `begin`,
    `  select club_career into v_current from public.career_players where id = ${literal(id).replace('::jsonb', '')};`,
    `  if v_current is null then`,
    `    raise exception 'career_players.${id} não encontrado — aborta.';`,
    `  end if;`,
    `  if v_current != ${literal(before)} then`,
    `    raise exception 'career_players.${id}.club_career não está no estado esperado antes da correção — aborta pra não sobrescrever uma mudança feita por outro caminho. Atual: %', v_current;`,
    `  end if;`,
    `end $$;`,
    ``,
    `update public.career_players set club_career = ${literal(after)} where id = ${literal(id).replace('::jsonb', '')};`,
    ``,
  );
}

// PÓS-condição única no final conferindo todos de uma vez
lines.push(`-- PÓS: confirma que todos os ${affectedIds.size} jogadores ficaram no estado esperado.`);
lines.push(`do $$`, `declare`, `  v_bad text[];`, `begin`);
lines.push(`  v_bad := array[]::text[];`);
for (const id of affectedIds) {
  const player = byId.get(id);
  const after = JSON.stringify(player.club_career).replace(/'/g, "''");
  lines.push(
    `  if (select club_career from public.career_players where id = '${id}') != '${after}'::jsonb then`,
    `    v_bad := array_append(v_bad, '${id}');`,
    `  end if;`,
  );
}
lines.push(
  `  if array_length(v_bad, 1) > 0 then`,
  `    raise exception 'Pós-condição falhou pros ids: %', v_bad;`,
  `  end if;`,
  `end $$;`,
);

fs.writeFileSync(
  'supabase/migrations/20260930010000_fix_career_players_goias_ogol_research.sql',
  lines.join('\n') + '\n',
  'utf8',
);
console.log(`Gerado migration com ${affectedIds.size} jogadores afetados:`, [...affectedIds].join(', '));
