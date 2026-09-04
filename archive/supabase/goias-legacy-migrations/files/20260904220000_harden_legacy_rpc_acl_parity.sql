-- Paridade de ACL Goiás x canonical (achado real comparando os dois bancos
-- já convergidos — diff_schema_goias_bragantino.mjs, categoria "grants").
--
-- 13 functions pré-existentes do Goiás nunca tinham passado pelo hardening
-- "revoke all from public + grant explícito" que o canonical baseline já
-- aplica pra tudo — historicamente ficaram com EXECUTE aberto a PUBLIC
-- (pub=true), looseness herdada de migrations antigas, nunca endurecida.
-- generate_store_order_number(p_club_id uuid), recém-criada pela migration
-- anterior (20260904190000) já com "revoke all ... from public", mesmo
-- assim ficou com anon/service_role=true ao vivo — o projeto Goiás tem uma
-- regra ALTER DEFAULT PRIVILEGES que auto-concede EXECUTE a anon/
-- authenticated/service_role em toda function NOVA de public (bootstrap
-- padrão do Supabase; o Bragantino não tem essa regra, por isso nunca
-- precisou disso). REVOKE ALL FROM PUBLIC não cobre grants diretos
-- concedidos assim — precisa revoke explícito de anon/service_role também.

revoke all on function public.delivery_address_enforce_single_default() from public;
grant execute on function public.delivery_address_enforce_single_default() to anon, authenticated, service_role;

revoke all on function public.delivery_address_ensure_default() from public;
grant execute on function public.delivery_address_ensure_default() to anon, authenticated, service_role;

revoke all on function public.generate_store_order_number(p_club_id uuid) from public, anon, service_role;
grant execute on function public.generate_store_order_number(p_club_id uuid) to authenticated;

revoke all on function public.handle_new_user() from public;
grant execute on function public.handle_new_user() to anon, authenticated, service_role;

revoke all on function public.passport_memorable_match_id(p_user_id uuid) from public;
grant execute on function public.passport_memorable_match_id(p_user_id uuid) to anon, authenticated, service_role;

revoke all on function public.passport_my_attendances_for_year(p_season integer) from public;
grant execute on function public.passport_my_attendances_for_year(p_season integer) to anon, authenticated, service_role;

revoke all on function public.passport_my_rank(p_year integer) from public;
grant execute on function public.passport_my_rank(p_year integer) to anon, authenticated, service_role;

revoke all on function public.passport_ranking(p_year integer, p_limit integer) from public;
grant execute on function public.passport_ranking(p_year integer, p_limit integer) to anon, authenticated, service_role;

revoke all on function public.passport_save_attendances(p_changes jsonb) from public;
grant execute on function public.passport_save_attendances(p_changes jsonb) to anon, authenticated, service_role;

revoke all on function public.passport_seasons() from public;
grant execute on function public.passport_seasons() to anon, authenticated, service_role;

revoke all on function public.passport_set_memorable_match(p_match_id text) from public;
grant execute on function public.passport_set_memorable_match(p_match_id text) to anon, authenticated, service_role;

revoke all on function public.passport_stadium_summary(p_user_id uuid) from public;
grant execute on function public.passport_stadium_summary(p_user_id uuid) to anon, authenticated, service_role;

revoke all on function public.passport_summary(p_user_id uuid) from public;
grant execute on function public.passport_summary(p_user_id uuid) to anon, authenticated, service_role;

revoke all on function public.rls_auto_enable() from public;
grant execute on function public.rls_auto_enable() to anon, authenticated, service_role;
