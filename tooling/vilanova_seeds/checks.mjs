// Checagens pós-seed usadas pelo simulador (contagens, órfãos, RPCs do app).
export default async function (q, db) {

  for (const t of ['club_board_sections','club_board_members','club_transparency_topics','club_transparency_documents','squad_members','quiz_questions','lineup_matches','career_players','guess_players','passport_matches','venues']) {
    console.log(t.padEnd(28), (await q(`select count(*)::int n from public.${t}`))[0].n);
  }
  console.log('quiz por nivel:', JSON.stringify(await q(`select difficulty, count(*)::int from public.quiz_questions group by 1 order by 1`)));
  console.log('elenco por grupo:', JSON.stringify(await q(`select position_group, count(*)::int from public.squad_members group by 1 order by min(sort_order)`)));
  console.log('guess status:', JSON.stringify(await q(`select data_status, count(*)::int from public.guess_players group by 1`)));
  console.log('carreira sem passagem no clube:', (await q(`select count(*)::int n from public.career_players where not exists (select 1 from jsonb_array_elements(club_career) e where (e->>'is_goias')::boolean)`))[0].n);
  console.log('club_id errado:', (await q(`select (select count(*) from public.squad_members where club_id <> '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e') + (select count(*) from public.quiz_questions where club_id <> '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e') + (select count(*) from public.lineup_matches where club_id <> '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e') as n`))[0].n);
  console.log('escalacao exemplo:', JSON.stringify((await q(`select id, formation, jsonb_array_length(lineup) n, lineup->0 gk from public.lineup_matches order by display_order limit 1`))[0]));


  console.log('por temporada:', JSON.stringify(await q(`select season, count(*)::int n, count(venue_id)::int com_venue, count(*) filter (where status='SCHEDULED')::int agendados from public.passport_matches group by season order by season`)));
  console.log('orfaos (estadio sem venue):', (await q(`select count(*)::int n from public.passport_matches where stadium is not null and venue_id is null`))[0].n);
  console.log('venues sem uso:', (await q(`select count(*)::int n from public.venues v where not exists (select 1 from public.passport_matches m where m.venue_id=v.id)`))[0].n);
  console.log('top estadios:', JSON.stringify(await q(`select v.display_name, count(*)::int n from public.passport_matches m join public.venues v on v.id=m.venue_id group by 1 order by 2 desc limit 5`)));
  console.log('santa cruz unificado:', JSON.stringify(await q(`select v.id, count(*)::int n from public.passport_matches m join public.venues v on v.id=m.venue_id where v.city='Ribeirão Preto' group by 1`)));
  console.log('penaltis em notes:', JSON.stringify(await q(`select id, outcome, data_notes from public.passport_matches where data_notes like '%pênaltis%' order by match_date limit 3`)));
  // RPCs que o app chama, com um usuário autenticado FALSO — tudo dentro de
  // uma transação desfeita no fim (ROLLBACK). Este arquivo também roda contra
  // o banco REAL (verify-vilanova-live.mjs): até 2026-09-30 o insert abaixo
  // ficava gravado e criou um usuário "t@t" em produção (removido). Nunca
  // tirar o begin/rollback.
  await db.exec('begin');
  try {
  await db.exec(`insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000001','t@t') on conflict do nothing`);
  await db.exec(`select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001', true)`);
  const fns = await q(`select p.proname, pg_get_function_identity_arguments(p.oid) args from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'passport%' order by 1`);
  console.log('rpcs:', fns.map((f) => `${f.proname}(${f.args})`).join(' | '));
  try {
    const rows = await q(`select * from public.passport_matches_for_year(2025)`);
    console.log('passport_matches_for_year(2025):', rows.length, 'linhas; exemplo:', JSON.stringify(rows.find((r) => r.venue_name)));
  } catch (e) { console.log('RPC for_year FAIL:', e.message); }
  // Cobertura da RPC em todos os anos do pacote (2010–2026 desde a v1.4):
  // cada ano precisa devolver exatamente o que está na tabela.
  try {
    const seasons = await q(`select season, count(*)::int n from public.passport_matches group by 1 order by 1`);
    const bad = [];
    for (const { season, n } of seasons) {
      const got = (await q(`select * from public.passport_matches_for_year(${season})`)).length;
      if (got !== n) bad.push(`${season}: rpc ${got} ≠ tabela ${n}`);
    }
    console.log(`passport_matches_for_year(${seasons[0]?.season}..${seasons.at(-1)?.season}):`, bad.length ? 'DIVERGE ' + bad.join('; ') : `OK em ${seasons.length} anos`);
  } catch (e) { console.log('RPC for_year (todos) FAIL:', e.message); }
  try {
    console.log('passport_seasons:', JSON.stringify(await q(`select * from public.passport_seasons()`)));
  } catch (e) { console.log('RPC seasons FAIL:', e.message); }
  } finally {
    await db.exec('rollback');
  }
}
