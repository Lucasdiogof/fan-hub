import { defineConfig } from 'vitest/config';
import { cloudflareTest } from '@cloudflare/vitest-pool-workers';

export default defineConfig({
  plugins: [cloudflareTest({ wrangler: { configPath: './wrangler.toml' } })],
  test: {
    // `supabase/functions/_shared/**` inclui só os módulos PUROS
    // compartilhados pelas Edge Functions (0 import Deno-specific, 0 I/O) —
    // nunca o runtime da própria Edge Function (`Deno.serve`, `Deno.env`),
    // que continua só rodando de verdade no Supabase. Ver M3.3 (rodada de
    // hardening) §7: harness Node/TS pros helpers puros, sem alterar o
    // runtime real da function.
    include: ['src/**/*.test.ts', 'supabase/functions/_shared/**/*.test.ts'],
  },
});
