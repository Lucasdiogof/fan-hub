-- ============================================================================
-- Adiciona o status 'refunded' a public.tickets, pro fluxo de "Solicitar
-- reembolso" em Meus Ingressos (reembolso simulado, sem gateway real --
-- ver supabase/tickets.sql pro schema completo da tabela). Idempotente:
-- rodar de novo nao muda nada se ja aplicada.
--
-- Nao mexe em RLS -- a policy "update own tickets" (auth.uid() = user_id)
-- ja cobre a operacao; o app protege contra reembolso duplicado/de outra
-- conta com um UPDATE condicional (where status = 'active'), nao com uma
-- RPC nova, seguindo o mesmo padrao ja usado por checkIn/undoCheckIn nesta
-- tabela.
-- ============================================================================

alter table public.tickets
  add column if not exists refunded_at timestamptz;

alter table public.tickets
  drop constraint if exists tickets_status_check;

alter table public.tickets
  add constraint tickets_status_check
  check (status in ('active', 'cancelled', 'used', 'expired', 'refunded'));
