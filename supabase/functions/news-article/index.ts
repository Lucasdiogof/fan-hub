// Artigo de notícia sob demanda (sem persistir). O gateway roda com
// --no-verify-jwt (a publishable key do app não é JWT), então a própria função
// exige e valida a sessão do usuário (ver `_shared/news/handler.ts`). O cliente
// manda SÓ `id` (+ `club` opcional); a URL vem da lista do snapshot.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { SERVER_CLUB_REGISTRY } from '../_shared/club_server_config.ts';
import { createImageDeps } from '../_shared/football/store.ts';
import { handleNewsArticle } from '../_shared/news/handler.ts';
import { NEWS_IMAGE_BUCKET } from '../_shared/news/images.ts';
import { readNewsList } from '../_shared/news/store.ts';

Deno.serve((req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const admin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  return handleNewsArticle(req, {
    // Auth valida o JWT do usuário no servidor; chave publishable/service role não são usuário.
    verifyUser: async (token) => {
      const { data, error } = await admin.auth.getUser(token);
      return !error && !!data.user;
    },
    clubs: async () => {
      const { data, error } = await admin.from('clubs').select('id');
      if (error) return [];
      const present = new Set((data ?? []).map((r: { id: string }) => r.id));
      return SERVER_CLUB_REGISTRY.filter((c) => c.news && present.has(c.canonicalClubId));
    },
    readList: (clubId) => readNewsList(admin, clubId),
    images: Deno.env.get('NEWS_IMAGES') === 'on' ? createImageDeps(admin, supabaseUrl, fetch, NEWS_IMAGE_BUCKET) : null,
    fetch,
  });
});
