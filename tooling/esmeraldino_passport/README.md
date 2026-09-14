# Passaporte Esmeraldino

Feature de presença autodeclarada em partidas históricas do Goiás
(2000–2026) + ranking próprio. Este documento cobre a carga histórica, a
sincronização de partidas recentes (hoje **não ativa**, ver seção
"Bloqueio real" abaixo) e como validar tudo depois de rodar.

## 1. Fonte dos dados

`source/esmeraldino_passport_matches_2000_2026.json` — fornecido pelo
usuário, nunca gerado por scraping deste app. Schema `1.0.0`, 1.697
partidas (1.696 `FINISHED` + 1 `SCHEDULED` na data de corte).

SHA-256 esperado:
```
a6fac753504bfe90e04f053851aa2a1466afae45f475a258f2db3620cb82f46b
```

O CSV/XLSX de auditoria e o PDF de catálogo (fornecidos junto) são só pra
conferência humana — nunca importados por nenhum script deste repositório.

## 2. Rodando a carga histórica

Ordem de execução no **SQL Editor do Supabase**:

1. `supabase/passport_esmeraldino.sql` — cria as tabelas (`venues`,
   `passport_matches`, `passport_attendances`, `passport_sync_runs`), RLS e
   índices.
2. `supabase/passport_esmeraldino_import.sql` — insere/atualiza as 1.697
   partidas. **Gerado**, não editar à mão — ver seção 3.
3. `supabase/passport_esmeraldino_functions.sql` — cria as RPCs que o
   Flutter chama.

O import é transacional (uma única instrução `insert ... on conflict do
update`) e devolve, na própria saída da query, o relatório final:

| inseridos | atualizados | sem_mudanca | erros |
|---|---|---|---|
| ... | ... | ... | 0 |

Idempotente: rodar de novo nunca duplica partida nem apaga presença de
usuário (`passport_attendances` referencia `passport_matches.id`, que
nunca muda numa reimportação; o `on conflict` só atualiza colunas que
vieram diferentes, nunca deleta a linha).

Depois, rode `supabase/checkup.sql` pra confirmar: deve aparecer só a
seção RESUMO com `passport_matches = 1697`, nenhuma linha de `❌`.

## 3. Regerando o SQL de importação

Se o JSON de origem mudar (nova versão, mais partidas), regenere o SQL:

```bash
python tooling/esmeraldino_passport/generate_import_sql.py
```

O script valida, nesta ordem, antes de escrever qualquer arquivo:
checksum SHA-256, `schema_version`, contagem exata de registros esperada
(hoje 1.697), IDs únicos, campos obrigatórios presentes em todo registro.
Qualquer falha aborta sem gerar nada. A saída (`supabase/passport_esmeraldino_import.sql`)
é sempre um único `INSERT` em lote — nunca uma instrução por partida.

## 4. RPCs (Supabase)

Não existe API REST própria pra isso — mesmo padrão já usado no
`arena_ranking.sql`: funções Postgres `security definer`, `auth.uid()`
resolvido no servidor, nunca recebido como parâmetro do cliente.

| RPC | Uso |
|---|---|
| `passport_seasons()` | Lista de temporadas + contagem, pro seletor de ano |
| `passport_matches_for_year(p_season)` | Partidas de um ano + presença do usuário atual |
| `passport_summary()` | Total, anos com presença, primeira/última partida marcada |
| `passport_save_attendances(p_changes jsonb)` | Salva o lote — só `FINISHED`, nunca partida futura, nunca de outro usuário |
| `passport_ranking(p_year, p_limit)` | Ranking (geral ou por ano) |
| `passport_my_rank(p_year)` | Posição do usuário atual |

`passport_attendances` não tem policy de insert/update pro cliente — só a
RPC `passport_save_attendances` escreve ali, porque as regras (partida
`FINISHED`, nunca data futura) precisam valer no servidor mesmo que o
Flutter tente mandar qualquer coisa.

## 5. Sincronização de partidas recentes — BLOQUEIO REAL, não implementada

O pedido original pede um sincronizador diário (partidas dos últimos 14
dias / próximos 30 dias) rodando via Cloudflare Cron Trigger, atualizando
`passport_matches` sem nunca sobrescrever um campo preenchido com `null`.

**Isso não foi implementado porque não existe hoje, neste projeto, uma
fonte de dados verificada com cobertura pras competições que o Goiás
disputa historicamente** (Campeonato Goiano, Brasileirão A/B, Copa do
Brasil, Copa Verde, Sul-Americana, Libertadores). O Worker deste repo
(`src/football/`) só cobre **uma competição por vez**, via um slug fixo
do OneFootball (`ONEFOOTBALL_COMPETITION_SLUG` em `wrangler.toml`) — hoje
Brasileirão Série B. Isso resolve o "próximo jogo"/"últimos resultados"
mostrados no Início, mas não cobre o catálogo multi-competição que o
Passaporte precisa.

**O que existe pronto pra quando houver um provider real:**
- `passport_sync_runs` — tabela de log de execução (provider, contagens,
  status, `metadata` jsonb), já criada em `passport_esmeraldino.sql`.
- O Worker já tem um Cron Trigger configurado (`wrangler.toml`,
  `[triggers] crons = [...]`) e um handler `scheduled()` em `src/index.ts`
  — um novo branch de sincronização entraria ali, no mesmo padrão que já
  existe pra sync do Instagram (`src/social/instagram_sync.ts`): busca a
  fonte externa, nunca sobrescreve dado já preenchido com `null` em caso
  de falha parcial, grava resultado, e expõe um trigger manual admin
  protegido por chave compartilhada (`x-sync-key`).

**O que falta, de verdade, antes de ativar:**
1. Escolher e validar um provider com cobertura confirmada pra TODAS as
   competições listadas acima — não só a atual.
2. Adicionar a variável de ambiente/secret correspondente via
   `wrangler secret put NOME_DA_VARIAVEL` (nunca hardcoded no código).
3. Escrever o módulo de sincronização de verdade (`MatchProvider` /
   `RemoteRecentMatchesProvider` / `MatchSyncService`, conforme pedido),
   testado contra a cobertura real do provider escolhido.
4. Registrar cada execução em `passport_sync_runs`.

Até lá, a tabela `passport_matches` só se atualiza reimportando o JSON
manualmente (seção 2–3) — o que é suficiente pro catálogo histórico, mas
não pega o resultado de uma partida de ontem automaticamente.

## 6. Verificação

- `supabase/checkup.sql` — validações de integridade (id duplicado,
  `FINISHED` sem placar, `SCHEDULED` no passado, presença em partida não
  encerrada, `user_id`+`match_id` duplicado) + contagens de RESUMO.
- `flutter analyze lib` — sem warnings novos.
- `flutter test test/features/passport/` — lógica de delta/toggle/save do
  Cubit principal.
