// Adaptador Supabase (service_role) para `refresh.ts` / `article.ts`.
import type { NewsItem } from './types.ts';
import type { FailurePatch, NewsRow, NewsStore } from './refresh.ts';

// deno-lint-ignore no-explicit-any
type Admin = any;

export function createNewsStore(admin: Admin): NewsStore {
  return {
    async state(clubId) {
      const { data, error } = await admin
        .from('news_snapshots')
        .select('next_refresh_at,consecutive_failures')
        .eq('club_id', clubId)
        .maybeSingle();
      if (error) throw new Error(`news_snapshots state: ${error.message}`);
      return data ?? null;
    },
    async upsert(row: NewsRow) {
      const { error } = await admin.from('news_snapshots').upsert(row, { onConflict: 'club_id' });
      if (error) throw new Error(`news_snapshots upsert: ${error.message}`);
    },
    async markFailure(clubId: string, patch: FailurePatch) {
      const { data, error } = await admin.from('news_snapshots').update(patch).eq('club_id', clubId).select('club_id');
      if (error) throw new Error(`news_snapshots markFailure: ${error.message}`);
      return (data ?? []).length > 0;
    },
  };
}

/** Lista atual do snapshot (null se nunca houve refresh). */
export async function readNewsList(admin: Admin, clubId: string): Promise<NewsItem[] | null> {
  const { data, error } = await admin.from('news_snapshots').select('payload').eq('club_id', clubId).maybeSingle();
  if (error) throw new Error(`news_snapshots read: ${error.message}`);
  const items = data?.payload?.items;
  return Array.isArray(items) ? (items as NewsItem[]) : null;
}
