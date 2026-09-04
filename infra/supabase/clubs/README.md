# Bootstrap de identidade por clube

Separação deliberada, pedida explicitamente: **cadeia canônica de migrations** (`supabase/migrations/` — desde 2026-09-04 é a ÚNICA cadeia oficial, usada por goias e bragantino, ver `docs/multiclub/55_...cutover`) nunca sabe qual clube existe — cria `public.clubs` vazia e todo o resto do schema. **Club bootstrap** (aqui) é o passo SEPARADO, por clube, que insere a 1 linha de identidade depois que o baseline já foi aplicado num projeto.

Cada `infra/supabase/clubs/<clube>/bootstrap.sql` é standalone — não é uma "migration" no sentido do Supabase CLI (não fica em `supabase/migrations/`, nunca entra em `migration list`/`db push`). É aplicado manualmente, uma vez, depois do baseline, via execução direta contra o projeto certo (`npx supabase db query --file ...`, statements separados — `db query --file` não aceita múltiplos statements de uma vez).

**Status real (2026-09-04)**: `bragantino/bootstrap.sql` já foi aplicado contra o projeto Bragantino real (`yrgyzkaaudyzmsqwzecj`) — `public.clubs` tem a linha do Bragantino. `goias/bootstrap.sql` nunca foi aplicado literalmente (o Goiás já tinha sua própria linha de `clubs` de antes da arquitetura multi-Supabase existir, via `supabase/migrations/20260902030000_seed_clubs.sql`, agora arquivada em `archive/supabase/goias-legacy-migrations/`) — o arquivo aqui existe só como documentação/paridade de como um Goiás reconstruído do zero a partir do canonical baseline se inicializaria.

UUID de cada clube: `uuidV5(CLUBS_UUID_NAMESPACE, canonicalClubKey)`, mesmo algoritmo/namespace de sempre (`tooling/multiclub/club_registry.mjs`), registrado em `tooling/multiclub/clubs_registry.json` — nunca um valor solto/reinventado aqui.
