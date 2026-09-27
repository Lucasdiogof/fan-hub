// Autorização das Edge Functions que só a infraestrutura pode chamar
// (pg_cron via pg_net e as próprias functions entre si): cleanup de
// cadastros, sync/poll de partida e dispatch de push.
//
// Por que existe: o gateway do Supabase (verify_jwt) aceita QUALQUER JWT
// válido do projeto — inclusive a anon/publishable key, que é pública e está
// embutida no app. Sem esta checagem, qualquer pessoa com a anon key dispara
// uma função que roda com service_role (apagar cadastros, mandar push).
//
// Regra: só passa quem prova ser service_role.
//  1. Bearer idêntico ao SUPABASE_SERVICE_ROLE_KEY do runtime (comparação em
//     tempo constante) — é o caminho do cron e das chamadas entre functions.
//  2. Senão, o próprio Supabase Auth confirma o token numa rota que exige
//     service_role (admin API). Cobre chave secreta nova (sb_secret_...) ou
//     rotacionada sem depender de decodificar/confiar em claim localmente.
// Sem header, anon, token de usuário ou verificação falhando → recusa.
//
// Módulo puro (0 import Deno, 0 I/O próprio): a verificação remota é
// injetada, então roda no vitest do repo.

export type ServiceCallerDecision =
  | { ok: true; via: 'service_key' | 'auth_admin' }
  | { ok: false; status: 401 | 403; reason: string };

export function extractBearerToken(authorizationHeader: string | null): string | null {
  if (!authorizationHeader) return null;
  const match = /^Bearer\s+(.+)$/i.exec(authorizationHeader.trim());
  const token = match?.[1]?.trim();
  return token ? token : null;
}

export function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const left = enc.encode(a);
  const right = enc.encode(b);
  // Percorre sempre o maior tamanho: não vaza, pelo tempo, em que posição
  // (nem se pelo tamanho) as chaves divergem.
  const length = Math.max(left.length, right.length);
  let diff = left.length ^ right.length;
  for (let i = 0; i < length; i++) {
    diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return diff === 0;
}

export async function authorizeServiceCaller(
  authorizationHeader: string | null,
  serviceRoleKey: string | undefined,
  verifyServiceTokenRemotely: (token: string) => Promise<boolean>,
): Promise<ServiceCallerDecision> {
  const token = extractBearerToken(authorizationHeader);
  if (!token) {
    return { ok: false, status: 401, reason: 'missing bearer token' };
  }

  if (serviceRoleKey && timingSafeEqual(token, serviceRoleKey)) {
    return { ok: true, via: 'service_key' };
  }

  let verified = false;
  try {
    verified = await verifyServiceTokenRemotely(token);
  } catch {
    verified = false;
  }
  if (verified) {
    return { ok: true, via: 'auth_admin' };
  }

  return { ok: false, status: 403, reason: 'service_role required' };
}

// Rota do GoTrue que só aceita service_role (valida assinatura/chave do lado
// do Supabase). per_page=1: só prova o acesso, não lê a base de usuários.
export function makeAuthAdminVerifier(
  supabaseUrl: string,
  fetchImpl: typeof fetch = fetch,
): (token: string) => Promise<boolean> {
  return async (token: string) => {
    const res = await fetchImpl(`${supabaseUrl}/auth/v1/admin/users?page=1&per_page=1`, {
      headers: { apikey: token, Authorization: `Bearer ${token}` },
    });
    return res.ok;
  };
}

// Uso no topo do handler: `const denied = await rejectUnlessServiceCaller(...);
// if (denied) return denied;`. Nunca devolve o motivo exato ao chamador.
export async function rejectUnlessServiceCaller(
  req: Request,
  supabaseUrl: string,
  serviceRoleKey: string | undefined,
  fetchImpl: typeof fetch = fetch,
): Promise<Response | null> {
  const decision = await authorizeServiceCaller(
    req.headers.get('Authorization'),
    serviceRoleKey,
    makeAuthAdminVerifier(supabaseUrl, fetchImpl),
  );
  if (decision.ok) return null;
  return new Response(JSON.stringify({ ok: false, error: 'forbidden' }), {
    status: decision.status,
    headers: { 'Content-Type': 'application/json' },
  });
}
