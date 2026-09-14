# 03 — Mapa de Fontes de Dados (feature a feature)

> Pra cada informação que aparece no app: de onde ela vem, de fato. Gerado em 2026-09-01.

## Elenco atual (`squad`)
- **Fonte**: Supabase, tabela `squad_members` (seed `squad_members_seed.sql`, 31 jogadores). **Sem fallback local** — falha de query = `ServerFailure`, não cai pra dado em cache.
- Fotos: mapa hardcoded separado, `lib/features/squad/domain/squad_photos.dart` (`squadPhotoAssets`), chaveado pelo mesmo `id`.
- Campos: id, name, fullName, shirtNumber, position, positionGroup, birthDate, nationality, heightCm, foot, photoUrl, instagramUrl, clubHistory (lista de passagens: period/team/appearances/goals/loan/isGoias/dataQuality/notes).

## Próximos jogos / partida ao vivo (`match`)
- **Fonte**: Cloudflare Worker (`goias-app.lucasdiogo1234.workers.dev/api/football/*`), que por trás proxia a OneFootball. Nunca persistido no cliente — toda tela refaz o fetch; `LiveMatchPoller` mantém só estado em memória, para de pollar (45s) fora do ciclo de vida ativo.
- Endpoints: `/standings`, `/current-round`, `/team/goias` (próximo jogo + resultados recentes), `/team/goias/season`, `/fixtures/{id}` (detalhe: eventos, escalação, estatísticas).
- **Sem fallback local.**

## Partidas históricas / Passaporte (`passport`)
- **Fonte**: Supabase, tabela `passport_matches` — 1.697 linhas, importadas de um **JSON fornecido pelo usuário** (`tooling/esmeraldino_passport/source/esmeraldino_passport_matches_2000_2026.json`, SHA-256 documentado), nunca scraping do próprio app. Cada linha carrega proveniência por partida (`source_provider`: RSSSF Brasil ou oGol, `source_url`, `source_confidence`).
- Estádios (`venues`, ~160 registros) foram enriquecidos numa migration posterior (31/08) — ver `06_database_audit.md §5` e `07_data_coverage.md` para os números de cobertura exatos.
- Fluxo de escrita: nunca via INSERT direto do cliente — sempre por RPC (`passport_save_attendances`, validando `FINISHED`+não-futuro server-side).

## Produtos (`store`)
- **Fonte**: JSON local (`lib/assets/content/store_products.json`, 104 itens), carregado via `rootBundle` por `MockStoreRepository` (**única** implementação de `StoreRepository` hoje — não é Supabase-backed apesar de um comentário no código mencionar uma futura `TrayStoreRepository`).
- Categorias: hardcoded Dart (`store_category_catalog.dart`).
- Frete: calculado com valores fixos em runtime (não vem de API de transportadora).
- Cupons: mapa hardcoded (`VERDAO10`, `SOCIO15`).
- Pedidos/checkout: Supabase (`store_orders`/`store_order_items`, RPC `create_store_order`). Endereços de entrega: Supabase (`delivery_addresses`).

## Sócio / Membership
- Planos: **100% hardcoded Dart** (`membership_plans_catalog.dart`) — não há tabela Supabase pra planos, apesar de `membership_content.sql` existir (esse arquivo só cria o FAQ).
- FAQ: Supabase (`membership_faq_categories`/`items`), com fallback pra asset JSON local se vazio/falhar.
- Regulamento: gerado estaticamente em Dart (`regulation_content.dart`, comentário explícito "GERADO... não editar à mão") a partir de `lib/assets/legal/membership_regulation.md` — não é Supabase-backed.
- Contato (WhatsApp): constantes hardcoded (`membership_contact_config.dart`).
- Assinatura do sócio: Supabase (`supporter_memberships`, RPC `get_my_membership`/`subscribe_to_plan` — este último **hardcoda os 6 planos** na própria função).

## Ranking (Arena)
- Cálculo de pontuação **inteiramente server-side**, via RPC `security definer` `arena_record_score`. O cliente nunca calcula/envia pontuação pronta — só reporta o que aconteceu; a RPC valida que o `item_id` existe de verdade na tabela de conteúdo correspondente e grava em `user_game_item_progress` (estado atual) + `score_events` (histórico append-only).
- Consultas via RPCs `arena_ranking`/`arena_my_rank`/`arena_user_detail`.
- **Sem fallback offline** — depende inteiramente do Supabase.

## Quiz
- Supabase (`quiz_questions`, tabela) é a fonte primária em uso normal. O const Dart `quizQuestions` (60 perguntas, `quiz_questions.dart`) é **estritamente fallback**, por design documentado em comentário — só entra se a query falhar (com report pro Sentry) ou vier vazia.

## Notícias
- API externa via Dio, `/api/news` e `/api/news/:id` no Worker de produção, que por trás faz **scraping de HTML** do site oficial (`goiasec.com.br`) — não é uma API real, ver `04_external_integrations.md`.
- **Sem cache/fallback offline** — erro de rede vira `ServerFailure` exibido como estado de erro.

## Feed social ("Goiás na Rede")
- API externa via Dio, `/api/social/feed?platform=` no mesmo Worker, combinando YouTube (API oficial), Instagram (via Apify) e X (JSON estático sincronizado manualmente — ver `04_external_integrations.md`).
- Nenhum channel ID/hashtag/token está hardcoded no app Flutter — essa config vive no Worker.
- **Sem fallback de dado**; existe só um estado vazio com links hardcoded pra Instagram/YouTube oficiais.

## Clube (história, diretoria, transparência, hino)
- História (`club_history_data.dart`) e linha do tempo (`club_timeline_data.dart`): **100% hardcoded Dart** (fonte citada em comentário: goiasec.com.br/historia).
- Diretoria: Supabase (`club_board_sections`/`club_board_members`) — "Supabase é a fonte da verdade" por comentário no próprio SQL.
- Transparência: Supabase (`club_transparency_topics`/`documents`).
- Músicas/hino e títulos: hardcoded Dart (`club_songs_data.dart`/`club_titles_data.dart`).
- **Sem fallback local** pra Diretoria/Transparência — dependem do Supabase; não aplicável a História/Timeline (só existem como Dart local).

## Ingressos / Check-in (`ticket`)
- Pasta real é `lib/features/ticket/` (singular). Repositório único (`MockTicketRepository`): setores/preços/portões/janelas de venda vêm **100% hardcoded** de `mock_ticket_fixture.dart` ("fonte única do conteúdo de venda... enquanto não existe API real de ingressos" — comentário no código), aplicados à partida REAL vinda de `FootballRepository` (não a um `matchId` fixo).
- Dados do usuário (decisão de check-in, ingressos emitidos, pedidos): Supabase (`ticket_checkin_decisions`, `ticket_orders`, `tickets`). Compra/pagamento continuam simulados (sem gateway real).

---

## Jogadores — auditoria consolidada (achado mais denso da Fase 1)

Existem **seis fontes independentes** de dado de jogador, com **três esquemas de ID diferentes** entre elas e **sem chave de junção comum**:

| Fonte | Fonte de dado | Contagem | Esquema de ID |
|---|---|---|---|
| Elenco atual (`squad_members`) | Supabase, sem fallback | 31 | slug curto (`tadeu`) |
| Escalação da Torcida (`goias_squad.dart`) | Dart hardcoded, **terceira cópia independente** do elenco atual (não lê do Supabase) | 31 (verificado 1:1 com squad_members) | slug curto igual ao squad |
| Adivinhe o Jogador (`career_players`) | Supabase com fallback Dart (`career_players.dart`) | 30 | apelido/primeiro nome |
| Autocomplete do Adivinhe o Jogador (`goias_players.dart`) | Dart hardcoded, só nomes (sem dado estruturado) | 215 | nome livre |
| Quem Vestiu o Manto (`guess_players`) | Supabase com fallback Dart | 173 | slug de **nome completo**, distinto de `squad_members.id` |
| Adivinhe a Escalação (`lineup_matches`) | Supabase com fallback Dart | 31 partidas × 11 titulares = 341 slots (~120-150 nomes únicos) | nome livre por partida |
| Identidade Futebolística (técnicos, não jogadores) | Dart hardcoded, dataset de referência de estilo | 12 técnicos | slug |
| Que Craque Esmeraldino É Você (jogadores-referência de estilo) | Dart hardcoded | 21 | apelido |

**Estimativa de melhor esforço**: ~230–260 indivíduos únicos nomeados no total (sem contar os 12 técnicos), com sobreposição pesada entre `goias_players.dart` (215) e `guess_players` (173). Uma contagem exata exige normalização de nome (insensível a acento, ciente de apelido) e junção entre os três esquemas de ID — esse trabalho de normalização **não existe hoje no código**.

**Divergências reais encontradas** (mesmo jogador, dados diferentes entre fontes):
- **Tadeu**: 398 jogos (squad, 2 passagens) vs. 400 jogos (career_players, 1 passagem combinada) — gols batem (13), jogos não.
- **Walter**: career_players registra passagens "2012-2013"/"2016-2017"; player_identity_references registra "2012–2013 / 2019" — o ano 2019 não bate com nenhuma fonte.
- **Erik**: career_players registra "2013-2015"; player_identity_references registra "anos 2020" — não bate.
- **Danilo** (colisão de nome, não divergência de dado): `danilo` é usado como ID tanto pro meio-campista histórico (1999-2003) quanto pro lateral atual (desde 2025) — **pessoas diferentes com o mesmo slug**.
- **Fernandão**: divergência de linhagem entre versões do mesmo dataset — `career_players.sql` original tinha uma passagem combinada "1996–2002; 2009–2010"; a migration v2 (31/08) splitou em duas ("1995-2001"/"2009-2010"). `player_identity_references` bate com a v2, confirmando que v2 é a versão vigente.
- **Squad atual duplicado em `guess_players` sob ids de nome completo**: verificado consistente (shirt numbers batem: Juninho #8, Ezequiel #12, Luisão #25, Pedrinho #17) — mas confirma que qualquer exportação consolidada precisa de join por **nome**, não por id.

---

## Ver também
- Cobertura de campos por partida/jogador: `07_data_coverage.md`
- Mapa de origem campo a campo: `08_field_origin_map.md`
- Hardcodes de marca específicos: `05_goias_hardcodes.md`
- Integrações externas em detalhe: `04_external_integrations.md`
