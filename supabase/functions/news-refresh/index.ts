// Atualiza `news_snapshots` (lista de notícias) deste projeto Supabase a partir
// do site oficial do clube. Só cron/service_role. Body opcional:
// { club?: string, force?: boolean } — padrão: o que estiver vencido.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { SERVER_CLUB_REGISTRY, resolveClubServerConfigByCode } from '../_shared/club_server_config.ts';
import { createImageDeps } from '../_shared/football/store.ts';
import { NEWS_IMAGE_BUCKET } from '../_shared/news/images.ts';
import { refreshNews } from '../_shared/news/refresh.ts';
import { createNewsStore } from '../_shared/news/store.ts';
import { rejectUnlessServiceCaller } from '../_shared/service_caller_auth.ts';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const denied = await rejectUnlessServiceCaller(req, supabaseUrl, serviceRoleKey);
    if (denied) return denied;

    const body = (await req.json().catch(() => ({}))) as { club?: string; force?: boolean };
    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: rows, error } = await admin.from('clubs').select('id');
    if (error) return json({ ok: false, error: 'clubs unavailable' }, 500);
    const present = new Set((rows ?? []).map((r: { id: string }) => r.id));
    const candidates = body.club ? [resolveClubServerConfigByCode(body.club)] : SERVER_CLUB_REGISTRY;
    const clubs = candidates.filter((c) => c?.news && present.has(c.canonicalClubId));
    if (clubs.length === 0) return json({ ok: false, error: 'unknown club' }, 404);

    // Capas no Storage só com o flag ligado (bucket `news-images` existe).
    const images =
      Deno.env.get('NEWS_IMAGES') === 'on' ? createImageDeps(admin, supabaseUrl, fetch, NEWS_IMAGE_BUCKET) : null;
    const store = createNewsStore(admin);

    const results = [];
    for (const club of clubs) {
      if (!club) continue;
      results.push({ club: club.code, ...(await refreshNews(club, { store, fetch, images }, body.force === true)) });
    }
    return json({ ok: results.every((r) => r.ok), results });
  } catch (err) {
    console.error('news-refresh', err instanceof Error ? err.message : String(err));
    return json({ ok: false }, 500);
  }
});
