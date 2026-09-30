# Flavor Vila Nova — handoff de estado

> **Leia isto primeiro ao retomar** (outra conta ou outra sessão). Atualizado em 2026-09-30, no commit `896ec4e` (18 commits à frente de `origin/main`). Tudo está commitado, mas ainda SEM PUSH (avise antes de subir).
> Prompt pronto para começar a nova conversa: `docs/vila_nova_data/PROMPT_RETOMADA.md`.

## 1. O que é e como trabalhamos

3º flavor do fan-hub: **`vilanova`** (Vila Nova Futebol Clube, Goiânia-GO), no mesmo padrão do Bragantino (`lib/core/club/bragantino_club_config.dart`, `docs/multiclub/47_*`, `docs/bragantino_data/`).

Divisão de trabalho:
1. **Pesquisa externa.** Ele entrega ZIPs incrementais na Área de Trabalho (`C:\Users\lucas\OneDrive\Desktop\vila_nova_*.zip`), cada um só com os arquivos alterados + `manifest.json`. O pedido original está em `docs/vila_nova_data/PROMPT_PESQUISA.md`.
2. **A auditoria confere** cada ZIP (receita na §7), aplica em `docs/vila_nova_data/` e devolve ao usuário uma **mensagem pronta para colar na ferramenta de pesquisa** com as correções.
3. **A implementação segue** o app fase a fase, com commit no fim de cada fase. O usuário está em modo automático e não quer aprovar cada passo, mas o push é confirmado no fim de cada entrega.

Regras que não mudam:
- só `status: READY` entra no app;
- nunca inventar dado;
- em partida decidida nos pênaltis, `outcome` = resultado do tempo normal (DRAW), com a disputa à parte;
- estádio só com fonte da própria partida (`MATCH_SPECIFIC`);
- vice nunca é título;
- o Vila é rival do Goiás: zero reaproveitamento de texto, asset ou dado;
- texto de bastidor da pesquisa ("lote", "acervo", "snapshot") nunca vai pro app. Corrigir no pacote, com `editorial_note`.

## 2. Implementação no app

| Fase | Estado | Commit / relatório |
|---|---|---|
| F0 infraestrutura | ✅ flavor Android/iOS/web, `br.com.fanhub.vilanova`, `club_id` `3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e`. Feito por outra sessão | `00ec2fe` · `docs/multiclub/57_*` |
| Firebase | ✅ apps criados via CLI no `fan-hub-29e9b`; configs no repo | `f885cd8` |
| F1 config | ✅ `lib/core/club/vilanova_club_config.dart` no `clubRegistry`; OneFootball 2865 / `vila-nova-2865` / `brasileirao-serie-b-superbet-119` (confirmado) | `f885cd8` · `58_*` |
| F2 marca | ✅ cor oficial **#C33D41** (manual, pág. 9); escudo, selo, login e ícones gerados do PDF vetorial por `tooling/vilanova_brand/build_brand_assets.py` | `f885cd8` · `58_*` |
| F3 /clube | ✅ `hasClubContent` ligado: história (7), linha do tempo (30), 31 títulos, 3 vices da Copa Verde, 9 ídolos. História/timeline **geradas** por `tooling/vilanova_content/generate_institutional_dart.mjs` (corrigir no JSON e regenerar + `dart format`) | `7b66b3e` · `59_*` |
| Seeds SQL | ✅ 17 arquivos `supabase/vilanova_*.sql`, testados em Postgres real (PGlite): Passaporte 2019–2026 (468 jogos, 78 estádios), diretoria, transparência, elenco, quiz, escalações, carreira, Manto | `777fded` + commit do lote 2019 · `60_*` (runbook) |
| **Supabase do Vila** | ✅ **projeto criado, schema+bootstrap+todos os 17 seeds APLICADOS DE VERDADE** em 2026-09-29 (projeto `vkybbrfvmexevakknlsi`), verificado ao vivo (não só no simulador): 468 partidas, 78 venues, 0 órfão, 0 venue sem uso, RPCs `passport_seasons()`/`passport_matches_for_year()` respondendo certo. `supabaseUrl`/`supabasePublishableKey` preenchidos no config | commit do lote de aplicação |
| F4 diretoria/transparência/elenco | ✅ nenhuma mudança de código precisou — `hasClubContent` (F3) já cobria diretoria/transparência (Supabase), e elenco nunca teve gate de capability (sempre `club_id`-scoped). Só precisava do banco existir, que já existe. Confirmado ao vivo: 6 seções/28 pessoas, 5 documentos, 31 atletas | — |
| F5 Arena | ✅ **os 6 jogos ligados** em `enabledArenaGames`: `quiz` (45/45), `lineup` (15/15, 11 jogadores + formação reconhecida cada), `player_identity`/`tactical_identity` (referências Dart, calibradas), `career_path` (30/30, mas **todas do elenco atual** — decisão (c) ainda em aberto, o app já roda com o que existe), `guess_player` (Manto) — **ASSET_GAP resolvido em 2026-09-30** (ver linha "Fotos do elenco" abaixo), 14/50 cartas elegíveis como segredo | commit da F4/F5 + commit das fotos |
| **Fotos do elenco (ASSET_GAP resolvido)** | ✅ 31 fotos individuais reais extraídas de `vilanovafc.com.br/elenco-profissional` em 2026-09-30 (atributo `data-src` de cada `<img>`, formato AVIF) — hotlink direto pro CDN oficial, mesmo padrão do Bragantino (`_bragantinoGuessPlayerPhotos`). Substituem o link de pasta do Drive que não servia como imagem. Aplicadas em 3 lugares: (1) `docs/vila_nova_data/data/squad_current.json`/`arena/guess_player.json` (pacote, `photo_source_url` + `photo_key`), (2) `vilanova_squad_members.sql`/`vilanova_guess_players.sql` (regenerados, aplicados só no **simulador** até agora — falta aplicar no banco real, precisa de `VILANOVA_DB_URL`), (3) `ClubConfig.assets.guessPlayerPhotos` (Dart, 31 entradas). **CAVEAT não verificado:** o CDN do Vila só serve `.avif` sem negociação de formato — não consegui confirmar a renderização ao vivo no app (bug conhecido do `preview_start`, cwd errado — ver §8) | commit das fotos |
| F6 Passaporte | ✅ `hasPassport: true` ligado em 2026-09-30 — nenhuma mudança de código precisou: `passportContent` já apontava pro `VilaNovaPassportContent` ("Passaporte Colorado") desde o F3, e `SupabasePassportRepository` é genérico por clube (lê o `supabaseUrl`/`Key` do config ativo). Dado (468 partidas / 78 venues) já tinha sido verificado ao vivo quando o runbook foi aplicado | commit do F6 |
| F7 Sócio Tigrão | ✅ **`hasMembership: true`** ligado em 2026-09-30 — 4 planos REAIS (RUBI/OURO/PRATA/TIME DO POVO), fonte: API pública do provedor de adesão (`vilanova.ingressosa.com.br/public/api/v1/socio/benefits-plan`, sem login). Achado importante: todo plano é **adesão ANUAL só** (nenhum registro de pagamento com periodicidade mensal, mesmo o card comercial mostrando "/mês" — é a parcela de 11x do valor anual real). Modelagem nova: `MembershipCommitmentPeriod` (`monthlyRecurring` pros catálogos existentes, `annualContract` pro Vila) — `annualPrice` continua não-nulo porque o total é REAL (não `mensal*12`), confirmado pela própria API. Regulamento continua ausente (nenhum documento oficial) — `MembershipProgramConfig.hasRegulationContent` (novo getter) esconde o botão em vez de mostrar tela vazia. CTA "Quero ser sócio" abre `externalCheckoutUrl` (novo campo, `https://vilanova.ingressosa.com.br/selecionar-plano`) em vez do cadastro mockado interno — o Vila não recria o checkout de um provedor terceiro real. Loja e Ingressos continuam `false` (ver auditoria de isolamento abaixo) | commit do F7 |
| **Auditoria de isolamento multi-clube (Tickets/Store)** | Durante o F7, achei e corrigi um vazamento de dado JÁ EM PRODUÇÃO: `TicketFixture` (setores/preços/portões de ingresso) era código **compartilhado** com o conteúdo hardcoded do Goiás ("Goiás E.C.", Serra Dourada) embutido nele — o Bragantino tinha `hasTickets: true` sem fixture própria e mostrava esse mesmo conteúdo do Goiás. Corrigido: `ClubConfig.ticketsContent` (novo, nullable) por clube; sem conteúdo, a feature fica indisponível (`Success(null)`), nunca cai pro Goiás. **Bragantino voltou pra `hasTickets: false`** até existir pesquisa real de ingressos dele (regressão consciente e documentada — melhor que mostrar dado errado). Loja: `StoreProduct.images`/`.thumbnail` viraram opcionais (`ProductImagePlaceholder` cobre a ausência na UI) — segue `hasStore: false` pro Vila até a coleta de produtos (hoje 12/125, sem foto nenhuma) ficar completa | commit do F7 |
| F8 → F9 | ⏳ seguir a ordem | — |

Estado atual do app: o flavor **compila**, o Supabase está **no ar com dado real** (URL/key preenchidos, banco populado, F4/F5/F6/F7 ligadas) — falta F8 (Worker + Auth Site URL/redirect, adiado de propósito), F9 (QA + revisão visual) e **aplicar o seed novo de fotos no banco real** (simulado e validado, mas só simulado — ver §3 item 1).

Verificação da última rodada: `flutter test` completo (1.559 casos) e `flutter analyze` sem issue novo (12 infos/warnings pré-existentes, nenhum nos arquivos tocados); `test/core/club/vilanova_identity_isolation_test.dart` atualizado pra `hasMembership: true`; novos testes de periodicidade anual (`vilanova_membership_plans_catalog_test.dart`), isolamento de ingressos (`club_scoped_user_state_test.dart`) e imagem opcional de produto (`store_product_optional_image_test.dart`).

## 3. Próximos passos, em ordem

1. ✅ **[USUÁRIO] Projeto Supabase criado e runbook aplicado** em 2026-09-29 (`vkybbrfvmexevakknlsi`). Usuário criou o projeto, mandou a connection string (session pooler) e a publishable key; aplicado via `VILANOVA_DB_URL` (mesmo padrão de `GOIAS_DB_URL`/`BRAGANTINO_DB_URL` — nunca precisou do login CLI de org que só enxerga Aura/La Pelve): 7 migrations, `bootstrap.sql`, e os 17 seeds (venues + 8 anos de Passaporte + diretoria + transparência + elenco + quiz + escalações + carreira + Manto), tudo verificado ao vivo com `tooling/multiclub/verify-vilanova-live.mjs` (novo — mesmas checagens do simulador, mas contra o banco remoto). `supabaseUrl`/`supabasePublishableKey` preenchidos em `vilanova_club_config.dart`.
2. **[USUÁRIO, quando for a hora do F8] Configurar Auth Site URL/redirect** no dashboard do projeto — adiado de propósito: sem Worker ainda (F8), não há URL de callback real pra apontar. `supabaseRedirectUrl` continua `null` até lá.
3. ✅ **F4** — sem mudança de código; `hasClubContent` já cobria diretoria/transparência, elenco nunca teve gate. Confirmado ao vivo (28 pessoas, 5 documentos, 31 atletas).
4. ✅ **F5 Arena** — os 6 jogos ligados, incluindo `guess_player` desde 2026-09-30 (ver item 4b).
4b. ✅ **Fotos do elenco/Manto** — 31 fotos reais extraídas do site oficial (hotlink AVIF), aplicadas no pacote + gerador + `ClubConfig.assets.guessPlayerPhotos` + regeneradas em `vilanova_squad_members.sql`/`vilanova_guess_players.sql`. **Simulador rodou 2x (idempotente), mas o seed novo AINDA NÃO foi aplicado no banco real** — falta `VILANOVA_DB_URL=<connection string> node tooling/multiclub/run-sql-file.mjs vilanova supabase/vilanova_squad_members.sql --yes` e o mesmo pra `vilanova_guess_players.sql`, depois `node tooling/multiclub/verify-vilanova-live.mjs`. Peça a connection string ao usuário quando for a hora (não fica salva em lugar nenhum). Também não consegui confirmar a renderização visual do AVIF no app rodando (bug conhecido do `preview_start`, cwd aponta pro diretório errado — ver §8) — vale um teste manual num device/emulador antes de considerar 100% fechado.
5. ✅ **F6 Passaporte** — `hasPassport: true` ligado em 2026-09-30. Novos lotes da pesquisa externa continuam o fluxo normal: `node tooling/vilanova_passport/generate_passport_sql.mjs`, revalidar com o simulador E com `verify-vilanova-live.mjs`, reaplicar só o seed do ano novo via `run-sql-file.mjs` (a flag já está ligada, não precisa mexer nela de novo).
6. ✅ **F7 Sócio Tigrão** — `hasMembership: true` ligado em 2026-09-30, 4 planos reais da própria API do provedor de adesão (ver tabela acima). Loja e Ingressos continuam `false` (dado insuficiente/sem pesquisa própria — ver auditoria de isolamento na tabela acima).
7. **[quando surgir pesquisa de Loja/Ingressos do Vila]** Loja: completar o catálogo (hoje 12/125 produtos, nenhum com foto) e então ligar `hasStore`. A entidade já aceita produto sem imagem (`ProductImagePlaceholder`), então não precisa de mudança de código, só o dado. Ingressos: pesquisar setores/preços/portões reais do estádio do Vila e preencher `ClubConfig.ticketsContent` (`ClubTicketsContent`, ver `lib/features/ticket/data/goias_ticket_content.dart` como modelo) — também sem mudança de arquitetura, só o dado. **O mesmo vale pro Bragantino**, que perdeu `hasTickets` nesta rodada por não ter conteúdo próprio.
8. **F8** Worker `wrangler.vilanova.toml` (jogos, notícias do site oficial, Instagram), ligando `hasMatches`/`hasNews`/`hasSocial`. O parser de notícias é novo (`src/news/`), no modelo do `bragantino_parser.ts`. Preencher `supabaseRedirectUrl` e configurar a Auth Site URL (passo 2 acima) junto com essa fase.
9. **F9** QA de isolamento com os 3 flavors + revisão visual (golden temporário, ver memória "revisão visual sem login").
10. **[próxima pesquisa]** Prompt de continuação já registrado em `docs/vila_nova_data/PROMPT_PESQUISA_CONTINUACAO_2026-09-30.md` (Rio Branco-VN x Rio Branco-ES, `calendar_year` como número, honors/conflitos do Goiano, fusão de venue Arena Nicnet, Arena 21/12/15/≥5/≥10, parceiros 2026 com auditoria de uniforme, Passaporte 2018 pra trás). Ainda não enviado à pesquisa — aguardando o usuário mandar e devolver o ZIP.

**Decisões pendentes do usuário:**
- (c) `career_path` foi ligado em 2026-09-29 com os 30 do elenco atual (uma das duas opções já apresentadas antes, pra não travar o F5 inteiro nisso) — mas se o usuário preferir esperar os nomes históricos da pesquisa externa, é só avisar: troca de dado sem custo (mesmo seed, mesma capability, só o conteúdo muda).

**Decisões já tomadas:**
- (a) **Parceiros**: usuário decidiu em 2026-09-29 incluir a FatalFans normalmente — é patrocínio real (estampado no número da camisa), sem restrição editorial. `hasPartners` continua `false` só porque a lista em `data/partners.json` está incompleta (`coverage_status: "PARTIAL"`: falta o patrocinador máster atual e uma auditoria uniforme por uniforme) — não mais por causa da FatalFans. Assim que a auditoria completar, pode ligar `hasPartners: true` com a lista inteira, FatalFans incluída.

## 4. Pacote de pesquisa: v1.2 (`docs/vila_nova_data/`)

| Área | Situação |
|---|---|
| Identidade, história, timeline, títulos | ✅ (16 Goianos pelo site oficial; a Wikipedia diz 17: é conflito documentado, não erro) |
| Ídolos | 11 READY + 4 REVIEW. **Túlio** em conflito (pacote 104j/92g × Wikipedia/oGol 58j/51g). No app, está retido |
| Diretoria / transparência / elenco | ✅ (a pasta do Drive não serve como foto) |
| Quiz 45 · Escalações 15 · Manto 50 | ✅ READY. Tudo recente (escalações de 2015 pra cá; Manto sem estreia antes de 2013) |
| Carreira 30 | READY, mas **todas do elenco atual** |
| Perfis jogador (10) / técnico (6) | ✅ convertidos pro motor real e calibrados (ver §2, linha "perfis de jogador/técnico"). O pacote de origem (`docs/vila_nova_data/arena/player_identity.json` / `tactical_identity.json`) continua com o schema de 8 dimensões em português — serve só de evidência, não é mais usado pelo app |
| Sócio / Loja | REVIEW / parcial |
| Passaporte | 2019–2025 CLOSED, 2026 PARTIAL (faltam R35–R38 + 2ª fonte). 2019 fechado em 2026-09-29 (v1.3: 60/60, 0 estádio UNKNOWN, 3 conflitos resolvidos). **1943–2018 não pesquisado; próximo lote = 2018** |

Correções já feitas **no pacote** (com `editorial_note`):
- 5 frases de bastidor na história e na timeline;
- `vn_venue_arena_nicnet` fundido em `vn_venue_santa_cruz_ribeirao` (mesma casa).

Erros abertos, a devolver à pesquisa:
- 2025-03-13 (Copa do Brasil, 6–0): o adversário é **Rio Branco-VN**, não Rio Branco-ES;
- `calendar_year` em string em 3 jogos de 2026 (o gerador já normaliza);
- registrar o conflito 16 × 17 Goianos;
- Túlio em REVIEW.

## 5. Perfis da Arena: o formato que o app realmente usa

O motor e as perguntas são únicos para todos os clubes; cada clube só fornece referências.
- **Jogador**: `lib/features/arena/games/player_identity/domain/<clube>_player_identity_references.dart`, com 6 atributos de 0 a 100 (`creativity, definition, leadership, intensity, technique, tactics`). O clube entra em `player_identity_reference_sets.dart`. Meta: **21** referências.
- **Técnico**: `tactical_identity/domain/<clube>_tactical_coach_references.dart`, com `x` (posse − / vertical +), `y` (dogmático − / pragmático +), `pressing, blockHeight, risk, structuralFluidity`. Entra em `tactical_coach_reference_sets.dart`. Meta: **12**.
- Calibração: todos precisam aparecer como Top 1, nenhum acima de 20%, gap Top1→Top2 saudável (ver o topo de `bragantino_player_identity_references.dart` e `tool/bragantino_*_calibration.dart`).

## 6. Mensagem pendente à pesquisa (se o usuário ainda não mandou)

```
v1.2 e v1.3 aplicados — 2019 a 2025 ficaram excelentes (2019 fechado 60/60, 0 estádio UNKNOWN, 3 conflitos de estádio resolvidos com fonte forte — bom trabalho). Ajustes:

1. 2025-03-13 (Copa do Brasil 2ª fase, 6–0): o adversário é Rio Branco-VN (Venda Nova do Imigrante-ES), não Rio Branco-ES. Corrija. Confira também o "Rio Branco-ES" da Copa Verde 2026.
2. 2026: calendar_year dos 3 jogos vn_official_cdb_2026_f* está em string ("2026"); deixe número.
3. Honors: registre em conflicts que a Wikipedia conta 17 Goianos contra 16 do site oficial (mantenha o oficial).
4. Venues: o venues.json do v1.3 trouxe de volta vn_venue_arena_nicnet como entrada separada. Ela já tinha sido fundida em vn_venue_santa_cruz_ribeirao (Arena Nicnet é o naming rights do próprio Estádio Santa Cruz) — removi de novo na aplicação, mas por favor pare de incluir vn_venue_arena_nicnet nas próximas entregas: use vn_venue_santa_cruz_ribeirao (com "Arena Nicnet" como alias) desde a origem.
5. Arena (pendente desde o v0.6): perfis com 21 jogadores e 12 técnicos (só nome, período, função e 4–6 evidências de ESTILO — não precisa de perguntas nem notas), 15 carreiras históricas no lugar de atuais, Túlio em REVIEW, ≥5 escalações anteriores a 2000 e ≥10 cartas do Manto com estreia antes de 2005. (Os 10/6 perfis atuais já foram convertidos e calibrados no motor do app — a expansão pra 21/12 continua valendo, não é bloqueante.)
6. Parceiros (`data/partners.json`): completar a lista de patrocinadores da temporada atual (2026). Hoje só tem FatalFans e Volt Sport. Falta pelo menos: o patrocinador MÁSTER atual (o contrato da GingaBet anunciado em 26/02/2025 era de 12 meses e não foi projetado além do prazo — confirme se ainda é ela ou se trocou), e uma auditoria uniforme por uniforme (manga, calção, patrocinador máster no peito, apoiadores/fornecedores menores) com foto/fonte de cada um. Pra cada patrocinador: `tier` (MASTER/OFFICIAL/SUPPLIER/…), `category`, `url`, `logo_source_url`, `since`, `placement` (onde aparece no uniforme) e fonte. Sem restrição editorial: pode incluir qualquer patrocinador real, incluindo a FatalFans (já aprovada).

Próximo lote do Passaporte: 2018, depois seguindo para trás até 1943.
```

## 7. Como auditar um ZIP novo (receita)

1. Extrair no scratchpad e aplicar **em ordem de versão** sobre uma cópia de `docs/vila_nova_data/`.
2. `node docs/vila_nova_data/validate_passport.js <pasta>`: todos os anos, placar × resultado, pênaltis, lado do Vila, estádio × `venues.json`, totais × `passport_audit_manifest.json`.
3. Arena: XI = 11 com 1 GOL, formações que o `FormationLayoutService` conhece, `is_club` nas carreiras, IDs e nomes únicos.
4. Conferir 2–3 fatos na web: campanha do ano, finais, adversários com nome parecido. Nomes de estádio ambíguos ("Castelão") são desempatados pela cidade.
5. Copiar para `docs/vila_nova_data/`, **regenerar os seeds** (`generate_passport_sql.mjs` / `generate_seed_sql.mjs`) e rodar o simulador:
   ```
   npm i --no-save @electric-sql/pglite
   CHECKS=tooling/vilanova_seeds/checks.mjs node tooling/vilanova_seeds/simulate_fresh_project.mjs <seeds na ordem do runbook>
   ```
6. Atualizar este arquivo, fazer o commit e devolver a mensagem de correções.
7. **Desde 2026-09-29, o projeto Supabase existe e já tem dado real** — depois do simulador OK, aplicar o(s) seed(s) novo(s)/alterado(s) no banco de verdade: `VILANOVA_DB_URL=<connection string> node tooling/multiclub/run-sql-file.mjs vilanova <arquivo> --yes`, depois `node tooling/multiclub/verify-vilanova-live.mjs` pra conferir contagens/RPCs ao vivo.

## 8. Armadilhas conhecidas

- `tooling/multiclub/test_*.mjs` **reescreve** artefatos rastreados em `archive/` e `data_export/`: restaurar com `git checkout` antes de commitar. 13 dessas auditorias **já falham no HEAD**. Para saber se algo é regressão, compare com uma worktree limpa; não assuma.
- No Windows, criar app no Firebase CLI funciona pelo PowerShell (`npx firebase-tools ...`); pelo Git Bash deu erro de `C:\Program`.
- No pbxproj iOS, clonar entradas linha a linha: regex multi-linha já estragou o arquivo.
- Golden temporário: a fonte do Flutter no cache é `roboto-*.ttf` (minúsculo); a imagem precisa de `tester.runAsync` pra decodificar. Nunca commitar.
- A cadeia de migrations quebrava num projeto zerado (trigger duplicado). Foi corrigida em `777fded`: sempre testar projeto novo no simulador.
- `preview_start`/`preview_list` (browser embutido do ambiente de desenvolvimento): o `cwd` da sessão de preview às vezes fica no diretório PAI (`AndroidStudioProjects`) em vez de `fan-hub`, e tenta rodar `launch.json` local de outro projeto do workspace (já aconteceu de pegar config de um projeto totalmente diferente, tipo "fifa-queue"). `mcp__ccd_directory__change_directory` não resolve na hora (só no fim do turn). Sem solução encontrada ainda — se precisar rodar o app pra verificar algo visual (ex.: conferir se uma foto AVIF renderiza), pode ser preciso pedir pro usuário testar manualmente num device/emulador, ou tentar de novo numa sessão nova.
