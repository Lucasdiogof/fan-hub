# M4 — Multi-Supabase: correção do contrato de CLI (comandos, secrets, Storage, staging)

Data: 2026-09-04
Status: **AUDIT + DESIGN, correção do relatório 49.** 0 implementação, 0 db push, 0 migration repair, 0 mover migrations, 0 git push. `infra/supabase/canonical/` continua não criado.

## 1) `--project-ref` — testado empiricamente, resultado real (nem exatamente o que eu tinha desenhado, nem exatamente "não funciona")

Antes de aceitar a correção às cegas, testei os dois lados (comandos só de LEITURA, seguros, sem `--dry-run`/push nenhum):

```bash
npx supabase migration list --project-ref yonozsdgyrhgqrvydbnr
# -> conecta, retorna as 60 migrations com remote=<timestamp> (bate com o Goiás real)

npx supabase migration list --project-ref yrgyzkaaudyzmsqwzecj
# -> conecta em OUTRO projeto de verdade (confirmado: não é fallback silencioso pro
#    default do config.toml — os 60 "remote" vieram TODOS como "" vazio, porque o
#    Bragantino está genuinamente vazio) — a flag funcionou como seletor de alvo real.
```

**Fato confirmado**: `--project-ref` FUNCIONA como seletor de projeto pra `migration list` nesta sessão — não é a "flag morta" que eu temia ter desenhado errado, mas também não é `--linked`. O que a flag faz de verdade: resolve o projeto via Management API, usando o token de `supabase login` já ativo nesta sessão (é por isso que funciona sem `--db-url`/senha — a autenticação vem da sessão CLI, não de uma connection string). Isso é diferente de `--linked` (que exige `supabase/config.toml` apontando pro projeto) e diferente de `--db-url` (que não depende de sessão de login nenhuma, só da própria connection string).

**Por que ainda assim desenho com `--db-url`, como você pediu**: `--project-ref` depende de uma sessão de CLI autenticada e com acesso aos projetos certos — ótimo pra uso interativo (como o desta sessão), mas ruim pra CI/wrapper determinístico (exigiria gerenciar token de login como secret, não só a connection string). `--db-url` é mais portável, mais explícito sobre qual banco está sendo tocado, e combina melhor com o modelo "nunca versionar segredo, vem de env" que você pediu. **Registro os dois, mas desenho os wrappers do item 2 com `--db-url`**, por ser estritamente mais seguro/portável — não porque `--project-ref` esteja quebrado (não está, testei).

## 2) Modelo operacional corrigido

**Dois eixos, sempre explícitos, nunca implícitos**:
- **`--workdir <caminho>`** → escolhe a CADEIA de migrations (raiz `supabase/` = histórico Goiás · `infra/supabase/canonical` = baseline canônico).
- **`--db-url "$VAR_DE_AMBIENTE"`** → escolhe o BANCO remoto de verdade, nunca escrito em texto no comando/arquivo.

```bash
# Fase 1 — aplicar o baseline no Bragantino (staging descartável, ver item 5)
npx supabase db push \
  --workdir infra/supabase/canonical \
  --db-url "$BRAGANTINO_DB_URL" \
  --dry-run

# Comparar baseline vs Goiás — SEMPRE leitura, Goiás nunca recebe --db-url de escrita
npx supabase db diff \
  --workdir infra/supabase/canonical \
  --from "$BRAGANTINO_DB_URL" \
  --to "$GOIAS_DB_URL" \
  --schema public,storage \
  -o baseline_vs_goias_diff.sql
```
`db diff --from`/`--to` aceitam URL Postgres direta pros dois lados — comparação remoto-a-remoto sem shadow database, sem Docker, exatamente o que o item 3 pediu.

**Formato da connection string**: nunca inventado aqui — cada projeto tem a sua própria em Dashboard → Settings → Database → Connection string (padrão Supabase: pooler de sessão `postgresql://postgres.<ref>:<senha>@aws-0-<região>.pooler.supabase.com:5432/postgres`, percent-encoded). Nunca commitada, nunca impressa em log — só injetada via env/secret no momento do comando.

## 3) Estratégia de secrets — `DB_URL` nunca versionado

Convenção proposta (mesma família de `--dart-define`/dashboard vars já usada no resto do projeto — nunca um `.env` versionado, que não existe hoje neste repo):
- Local (dev/você rodando manualmente): exportar na sessão do shell antes de rodar qualquer wrapper — `export GOIAS_DB_URL="..."`/`export BRAGANTINO_DB_URL="..."` — nunca escrito em arquivo dentro do repo. Um `README`/comentário no wrapper documenta ONDE pegar o valor (Dashboard, nunca um arquivo local persistente sugerido).
- CI (se algum dia existir pipeline automatizado pra isso — não existe hoje, nenhum workflow do GitHub Actions toca Supabase): secret do GitHub Actions (`secrets.GOIAS_DB_URL`/`secrets.BRAGANTINO_DB_URL`), injetado só no step que precisa, nunca em log (`::add-mask::` ou equivalente).
- `.gitignore` já cobre a convenção geral do projeto (confirmar que nenhum arquivo de secret sugerido pelos wrappers do item 6 fique fora do ignore, quando eles forem escritos de verdade).

## 4) Storage — dupla prova, não só `db diff`

Confirmado: `db diff` tem limitações conhecidas com objetos de Storage (buckets/policies nem sempre aparecem de forma confiável num schema diff genérico, dependendo do engine — `migra`/`pg-schema-diff`/`pg-delta` tratam `storage.*` de formas diferentes, nenhuma delas documentada como garantia total). Por isso a validação do baseline usa **duas provas independentes**, nunca só uma:

**Prova A — schema diff** (`db diff --schema public,storage`, item 2) — pega divergência estrutural de tabela/coluna/RLS/índice/função de forma ampla.

**Prova B — auditoria SQL explícita, expected-state estruturado**, comparando os DOIS bancos com a MESMA query, resultado esperado idêntico (exceto nome/id do clube, que é esperado divergir):
```sql
-- rodar nos dois: Goiás (leitura) e Bragantino (leitura, pós-baseline)
select id, name, public from storage.buckets order by id;
-- esperado: mesmos 2 buckets (avatars, email-assets), mesmo public=true

select policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
order by policyname;
-- esperado: as mesmas 4 policies, MESMO texto de qual/with_check (todas
-- genéricas por auth.uid()/storage.foldername, sem literal de clube)
```
Estado esperado (capturado ao vivo do Goiás nesta auditoria, vira o "gabarito" de comparação):
```
buckets: avatars(public=true), email-assets(public=true)
policies: avatars_delete_own(DELETE), avatars_public_read(SELECT),
          avatars_update_own(UPDATE), avatars_write_own(INSERT)
```
Comparação exata = os 2 buckets + as 4 policies precisam bater byte a byte (nome, comando, `qual`) entre os dois projetos — qualquer diferença = baseline incompleto nessa parte, corrigir antes de considerar provado. Isso nunca é coberto por `db dump`/migration nenhuma hoje (achado do relatório 49) — só entra no baseline se for escrito à mão como statement explícito (`insert into storage.buckets`/`create policy on storage.objects`), testado com esta comparação.

## 5) Bragantino como staging descartável — confirmado, sem 3º projeto agora

Aceito: `yrgyzkaaudyzmsqwzecj` genuinamente vazio, sem usuário/dado real, serve como banco descartável da Fase 1. Regras não-negociáveis:
- **Goiás é SEMPRE read-only** nesta fase — todo comando que toca Goiás é `migration list`/`db diff --to`, nunca `db push`/`db reset` com `$GOIAS_DB_URL` como alvo de escrita.
- **Antes de qualquer operação, confirmar o alvo** — todo comando real (quando esta etapa for implementada) imprime clube + host/project ref resolvido ANTES de executar, nunca silencioso.
- **Se o baseline falhar no Bragantino, resetar e reconstruir** — sem custo, sem dado real em risco.
- Docker local (`supabase start`) continua como opção pra testes repetíveis/rápidos (sem gastar ciclo contra o projeto real), mas não é obrigatório pra começar — a Fase 1 pode ir direto: aplicar o baseline no Bragantino → comparar (item 2+4) → corrigir → reaplicar (reset se precisar) → repetir até bater.

## 6) Tooling futuro (desenho, não implementado)

Wrappers pretendidos — nenhum arquivo criado ainda:
```
tooling/multiclub/db-status.mjs <goias|bragantino>
tooling/multiclub/db-push.mjs   <goias|bragantino> [--dry-run]
```
Mapeamento interno (fonte única, não implementado):
```js
const CLUBS = {
  goias:      { workdir: 'infra/supabase/canonical', envVar: 'GOIAS_DB_URL' },
  bragantino: { workdir: 'infra/supabase/canonical', envVar: 'BRAGANTINO_DB_URL' },
};
```
Nota: `goias` só entra nesse mapa formalmente na FASE 2 (depois do cutover) — antes disso, "db:push goias" não deveria nem existir como comando válido (o histórico do Goiás continua sendo mexido do jeito de sempre, `supabase/migrations/` na raiz, sem passar por este wrapper).

Comportamento obrigatório de cada wrapper, antes de qualquer operação (inclusive `--dry-run`):
1. Resolver `club` do argumento (`goias`/`bragantino`) → `workdir` + nome da env var.
2. **Fail-loud se a env var estiver ausente** — nunca continuar com um valor vazio/default, nunca perguntar interativamente por uma URL (evita digitar credencial em texto claro no terminal/shell history).
3. Imprimir **claramente**: `clube=<nome> workdir=<caminho> host=<extraído da URL, sem senha>` — nunca a connection string inteira (a senha nunca aparece em stdout/log).
4. Só depois disso, rodar o comando `supabase` real com `--workdir`/`--db-url`.
5. Operação destrutiva (`db push` sem `--dry-run`, `db reset`) exige uma confirmação extra explícita no próprio wrapper (ex.: `--yes` obrigatório, nunca implícito) — mesmo princípio de fail-loud já usado no resto do projeto (`APP_CLUB`/`ENABLE_SYNTHETIC_CLUB` antes, `resolveActiveClub` hoje).

## O que NÃO muda desta revisão

Item 6 do relatório 49 (estratégia geral: `supabase/` intocado, `infra/supabase/canonical/` = baseline, Fase 1 = baseline+Bragantino, Fase 2 = cutover futuro do Goiás) continua de pé — esta rodada só corrige o MODELO DE COMANDO (workdir+db-url em vez de workdir+project-ref) e adiciona a prova dupla de Storage + o desenho de secrets/tooling. Nenhuma migration criada, nenhum diretório novo criado, nenhum comando de escrita executado.

---

**0 implementação. 0 db push. 0 migration repair. 0 mover migrations. 0 git push.**

PARE.
