// Atualiza os snapshots de futebol (`football_snapshots`) deste projeto
// Supabase. Só cron/outras functions (service_role). Body opcional:
// { club?: string, kinds?: string[] } — padrão: todo clube deste projeto,
// só o que estiver vencido (`next_refresh_at <= now`). Roda em Deno.
// Agendamento (pg_cron + pg_net) é uma etapa SEPARADA da migration do schema.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { SERVER_CLUB_REGISTRY, resolveClubServerConfigByCode } from '../_shared/club_server_config.ts';
import { isSnapshotKind, type SnapshotKind } from '../_shared/football/contract.ts';
import { refreshDue } from '../_shared/football/refresh.ts';
import { createImageDeps, createSnapshotStore } from '../_shared/football/store.ts';
import { rejectUnlessServiceCaller } from '../_shared/service_caller_auth.ts';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const denied = await rejectUnlessServiceCaller(req, supabaseUrl, serviceRoleKey);
    if (denied) return denied;

    const body = (await req.json().catch(() => ({}))) as { club?: string; kinds?: string[] };
    const kinds = body.kinds?.filter(isSnapshotKind) as SnapshotKind[] | undefined;
    if (body.kinds && kinds?.length !== body.kinds.length) return json({ ok: false, error: 'invalid kinds' }, 400);

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Clubes deste projeto = os do registry que existem em `public.clubs`
    // (cada projeto Supabase tem o seu). `club` no body restringe.
    const { data: rows, error } = await admin.from('clubs').select('id');
    if (error) return json({ ok: false, error: 'clubs unavailable' }, 500);
    const present = new Set((rows ?? []).map((r: { id: string }) => r.id));
    const candidates = body.club ? [resolveClubServerConfigByCode(body.club)] : SERVER_CLUB_REGISTRY;
    const clubs = candidates.filter((c) => c && present.has(c.canonicalClubId));
    if (clubs.length === 0) return json({ ok: false, error: 'unknown club' }, 404);

    // Materialização de imagens só quando habilitada (bucket `football-images` existe).
    const images = Deno.env.get('FOOTBALL_IMAGES') === 'on' ? createImageDeps(admin, supabaseUrl) : null;
    const store = createSnapshotStore(admin);

    const results = [];
    for (const club of clubs) {
      if (!club) continue;
      const done = await refreshDue(club, { store, images }, kinds);
      results.push(...done.map(({ payload: _payload, ...rest }) => rest));
    }
    return json({ ok: results.every((r) => r.ok), results });
  } catch (err) {
    console.error('football-refresh', err instanceof Error ? err.message : String(err));
    return json({ ok: false }, 500);
  }
});
