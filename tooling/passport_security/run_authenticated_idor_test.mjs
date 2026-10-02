// Cria (frescas, descartáveis) as 2 contas QA de um projeto, marca uma
// presença REAL numa partida FINISHED só pra A (via `passport_save_attendances`
// oficial — nunca DELETE/UPDATE administrativo, nunca service_role), prova
// que A e B enxergam dados DIFERENTES e que B nunca acessa os dados de A
// (nem o contrário), desfaz a marcação pela mesma RPC oficial ao final, e
// confirma que a limpeza realmente aconteceu. Roda a matriz A×B de
// identidade/permissão (authenticated_idor_test.mjs) nas 5 RPCs privadas +
// anon + ranking/my_rank.
//
// Token, senha e refresh token NUNCA são impressos, gravados em arquivo, log
// ou memória — só nome de RPC, status HTTP, contagens e PASS/FAIL.
//
// Rode uma vez por projeto (cada clube é um banco de auth separado; cada
// execução cria seu próprio par de contas QA nesse projeto). O clube é OBRIGATÓRIO
// e o destino é validado contra supabase_projects_registry.json ANTES de qualquer
// rede ou escrita — a URL é o que decide onde as contas serão criadas, então um
// SUPABASE_URL de outro projeto aborta aqui, sem criar nada:
//
//   SUPABASE_URL=https://<project-ref-do-clube>.supabase.co \
//   SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
//   node tooling/passport_security/run_authenticated_idor_test.mjs --club goias
//
// `--club` aceita: goias | bragantino | vilanova (as chaves do registry). Conta
// Supabase (accountLabel) NÃO entra na validação: vale só clube -> projectRef.
//
// Pré-requisito: "Confirm email" OFF no projeto (já é o caso nos dois — ver
// reference_supabase_email_confirmation_toggle), senão o signup não devolve
// sessão imediata e o script não tem como logar sozinho.

import { randomBytes } from 'node:crypto';
import { assertSupabaseUrlMatchesClub } from '../multiclub/db_target_resolver.mjs';
import { callRpc, runMatrix } from './authenticated_idor_test.mjs';

function parseClubFlag(argv) {
  const eq = argv.find((a) => a.startsWith('--club='));
  if (eq) return eq.slice('--club='.length);
  const i = argv.indexOf('--club');
  return i >= 0 ? argv[i + 1] : undefined;
}

const clubLabel = parseClubFlag(process.argv.slice(2));
const url = process.env.SUPABASE_URL;
const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY;

if (!clubLabel || clubLabel.startsWith('--')) {
  console.error('Uso: node tooling/passport_security/run_authenticated_idor_test.mjs --club <goias|bragantino|vilanova>');
  process.exit(1);
}
if (!url || !publishableKey) {
  console.error('Faltam SUPABASE_URL e/ou SUPABASE_PUBLISHABLE_KEY.');
  process.exit(1);
}
// Validação do destino ANTES de qualquer fetch (nenhum usuário é criado se divergir).
try {
  assertSupabaseUrlMatchesClub(clubLabel, url);
} catch (err) {
  console.error(err.message);
  process.exit(1);
}

async function signupDisposableAccount(label) {
  const stamp = Date.now();
  const email = `${clubLabel}-passport-qa-${label}-${stamp}@example.invalid`;
  const password = randomBytes(24).toString('base64url');

  const res = await fetch(`${url}/auth/v1/signup`, {
    method: 'POST',
    headers: { apikey: publishableKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const json = await res.json();

  if (!res.ok || !json.access_token || !json.user?.id) {
    console.error(
      `Falha ao criar conta QA ${label}: HTTP ${res.status} — ${json.msg || json.error_description || JSON.stringify(json)}`,
    );
    process.exit(1);
  }

  return { token: json.access_token, uid: json.user.id, email };
}

async function findFinishedMatchId(token) {
  const seasonsRes = await callRpc(url, publishableKey, 'passport_seasons', token, {});
  if (seasonsRes.status !== 200 || !Array.isArray(seasonsRes.body)) {
    throw new Error(`Não consegui listar temporadas: HTTP ${seasonsRes.status}`);
  }
  const seasons = seasonsRes.body
    .filter((s) => (s.finished_count ?? 0) > 0)
    .sort((a, b) => b.season - a.season);
  for (const s of seasons) {
    const matchesRes = await callRpc(url, publishableKey, 'passport_matches_for_year', token, {
      p_season: s.season,
    });
    if (matchesRes.status !== 200 || !Array.isArray(matchesRes.body)) continue;
    const finished = matchesRes.body.find((m) => m.status === 'FINISHED');
    if (finished) return finished.id;
  }
  throw new Error('Não encontrei nenhuma partida FINISHED pra usar no teste.');
}

async function getTotalMatches(token) {
  const res = await callRpc(url, publishableKey, 'passport_summary', token, {});
  if (res.status !== 200) throw new Error(`passport_summary falhou: HTTP ${res.status}`);
  return res.body?.[0]?.total_matches ?? 0;
}

async function saveAttendance(token, matchId, attended) {
  const res = await callRpc(url, publishableKey, 'passport_save_attendances', token, {
    p_changes: [{ matchId, attended }],
  });
  const applied = Array.isArray(res.body) && res.body[0]?.applied === true;
  if (res.status !== 200 || !applied) {
    const reason = Array.isArray(res.body) ? res.body[0]?.reason : undefined;
    throw new Error(
      `passport_save_attendances(attended:=${attended}) não aplicou (HTTP ${res.status}, reason=${reason ?? 'desconhecido'})`,
    );
  }
}

async function main() {
  console.log(`Criando 2 contas QA descartáveis em ${url} (label: ${clubLabel})...`);
  const a = await signupDisposableAccount('a');
  const b = await signupDisposableAccount('b');
  console.log('Contas QA criadas (emails apenas, sem token/senha impressos):');
  console.log(`  A: ${a.email}`);
  console.log(`  B: ${b.email}`);

  const matchId = await findFinishedMatchId(a.token);
  console.log(`Partida FINISHED escolhida pro teste: ${matchId}`);

  const baselineA = await getTotalMatches(a.token);
  const baselineB = await getTotalMatches(b.token);
  console.log(`Baseline (esperado 0 em conta nova): A=${baselineA}, B=${baselineB}`);

  await saveAttendance(a.token, matchId, true);
  console.log('PASS: "Eu fui" marcado pra A via RPC oficial (passport_save_attendances)');

  try {
    const afterA = await getTotalMatches(a.token);
    const afterB = await getTotalMatches(b.token);
    if (afterA !== baselineA + 1) {
      throw new Error(`passport_summary(A) esperado ${baselineA + 1}, veio ${afterA}`);
    }
    if (afterB !== baselineB) {
      throw new Error(`passport_summary(B) esperado ${baselineB} (inalterado), veio ${afterB}`);
    }
    console.log(`PASS passport_summary: A=${afterA} presença(s), B=${afterB} presença(s) — isolado`);

    const { log } = await runMatrix({
      url,
      publishableKey,
      tokenA: a.token,
      uidA: a.uid,
      tokenB: b.token,
      uidB: b.uid,
    });
    for (const line of log) console.log(line);

    const matchesA = await callRpc(url, publishableKey, 'passport_attended_matches', a.token, {});
    const matchesB = await callRpc(url, publishableKey, 'passport_attended_matches', b.token, {});
    const aHasMatch = Array.isArray(matchesA.body) && matchesA.body.some((m) => m.id === matchId);
    const bHasMatch = Array.isArray(matchesB.body) && matchesB.body.some((m) => m.id === matchId);
    if (!aHasMatch) {
      throw new Error('A deveria ver a partida QA em passport_attended_matches e não viu');
    }
    if (bHasMatch) {
      throw new Error('VAZAMENTO: B enxergou a partida QA marcada por A em passport_attended_matches');
    }
    console.log('PASS passport_attended_matches: A vê a partida QA, B não vê (nem via p_user_id=A, barrado acima)');

    console.log(
      `==== TODOS OS TESTES AUTENTICADOS (A x B, com dado real) PASSARAM — ${clubLabel} ====`,
    );
  } finally {
    // Limpeza SEMPRE roda, mesmo se alguma asserção acima falhar — nunca
    // deixa a presença QA pra trás. Só a RPC pública/autenticada do próprio
    // app, nunca DELETE administrativo nem service_role.
    await saveAttendance(a.token, matchId, false);
    const afterCleanupA = await getTotalMatches(a.token);
    if (afterCleanupA !== baselineA) {
      console.error(
        `FAIL limpeza: A deveria voltar a ${baselineA} presença(s), ficou em ${afterCleanupA}`,
      );
      process.exitCode = 1;
    } else {
      console.log(`PASS limpeza: presença de A removida via RPC oficial, contagem voltou a ${afterCleanupA}`);
    }
  }
}

main().catch((err) => {
  console.error(`FAIL (${clubLabel}): ${err.message}`);
  process.exitCode = 1;
});
