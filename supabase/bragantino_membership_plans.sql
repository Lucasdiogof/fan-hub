-- ============================================================================
-- Massa Bruta (Sócio Torcedor do Red Bull Bragantino) — catálogo de planos
-- server-side. Rode no SQL Editor do projeto Supabase do BRAGANTINO
-- (ref yrgyzkaaudyzmsqwzecj), nunca no do Goiás.
--
-- A tabela `public.membership_plans` já existe no schema canônico
-- (convergido entre os dois clubes) mas está VAZIA — cada clube semeia os
-- próprios planos. `subscribe_to_plan_for_club(p_club_id, p_plan_id)`
-- rejeita ("invalid plan_id") qualquer `plan_id` que não tenha uma linha
-- aqui pro `club_id` do Bragantino — sem rodar isto, a Etapa 2 (Revisão →
-- Confirmar Associação) do cadastro Massa Bruta falha em produção mesmo
-- com o app compilando normalmente.
--
-- `plan_key` tem que bater EXATAMENTE com os `id` de
-- `BragantinoMembershipPlansCatalog.plans` (lib/features/membership/data/
-- bragantino_membership_plans_catalog.dart) — é só esse texto que viaja
-- entre Flutter e Postgres; nome/benefícios/preço de exibição continuam
-- vindo do catálogo Dart, nunca desta tabela.
--
-- `duration_days = 30` — mesma janela "mock" já usada pro Sócio Esmeralda
-- (Goiás): a adesão concede status de sócio ativo por 30 dias a partir da
-- confirmação, sem cobrança real (`membershipCommerceMode: demo` nos dois
-- clubes) — mesma estratégia, não um comportamento novo.
-- ============================================================================

insert into public.membership_plans (club_id, plan_key, name, duration_days, is_active, sort_order)
values
  ('51683d2a-ea1d-57c6-8014-996146f242e7', 'asas-bronze',  'Asas Bronze',  30, true, 1),
  ('51683d2a-ea1d-57c6-8014-996146f242e7', 'asas-prata',   'Asas Prata',   30, true, 2),
  ('51683d2a-ea1d-57c6-8014-996146f242e7', 'asas-ouro',    'Asas Ouro',    30, true, 3),
  ('51683d2a-ea1d-57c6-8014-996146f242e7', 'asas-platina', 'Asas Platina', 30, true, 4)
on conflict (club_id, plan_key) do update set
  name = excluded.name,
  duration_days = excluded.duration_days,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order;
