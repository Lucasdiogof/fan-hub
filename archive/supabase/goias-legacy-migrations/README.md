# Cadeia de migrations original do Goiás (histórico, arquivada)

Este diretório NÃO é um workdir do Supabase CLI — não existe `config.toml`
em nenhum nível deste caminho, o CLI nunca vai detectar/rodar nada daqui,
mesmo com "supabase" no nome do path. Se algum dia precisar rodar o CLI
contra o Goiás, use sempre `supabase/migrations/` na raiz do repo (a cadeia
canônica oficial, ver `docs/multiclub/54_m4_convergencia_real_goias_
bragantino.md` e `docs/multiclub/55_...` [cutover]).

## O que é isto

Os **63 arquivos `.sql`** que formaram a cadeia REAL de migrations do
projeto Goiás (`yonozsdgyrhgqrvydbnr`) entre 2026-08-30 e 2026-09-04 —
desde a primeira migration (`20260830220000_baseline_marker.sql`) até a
convergência final pro schema canônico Fan Hub (`20260904230000_align_
function_body_order_with_canonical.sql`).

Em 2026-09-04, depois de provar `SCHEMA_DIFF=0` entre Goiás e Bragantino
(o Goiás convergiu pro mesmo schema canônico, mas por um caminho de 63
migrations incrementais, não pela cadeia canônica de 2 arquivos), o
usuário autorizou um `migration repair` (metadata-only, nunca re-executa
DDL) pra fazer o Goiás **reportar** a mesma cadeia operacional que o
Bragantino: `20260904000000_canonical_baseline` + `20260904210000_add_
delivery_address_triggers`.

Esses 63 arquivos deixam de ser a cadeia OPERACIONAL (não são mais
aplicados/rastreados por `db push`/`migration list`), mas continuam sendo
o registro **real e verdadeiro** de como o schema do Goiás evoluiu
statement por statement — nunca apagado, só arquivado.

## Conteúdo deste diretório

- `files/` — os 63 arquivos `.sql`, cópia exata (byte-a-byte) dos que
  estavam em `supabase/migrations/` antes do cutover. Nomes/timestamps de
  versão preservados.
- `files_sha256_manifest.json` — hash SHA-256 + tamanho em bytes de cada
  um dos 63 arquivos locais, pra provar integridade se algum dia alguém
  precisar comparar com o histórico do git.
- `last_remote_state_before_cutover.json` — snapshot de
  `supabase_migrations.schema_migrations` do projeto Goiás capturado
  IMEDIATAMENTE antes do `migration repair` (version, name, contagem de
  statements, md5 dos statements aplicados de verdade no banco — não só
  do arquivo local). É a prova de que o repair partiu de um estado
  conhecido e documentado, nunca de uma suposição.

## Por que arquivar em vez de deletar

- Auditoria: qualquer pessoa consegue reconstruir exatamente como/quando
  cada tabela/RPC/coluna nasceu no Goiás, statement por statement.
- Segurança do cutover: se o `migration repair` precisar ser revertido
  por qualquer motivo, o estado completo de "antes" está aqui, versionado
  no git, nunca só na memória de uma sessão.
- Nenhum dado real foi perdido — o cutover é 100% metadata (`schema_
  migrations`), o schema em si já era idêntico ao canonical antes do
  repair (`SCHEMA_DIFF=0` provado e documentado em
  `docs/multiclub/54_m4_convergencia_real_goias_bragantino.md`).

## Se um clube novo precisar do schema completo do zero

Use `infra/supabase/canonical/supabase/migrations/` (ou, depois do
cutover, `supabase/migrations/` — as duas cadeias convergem pro mesmo
conteúdo canônico) — nunca reaplique estes 63 arquivos legados num
projeto novo.
