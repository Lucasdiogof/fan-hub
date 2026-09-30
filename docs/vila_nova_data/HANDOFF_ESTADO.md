# Flavor Vila Nova — handoff de estado

> **Leia isto primeiro ao retomar** (outra conta ou outra sessão). Atualizado em 2026-09-29, no commit `777fded`. Tudo está commitado e em `origin/main`.
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
| Seeds SQL | ✅ 16 arquivos `supabase/vilanova_*.sql`, testados em Postgres real (PGlite): Passaporte 2020–2026 (408 jogos, 67 estádios), diretoria, transparência, elenco, quiz, escalações, carreira, Manto | `777fded` · `60_*` (runbook) |
| F4 → F9 | ⏳ dependem do **projeto Supabase do Vila** | — |

Estado atual do app: o flavor **compila** (APK debug e build web ok), mas **não sobe**, porque `supabaseUrl` é null e `SupabaseConfig` falha alto de propósito, pra nunca cair no banco de outro clube.

Verificação da última rodada: `flutter test` com 1540 ok; `flutter analyze` sem issue nos arquivos do Vila; `test/core/club/vilanova_identity_isolation_test.dart` com 24 testes de isolamento e conteúdo.

## 3. Próximos passos, em ordem

1. **[USUÁRIO] Criar o projeto Supabase do Vila Nova** na organização do Fan Hub. Passar URL + chave publishable, ou definir o token na janela dele: a CLI daqui só enxerga os projetos da Aura e da La Pelve.
2. **Aplicar o runbook** `docs/multiclub/60_vilanova_seeds_runbook.md`: migrations → `infra/supabase/clubs/vilanova/bootstrap.sql` → seeds na ordem. Preencher `supabaseUrl`/`supabasePublishableKey`/`supabaseRedirectUrl` na config. Configurar Auth URL do projeto (redirect).
3. **F4**: diretoria, transparência e elenco já no banco; conferir as telas.
4. **F5 Arena**, uma subfase por jogo, ligando em `enabledArenaGames`:
   - quiz, escalação e Manto estão prontos;
   - carreira: esperar os nomes históricos da pesquisa externa, ou ligar com os 30 atuais se o usuário aceitar;
   - **perfis de jogador/técnico**: converter as referências para o motor (ver §5) e calibrar como no Bragantino (`tool/bragantino_*_calibration.dart`).
5. **F6 Passaporte**: ligar `hasPassport`. Novos lotes: `node tooling/vilanova_passport/generate_passport_sql.mjs` + simulador.
6. **F7** Sócio Tigrão / Loja / Ingressos em modo demo. O pacote ainda está em REVIEW (preços do sócio vieram de jornal; a loja tem 12 de ~125 produtos).
7. **F8** Worker `wrangler.vilanova.toml` (jogos, notícias do site oficial, Instagram), ligando `hasMatches`/`hasNews`/`hasSocial`. O parser de notícias é novo (`src/news/`), no modelo do `bragantino_parser.ts`.
8. **F9** QA de isolamento com os 3 flavors + revisão visual (golden temporário, ver memória "revisão visual sem login").

**Decisões pendentes do usuário:**
- (a) **Parceiros**: a lista está incompleta e a FatalFans é uma plataforma de conteúdo adulto. `hasPartners` segue false até ele decidir.
- (b) O projeto Supabase (passo 1).
- (c) Ligar a carreira só com o elenco atual ou esperar os nomes históricos.

## 4. Pacote de pesquisa: v1.2 (`docs/vila_nova_data/`)

| Área | Situação |
|---|---|
| Identidade, história, timeline, títulos | ✅ (16 Goianos pelo site oficial; a Wikipedia diz 17: é conflito documentado, não erro) |
| Ídolos | 11 READY + 4 REVIEW. **Túlio** em conflito (pacote 104j/92g × Wikipedia/oGol 58j/51g). No app, está retido |
| Diretoria / transparência / elenco | ✅ (a pasta do Drive não serve como foto) |
| Quiz 45 · Escalações 15 · Manto 50 | ✅ READY. Tudo recente (escalações de 2015 pra cá; Manto sem estreia antes de 2013) |
| Carreira 30 | READY, mas **todas do elenco atual** |
| Perfis jogador (10) / técnico (6) | formato errado (culpa do prompt original). Aproveitam-se nomes e evidências |
| Sócio / Loja | REVIEW / parcial |
| Passaporte | 2020–2025 CLOSED, 2026 PARTIAL (faltam R35–R38 + 2ª fonte). **1943–2019 não pesquisado; próximo lote = 2019** |

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
v1.2 aplicado — 2020 a 2025 ficaram excelentes (bati Série B de 2022, 2023, 2024 e 2025 com fontes externas). Ajustes:

1. 2025-03-13 (Copa do Brasil 2ª fase, 6–0): o adversário é Rio Branco-VN (Venda Nova do Imigrante-ES), não Rio Branco-ES. Corrija. Confira também o "Rio Branco-ES" da Copa Verde 2026.
2. 2026: calendar_year dos 3 jogos vn_official_cdb_2026_f* está em string ("2026"); deixe número.
3. Honors: registre em conflicts que a Wikipedia conta 17 Goianos contra 16 do site oficial (mantenha o oficial).
4. Venues: fundi vn_venue_arena_nicnet em vn_venue_santa_cruz_ribeirao (Arena Nicnet é o naming rights do próprio Estádio Santa Cruz). Use o id vn_venue_santa_cruz_ribeirao daqui pra frente.
5. Arena (pendente desde o v0.6): perfis com 21 jogadores e 12 técnicos (só nome, período, função e 4–6 evidências de ESTILO — não precisa de perguntas nem notas), 15 carreiras históricas no lugar de atuais, Túlio em REVIEW, ≥5 escalações anteriores a 2000 e ≥10 cartas do Manto com estreia antes de 2005.

Próximo lote do Passaporte: 2019, depois seguindo para trás até 1943.
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

## 8. Armadilhas conhecidas

- `tooling/multiclub/test_*.mjs` **reescreve** artefatos rastreados em `archive/` e `data_export/`: restaurar com `git checkout` antes de commitar. 13 dessas auditorias **já falham no HEAD**. Para saber se algo é regressão, compare com uma worktree limpa; não assuma.
- No Windows, criar app no Firebase CLI funciona pelo PowerShell (`npx firebase-tools ...`); pelo Git Bash deu erro de `C:\Program`.
- No pbxproj iOS, clonar entradas linha a linha: regex multi-linha já estragou o arquivo.
- Golden temporário: a fonte do Flutter no cache é `roboto-*.ttf` (minúsculo); a imagem precisa de `tester.runAsync` pra decodificar. Nunca commitar.
- A cadeia de migrations quebrava num projeto zerado (trigger duplicado). Foi corrigida em `777fded`: sempre testar projeto novo no simulador.
