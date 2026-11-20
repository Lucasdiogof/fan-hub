// Adaptador Supabase (service_role) pra `refresh.ts` e Storage pra `images.ts`.
// Fino de propósito: toda regra fica em módulos puros.
import type { SnapshotRow } from './contract.ts';
import { IMAGE_BUCKET, type ImageDeps } from './images.ts';
import type { DueInfo, SnapshotStore } from './refresh.ts';

// Tipo mínimo do client (evita importar supabase-js aqui e mantém o módulo testável).
// deno-lint-ignore no-explicit-any
type Admin = any;

export function createSnapshotStore(admin: Admin): SnapshotStore {
  return {
    async list(clubId) {
      const { data, error } = await admin
        .from('football_snapshots')
        .select('kind,key,next_refresh_at,consecutive_failures')
        .eq('club_id', clubId);
      if (error) throw new Error(`football_snapshots list: ${error.message}`);
      return (data ?? []) as DueInfo[];
    },
    async upsert(rows: SnapshotRow[]) {
      const { error } = await admin.from('football_snapshots').upsert(rows, { onConflict: 'club_id,kind,key' });
      if (error) throw new Error(`football_snapshots upsert: ${error.message}`);
    },
    async markFailure(clubId, kind, key, patch) {
      const { data, error } = await admin
        .from('football_snapshots')
        .update(patch)
        .eq('club_id', clubId)
        .eq('kind', kind)
        .eq('key', key)
        .select('key');
      if (error) throw new Error(`football_snapshots markFailure: ${error.message}`);
      return (data ?? []).length > 0;
    },
  };
}

export function createImageDeps(admin: Admin, supabaseUrl: string, fetchImpl: typeof fetch = fetch): ImageDeps {
  const publicBase = `${supabaseUrl}/storage/v1/object/public/${IMAGE_BUCKET}`;
  return {
    fetch: fetchImpl,
    publicBase,
    storage: {
      // HEAD na URL pública: mais barato que listar o bucket a cada imagem.
      async exists(path) {
        // 1 retry: erro de rede transitório aqui deixaria a URL original no snapshot até o próximo refresh.
        for (let attempt = 0; ; attempt++) {
          try {
            const res = await fetchImpl(`${publicBase}/${path}`, { method: 'HEAD' });
            return res.ok;
          } catch (err) {
            if (attempt >= 1) throw err;
          }
        }
      },
      async upload(path, bytes, contentType) {
        const { error } = await admin.storage
          .from(IMAGE_BUCKET)
          .upload(path, bytes, { contentType, upsert: false, cacheControl: '31536000' });
        // Corrida entre dois refreshes: o arquivo já existe -> ok.
        if (error && !/already exists|Duplicate/i.test(error.message)) throw new Error(error.message);
      },
    },
  };
}
