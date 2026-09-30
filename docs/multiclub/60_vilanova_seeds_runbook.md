# Vila Nova — seeds prontos + runbook do projeto Supabase novo

Data: 2026-09-29. Tudo abaixo foi **testado de ponta a ponta num Postgres real** (PGlite 0.5.8 / PostgreSQL 18.3), simulando o projeto novo: baseline + migrations + bootstrap + todos os seeds, duas vezes seguidas.

**Atualização 2026-09-29 (v1.3):** Passaporte 2019 fechado (60/60, 0 UNKNOWN) e aplicado — 8 anos, 468 partidas, 78 venues. Simulador rodado de novo com o seed novo, tudo OK (ver `git log` deste arquivo).

## Runbook (quando o projeto Supabase do Vila existir)

Cada arquivo roda inteiro, de uma vez, no **SQL Editor do projeto do Vila Nova**. Todos são idempotentes e começam com uma trava que PARA se o banco não for o do Vila (`public.clubs` precisa ter só a linha `vilanova`).

| # | Arquivo | O que faz |
|---|---|---|
| 1 | `supabase/migrations/*` (em ordem) | schema (canonical baseline + 6 migrations) |
| 2 | `infra/supabase/clubs/vilanova/bootstrap.sql` | linha do Vila em `public.clubs` |
| 3 | `supabase/vilanova_passport_infra.sql` | colunas de enriquecimento do Passaporte (iguais às do Bragantino) |
| 4 | `supabase/vilanova_passport_venues_seed.sql` | 67 estádios |
| 5 | `supabase/vilanova_passport_matches_<ano>_seed.sql` (2019 → 2026) | 468 partidas |
| 6 | `supabase/vilanova_club_board.sql` | diretoria: 6 seções, 28 pessoas |
| 7 | `supabase/vilanova_club_transparency.sql` | 5 documentos oficiais (4 balanços + estatuto) |
| 8 | `supabase/vilanova_squad_members.sql` | elenco: 31 atletas |
| 9 | `supabase/vilanova_quiz_questions.sql` | 45 perguntas |
| 10 | `supabase/vilanova_lineup_matches.sql` | 15 escalações |
| 11 | `supabase/vilanova_career_players.sql` | 30 carreiras |
| 12 | `supabase/vilanova_guess_players.sql` | 50 cartas do Manto |

Depois: preencher `supabaseUrl`/`supabasePublishableKey`/`supabaseRedirectUrl` em `vilanova_club_config.dart` e ligar as capabilities fase a fase (F4 elenco/diretoria, F5 cada jogo da Arena, F6 Passaporte).

## ⚠ Correção na cadeia de migrations (afeta qualquer clube novo)
`20260904210000_add_delivery_address_triggers.sql` falhava num projeto **zerado** com "trigger already exists": o baseline canônico passou a incluir os mesmos 2 triggers depois. Ganhou `DROP TRIGGER IF EXISTS` antes do `CREATE`.
- Goiás e Bragantino já aplicaram essa migration e ela nunca roda de novo, então nada muda neles.
- Sem essa correção, o `db push` do projeto do Vila pararia na 2ª migration.

## Geradores (nunca editar os .sql à mão)
- `node tooling/vilanova_passport/generate_passport_sql.mjs` gera o Passaporte (venues + um arquivo por ano) a partir de `docs/vila_nova_data/passport/`.
- `node tooling/vilanova_content/generate_seed_sql.mjs` gera diretoria, transparência, elenco e os 4 jogos da Arena com dados.

Adaptações pacote → app (documentadas no cabeçalho de cada gerador; nenhuma inventa dado):
- `is_club` → `is_goias`: chave legada que o app lê como "passagem pelo clube ativo".
- `position_group` do elenco é derivado da posição. O pacote usa "Defensores"/"Meio-campistas", e a tela agrupa por `positionGroupOrder`.
- `photo_url` do elenco fica null: o pacote aponta pra uma **pasta** do Google Drive, não pra uma imagem.
- `club_history` do elenco fica vazio (REVIEW no pacote).
- Quiz: EASY/MEDIUM/HARD viram os códigos internos `torcedor`/`esmeraldino`/`fanatico`.
- Escalação: o XI é reordenado por linha e da direita pra esquerda, que é como o `FormationLayoutService` desenha. A camisa (`no`) é sempre null.
- Transparência: `document_date` é o `last-modified` do próprio PDF, conferido via HTTP (mesmo critério do Bragantino).
- Passaporte:
  - `weekday`/`day_type`/`day_period`/`phase_status` são derivados de data, hora e rodada, com as regras do Bragantino;
  - a disputa de pênaltis vai para `data_notes`;
  - a ligação partida→estádio usa o nome oficial primeiro e desempata pela cidade ("Castelão" existe em Fortaleza e em São Luís).

Correção no pacote: `vn_venue_arena_nicnet` foi fundido em `vn_venue_santa_cruz_ribeirao`. Arena Nicnet é o nome comercial do próprio Estádio Santa Cruz, e dois venues para a mesma casa rachariam "estádio mais visitado". A mudança tem `editorial_note` no JSON.

## Simulador
`tooling/vilanova_seeds/simulate_fresh_project.mjs` + `checks.mjs` (`npm i --no-save @electric-sql/pglite` antes). Usar a cada lote novo do Passaporte.

Resultado da última rodada (v1.2, 408 partidas):
- as 16 SQLs aplicaram 2× sem erro (idempotência);
- 0 estádio órfão, 0 `club_id` errado, 0 carreira sem passagem pelo Vila;
- a RPC do app `passport_matches_for_year(2025)` devolve 62 partidas com estádio, e `passport_seasons()` lista 2020–2026;
- num banco com só a linha do Goiás, os seeds são barrados pela trava.

Resultado da rodada v1.3 (2019 incluído, 468 partidas, 78 venues):
- as 17 SQLs (agora com `vilanova_passport_matches_2019_seed.sql`) aplicaram sem erro;
- 0 estádio órfão, 0 venue sem uso, 0 carreira sem passagem pelo Vila, 0 `club_id` errado;
- `passport_seasons()` lista 2019–2026, 2019 com 60/60 finalizados;
- `vn_venue_santa_cruz_ribeirao` continua unificado (5 partidas), confirmando que a correção do Arena Nicnet segue válida mesmo com o venues.json novo da pesquisa externa reintroduzindo `vn_venue_arena_nicnet` como entrada separada — essa entrada foi excluída na aplicação (ver nota abaixo).

**Cuidado ao aplicar entregas futuras da pesquisa externa**: o `venues.json` que ele manda é regenerado do zero e pode reintroduzir `vn_venue_arena_nicnet` (ele ainda não recebeu confirmação de que a fusão foi aceita). Nunca sobrescrever `docs/vila_nova_data/passport/venues.json` inteiro — sempre mesclar só os IDs novos, excluindo `vn_venue_arena_nicnet`.

## Não entra (ainda)
- Sócio Tigrão (F7): preços em REVIEW.
- Perfis de jogador/técnico: são referências em Dart, não seed, e precisam de conversão/calibração no motor (F5).
- Fotos (ASSET_GAP).
