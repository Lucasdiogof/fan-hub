// Teste autenticado A×B do fix de IDOR do Passaporte (5 RPCs por-usuário).
// Complementa supabase/passport_harden_per_user_rpcs.sql — aquele arquivo já
// prova a guarda via impersonação de jwt.claims (sem usuário real); este
// aqui prova com sessões REAIS de duas contas de TESTE, contra o REST/RPC
// já em produção, para o caso de ponta a ponta funcionar exatamente como o
// app funcionaria.
//
// NUNCA usa dados de usuários existentes/produção. Se as duas contas de
// teste não estiverem configuradas, o script imprime
// AUTHENTICATED_SECURITY_TEST_PENDING e sai com código 0 (não falha CI/lint
// por falta de infraestrutura de teste, só documenta o que falta).
//
// Nunca imprime token/senha — só status HTTP e códigos de erro.
//
// Uso direto (se você já tem 2 sessões prontas):
//   SUPABASE_URL=https://<ref>.supabase.co \
//   SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
//   TEST_USER_A_TOKEN=<jwt da sessão de A> TEST_USER_A_UID=<uuid de A> \
//   TEST_USER_B_TOKEN=<jwt da sessão de B> TEST_USER_B_UID=<uuid de B> \
//   node tooling/passport_security/authenticated_idor_test.mjs
//
// Uso recomendado (cria as contas QA sozinho): ver
// run_authenticated_idor_test.mjs no mesmo diretório — ele chama runMatrix()
// exportado abaixo depois de criar/logar as 2 contas descartáveis.
//
// Rode uma vez por projeto (Goiás e Bragantino são bancos separados).

const RPCS = [
  'passport_summary',
  'passport_attendance_breakdown',
  'passport_stadium_summary',
  'passport_attended_matches',
  'passport_memorable_match_id',
];

export async function callRpc(url, publishableKey, fn, token, body) {
  const headers = {
    apikey: publishableKey,
    'Content-Type': 'application/json',
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${url}/rest/v1/rpc/${fn}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body ?? {}),
  });
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch {
    // corpo não-JSON (raro) — mantém texto bruto pra diagnóstico
  }
  return { status: res.status, body: json ?? text };
}

class MatrixFailure extends Error {}

function assertOk(res, label) {
  if (res.status !== 200) {
    throw new MatrixFailure(
      `${label}: esperado 200, veio ${res.status} — ${JSON.stringify(res.body)}`,
    );
  }
}

function assertForbidden(res, label) {
  const code = res.body && typeof res.body === 'object' ? res.body.code : null;
  if (res.status < 400) {
    throw new MatrixFailure(
      `${label}: esperado recusa (>=400), veio 200 — POSSÍVEL VAZAMENTO DE DADO PRIVADO: ${JSON.stringify(res.body)}`,
    );
  }
  if (code !== null && code !== '42501' && code !== 'P0001') {
    throw new MatrixFailure(
      `${label}: recusado (${res.status}) mas código inesperado — ${JSON.stringify(res.body)}`,
    );
  }
}

// Roda a matriz completa A×B nas 5 RPCs + anon + ranking, num projeto.
// Lança MatrixFailure com o motivo exato na primeira falha.
// Nunca recebe nem imprime senha — só token/uid, e mesmo esses não são logados.
//
// Cada checagem imprime o próprio PASS na hora (não só no fim): se alguma
// falhar, fica registrado até onde a matriz passou. Por isso `log` volta
// vazio — as linhas já foram impressas; o campo só existe por compatibilidade
// com quem ainda itera sobre ele.
//
// Ranking: desde a 20261002040000 NENHUMA `passport_*` executa para anon
// (inclusive passport_ranking/passport_my_rank). Testa os dois lados: sem
// sessão é recusado; com sessão responde 200 e no formato esperado.
export async function runMatrix({ url, publishableKey, tokenA, uidA, tokenB, uidB }) {
  const pass = (label) => console.log(`PASS ${label}`);
  const ok = (res, label) => {
    assertOk(res, label);
    pass(label);
  };
  const forbidden = (res, label) => {
    assertForbidden(res, label);
    pass(`${label} -> recusado (${res.status})`);
  };

  for (const fn of RPCS) {
    ok(await callRpc(url, publishableKey, fn, tokenA, {}), `${fn}: A lê os próprios dados (sem p_user_id)`);
    ok(
      await callRpc(url, publishableKey, fn, tokenA, { p_user_id: uidA }),
      `${fn}: A lê os próprios dados (p_user_id=A)`,
    );
    ok(await callRpc(url, publishableKey, fn, tokenB, {}), `${fn}: B lê os próprios dados (sem p_user_id)`);
    ok(
      await callRpc(url, publishableKey, fn, tokenB, { p_user_id: uidB }),
      `${fn}: B lê os próprios dados (p_user_id=B)`,
    );
    forbidden(
      await callRpc(url, publishableKey, fn, tokenA, { p_user_id: uidB }),
      `${fn}: A tenta consultar B`,
    );
    forbidden(
      await callRpc(url, publishableKey, fn, tokenB, { p_user_id: uidA }),
      `${fn}: B tenta consultar A`,
    );
    forbidden(await callRpc(url, publishableKey, fn, null, {}), `${fn}: sem sessão`);
    forbidden(
      await callRpc(url, publishableKey, fn, null, { p_user_id: uidA }),
      `${fn}: sem sessão com p_user_id=A`,
    );
  }

  // Ranking/my_rank sem sessão: recusados (anon sem EXECUTE).
  forbidden(await callRpc(url, publishableKey, 'passport_ranking', null, {}), 'passport_ranking: sem sessão');
  forbidden(await callRpc(url, publishableKey, 'passport_my_rank', null, {}), 'passport_my_rank: sem sessão');

  // Ranking autenticado: 200 e lista no formato do leaderboard.
  const ranking = await callRpc(url, publishableKey, 'passport_ranking', tokenA, {});
  assertOk(ranking, 'passport_ranking: autenticado');
  const rankingShapeOk =
    Array.isArray(ranking.body) &&
    ranking.body.every(
      (r) => Number.isInteger(r.rank) && typeof r.user_id === 'string' && Number.isInteger(r.match_count),
    );
  if (!rankingShapeOk) {
    throw new MatrixFailure(
      `passport_ranking: autenticado respondeu 200 com formato inesperado — ${JSON.stringify(ranking.body).slice(0, 300)}`,
    );
  }
  pass(`passport_ranking: autenticado -> 200, ${ranking.body.length} linha(s) no formato esperado`);

  // my_rank autenticado: 200, no máximo 1 linha (a do próprio usuário).
  for (const [who, token] of [
    ['A', tokenA],
    ['B', tokenB],
  ]) {
    const myRank = await callRpc(url, publishableKey, 'passport_my_rank', token, {});
    assertOk(myRank, `passport_my_rank: autenticado (${who})`);
    const myRankShapeOk =
      Array.isArray(myRank.body) &&
      myRank.body.length <= 1 &&
      myRank.body.every((r) => Number.isInteger(r.rank) && Number.isInteger(r.match_count));
    if (!myRankShapeOk) {
      throw new MatrixFailure(`passport_my_rank (${who}): formato inesperado — ${JSON.stringify(myRank.body)}`);
    }
    const desc = myRank.body.length
      ? `posição ${myRank.body[0].rank}, ${myRank.body[0].match_count} jogo(s)`
      : 'sem posição (0 jogos)';
    pass(`passport_my_rank: autenticado (${who}) -> 200, ${desc}`);
  }

  return { pass: true, log: [] };
}

async function mainFromEnv() {
  const url = process.env.SUPABASE_URL;
  const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY;
  const tokenA = process.env.TEST_USER_A_TOKEN;
  const uidA = process.env.TEST_USER_A_UID;
  const tokenB = process.env.TEST_USER_B_TOKEN;
  const uidB = process.env.TEST_USER_B_UID;

  if (!url || !publishableKey || !tokenA || !uidA || !tokenB || !uidB) {
    console.log('AUTHENTICATED_SECURITY_TEST_PENDING');
    console.log(
      'Faltam variáveis de ambiente. Necessárias: SUPABASE_URL, ' +
        'SUPABASE_PUBLISHABLE_KEY, TEST_USER_A_TOKEN, TEST_USER_A_UID, ' +
        'TEST_USER_B_TOKEN, TEST_USER_B_UID. Ou use run_authenticated_idor_test.mjs ' +
        'pra criar as contas QA automaticamente.',
    );
    process.exit(0);
  }

  try {
    const { log } = await runMatrix({ url, publishableKey, tokenA, uidA, tokenB, uidB });
    for (const line of log) console.log(line);
    console.log('==== TODOS OS TESTES AUTENTICADOS (A x B) PASSARAM ====');
  } catch (err) {
    console.error(`FAIL: ${err.message}`);
    process.exit(1);
  }
}

// Só roda o fluxo de env vars quando chamado diretamente (não quando importado).
if (import.meta.url === `file://${process.argv[1]}`) {
  mainFromEnv();
}
