-- Gap real achado comparando Goiás (já convergido) x Bragantino (baseline
-- original): o baseline criava delivery_address_enforce_single_default() e
-- delivery_address_ensure_default() (as functions) mas nunca os TRIGGERS
-- que as ligam a public.delivery_addresses -- introspecção original (pg_proc)
-- capturou as functions, mas o trigger-capture explícito só cobriu
-- auth.users (handle_new_user), não outras tabelas com trigger em `public`.
-- Categoria C do diff (objeto faltante no canonical), corrigido aqui.

CREATE TRIGGER delivery_addresses_ensure_default BEFORE INSERT ON public.delivery_addresses FOR EACH ROW EXECUTE FUNCTION delivery_address_ensure_default();
CREATE TRIGGER delivery_addresses_single_default BEFORE INSERT OR UPDATE ON public.delivery_addresses FOR EACH ROW EXECUTE FUNCTION delivery_address_enforce_single_default();
