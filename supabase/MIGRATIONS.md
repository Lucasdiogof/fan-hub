# Migrations do Supabase

A partir de 30/08/2026, toda alteração de schema/RPC/policy do banco vira um
arquivo em `supabase/migrations/`, nunca mais uma edição direta de um dos
scripts soltos em `supabase/*.sql`.

Os scripts soltos (`arena_ranking.sql`, `quiz_questions.sql`, etc.) continuam
existindo como referência histórica de como cada tabela nasceu — não foram
convertidos retroativamente em migrations (ver o marcador de baseline em
`supabase/migrations/20260830220000_baseline_marker.sql` pra entender por
quê). Isso significa que reconstruir um ambiente do zero exige dois passos:
primeiro os scripts soltos (na ordem que fizer sentido pras dependências
entre tabelas), depois as migrations em ordem cronológica.

## Pré-requisito

[Supabase CLI](https://supabase.com/docs/guides/cli/getting-started)
instalado localmente. Neste ambiente de desenvolvimento (onde estes arquivos
foram escritos) o CLI não está disponível — os arquivos de migration foram
escritos manualmente seguindo o formato oficial, mas nunca foram aplicados
via `supabase db push` de dentro daqui. Rode `supabase migration list`
antes de aplicar qualquer coisa em produção, pra conferir que o histórico
bate com o que o banco real já tem.

## Como criar uma migration

```bash
supabase migration new nome_da_mudanca
```

Isso cria `supabase/migrations/<timestamp>_nome_da_mudanca.sql` vazio.
Escreva o SQL da mudança ali dentro. Convenções:

- `create or replace function` em vez de `drop` + `create` sempre que
  possível — idempotente, seguro de rodar mais de uma vez.
- Novas tabelas: `create table if not exists`.
- Novas policies: `drop policy if exists "nome" on tabela;` antes de
  recriar, mesmo padrão que os scripts soltos já usam.
- Nunca `drop table`/`truncate` numa migration sem confirmar explicitamente
  com quem pediu a mudança — é destrutivo e não tem volta.

## Como aplicar em QA

```bash
supabase link --project-ref <ref-do-projeto-qa>
supabase db push
```

`db push` aplica só as migrations que ainda não rodaram naquele projeto
(controladas por uma tabela interna do próprio Supabase,
`supabase_migrations.schema_migrations`).

## Como validar

- `supabase migration list` — mostra quais migrations já rodaram no projeto
  linkado e quais estão pendentes localmente.
- Depois de aplicar, rode a suíte de smoke test relevante (por exemplo, o
  script de verificação SQL que valida o `arena_record_score` — ver o
  histórico do Lote 1) antes de considerar a migration "concluída".

## Como aplicar em PROD

Mesmo comando (`supabase db push`), mas depois de já ter validado em QA:

```bash
supabase link --project-ref yonozsdgyrhgqrvydbnr
supabase migration list   # confirma o que está pendente antes de aplicar
supabase db push
```

Nunca pule QA pra uma mudança de schema/RPC nova — só migrations já
validadas lá (como o marcador de baseline e o fix do `arena_record_score`,
que só re-registra algo que já está em produção) podem ir direto.

## Como verificar migrations pendentes

```bash
supabase migration list
```

Compara o que existe em `supabase/migrations/` localmente contra o que já
foi aplicado no projeto linkado — qualquer linha sem "Applied" ainda não
rodou lá.

## O que NÃO fazer

- **Nunca editar o banco direto pelo Dashboard/SQL Editor e seguir em
  frente sem versionar.** Se precisou colar SQL no editor pra resolver
  algo urgente, a próxima ação é criar a migration correspondente
  (idempotente, `create or replace`) descrevendo exatamente o que foi
  aplicado — mesmo que já esteja rodando, pra não se perder numa
  reconstrução do ambiente.
- Não editar um arquivo de migration já commitado/já aplicado em algum
  ambiente — crie uma nova migration corrigindo, nunca reescreva a
  história.
- Não misturar mudança de schema com dado de seed grande na mesma
  migration — mantém revert/replay mais simples.
