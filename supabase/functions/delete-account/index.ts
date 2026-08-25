// Exclusão de conta — cole no dashboard do Supabase (Edge Functions > Create
// a new function, nome "delete-account") ou publique via CLI se configurar
// uma. Roda em Deno, não em Node — não faz parte do build do Flutter/Worker.
//
// O usuário é identificado SÓ pelo JWT do header Authorization (nunca por um
// id enviado no corpo da requisição) — assim ninguém consegue excluir a
// conta de outra pessoa. `service_role` só existe aqui dentro, nunca chega
// ao Flutter.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Não autenticado.' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Client escopado ao chamador — só serve pra descobrir QUEM ele é.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await callerClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: 'Sessão inválida ou expirada.' }, 401);
    }

    const uid = user.id;

    // Client admin — só existe dentro da função.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // 1. Remove arquivos pessoais do Storage (não segue cascade de FK).
    const { data: avatarFiles } = await adminClient.storage.from('avatars').list(uid);
    if (avatarFiles && avatarFiles.length > 0) {
      const paths = avatarFiles.map((file) => `${uid}/${file.name}`);
      const { error: removeError } = await adminClient.storage.from('avatars').remove(paths);
      if (removeError) {
        console.error(`delete-account: falha ao remover avatar de ${uid}`, removeError.message);
      }
    }

    // 2. Remove a conta — cascade cuida de profiles, user_addresses e todo
    // o progresso da Arena (quiz, escalação, jogador, votos, scores etc.).
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(uid);
    if (deleteError) {
      console.error(`delete-account: falha ao excluir ${uid}`, deleteError.message);
      return jsonResponse(
        { error: 'Não foi possível excluir sua conta. Tente novamente em alguns instantes.' },
        500,
      );
    }

    return jsonResponse({ success: true }, 200);
  } catch (err) {
    console.error('delete-account: erro inesperado', err instanceof Error ? err.message : String(err));
    return jsonResponse(
      { error: 'Não foi possível excluir sua conta. Tente novamente em alguns instantes.' },
      500,
    );
  }
});
