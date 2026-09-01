// Limpeza de cadastros pendentes há mais de 48h — cole no dashboard do
// Supabase (Edge Functions > Create a new function, nome
// "cleanup-unconfirmed-signups") e agende via pg_cron (ver
// supabase/cleanup_unconfirmed_signups_cron.sql). Roda em Deno, chamada só
// pelo cron (nunca pelo Flutter) — o `Authorization: Bearer <service_role>`
// que o pg_net manda já é a própria autenticação da chamada.
//
// `service_role` só existe aqui dentro, nunca chega ao Flutter. A lista de
// quem apagar vem da RPC `public.list_unconfirmed_signups_for_cleanup`
// (definida no mesmo SQL do cron), que só o `service_role` tem permissão de
// chamar — nunca apaga baseado em nada que o cliente tenha mandado.
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: pending, error: listError } = await adminClient.rpc(
      'list_unconfirmed_signups_for_cleanup',
    );
    if (listError) {
      console.error('cleanup-unconfirmed-signups: falha ao listar pendentes', listError.message);
      return jsonResponse({ error: 'Falha ao listar cadastros pendentes.' }, 500);
    }

    const rows = (pending ?? []) as Array<{ id: string; email: string | null }>;
    let deleted = 0;
    let failed = 0;

    for (const row of rows) {
      const { error: deleteError } = await adminClient.auth.admin.deleteUser(row.id);
      if (deleteError) {
        failed += 1;
        // Só o e-mail (não CPF/senha/OTP) — útil pra investigar manualmente
        // qual conta específica falhou, sem logar nenhum dado sensível.
        console.error(
          `cleanup-unconfirmed-signups: falha ao excluir ${row.email ?? row.id}`,
          deleteError.message,
        );
      } else {
        deleted += 1;
      }
    }

    return jsonResponse({ success: true, scanned: rows.length, deleted, failed }, 200);
  } catch (err) {
    console.error('cleanup-unconfirmed-signups: erro inesperado', err instanceof Error ? err.message : String(err));
    return jsonResponse({ error: 'Erro inesperado na limpeza.' }, 500);
  }
});
