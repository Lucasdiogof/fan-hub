# M4 — Multi-Supabase: revisão do desenho (workdir canônico, 2 fases)

Data: 2026-09-04
Status: **AUDIT + DESIGN, revisão do relatório 48.** 0 implementação, 0 db push, 0 migration repair, 0 mover migrations, 0 git push.

**Correção de ponto crítico do relatório 48**: a recomendação anterior ("mover as 60 migrations do Goiás pra fora de `supabase/migrations/`, aceitar `migration list` remote-only como normal") está **retirada**. `supabase/` e `supabase/migrations/` do Goiás continuam **100% intocados** — nenhuma migration atual muda de lugar, nenhum histórico local/remoto diverge deliberadamente. Esta revisão substitui a seção 5/6 do relatório 48; o restante dele (classificação das 60 migrations, achados de `profiles`/Storage/Vault, Auth/CPF, Edge Functions, Flutter/Supabase por flavor) continua válido e não é repetido aqui.

## Prova do UUID (validado de novo, do zero)

```
namespace:              8c1f4e6a-2d9b-4a3c-9e7f-1b6d8a4c2f9e
string de entrada Goiás: "goias-app:multiclub:club:1"
helper:                  uuidV5() em tooling/multiclub/person_registry.mjs (SHA-1, RFC4122 v5 padrão)

uuidV5(namespace, "goias-app:multiclub:club:1")
  = 4c16340d-300c-5ab2-903f-17519db9b146

valor REAL armazenado em clubs.id (Goiás), ao vivo:
  = 4c16340d-300c-5ab2-903f-17519db9b146

MATCH: true — o mesmo algoritmo, com a mesma entrada, reproduz EXATAMENTE
o UUID real do Goiás. Não é coincidência nem aproximação — é o método
determinístico funcionando como documentado.
```
Só **depois** dessa prova considero o preview do Bragantino válido:
```
string de entrada Bragantino: "goias-app:multiclub:club:2"
uuidV5(namespace, "goias-app:multiclub:club:2")
  = 51683d2a-ea1d-57c6-8014-996146f242e7   (preview — nada gravado)
```
`tooling/multiclub/clubs_registry.json` reconfirmado sem mudança (`nextSequence: 2`, só a entrada do Goiás) — o preview continua válido até que outra sessão rode o gerador de verdade.

## Auditoria de limitações do `migration squash` / `db dump` (por que não é a solução final)

Confirmado via `--help` do CLI + auditoria dos arquivos reais deste projeto:

- **`migration squash`** não faz introspecção nova do banco remoto — ele REPLICA os arquivos locais de `supabase/migrations/` contra um shadow database (precisa de Docker/`supabase start`) e despeja o resultado. Ou seja: herda os MESMOS 60 arquivos, na MESMA ordem, com as MESMAS 10 migrations de transição single→multi-tenant — só compacta em 1 arquivo, não remove nada Goiás-específico automaticamente. Não resolve o problema de fundo.
- **DML**: `db dump` sem `--data-only` é schema-only por padrão — bom, não traz dado. Mas `migration squash` reconstrói o schema RODANDO as migrations (que incluem `INSERT`/`DO $$` de dado real) — o dado é executado no shadow db mesmo que não apareça no arquivo final squashado. Precisa validar isso explicitamente antes de confiar (não assumido aqui).
- **Cron (`pg_cron`)**: já é gerenciado FORA de `supabase/migrations/` neste projeto — `supabase/notifications_cron.sql`/`supabase/cleanup_unconfirmed_signups_cron.sql` são scripts soltos, o primeiro já um TEMPLATE reusável (`<SEU_PROJECT_REF>`), o segundo hardcoda o ref do Goiás. Nenhum dos dois seria capturado por `db dump --schema public` (schema `cron` é extensão, fora de `public`) nem por `migration squash` (não são migrations). **Ficam de fora do baseline canônico por design** — são passo manual documentado, não SQL replicável.
- **Storage**: **achado novo desta rodada** — 2 buckets reais existem ao vivo no Goiás (`avatars`, `email-assets`, ambos `public=true`) + 4 RLS policies em `storage.objects` (`avatars_delete_own`/`avatars_public_read`/`avatars_update_own`/`avatars_write_own`, todas genéricas por `auth.uid()`/`storage.foldername`, sem nada do Goiás) — **nenhum dos dois está em migration nenhuma**, mesma classe de gap que `profiles`. `db dump --schema public` não captura bucket nem policy de `storage.objects` (schema `storage`, não `public`) — precisa de introspecção própria + `--schema storage` explícito no dump, ou statements manuais.
- **Vault**: usado de verdade neste projeto — `vault.create_secret`/`vault.decrypted_secrets` em `supabase/notifications_cron.sql` (guarda a service_role key como secret, nunca em texto plano no cron job) e leitura em `supabase/signup_audit_introspection.sql`. Já corretamente fora de `supabase/migrations/` (mesmo motivo do cron — secret nunca deveria estar num arquivo versionado). Fica de fora do baseline, é passo manual por projeto.
- **Objetos fora de `public`**: a trigger `on_auth_user_created` está em `auth.users` (schema `auth`, gerenciado pela Supabase) — a FUNÇÃO `handle_new_user()` vive em `public` (capturável), mas o `CREATE TRIGGER ... ON auth.users` em si pertence à tabela `auth.users`. **Não tenho confirmação de que `db dump --schema public` captura essa trigger** (pg_dump tipicamente associa a trigger à tabela dona, que está fora do schema incluído) — **presumir que fica de fora até testar**, e escrever esse `CREATE TRIGGER` à mão no baseline (já tenho a definição exata capturada ao vivo, ver relatório 48 §3).
- **Auth-related config** (fora de SQL inteiramente): templates de e-mail, allowlist de redirect URL, tempo de expiração de OTP, provedores habilitados — isso vive na config gerenciada da Supabase (dashboard/Management API), nunca em `pg_dump`/migration nenhuma. **Não faz parte do baseline SQL** — precisa de um checklist manual de configuração de projeto, documentado separadamente (fora do escopo desta auditoria, mas registrado como pendência real pro dia de inicializar o Bragantino de verdade).

**Conclusão**: o baseline não pode ser "rodar 1 comando e confiar". É uma composição consciente de 4 fontes: (1) `db dump --schema public` (schema/RLS/RPC/índices/constraints de `public`, revisado à mão), (2) introspecção manual de `profiles`/`user_addresses`/`handle_new_user` (já capturada, relatório 48 §3), (3) introspecção manual de Storage (buckets + policies, capturada acima), (4) checklist manual de config de Auth (não-SQL, documentado à parte) + Vault/cron (scripts template já existentes, reaplicados por projeto, nunca dentro do baseline SQL).

## FASE 1 — Workdir canônico independente

### 1) Estrutura de diretórios proposta
```
goias-app/                              (raiz do repo, Fan Hub)
├── supabase/                           (INTOCADO — projeto/histórico Goiás)
│   ├── config.toml                     (project_id = yonozsdgyrhgqrvydbnr)
│   └── migrations/                     (as 60 atuais, para sempre, sem mover)
├── infra/
│   └── supabase/
│       └── canonical/
│           └── supabase/
│               ├── config.toml         (NOVO — project_id inicialmente vazio/placeholder; workdir nunca fica linkado por padrão a nenhum projeto real)
│               └── migrations/
│                   └── <timestamp>_canonical_baseline.sql   (o baseline sendo construído/provado)
└── ...
```
`infra/supabase/canonical/` fica FORA de `supabase/` de propósito — impossível confundir com o workdir padrão só olhando o caminho, e nenhum comando sem `--workdir` explícito jamais o atinge por engano.

### 2) Como usar `--workdir`
Confirmado no `--help`: `--workdir` é uma GLOBAL FLAG, aceita por `migration list`/`db push`/`db dump`/`db diff`/etc. Uso:
```bash
npx supabase migration list --workdir infra/supabase/canonical --project-ref <ref>
npx supabase db push --workdir infra/supabase/canonical --project-ref <ref> --dry-run
```
Sem `--workdir`, todo comando continua olhando pra `supabase/` da raiz (o Goiás) — comportamento de hoje, zero mudança.

### 3) Como linkar/selecionar Goiás vs Bragantino sem engano
Dois eixos INDEPENDENTES, nunca confundidos:
- **Qual conjunto de migrations** (`--workdir`): raiz = histórico Goiás (60 arquivos) · `infra/supabase/canonical` = baseline canônico (1 arquivo, crescendo).
- **Qual projeto remoto** (`--project-ref`): `yonozsdgyrhgqrvydbnr` = Goiás · `yrgyzkaaudyzmsqwzecj` = Bragantino.

Combinações válidas e o que cada uma significa:
| workdir | project-ref | Significado |
|---|---|---|
| raiz (padrão) | Goiás | Uso normal de hoje, sem mudança |
| raiz (padrão) | Bragantino | **NUNCA fazer** — aplicaria as 60 migrations Goiás-specific no Bragantino |
| canonical | Bragantino | Uso pretendido — aplica só o baseline genérico |
| canonical | Goiás | Só leitura/`db diff` nesta fase (comparação, nunca `db push`) — é assim que provo equivalência sem tocar o Goiás |

Nenhum `supabase link` persistente em lugar nenhum — sempre `--project-ref` explícito por comando, nos dois workdirs. Isso por si só já é uma proteção: esquecer o `--project-ref` faz o comando falhar pedindo link, nunca aplica no projeto errado por padrão.

### 4) Como uma migration futura compartilhada entraria nos dois projetos
Uma vez que o baseline estiver provado e aplicado no Bragantino (fim da Fase 1), toda migration NOVA e genérica nasce em `infra/supabase/canonical/supabase/migrations/` (nunca na raiz) e é aplicada assim:
```bash
npx supabase db push --workdir infra/supabase/canonical --project-ref yrgyzkaaudyzmsqwzecj
# e, só depois do cutover formal da Fase 2 (não agora):
npx supabase db push --workdir infra/supabase/canonical --project-ref yonozsdgyrhgqrvydbnr
```
Antes do cutover da Fase 2, uma migration genérica nova precisaria, na prática, ser escrita DUAS vezes (uma vez pro histórico Goiás em `supabase/migrations/`, outra pro baseline canônico em `infra/supabase/canonical/`) — essa é exatamente a duplicação manual que a Fase 2 existe pra eliminar. Registrado como custo real da Fase 1 sozinha, não escondido.

### 5) Como impedir uma migration Goiás-only de entrar na cadeia canônica
Disciplina estrutural, não automática: `infra/supabase/canonical/supabase/migrations/` só recebe arquivo que passe nos MESMOS critérios usados na classificação do relatório 48 (SCHEMA_GENERIC/SECURITY_GENERIC/RPC_GENERIC/CANONICAL_FOR_NEW_CLUB — nunca GOIAS_DATA/GOIAS_SEED/GOIAS_DEFAULT/UNSAFE_FOR_NEW_CLUB). Reforçável depois (não nesta rodada) por uma checagem de tooling que reprova qualquer arquivo novo em `infra/supabase/canonical/` contendo literais como `'goias'`/UUID do Goiás/`DEFAULT` de club_id — mesmo padrão de `noSyntheticResidue` já usado pra `clubb`/`club-b` no pipeline de flavor.

### 6) Como testar o baseline contra um banco vazio
Duas opções reais, nenhuma aplicada ainda — decisão seguinte fica com você:
- **(a) `supabase start` local (Docker)** — único jeito de ter um Postgres genuinamente descartável sem criar/gastar outro projeto Supabase. Contraria a convenção atual do projeto (`config.toml`: "Nao usamos supabase start... propositalmente omitidas"), mas seria uma exceção ESCOPADA só pra validar o baseline, nunca pro fluxo normal do dia a dia.
- **(b) Um 3º projeto Supabase genuinamente descartável** (criado só pra este teste, deletado depois) — mantém a convenção "sem Docker" do projeto, mas depende de você criar/deletar um projeto manualmente (mesma limitação de dashboard já vista com o Cloudflare do Bragantino).
- **Depois** de validar num desses dois: aplicar o mesmo baseline no Bragantino de verdade (`--workdir canonical --project-ref yrgyzkaaudyzmsqwzecj`) — que hoje está vazio, então serve como o "banco real, mas ainda sem custo de dado" que você pediu como 2º estágio.

### 7) Como comparar baseline vs schema live do Goiás
`supabase db diff` suporta `--from`/`--to` apontando pra `local`/`linked`/`migrations`/uma URL Postgres direta — inclusive comparando DOIS bancos remotos diretamente, sem shadow database no meio, quando ambos os lados já são "live" (ex.: Bragantino recém-aplicado vs Goiás). Comando-tipo (não rodado):
```bash
npx supabase db diff --project-ref yrgyzkaaudyzmsqwzecj --linked \
  --to "postgresql://...<conexão Goiás>..." \
  --schema public,storage \
  -o baseline_vs_goias_diff.sql
```
Resultado esperado: diff vazio (ou só diferenças EXPLICITAMENTE esperadas — ex.: a linha de `clubs`, que nunca deveria ser igual). Qualquer outra diferença = baseline incompleto, corrigir antes de considerar provado. `--schema public,storage` cobre os 2 gaps achados nesta rodada (RLS/tabelas genéricas + buckets/policies de Storage) numa passada só.

## FASE 2 — Cutover futuro (só design, não avaliar como pronto agora)

Só depois do baseline **provado** (Fase 1 completa, diff vazio contra o Goiás, aplicado com sucesso no Bragantino):
1. Avaliar (sessão própria, autorização própria) se faz sentido o Goiás migrar pra a MESMA cadeia (`canonical_baseline` + `future_migration_00N`...).
2. Se sim: como o schema do Goiás JÁ seria equivalente ao baseline (por definição — foi provado igual na Fase 1), o `migration repair` necessário seria **só de metadata** (marcar o baseline como "applied" na tabela de tracking do Goiás sem rodar o SQL de novo — o schema já está lá) — nunca execução real.
3. As 60 migrations atuais viram `docs/`/`archive/`/git history **só neste momento**, formalmente, com o schema já provado equivalente — nunca antes disso, nunca como parte da Fase 1.

### 9) Rollback se a validação falhar
- **Banco descartável (item 6a/6b)**: descartar/deletar — zero impacto, era descartável por design.
- **Bragantino** (ainda vazio, sem usuário real): se o baseline aplicado não bater no diff, `db reset`/dropar os objetos criados e corrigir o baseline antes de tentar de novo — Bragantino não tem nada de valor ainda, seguro reiniciar quantas vezes precisar.
- **Goiás**: nunca em risco na Fase 1 (só leitura via `db diff`, nunca `db push`). Na Fase 2 (futuro, hipotético): se o `migration repair` de metadata for aplicado e algo destoar, reverter é rodar `migration repair --status reverted <versões>` de volta ao estado anterior — só é seguro fazer isso se o estado ANTERIOR da tabela `supabase_migrations.schema_migrations` do Goiás for registrado/exportado antes de qualquer `repair`, nunca de memória. Não é preciso desenhar isso em detalhe agora — só registrar que existe um caminho de volta, e que ele depende de um backup de metadata prévio.

## Comparação revisada das 4 opções, com os 8 critérios pedidos

| Critério | A) 60-pra-sempre + baseline próprio por clube | B) Baseline+workdir agora, cutover Goiás depois (RECOMENDADA) | C) Workdir separado por clube pra sempre | D) — |
|---|---|---|---|---|
| 1. `db push` previsível | ✅ | ✅ (workdir+project-ref explícitos, nunca ambíguo) | ✅ | — |
| 2. Sem remote-only como normal | ✅ (Goiás nunca muda) | ✅ (Goiás nunca muda na Fase 1; Fase 2 só depois de provado) | ✅ | — |
| 3. `db reset` local reproduzível | ⚠️ (cada clube com baseline diferente, testar cada um separado) | ✅ (1 baseline, testável 1 vez, reaplicado igual em todos) | ⚠️ (mesmo problema de A) | — |
| 4. N clubes | ✅ | ✅ | ✅ | — |
| 5. Migration genérica futura em todos | ⚠️ manual, por clube | ✅ (1 arquivo, aplicado via `--workdir canonical --project-ref <cada>`) | ⚠️ manual, por clube | — |
| 6. Evita duplicação manual de SQL | ❌ (cada clube com sua história própria pra sempre) | ⚠️ Fase 1 sozinha ainda duplica (Goiás continua na história antiga); ✅ só depois do cutover da Fase 2 | ❌ (pior — workdirs nunca convergem) | — |
| 7. Histórico legado auditável | ✅ | ✅ (nunca movido, git history + as 60 migrations continuam no lugar) | ✅ | — |
| 8. Sem replay das 60 no Bragantino | ✅ | ✅ (baseline é composição consciente, nunca replay) | ✅ | — |

**B continua a recomendação**, mas agora sem o erro do relatório 48: nada no Goiás muda na Fase 1, a convergência de histórico (item 6, marcada ⚠️ até lá) só acontece formalmente na Fase 2, com prova prévia, autorização própria, e plano de rollback via metadata backup. C foi reavaliada e descartada de novo — nunca converge, herda o pior de A com a complexidade extra de N workdirs permanentes.

---

**0 implementação. 0 db push. 0 migration repair. 0 mover migrations. 0 git push.** `infra/supabase/canonical/` ainda não criado — só desenhado. `supabase/`/`supabase/migrations/` do Goiás inteiramente intocados.

PARE.
