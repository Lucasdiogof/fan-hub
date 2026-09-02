# 22 — Etapa F4: migrar `squad_members` (Elenco) para `person_id`

> Migração PARALELA de identidade — nada removido, nada aplicado no Supabase, nada commitado. **PARE — aguardando revisão.**

## 1. Runtime real de `squad_members`

- **Fonte da verdade**: tabela real `public.squad_members` no Supabase, lida por `SupabaseSquadRepository.getSquad()` ([supabase_squad_repository.dart](goias-app/lib/features/squad/data/supabase_squad_repository.dart)) via `.from('squad_members').select().order('sort_order')` — nota: `.select()` **sem lista de colunas** (`select *`), diferente de `career_players`/`guess_players` que listavam colunas explicitamente.
- **Fallback**: **NÃO EXISTE.** Diferente de F1/F3, não há `const squadMembers`/catálogo local — em caso de falha, o repository devolve `Error(ServerFailure(...))` (`Result<List<SquadMember>>`), a tela mostra erro, sem elenco offline. Confirmado lendo o repository inteiro.
- **Seed histórico**: `supabase/squad_members.sql` + `squad_members_seed.sql` + `squad_members_position_groups.sql` + `squad_members_instagram.sql` — mesmo padrão pré-F1 do `career_players.sql`: scripts "rode no SQL Editor", **nenhum em `supabase/migrations/`**, nunca aplicados via migration tracked.
- **Feature/tela**: "Elenco" — `squad_list_page.dart` + `squad_member_detail_page.dart` + `squad_cubit.dart` (bem simples, sem lógica de identidade por nome, confirmado por leitura completa).

## 2. Todos os consumidores mapeados

| Consumidor | Usa `squad_members` (Supabase) diretamente? | Nota |
|---|---|---|
| Elenco (`squad_list_page.dart`, `squad_member_detail_page.dart`) | **SIM** | Consumidor real e único da tabela |
| Escalação da Torcida (`crowd_lineup`) | **NÃO** | Tem seu PRÓPRIO roster hardcoded (`goiasSquad`, `lib/features/crowd_lineup/domain/goias_squad.dart`) — mesmo id-space por convenção, mas **sem FK/leitura de `squad_members`** — ver item 14 |
| Fotos (`squadAvatar`, `squad_list_page.dart`) | Indireto | Resolve foto via `squadPhotoAssets[member.id]` (asset local, keyed por slug) — `squad_members.photo_url` (coluna real) está **NULL hoje** (confirmado ao vivo pro Tadeu) — ver item 15 |
| "Quem Vestiu o Manto" (`guess_players`) | **NÃO**, mas **compartilha o mesmo id-space de foto** | `squadPhotoAssets` é usado tanto pelo Elenco quanto por `guess_player_repository.dart` (via `photo_key`) — mesma chave (slug), sem leitura cruzada de tabela |
| Perfil/formações/outras features Arena | **NÃO** | Nenhuma outra referência a `squad_members`/`SquadMember` encontrada no código |
| Autocomplete (`goias_players.dart`, `career_path_page.dart`) | **NÃO** | `goias_players.dart` só é referenciado por `career_path_page.dart` — ver item 19 |

## 3. Estrutura real (colunas ao vivo)

`id text PK`, `name text not null`, `full_name text`, `shirt_number int`, `position text not null` (label PT-BR, ex. "Goleiro"), `position_group text not null` (ex. "Goleiros"), `birth_date date`, `nationality text`, `height_cm int`, `foot text`, `photo_url text` (nullable, **sempre NULL na prática hoje**), `instagram_url text`, `club_history jsonb not null`, `sort_order int not null`, `updated_at`. **Sem `is_active`** (diferente de career_players/guess_players) e **sem coluna `positions` plural** (só `position` singular + `position_group`).

| squad_members atual | equivalente canônico | migrar F4? |
|---|---|---|
| identidade (`id`+`name`+`full_name`) | `people` | **SIM** |
| `position`/`position_group` (label PT-BR único) | `player_positions` (1-3 códigos por pessoa) | NÃO — squad_members só guarda a PRIMÁRIA, nunca as secundárias (ver item 16) |
| `club_history` | `player_club_spells` | NÃO — `club_history` cobre a carreira INTEIRA (todos os clubes), `player_club_spells` só modela passagens pelo Goiás — mesma ressalva de F1/F3 |
| `appearances`/`goals` (dentro de `club_history`) | `player_club_stats` | NÃO |
| `shirt_number`/`photo_url`/`instagram_url` | contexto atual/editorial/asset | NÃO aplicável |

## 4. Quantidade Supabase/fallback/export

| | Valor |
|---|---|
| Linhas no Supabase (ao vivo) | **31** |
| Linhas no fallback | **N/A — não existe fallback** |
| Linhas no export | **31** (`data_export/goias/squad_members.json`) |

## 5-8. RESOLVED / AMBIGUOUS / UNRESOLVED / OUT_OF_SCOPE

Reconciliação **já existia** — os 31 `squad_members` já são `member`s de `canonical_people_candidates.json`. Não construí reconciliação nova.

| Status | Contagem |
|---|---|
| **RESOLVED** | **31** |
| **AMBIGUOUS** | 0 |
| **UNRESOLVED** | 0 |
| **OUT_OF_SCOPE** | 0 (categoria mantida pra formato consistente com F1/F3, mas `squad_members` não tem `is_active` — nunca populada aqui, documentado, não esquecido) |

**O elenco atual é 100% já aprovado na fundação canônica** — resultado honesto, não forçado (o script teria reportado qualquer UNRESOLVED se existisse).

## 9. Mapping completo

`data_export/goias/player_reconciliation/squad_members_person_mapping.json` (31 entradas) + `squad_members_person_mapping_stats.json`. Gerado por `tooling/multiclub/build_squad_members_person_mapping.mjs`, reprodutível byte-a-byte.

## 10. Casos sensíveis

| `squad_members.id` | `canonicalName` | Confirmado |
|---|---|---|
| `tadeu` | Tadeu Antônio Ferreira | ✅ |
| `nicolas` | **Nicolas Vichiatto da Silva** | ✅ nunca Nicolas Godinho Johann |
| `danilo` | **Danilo Cunha da Silva** | ✅ nunca Danilo Gabriel de Andrade |
| `djalma` | Djalma Antônio da Silva Filho | ✅ |
| `rodrigo_soares` | Rodrigo Alves Soares | ✅ |
| `lourenco` | João Paulo Ferreira Lourenço | ✅ |
| `lucas_rodrigues` | Lucas Rodrigues Moreira Costa | ✅ |
| `luiz_felipe` | Luiz Felipe do Nascimento dos Santos | ✅ |
| `murilo_camara` | **Murilo Camara Saquetti Chimelo Pereira** | ✅ pessoa DIFERENTE de Murillo Victorio |
| `murillo_victorio` | **Murillo Carvalho Victorio** | ✅ pessoa DIFERENTE de Murilo Câmara — normalização ortográfica não os mistura (UUIDs distintos, testado) |
| `dieguinho` | — | **Não existe no elenco atual** — confirmado por ausência (Jackson Diego Ibraim Fagundes não está entre os 31 titulares/reservas hoje) |

## 11. Cardinalidade — auditada nos 2 sentidos

1. **Direto**: 0 `person_id` reusado entre as 31 linhas RESOLVED.
2. **Reverso**: 0 pessoas canônicas com 2+ `members` de `source='squad_members'`.
3. **Evidência estrutural**: 31 nomes completos distintos (0 duplicata) — elenco atual, 1 linha por atleta, sem edições/temporadas duplicadas.

## 12. Decisão sobre `UNIQUE`

**Adicionada**, com a auditoria acima documentada na própria migration. Se qualquer uma das 2 checagens de cardinalidade tivesse dado positivo, o gerador **aborta automaticamente** (mesma trava de F3).

## 13. Mudanças Flutter (feitas)

- `SquadMember` ganhou `final String? personId` ([squad_member.dart](goias-app/lib/features/squad/domain/squad_member.dart)) — nullable.
- `SquadMember.fromJson()` agora lê `json['person_id']`.
- **Repository NÃO precisou de mudança** — `.select()` (sem lista de colunas) já traz todas as colunas, incluindo `person_id` quando existir; até a migration ser aplicada, a chave simplesmente não existe no map e `fromJson` resolve `null` sem erro (diferente de F1/F3, que usavam `.select('col1, col2, ...')` explícito e por isso quebrariam com 400 antes da migration).
- **Nenhum fallback pra atualizar** (não existe).
- Nenhuma UI, ordem, foto, posição exibida, navegação ou gameplay alterada.

## 14. Escalação da Torcida (`crowd_lineup`)

Auditado explicitamente, conforme pedido — **`crowd_lineup` NÃO lê `squad_members` do Supabase**. Tem seu próprio roster hardcoded, `lib/features/crowd_lineup/domain/goias_squad.dart` (`final List<SquadPlayer> goiasSquad`), com comentário explícito: *"Elenco profissional atual do Goiás — fonte da verdade fornecida pelo usuário... Nunca sobrescrever com dados externos."* Usa o **mesmo id-space** (`tadeu`, `ezequiel`, etc.) por convenção compartilhada com `squad_members`/`squadPhotoAssets`, mas é uma lista INDEPENDENTE, mantida manualmente.

**Identidade persistida pelas votações/formações**: `SquadPlayer.id` (o slug do `goiasSquad`, ex. `"tadeu"`) — confirmado em `supabase_crowd_lineup_repository.dart` (`playerIdBySlot`, `_SlotAssignment.playerId`). **Não é `person_id`, não é nome, não é `squad_members.id` via FK** — é o slug do PRÓPRIO `goiasSquad`, que só COINCIDE em valor com `squad_members.id` por convenção editorial.

**F4 não migra esse contrato** — `crowd_lineup` não foi tocado, nada de `goiasSquad` foi alterado. Migrar isso (dar um `person_id` ao `goiasSquad` também) seria uma etapa própria (F5+), fora de escopo aqui.

## 15. Fotos/assets

`squadPhotoAssets` (`lib/features/squad/domain/squad_photos.dart`, 31 entradas) — mapa Dart const, **chave = slug** (mesmo id de `squad_members`/`goiasSquad`), valor = caminho de asset local. Usado por:
- `squad_list_page.dart`/`squad_avatar.dart` (Elenco) — `squadPhotoAssets[member.id]`.
- `guess_player_repository.dart` (Quem Vestiu o Manto) — `squadPhotoAssets[photoKey]`, onde `photoKey` vem de `guess_players.photo_key` (coincide com o mesmo slug pros ~31 jogadores do elenco atual que também aparecem em `guess_players`).

`squad_members.photo_url` (coluna real, pensada pra URL externa) está **NULL em produção hoje** — a foto de fato vem 100% do asset local via slug, nunca da coluna do banco. **Não alterado nesta etapa** — resolução de asset continua por slug, `person_id` não participa disso (identidade canônica e resolução de asset são problemas diferentes, como pedido).

## 16. Posições vs. canonical (`player_positions`)

Comparação ao vivo pros 4 casos pedidos — **nenhuma divergência, só menor granularidade**:

| Jogador | `squad_members.position` | `player_positions` (Etapa C) |
|---|---|---|
| Rodrigo Alves Soares | "Lateral-direito" | `LD, ALD, LE` |
| Djalma Antônio da Silva Filho | "Lateral-esquerdo" | `LE, ALE, PE` |
| João Paulo Ferreira Lourenço | "Volante" | `VOL, MC, MEI` |
| Lucas Rodrigues Moreira Costa | "Volante" | `VOL, MC, MEI` |

Em todos os 4, `squad_members.position` bate exatamente com o código PRIMÁRIO de `player_positions` (LD/LE/VOL respectivamente) — nunca contraditório, só menos granular (squad_members não representa as posições secundárias). Padrão consistente em toda a amostra checada — nenhuma inconsistência encontrada pra reportar.

## 17. Stats/spells vs. canonical

Cobertura numérica nos itens 20/21/22 abaixo (não é comparação CONTEÚDO a CONTEÚDO exaustiva — o pedido pediu cobertura, não diff campo-a-campo). `club_history` de `squad_members` cobre a carreira internacional inteira (como `career_players.club_career`), então qualquer comparação direta contra `player_club_spells` (só Goiás) teria a mesma ressalva de semântica-não-idêntica já documentada em F1/F3 — não forcei essa equivalência.

## 18. Comparações textuais — classificadas

| Local | Classificação | Nota |
|---|---|---|
| `squad_member_detail_page.dart:173` — `link.name == 'Instagram'` | **ASSET_LOOKUP/DISPLAY** | Escolhe o link social certo numa lista `{name, url}` genérica — não decide identidade de pessoa |
| `squad_list_page.dart`/`squad_avatar.dart` — `squadPhotoAssets[member.id]` | **ASSET_LOOKUP** | Resolve foto por slug, não por nome — já usa `id`, não texto normalizado |
| `squad_cubit.dart` | — | Sem lógica de identidade nenhuma (load/emit puro) |

**Nenhuma `IDENTITY_LOGIC` perigosa encontrada** no runtime consumidor de `squad_members` — nada pra corrigir nesta F4.

## 19. Autocomplete / relação com `goias_players.dart`

Cadeia mapeada explicitamente, conforme pedido:

```
squad_members (Supabase, Elenco)         -- independente, sem fallback
goiasSquad (crowd_lineup, hardcoded)     -- independente, id-space compartilhado por convenção, SEM FK
guess_players (Supabase, Quem Vestiu)    -- independente, autocomplete self-contained (achado da F3)
career_players (Supabase, Adivinhe)      -- independente, MAS seu autocomplete FUNDE com:
goias_players.dart (~215 nomes)          -- usado SÓ por career_path_page.dart (achado da F1)
```

`goias_players.dart` é referenciado **exclusivamente** por `career_path_page.dart` — confirmado por busca no repo inteiro (`grep -rl`). `squad_members` **não alimenta** `goias_players.dart` nem nenhum autocomplete compartilhado — são datasets totalmente independentes, ligados só pela convenção de slug compartilhado nos assets de foto (item 15), nunca por FK ou merge de autocomplete.

## 20. Cobertura de `ongoing spell`

Pra cada um dos 31 RESOLVED, checado ao vivo se existe `player_club_spells` com `club_id=Goiás` e `is_ongoing=true`:

| | Contagem |
|---|---|
| Com ongoing spell | **23** |
| **Sem** ongoing spell | **8** |
| Com múltiplos ongoing spells | 0 |

Os 8 sem ongoing spell (achado pra revisão, **não corrigido**): Carlos Eduardo Amaral Pereira de Castro, Carlos Eduardo de Sousa Leopoldino, Geirton Marques Aires, Luis Fellipe Campos Doria, Luiz Felipe Clemente de Almeida, Luiz Filipe da Rosa Machado, Ramon Menezes Roma, Wellington Soares da Silva. Faz sentido pra reforços recém-chegados cuja passagem Goiás ainda não foi capturada em `player_club_spells` (Etapa B cobriu quem já tinha evidência estruturada em `career_players`/`squad_members.club_history` no momento daquela etapa) — **nenhum spell foi criado/corrigido aqui**, é só o achado.

## 21. Cobertura de `player_positions`

**31/31 — cobertura total.** Todo squad_member RESOLVED já tem pelo menos 1 posição canônica registrada.

## 22. Cobertura de `player_club_stats` (CLUB_TOTAL)

| | Contagem |
|---|---|
| Com `CLUB_TOTAL` | **29** |
| **Sem** `CLUB_TOTAL` | **2** |

Os 2: Ezequiel Alves de Oliveira Vieira, Murillo Carvalho Victorio. Achado pra revisão, **não corrigido**.

## 23. Migrations propostas

**`20260902180000_add_person_id_to_squad_members.sql`**
```sql
alter table public.squad_members
  add column if not exists person_id uuid references public.people(id);

alter table public.squad_members
  add constraint squad_members_person_id_key unique (person_id);
```
`person_id` **nullable mesmo com 31/31 RESOLVED** — deliberadamente não forçado `NOT NULL` (migração paralela, reversível por design, conforme pedido explícito). Sem índice redundante.

**`20260902190000_backfill_squad_members_person_id.sql`** — mesmo padrão endurecido de F3 (as 3 pré-condições — total, ids existem, `person_id` vazio antes — aplicadas desde o início desta vez, não como correção posterior) + pós-condição forte num `DO $$...$$`. Nunca `ilike`/`full_name`/lookup textual.

## 24. RLS/grants

Auditado ao vivo:
```
relrowsecurity: true
pg_policies: "squad_members_read_all" (SELECT) — a única
role_table_grants (anon/authenticated): INSERT/SELECT/UPDATE/DELETE/
  TRUNCATE/REFERENCES/TRIGGER — grant amplo pré-existente
```
Mesmo padrão pré-F1/F3 de dívida preexistente. As 2 migrations propostas **não tocam GRANT/POLICY nenhum** — reportado, não corrigido nesta etapa.

## 25. Testes JS

`tooling/multiclub/test_squad_members_person_mapping.mjs` — **26 testes, 0 falhando**: números gerais, cardinalidade nos 2 sentidos, os 11 casos sensíveis (incluindo Murilo Câmara ≠ Murillo Victorio e confirmação de ausência de Dieguinho), SQL sem `ilike`/`full_name`, as 3 pré-condições + pós-condição, schema sem índice redundante, nenhuma outra tabela canônica tocada.

**Suíte completa `tooling/multiclub/test_*.mjs`: 350 passando, 0 falhando** (324 de F1+F3 + 26 novos).

## 26. `flutter analyze`

```
Analyzing goias-app...
No issues found! (ran in 12.0s)
```

## 27. `flutter test`

```
00:21 +729 ~1: All tests passed!
```
729 passando, 1 skip — idêntico, nenhuma regressão.

## 28. `git diff --stat`

```
lib/features/squad/domain/squad_member.dart                   | 10 ++++++++++
lib/features/store/presentation/widgets/store_entry_card.dart |  2 +-  (pré-existente, fora de escopo)
2 files changed, 11 insertions(+), 1 deletion(-)
```

## 29. `git status`

```
 M lib/features/squad/domain/squad_member.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/squad_members_person_mapping.json
?? data_export/goias/player_reconciliation/squad_members_person_mapping_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (Etapa E, decisão separada pendente)
?? migration_dump.txt                                              (padrão de exclusão)
?? supabase/migrations/20260902180000_add_person_id_to_squad_members.sql
?? supabase/migrations/20260902190000_backfill_squad_members_person_id.sql
?? tooling/multiclub/build_squad_members_person_mapping.mjs
?? tooling/multiclub/generate_squad_members_person_migration.mjs
?? tooling/multiclub/test_squad_members_person_mapping.mjs
```
Nada staged, nada commitado, nada aplicado no Supabase.

---

**PARE.** F2, F5, `lineup_matches`, `goias_players.dart`, live sync e flavors — nenhum tocado, conforme instruído.
