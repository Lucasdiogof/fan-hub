# Roteiro de pesquisa — Pesquisa do flavor Vila Nova (Fan Hub)

> Copie tudo abaixo da linha e cole na ferramenta de pesquisa.

---

Você vai atuar como **pesquisador de dados esportivos e editor de conteúdo** para um app Flutter multi-clube chamado **Fan Hub**. O app já roda em produção para dois clubes (Goiás EC e Red Bull Bragantino), cada um como um *flavor* separado. Agora vamos criar o terceiro flavor: **Vila Nova Futebol Clube (Goiânia-GO)**.

O trabalho tem duas etapas:

1. **Etapa 1 — Pesquisa:** você levanta todos os dados listados abaixo e me entrega um **pacote de conteúdo** (arquivos JSON + um README), no formato exato descrito aqui.
2. **Etapa 2 — Prompts de implementação:** depois do pacote aprovado, você escreve uma sequência de prompts, **um por fase**, que eu vou colar no ambiente de desenvolvimento (que tem acesso ao repositório e já conhece a arquitetura). Detalhes no fim deste documento.

Não comece a Etapa 2 antes de eu aprovar a Etapa 1.

## Regras gerais (valem para tudo)

1. **Nunca invente.** Todo dado precisa de uma fonte. Quando não achar, deixe `null` e registre a lacuna. Um campo vazio e honesto vale mais que um preenchido por suposição.
2. **Toda entrada leva `status`:** `READY` (confirmado, pode publicar), `REVIEW` (tem fonte, mas com dúvida ou conflito) ou `GAP` (não encontrado). No app só entra `READY`.
3. **Toda entrada leva fonte:** `source_name` + `source_url` (ou `source_hint` quando for livro/jornal impresso sem URL).
4. **Conflitos ficam documentados, não resolvidos no chute.** Se duas fontes divergem (placar, data, número de gols), registre as duas em `conflicts` e marque `REVIEW`.
5. **Vila Nova e Goiás são rivais.** Nunca reaproveite texto, foto, dado ou fonte do Goiás como se fosse do Vila. Quando um jogo for o clássico, ele entra normalmente no Passaporte, mas do ponto de vista do Vila Nova.
6. **Separe título de campanha.** Vice-campeonato, 3º lugar e acesso **não são títulos**. Eles vão em `historical_campaigns`, nunca em `titles`.
7. **Estádio nunca é inferido pelo mandante.** Só preencha o estádio de uma partida com confirmação específica daquele jogo (ficha, súmula, jornal da época). Se não houver, use `stadium: null` e `stadium_status: "UNKNOWN"`.
8. **Não reproduza letras de música protegidas por direitos autorais.** Para hino e cânticos, entregue só metadados (título, autores, ano, link oficial). Eu decido depois se entra letra.
9. **Fotos e escudos:** não baixe nem embuta imagens. Entregue a **URL da fonte oficial** (site do clube, loja oficial, Wikimedia com a licença indicada) para eu baixar.
10. **Datas em ISO** (`YYYY-MM-DD`), horário local de Brasília (`HH:MM`), e textos em **português do Brasil**.
11. **IDs estáveis:** use `snake_case` sem acento, com prefixo `vn_` (ex.: `vn_q_001`, `vn_career_01`, `vn_manto_01`). Depois de publicado, um ID nunca muda.
12. Data de corte do pacote: **a data em que você fechar a pesquisa.** Registre essa data em todo arquivo (`snapshot_date`).

## Estrutura do pacote de entrega

```
vila_nova_data/
  README.md                      ← resumo, regras editoriais, lacunas e conflitos em aberto
  manifest.json                  ← lista de arquivos + contagem de itens READY/REVIEW/GAP por arquivo
  data/
    club.json
    branding.json
    integrations.json
    history.json
    timeline.json
    honors.json                  ← titles + historical_campaigns
    stadiums.json
    songs.json
    idols.json
    leadership.json
    transparency.json
    partners.json
    squad_current.json
    membership.json
    store_products.json
    tickets.json
  passport/
    passport_audit_manifest.json ← matriz de cobertura ano a ano
    venues.json
    passport_<ano>.json          ← um arquivo por temporada
  arena/
    quiz.json
    lineups.json
    career_path.json
    guess_player.json
    player_identity.json
    tactical_identity.json
  sources/
    source_catalog.json          ← todas as fontes usadas, com o que cada uma cobre
  assets_todo.md                 ← lista de imagens que EU preciso baixar (com URL e para qual campo servem)
```

## O que pesquisar — dataset por dataset

### 1. `club.json` — identidade

```json
{
  "schema_version": 1,
  "snapshot_date": "YYYY-MM-DD",
  "app_code": "vilanova",
  "display_name": "Vila Nova Futebol Clube",
  "short_name": "Vila Nova",
  "fan_demonym": "…",               // como a torcida é chamada (ex.: "Colorado"? confirme)
  "nicknames": ["…"],               // apelidos do clube (ex.: "Tigre"? confirme) com origem
  "founded_on": "YYYY-MM-DD",
  "city": "Goiânia", "state": "GO", "country": "Brasil",
  "header_tagline": { "pt": "…", "en": "…", "es": "…" },  // frase curta de orgulho/identidade, se existir uma consagrada e usada oficialmente; senão null
  "name_history": [ { "name": "…", "from": "…", "through": "…" } ],  // nomes anteriores, fusões e refundações, se houver
  "identity_policy_note": "…",      // como tratar eras e nomes antigos no Passaporte
  "current_home_stadium": "…",
  "product_names_suggestion": {
    "arena_name": "…",              // nome do módulo de jogos (ex.: "Arena do Tigre"), só sugestão
    "passport_name": "…",
    "store_name": "…",              // nome oficial da loja do clube
    "membership_program_name": "…"  // nome OFICIAL do programa de sócio-torcedor
  }
}
```

### 2. `branding.json` — cores e escudo

- Cores **oficiais** do clube em hex, com a fonte (manual de marca, site oficial, estatuto). Se só existirem descrições textuais ("vermelho e branco"), informe as cores medidas no escudo oficial e marque `REVIEW`.
- URL do escudo oficial em maior resolução disponível, em vetor (SVG/PDF) se existir.
- Variações do escudo (monocromático, escudo histórico) e em que período cada uma foi usada.
- Não precisa montar paleta de tema claro/escuro: a implementação monta a partir das cores oficiais.

### 3. `integrations.json` — canais e IDs externos

| campo | o que é |
|---|---|
| `onefootball_team_id` + `onefootball_team_slug` | ID do Vila Nova no OneFootball. A URL é `onefootball.com/pt-br/time/<slug>-<id>`. Confirme navegando. |
| `onefootball_primary_competition_slug` + nome exibido | competição principal da temporada atual (Série A, B ou C) no OneFootball |
| `official_site_url` | site oficial |
| `news_page_url` | página de listagem de notícias do site oficial; descreva também a estrutura (URL de cada notícia, onde fica título, data, imagem, se há paginação ou RSS) |
| `instagram_url`, `youtube_url`, `tiktok_url`, `facebook_url`, `x_url` | perfis **oficiais** e verificados |
| `contact_whatsapp` | só se for canal oficial publicado pelo clube |
| `store_url` | loja oficial online |
| `membership_url` | site do sócio-torcedor |
| `tickets_url` | venda oficial de ingressos |
| `store_pickup_address` | endereço de loja física oficial, se existir (nome, rua, bairro, cidade, UF, CEP) |
| `ogol_team_id` e/ou outras bases | IDs do clube em bases de dados usadas no Passaporte |

### 4. `history.json` — história em seções

Entre 5 e 10 seções cronológicas: `{ "period": "1943–1960", "title": "…", "paragraphs": ["…", "…"] }`. Texto original seu, factual, sem copiar trechos de fontes. Cada seção tem uma lista de fontes.

### 5. `timeline.json` — linha do tempo

De 20 a 40 marcos: `{ "year": 1943, "title": "…", "description": "…", "source_name": "…", "source_url": "…" }`.

### 6. `honors.json` — títulos e campanhas

```json
{
  "titles": [ { "competition": "Campeonato Goiano", "years": [ … ], "status": "READY", "sources": [ … ] } ],
  "historical_campaigns": [ { "competition": "…", "year": 0, "result": "RUNNER_UP | THIRD | PROMOTION | …", "sources": [ … ] } ]
}
```

Inclua **todos** os títulos oficiais (estaduais, nacionais, torneios oficiais). Torneios amistosos vão separados em `friendly_tournaments`. Informe a contagem total por competição e aponte divergências entre fontes (ex.: federação vs. imprensa).

### 7. `stadiums.json`

Estádio atual e anteriores: nome oficial, apelido, cidade, capacidade, período em que o Vila mandou jogos lá e papel (`CURRENT_HOME`, `PREVIOUS_HOME`, `ALTERNATE`), com fontes.

### 8. `songs.json` — só metadados

Hino oficial e cânticos consagrados: `{ "id", "title", "category": "ANTHEM | CHANT", "authors", "year", "official_url" }`. **Sem letra.**

### 9. `idols.json` — ídolos

De 10 a 20 nomes:

```json
{ "id": "vn_idol_…", "name": "…", "position": "…", "period": "1975–1982",
  "tier": 1,                         // 1 = maior ídolo da história, 2 = ídolo, 3 = ícone ou destaque
  "evidence_explicit_idol": true,    // alguma fonte chama explicitamente de ídolo? (true/false)
  "description": "2–3 frases com os feitos concretos (títulos, gols, jogos)",
  "stats": { "matches": null, "goals": null, "source": "…" },
  "photo_source_url": "…", "status": "READY" }
```

### 10. `leadership.json` — diretoria

Presidente, vices, conselho deliberativo e fiscal, diretoria executiva e de futebol, no formato `sections[] → members[] { name, role, photo_url }`, com a data do mandato e a fonte (site oficial ou ata publicada).

### 11. `transparency.json` — transparência

Documentos públicos (balanços, demonstrações financeiras, orçamentos, estatuto): `topics[] → documents[] { title, document_date, pdf_url }`. Só links oficiais. Inclua também, em `highlights`, os números principais (receita líquida, resultado, dívida) por ano, **com a fonte**.

### 12. `partners.json` — patrocinadores

`{ "name", "tier": "MASTER | OFFICIAL | SUPPLIER | …", "category", "url", "logo_source_url", "since" }`. Só a temporada atual, com a fonte (site oficial, uniforme e anúncios).

### 13. `squad_current.json` — elenco atual

Elenco profissional completo da temporada atual:

```json
{ "id": "vn_…", "name": "nome de guerra", "full_name": "…", "shirt_number": 0,
  "position": "Goleiro | Lateral-direito | Zagueiro | …",
  "position_group": "Goleiros | Defensores | Meio-campistas | Atacantes",
  "birth_date": "YYYY-MM-DD", "nationality": "…", "height_cm": 0, "foot": "Destro | Canhoto | Ambidestro",
  "photo_source_url": "…", "instagram_url": "…",
  "club_history": [ { "period": "2019–2021", "team": "…", "loan": false } ],
  "status": "READY" }
```

Inclua também o técnico e a comissão principal, além das saídas e chegadas recentes (em `departures_recent`/`arrivals_recent`). O site oficial é a fonte principal; use Transfermarkt/oGol para conferência.

### 14. Passaporte — TODAS as partidas oficiais desde a fundação

Esta é a maior parte do trabalho. O Passaporte permite ao torcedor marcar os jogos a que foi. Precisamos de **todas as partidas oficiais do time profissional**, da fundação até a data de corte, incluindo os jogos já marcados do restante da temporada atual (com `status: "SCHEDULED"`).

**Elegibilidade:** só partidas oficiais do time principal. Amistosos, base, time B e sub-23 ficam de fora. Um W.O. sem placar também fica de fora, mas é listado em `excluded` com o motivo.

**Estratégia:** comece pelo ano mais recente e volte ano a ano. Cada ano é um lote fechado em `passport/passport_<ano>.json`. Antes de fechar o lote, confira o total de jogos por competição contra uma segunda fonte.

**Formato de cada partida:**

```json
{
  "id": "vn_<fonte>_<id_na_fonte>",
  "calendar_year": 2019,
  "competition": "Série B",
  "competition_code": "BRASILEIRO_B",
  "competition_edition": "Série B 2019",   // calendar_year e competition_edition são campos DIFERENTES (ex.: Brasileirão 2020 terminou em 2021)
  "round": "R12",                           // null se a fonte não expuser
  "date": "YYYY-MM-DD",
  "time": "HH:MM",                          // null se desconhecido; nunca chute
  "home_team": "…", "away_team": "…",
  "club_is_home": true,
  "neutral_site": false,
  "home_score": 0, "away_score": 0,
  "club_score": 0, "opponent_score": 0,
  "penalty_home_score": null, "penalty_away_score": null,
  "score_display": "1–0",
  "status": "FINISHED | SCHEDULED | POSTPONED | CANCELLED",
  "outcome": "WIN | DRAW | LOSS",
  "stadium": "…",
  "stadium_status": "MATCH_SPECIFIC | UNKNOWN",
  "venue_city": "…", "venue_state": "GO", "venue_country": "BR",
  "source_provider": "…", "source_match_id": "…", "source_url": "…",
  "source_confidence": "HIGH | MEDIUM | LOW",
  "data_notes": null
}
```

**`venues.json`:** um registro por estádio que aparece no Passaporte: `{ id, canonical_name, display_name, aliases[], city, state, country, latitude, longitude }`.

**`passport_audit_manifest.json`:** uma matriz com uma linha por ano, contendo:
- `expected_total` (segundo qual fonte), `found_total`, `stadium_confirmed`, `stadium_unknown`;
- a contagem por competição;
- `coverage_status`: `CLOSED`, `PARTIAL` ou `NO_SOURCE`;
- as fontes usadas no ano.

Para as décadas antigas (1940–1970), é aceitável que alguns anos fiquem `PARTIAL` ou `NO_SOURCE`. O que importa é **documentar honestamente** a lacuna, nunca preencher por inferência. Sugestões de fonte: oGol, RSSSF Brasil, Futebol de Goyaz, acervos digitalizados de jornais goianos (O Popular, Diário da Manhã, Hemeroteca Digital da Biblioteca Nacional) e a Federação Goiana de Futebol.

**Clássico com o Goiás:** o pacote do Goiás já tem esses jogos. Mesmo assim, pesquise-os de forma independente, pelas fontes do Vila Nova. Se um placar ou data divergir do que é público sobre o clássico, registre em `conflicts`.

### 15. Arena — os 6 jogos

Metas mínimas, iguais às do Bragantino. Se o volume de fatos confiáveis permitir, pode entregar mais.

**a) `quiz.json`: Quiz (mínimo 45 perguntas READY)**
```json
{ "id": "vn_q_001", "difficulty": "EASY | MEDIUM | HARD",
  "question": "…", "options": ["…","…","…","…"], "correct_index": 0,
  "fact_key": "foundation_year", "source_hint": "…", "status": "READY" }
```
Use cerca de 1/3 para cada dificuldade, sempre 4 opções plausíveis e 1 correta. Nenhuma pergunta pode depender de fato em disputa. Mande as perguntas duvidosas para `review_candidates`.

**b) `lineups.json`: Adivinhe a Escalação (mínimo 15 partidas READY)**

Jogos marcantes (finais, títulos, acessos, clássicos históricos), cada um com o **XI titular completo e confirmado**:
```json
{ "id": "vn_lineup_01", "date": "YYYY-MM-DD", "competition": "…", "season": "…", "phase": "Final - jogo de volta",
  "venue": "…", "home_team": "…", "away_team": "…", "home_score": 0, "away_score": 0,
  "coach": "…", "formation": "4-4-2", "formation_confidence": "confirmed | probable | estimated",
  "xi": [ { "pos": "GOL", "name": "nome completo", "answer": "NOME DE GUERRA EM MAIÚSCULAS", "aliases": ["…"] } ],
  "status": "READY", "sources": [ … ] }
```
Nunca infira o número da camisa. Posições disponíveis: `GOL, LD, ZAG, LE, VOL, MC, MEI, PD, PE, ATA`.

**c) `career_path.json`: Adivinhe pela Carreira (mínimo 30 jogadores)**

Jogadores que passaram pelo Vila Nova, com carreira conhecida o suficiente para o torcedor adivinhar pela sequência de clubes:
```json
{ "id": "vn_career_01", "answer": "Nome de guerra", "accepted_answers": ["…","…"],
  "position": "Atacante",
  "club_career": [ { "period": "2010–2012", "team": "…", "appearances": null, "goals": null, "loan": false, "is_club": true } ],
  "national_teams": [ { "period": "…", "team": "Brasil", "appearances": null, "goals": null } ],
  "status": "READY", "sources": [ … ] }
```
`is_club: true` marca as passagens pelo Vila Nova. Misture ídolos antigos, jogadores recentes e gente que saiu do Vila e fez carreira fora.

**d) `guess_player.json`: Quem Vestiu o Manto (mínimo 50 cartas)**
```json
{ "id": "vn_manto_01", "name": "…", "display_name": "…", "aliases": ["…"],
  "position": "gol | ld | zag | le | vol | mc | mei | pd | pe | ata",
  "shirt_number": 0, "academy_club": "…", "nationality_code": "BR", "nationality_name": "Brasil",
  "club_debut_year": 2021, "photo_source_url": "…", "status": "READY", "missing_fields": [] }
```
Misture o elenco atual com nomes históricos. Para os históricos, a foto pode ficar pendente (vai para `assets_todo.md`); isso não bloqueia a entrega dos dados.

**e) `player_identity.json`: Que jogador do Vila Nova você seria? (10 perguntas, 10 perfis)**

**f) `tactical_identity.json`: Que técnico do Vila Nova você seria? (10 perguntas, 6 perfis)**

Os dois usam a mesma estrutura:
```json
{
  "dimensions": ["dim_1", "…"],     // 8 dimensões (jogador: visão/criação, 1x1, presença de área, segurança defensiva, leitura tática, verticalidade, liderança, intensidade; técnico: posse, pressão, transição, bola parada, rotação de elenco, gestão de grupo…)
  "profiles": [ { "id": "…", "name": "jogador ou técnico REAL da história do clube", "position": "…",
                  "traits": [0-10 × 8, na ordem de dimensions], "identity": ["3–4 descritores"],
                  "evidence": ["fatos que justificam os traits"] } ],
  "questions": [ { "id": "q1", "text": "…",
                   "options": [ { "text": "…", "effects": { "dim_x": 3, "dim_y": 1 } } ] } ],
  "scoring_rules": { "method": "weighted_trait_distance", "result_floor": 42, "winner_range": [82, 96],
                     "minimum_gap_winner_to_second": 7, "minimum_gap_between_top3": 4 }
}
```
Perfis com traits bem distintos entre si: dois perfis quase iguais geram porcentagens empatadas. Cada `trait` precisa de `evidence` factual.

### 16. `membership.json` — Sócio-torcedor

Nome oficial do programa, URL e todos os planos: `{ id, name, tagline, prices: [{ label: "Mensal", value }, { label: "Anual", value }], includes_stadium_access, allowed_sectors[], benefits[], highlight }`. Inclua também o regulamento em seções `{ title, paragraphs[] }` (resuma com suas palavras e informe o link do documento oficial), a data de consulta e a fonte.

### 17. `store_products.json` — Loja

Catálogo da loja oficial online, com **até 150 produtos** e prioridade para camisas, agasalhos e acessórios mais vendidos. Campos por produto: `id, slug, name, shortDescription, description, brand, reference, categories[], collections[], audience, productType, price, originalPrice, installments, images[] (URLs), thumbnail, variations[] (tamanhos/cores), isFeatured, isNew, specifications, sourceUrl`. Preços como número, em reais.

### 18. `tickets.json` — Ingressos

Setores do estádio atual, com nome, faixa de preço de inteira e meia de jogos recentes e as regras de meia-entrada e de prioridade do sócio. Registre a fonte e a data. O app usa isso só como demonstração: não precisa de integração real.

## `assets_todo.md`

Tabela com todas as imagens de que o app precisa e que eu vou baixar ou produzir: escudo (vetor + PNG grande), foto do estádio, fotos dos ídolos, fotos do elenco atual, fotos dos jogadores do "Quem Vestiu o Manto", logos dos patrocinadores e banners da loja. Colunas: `para que serve | URL da fonte | licença | observação`.

## Fora do escopo desta pesquisa (não precisa buscar)

Chaves e projetos de Supabase/Firebase, configuração de build Android/iOS/web, Worker da Cloudflare e textos de interface do app. Isso é implementação, que eu faço.

## Como entregar a Etapa 1

- Entregue um arquivo por vez, ou um ZIP com a estrutura acima.
- Por ser grande, o Passaporte pode vir em lotes (por década, por exemplo). A cada lote, atualize o `passport_audit_manifest.json` e me diga o percentual de cobertura.
- Ao final, o `README.md` deve listar: o que está READY, o que ficou em REVIEW (e por quê), os GAPs e os conflitos que precisam da minha decisão.

---

## Etapa 2 — Prompts de implementação (só depois que eu aprovar o pacote)

O ambiente de desenvolvimento tem acesso ao repositório `fan-hub` e **já conhece a arquitetura**: `ClubConfig`, `clubRegistry`, flavors por clube, um projeto Supabase por clube, tabelas `club_id`-scoped e as mesmas telas do Goiás e do Bragantino. Os seus prompts **não devem ditar código**. Eles dizem **o quê** fazer, **com quais arquivos do pacote** e **qual critério de aceite**. O desenvolvimento decide o **como**, seguindo o padrão que ele já usou no Bragantino.

Vou colocar o pacote em `docs/vila_nova_data/` no repositório. Referencie os arquivos por esse caminho.

Escreva **um prompt por fase**, nesta ordem:

| Fase | Escopo |
|---|---|
| F0 | Infraestrutura: flavor `vilanova` (Android/iOS/web), app no Firebase Fan Hub, projeto Supabase próprio, linha em `public.clubs`, Worker `wrangler.vilanova.toml`. Deixe claro que criar o projeto e baixar credenciais é tarefa minha; o desenvolvimento prepara o resto e me diz o que falta. |
| F1 | `vilanovaClubConfig` mínimo registrado no `clubRegistry`, com capabilities **desligadas**, identidade, branding e integrações do pacote |
| F2 | Assets: escudo, fundo de login, ícones do app e da web |
| F3 | Conteúdo institucional: história, timeline, títulos/campanhas, ídolos, parceiros, estádios; liga `hasClubContent`/`hasPartners` |
| F4 | Diretoria e transparência (Supabase) + elenco atual (`squad_members`) |
| F5 | Arena, com **uma subfase por jogo** (quiz, escalação, carreira, quem vestiu o manto, perfil de jogador, perfil de técnico); cada uma entra em `enabledArenaGames` só depois de validada |
| F6 | Passaporte: venues + partidas, **um seed SQL por ano**, validação contra o `passport_audit_manifest.json`; liga `hasPassport` |
| F7 | Sócio-torcedor, Loja e Ingressos (modo `demo`) |
| F8 | Jogos, notícias e redes sociais: IDs do OneFootball, parser de notícias do site oficial, feed social; liga `hasMatches`/`hasNews`/`hasSocial` |
| F9 | QA de isolamento: nenhum texto, asset ou dado do Goiás/Bragantino aparece no Vila Nova e vice-versa; build dos 3 flavors; testes verdes |

Cada prompt deve conter:
- **Objetivo** em 1–2 frases;
- **Entradas** (arquivos do pacote);
- **Regras**: não inventar; `REVIEW`/`GAP` não entram; seeds SQL idempotentes; não mexer nos flavors Goiás/Bragantino;
- **Critério de aceite** verificável (contagens esperadas, testes, build);
- a instrução final: **"Ao terminar, faça o commit da fase, me mostre o resumo e PARE, aguardando a próxima fase."**

Não junte fases num prompt só. Se alguma fase depender de algo que ainda é GAP no pacote, diga isso no prompt e indique o que deve ficar desligado.
