# Flavor Vila Nova — handoff de estado

> **Leia isto primeiro ao retomar** (outra conta ou outra sessão). Atualizado em 2026-09-29, no commit `3823501`. Tudo está commitado, mas ainda SEM PUSH (avise antes de subir).
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
| F4 → F9 | ⏳ banco já tem os dados (diretoria/elenco/Arena/Passaporte); falta ligar as capabilities no config, uma fase por vez | — |

Estado atual do app: o flavor **compila** e o Supabase **já teria dado** pra subir (URL/key preenchidos, banco populado) — falta só ligar as capabilities (`hasClubContent` já está; `hasPassport`/`enabledArenaGames`/etc. ainda não) e configurar a Auth Site URL/redirect no dashboard do projeto (adiado pra quando o Worker/F8 existir, pra não apontar pra uma URL que não resolve).

Verificação da última rodada: `flutter test` com 1540+ ok; `flutter analyze` sem issue nos arquivos do Vila; `test/core/club/vilanova_identity_isolation_test.dart` com 25 testes de isolamento e conteúdo (agora cobrindo supabaseUrl/publishableKey preenchidos, não mais null).

## 3. Próximos passos, em ordem

1. ✅ **[USUÁRIO] Projeto Supabase criado e runbook aplicado** em 2026-09-29 (`vkybbrfvmexevakknlsi`). Usuário criou o projeto, mandou a connection string (session pooler) e a publishable key; aplicado via `VILANOVA_DB_URL` (mesmo padrão de `GOIAS_DB_URL`/`BRAGANTINO_DB_URL` — nunca precisou do login CLI de org que só enxerga Aura/La Pelve): 7 migrations, `bootstrap.sql`, e os 17 seeds (venues + 8 anos de Passaporte + diretoria + transparência + elenco + quiz + escalações + carreira + Manto), tudo verificado ao vivo com `tooling/multiclub/verify-vilanova-live.mjs` (novo — mesmas checagens do simulador, mas contra o banco remoto). `supabaseUrl`/`supabasePublishableKey` preenchidos em `vilanova_club_config.dart`.
2. **[USUÁRIO, quando for a hora do F8] Configurar Auth Site URL/redirect** no dashboard do projeto — adiado de propósito: sem Worker ainda (F8), não há URL de callback real pra apontar. `supabaseRedirectUrl` continua `null` até lá.
3. **F4**: diretoria, transparência e elenco já no banco (28 pessoas, 5 documentos, 31 atletas); falta ligar as capabilities correspondentes no config e conferir as telas.
4. **F5 Arena**, uma subfase por jogo, ligando em `enabledArenaGames` (dado já está todo no banco: 45 quiz, 15 escalações, 30 carreiras, 50 Manto):
   - quiz, escalação e Manto estão prontos pra ligar;
   - carreira: esperar os nomes históricos da pesquisa externa, ou ligar com os 30 atuais se o usuário aceitar;
   - **perfis de jogador/técnico**: ✅ convertidos e calibrados (10 jogadores em `vilanova_player_identity_references.dart`, 8%–14% cada; 6 técnicos em `vilanova_tactical_coach_references.dart`, 16,4%–16,9% cada) — mas esses dois são referências em Dart, não seed; já estão prontos independente do banco. Falta só ligar `player_identity`/`tactical_identity` em `enabledArenaGames`.
5. **F6 Passaporte**: ligar `hasPassport` (468 partidas/78 venues já no banco). Novos lotes da pesquisa externa: `node tooling/vilanova_passport/generate_passport_sql.mjs`, revalidar com o simulador E com `verify-vilanova-live.mjs`, reaplicar só o seed do ano novo via `run-sql-file.mjs`.
6. **F7** Sócio Tigrão / Loja / Ingressos em modo demo. O pacote ainda está em REVIEW (preços do sócio vieram de jornal; a loja tem 12 de ~125 produtos).
7. **F8** Worker `wrangler.vilanova.toml` (jogos, notícias do site oficial, Instagram), ligando `hasMatches`/`hasNews`/`hasSocial`. O parser de notícias é novo (`src/news/`), no modelo do `bragantino_parser.ts`. Preencher `supabaseRedirectUrl` e configurar a Auth Site URL (passo 2 acima) junto com essa fase.
8. **F9** QA de isolamento com os 3 flavors + revisão visual (golden temporário, ver memória "revisão visual sem login").

**Decisões pendentes do usuário:**
- (c) Ligar a carreira só com o elenco atual ou esperar os nomes históricos.

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
