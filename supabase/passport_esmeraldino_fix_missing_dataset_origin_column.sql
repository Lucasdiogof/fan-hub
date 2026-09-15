-- ============================================================================
-- Correção pontual: a migration 20260915000000_passport_esmeraldino_historical_schema.sql
-- esqueceu de adicionar `dataset_origin` em public.passport_matches (só
-- adicionou nas outras 4 colunas novas + na tabela passport_matches_excluded,
-- que já tinha essa coluna certa). Já corrigi o arquivo da migration pra
-- quem rodar do zero no futuro — isto aqui é só pra quem, como você, já
-- rodou a migration antes da correção.
--
-- Seguro rodar mesmo se a coluna já existir (IF NOT EXISTS).
-- ============================================================================

alter table public.passport_matches
  add column if not exists dataset_origin text;

comment on column public.passport_matches.dataset_origin is
  'Lote/pipeline de origem do registro (ex.: historical_futebol80, modern_audited_2000_2026) — proveniência, não confiança.';
