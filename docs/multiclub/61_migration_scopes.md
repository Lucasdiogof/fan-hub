# 61 — Escopo de migrations por clube (A2)

Status: **implementado no tooling; NÃO validado contra os históricos reais dos três bancos.**
Nada foi aplicado em banco real nesta etapa.

## O problema

Todos os clubes compartilham a pasta `supabase/migrations/`. Onze migrations de
dados (`20260930010000` … `20261002030000`) só fazem sentido no Goiás (UUIDs de
jogadores/jogos do Goiás, guardas `raise exception` ou comparações com `NULL`).
Um `db push` apontado para Bragantino ou Vila Nova as enviaria junto: aborto no
meio do push (guarda com `raise`) ou no-op silencioso, ambos deixando o histórico
do clube divergente.

## Duas dimensões independentes

| Dimensão | O que é | Onde vive |
|---|---|---|
| **Escopo funcional** | A que clube(s) uma migration pertence | `supabase/migration_scopes.json` |
| **Destino Supabase** | Qual projeto (project ref) recebe | `tooling/multiclub/supabase_projects_registry.json` + env var `<CLUBE>_DB_URL` |

E uma terceira, **só informativa**: a conta Supabase (`accountLabel`).

Topologia atual:

- Conta A: Goiás + Bragantino (dois projetos distintos, escopos distintos)
- Conta B: Vila Nova

Mesma conta **não** significa mesmo escopo, e escopo **não** depende da conta.
`accountLabel` nunca entra na decisão (há teste que garante que o código de
escopo/push não o referencia).

## Fluxo (fail closed)

```
clube -> registry -> project ref -> env var <CLUBE>_DB_URL (ref validado)
      -> manifesto (integridade 1:1 + SHA) -> migrations permitidas ao clube
      -> workdir temporário (fora do repo) só com elas -> supabase db push --db-url -> banco
```

**Nunca** usar "a conta atualmente autenticada" (ou o projeto linkado em
`supabase/.temp`) como indicador de destino. O tooling usa `--db-url`, que não
depende de `supabase login`.

## Manifesto `supabase/migration_scopes.json`

Entrada por migration: `version`, `file`, `scope` (lista), `sha256`, `note`.

- `scope`: `["global"]` (exclusivo; vai para todos) ou lista de clubes do registry
  (`goias`, `bragantino`, `vilanova`). `global` combinado com clube é rejeitado.
- Cobertura 1:1 com `supabase/migrations/`: arquivo sem entrada, entrada sem
  arquivo, versão/arquivo duplicado, campo desconhecido, scope desconhecido ou
  SHA divergente → o tooling inteiro aborta.
- SHA-256 normalizado (CRLF→LF, por causa de `core.autocrlf` no Windows).
- **Aviso:** o hash prova apenas que o arquivo não mudou desde a criação do
  manifesto. **Não** prova que esses bytes foram os aplicados historicamente em
  bancos existentes.

Nova migration = nova entrada no manifesto (`node tooling/multiclub/migration_scope.mjs sha <arquivo>` ajuda a obter o hash). Sem entrada, nada roda.

## Ferramentas

- `db-push.mjs <clube> --dry-run`: plano local. Mostra clube, project ref,
  incluídas/excluídas, workdir que seria criado e comando lógico (credencial
  redigida). Não conecta, não cria workdir, não chama o CLI. Ainda exige a env
  var do clube (valida o destino).
- `db-push.mjs <clube> --dry-run --remote`: além disso, `supabase db push --dry-run` (lê o histórico remoto).
- `db-push.mjs <clube> --yes`: escrita real. O workdir temporário é removido mesmo se o CLI falhar.
- `db-status.mjs <clube> [--plan]`: mesma visão; `migration list` somente leitura.
- `run-sql-file.mjs`: se o arquivo é migration (está em `supabase/migrations/` **ou** tem o SHA normalizado de uma entrada do manifesto), valida o escopo e recusa **antes** de resolver alvo/conectar. Atenção: rodar migration por aqui **não registra** o histórico do Supabase. Manifesto inválido bloqueia até SQL solto (fail closed).
- `passport_security/run_authenticated_idor_test.mjs --club <clube>`: `--club` obrigatório; `SUPABASE_URL` é validada contra o registry **antes** de qualquer chamada (nenhuma conta QA é criada se divergir).
- `migration_scope.mjs check | plan <clube> | sha <arquivo>`.

Testes: `node tooling/multiclub/test_migration_scope.mjs` (sem banco real).

## Classificação atual

- Globais (8): `20260904000000`, `20260904210000`, `20260908000000`, `20260909000000`, `20260909120000`, `20260911000000`, `20260915000000`, `20261002040000` (hardening do passaporte).
- Só Goiás (11): `20260930010000` … `20260930050000`, `20261001010000` … `20261001030000`, `20261002010000` … `20261002030000`.

## Dívida separada (não corrigida aqui)

`20260909000000` (`arena_record_score` legado) insere em `score_events` sem
`club_id`, coluna `NOT NULL`. O escopo dela está correto (global); o bug de
função é outro assunto e deve ser tratado em migration nova (nunca editando a
histórica).

## Limitações restantes

1. **Históricos reais não reconciliados.** Falta comparar o manifesto com
   `supabase_migrations.schema_migrations` dos três bancos (`db-status`).
   Enquanto isso, A2 **não** está resolvido em produção.
2. O manifesto é a fonte de verdade humana: classificar errado uma migration
   nova continua sendo possível (o tooling só garante que *existe* classificação).
3. `supabase db push` direto (fora destes scripts) ainda vê tudo; a proteção
   depende de usar o wrapper. CI deve chamar apenas `db-push.mjs`.
4. Ctrl-C durante o push pode deixar o diretório temporário (só cópias de SQL).
5. Migrations globais futuras com dado específico de clube precisam de guarda própria.

## CI (desenho)

Um job por clube, com secrets separados (`GOIAS_DB_URL`, `BRAGANTINO_DB_URL`,
`VILANOVA_DB_URL`); cada job chama `db-push.mjs <clube> --dry-run` e só então
`--yes` em ambiente protegido. Nenhum job recebe a credencial de outro clube.
