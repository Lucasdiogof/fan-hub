# 15 — Relatório de Reconciliação de Jogadores (v3.1)

> **Gerado integralmente por script — zero prosa manual.** Pipeline: `reconcile_players.mjs` (motor automático, 6 fontes incluindo `goias_players.dart`, produz `candidates.json`) → `apply_overrides.mjs` (funde com `tooling/multiclub/player_reconciliation_overrides.json`, a ÚNICA fonte das decisões humanas, produz `canonical_people_candidates.json` + `canonical_aliases.json` + `canonical_stats.json`, com invariantes verificadas de verdade) → este script (`render_reconciliation_report.mjs`), que só formata o que o anterior já calculou. Rodar os dois em sequência sempre reproduz este documento byte-a-byte. Nenhum INSERT gerado. Nenhuma migration executada. Nenhum Flutter alterado. Ver `16_live_data_architecture.md` pro desenho de dado vivo motivado por este relatório.

## Fórmula do total final

```
176 clusters automáticos (5 fontes originais, sem goias_players.dart)
  - 3 consumidos pelos splits (Danilo/Nicolas/Michael)
  + 6 pessoas resultantes desses 3 splits
  = 179 pessoas (universo SEM goias_players.dart)

+ 215 nomes de goias_players.dart dobrados pro MESMO motor automático (6ª fonte)
  - 99 uniram com um cluster JÁ EXISTENTE (corroboram, não criam pessoa nova)
  = 116 formaram cluster próprio (SINGLE_SOURCE — não existem em nenhuma das outras 5 fontes)

- 0 deduplicações adicionais precisas depois disso (invariantes confirmam: nenhum canonicalId
  duplicado, nenhum source record mapeado pra 2 pessoas sem ser split contextual explícito)

= TOTAL FINAL DE PEOPLE: 295
```

Isso substitui a resposta anterior (179 pessoas + "66 novas pessoas" reportadas à parte) — não existe mais contagem paralela: os 215 nomes de `goias_players.dart` agora entram no MESMO union-find do motor automático (`reconcile_players.mjs`), então `canonical_people_candidates.json` já representa o universo inteiro numa passada só.

## Números finais (pós-overrides, 6 fontes)

```
TOTAL DE PESSOAS CANÔNICAS          295
  (motor automático produziu 292 candidatos, já incluindo goias_players.dart; overrides desmembraram 3 cluster(s) DISTINCT_PEOPLE em pessoas separadas)

EXACT_IDENTITY                      93
PROBABLE_IDENTITY                   1
AMBIGUOUS_IDENTITY                  83
DISTINCT_PEOPLE (resolvidos)        3 cluster(s) → 6 pessoa(s) canônica(s) separada(s)
DISTINCT_PEOPLE (NÃO resolvidos)    0  (nenhum — todos os clusters DISTINCT_PEOPLE do motor automático têm override)
SINGLE_SOURCE                       118
```

```
ORIGEM DA CLASSIFICAÇÃO
  HUMAN_VERIFIED (identidade definida/alterada por override)  9
  AUTOMATIC + anotação humana (identidade não mudou, dado extra anexado)  2
  AUTOMATIC sem revisão humana                                  284
```

## AMBIGUOUS_IDENTITY: nenhuma nova, todas já contadas antes de dobrar o autocomplete

O motor automático produzia **86 AMBIGUOUS_IDENTITY** com as 5 fontes originais (176 candidatos). Com `goias_players.dart` dobrado como 6ª fonte (292 candidatos), o número continua **exatamente 83** — nenhuma ambiguidade NOVA foi criada. Isso porque, dos 215 nomes do Dart:

- 99 uniram com um cluster já existente por match EXATO de string completa (nome ou alias) — o mesmo critério rigoroso que o motor já usa pra tudo, nunca sobreposição parcial de palavra;
- 116 não uniram com NADA e viraram `SINGLE_SOURCE` novo (categoria separada, não é ambiguidade);
- só 2 desses 99 caíram em clusters que já eram `AMBIGUOUS_IDENTITY`/`DISTINCT_PEOPLE` ANTES do Dart entrar (Dieguinho e Nicolas — ver overrides abaixo) — corroboraram o cluster existente, não criaram um novo.

**A resposta anterior reportava "50 ambíguos" do autocomplete — esse número vinha de um script paralelo (`reconcile_goias_players_dart.mjs`, agora removido) que usava sobreposição de TOKEN parcial como sinal de "ambíguo", um critério mais frouxo do que o union-find real do motor (que só une por string COMPLETA idêntica).** Rodando dentro do motor de verdade, praticamente nenhum desses 50 se qualifica como ambiguidade real — a maioria simplesmente não tem nenhuma correspondência forte o bastante pra unir com nada, e vira `SINGLE_SOURCE`. Isso não é uma correção de contagem por conveniência — é o motor rigoroso (mesma lógica usada pra todo o resto do dataset) substituindo um heurístico mais fraco que eu tinha escrito só pra essa auditoria paralela.

## Números do motor automático por fonte (contexto)

```
TOTAL DE IDENTIDADES CANDIDATAS (6 fontes)   292
EXACT_IDENTITY                                85
PROBABLE_IDENTITY                             0
AMBIGUOUS_IDENTITY                            86
DISTINCT_PEOPLE                               3
SINGLE_SOURCE                                 118
```

Metodologia do motor automático (união por STRING COMPLETA idêntica — nunca palavra/token isolado — corroboração por par, período por órfão, impossibilidade cronológica) inalterada desde o v3, só com a 6ª fonte somada — ver `tooling/multiclub/reconcile_players.mjs` pra implementação exata, é o comentário de topo do arquivo. Um ajuste real de bug nesta revisão: fontes estruturalmente rasas (`goias_players_dart`, sem posição/período/partida por natureza) deixaram de poder REBAIXAR a confiança de um cluster já bem corroborado por outras fontes — antes do fix, dobrar o autocomplete rebaixava 40 clusters de `EXACT_IDENTITY` pra `PROBABLE_IDENTITY` só por ganhar uma fonte sem dado nenhum, o que é o oposto do efeito desejado.

## Decisões humanas (`player_reconciliation_overrides.json`)

8 overrides registrados, todos aplicados com sucesso pelo pipeline (ver `canonical_stats.json.overridesApplied`). Cada um cita a evidência que sustenta a decisão — ver o JSON fonte pra campos completos, esta seção é a renderização legível.

### Tabela resumo

| Caso | Source records | Resultado | People geradas | Status final | Confiança |
|---|---|---|---|---|---|
| Danilo | `career_players:danilo`<br>`guess_players:danilo_cunha_da_silva`<br>`lineup_matches:danilo`<br>`squad_members:danilo` | DESMEMBRADO em 2 pessoas: **Danilo Cunha da Silva** + **Danilo Gabriel de Andrade** | 2 | `EXACT_IDENTITY`, `EXACT_IDENTITY` | 0.98, 0.9 |
|   ↳ **Danilo Cunha da Silva** | `squad_members:danilo`<br>`guess_players:danilo_cunha_da_silva` | pessoa própria | 1 | `EXACT_IDENTITY` | 0.98 |
|   ↳ **Danilo Gabriel de Andrade** | `career_players:danilo`<br>`lineup_matches:danilo` (2 partida(s)) | pessoa própria | 1 | `EXACT_IDENTITY` | 0.9 |
| Nicolas | `guess_players:nicolas_vichiatto_da_silva`<br>`lineup_matches:nicolas`<br>`squad_members:nicolas`<br>`goias_players_dart:178` | DESMEMBRADO em 2 pessoas: **Nicolas Vichiatto da Silva** + **Nicolas Godinho Johann** | 2 | `EXACT_IDENTITY`, `EXACT_IDENTITY` | 0.95, 0.9 |
|   ↳ **Nicolas Vichiatto da Silva** | `squad_members:nicolas`<br>`guess_players:nicolas_vichiatto_da_silva`<br>`lineup_matches:nicolas` (2 partida(s)) | pessoa própria | 1 | `EXACT_IDENTITY` | 0.95 |
|   ↳ **Nicolas Godinho Johann** | `lineup_matches:nicolas` (2 partida(s)) | pessoa própria | 1 | `EXACT_IDENTITY` | 0.9 |
| Michael | `career_players:michael`<br>`guess_players:michael`<br>`lineup_matches:michael`<br>`player_identity_references:michael` | DESMEMBRADO em 2 pessoas: **Michael Richard Delgado de Oliveira** + **Michael (1999, elenco do acesso à Série A)** | 2 | `EXACT_IDENTITY`, `PROBABLE_IDENTITY` | 0.9, 0.4 |
|   ↳ **Michael Richard Delgado de Oliveira** | `career_players:michael`<br>`guess_players:michael`<br>`player_identity_references:michael` | pessoa própria | 1 | `EXACT_IDENTITY` | 0.9 |
|   ↳ **Michael (1999, elenco do acesso à Série A)** | `lineup_matches:michael` (1 partida(s)) | pessoa própria | 1 | `PROBABLE_IDENTITY` | 0.4 |
| dieguinho | `guess_players:dieguinho`<br>`lineup_matches:dieguinho`<br>`goias_players_dart:174` | RECLASSIFICADO: **Jackson Diego Ibraim Fagundes** | 1 | `EXACT_IDENTITY` | 0.9 |
| erik | `career_players:erik`<br>`guess_players:erik`<br>`player_identity_references:erik` | RECLASSIFICADO: **Erik Nascimento de Lima** | 1 | `EXACT_IDENTITY` | 0.9 |
| fabiano | `guess_players:fabiano`<br>`lineup_matches:fabiano` | RECLASSIFICADO: **Fabiano Cézar Viegas** | 1 | `EXACT_IDENTITY` | 0.85 |
| tadeu | `squad_members:tadeu`<br>`career_players:tadeu`<br>`guess_players:tadeu_antonio_ferreira`<br>`lineup_matches:tadeu`<br>`player_identity_references:tadeu` | ANOTADO (identidade mantida): **Tadeu Antônio Ferreira** | 1 | `EXACT_IDENTITY` | 0.95 |
| walter | `career_players:walter`<br>`guess_players:walter`<br>`lineup_matches:walter`<br>`player_identity_references:walter` | ANOTADO (identidade mantida): **Walter Henrique da Silva** | 1 | `EXACT_IDENTITY` | 0.95 |

### `danilo_split` — DESMEMBRAR (pessoas diferentes)

**Motivo**: Confirmado por fonte externa: duas pessoas reais e documentadas, não colisão de dado. squad_members.birth_date=2007-05-12 já tornava cronologicamente impossível a passagem 1999-2003 de career_players, o que o motor automático já havia detectado sozinho (DISTINCT_PEOPLE, confiança 0.05) — esta evidência externa confirma a conclusão automática, não a contradiz.

**Evidência**:
  - **[externa]** [Danilo Gabriel de Andrade — meia, passagem histórica pelo Goiás](https://pt.wikipedia.org/wiki/Danilo_Gabriel_de_Andrade)
  - **[externa]** [Danilo Cunha da Silva — lateral-esquerdo, elenco atual](https://www.transfermarkt.com.br/danilo-cunha/profil/spieler/1257107)
  - **[interna]** As 2 aparições de lineup_matches:danilo (partidas 2003_juventude_brA_reacao e 2003_santos_brA_reacao, ambas 2003-01-01) caem inteiramente dentro do período 1999-2003 de career_players — pertencem 100% ao Danilo Gabriel de Andrade, nenhuma divisão adicional necessária dentro de lineup_matches.

**Resultado**: 
- **undefined** — `EXACT_IDENTITY` (confiança 0.98) — membros: `squad_members:danilo`, `guess_players:danilo_cunha_da_silva`
- **undefined** — `EXACT_IDENTITY` (confiança 0.9) — membros: `career_players:danilo`, `lineup_matches:danilo` (só partidas: 2003_juventude_brA_reacao, 2003_santos_brA_reacao)
  - _Período 1999-2003 pelo Goiás ainda não auditado item a item contra a Wikipédia — só a NÃO-identidade com o Danilo atual foi confirmada. Ver pendingVerification._

**Pendência explícita**: Auditar o período exato 1999-2003 de career_players:danilo contra a fonte Wikipédia antes do INSERT final.

### `nicolas_split` — DESMEMBRAR (pessoas diferentes)

**Motivo**: Confirmado por fonte externa: duas pessoas reais. As 4 aparições de lineup_matches:nicolas se dividem exatamente em 2 grupos por data, sem ambiguidade. Desde v3.1, goias_players_dart:178 ('Nicolas' bare, autocomplete) uniu com este mesmo cluster automático — mas SEM nenhum dado (posição/data/camisa) pra decidir qual dos dois Nicolas ele representa, então fica em unassignedMembers (nunca atribuído a um lado só) — é exatamente o caso que motivou o pedido de AMBIGUOUS_ALIAS no dataset canônico.

**Evidência**:
  - **[externa]** [Nicolas Godinho Johann — atacante, Goiás 2021/2022](https://www.transfermarkt.com.br/nicolas/profil/spieler/186408)
  - **[externa]** [Nicolas Vichiatto da Silva — lateral-esquerdo, Goiás 2026-atual, camisa 6](https://www.transfermarkt.com.br/nicolas/profil/spieler/442258)
  - **[interna]** lineup_matches:nicolas tem 4 aparições: 2021-10-15 e 2021-11-22 (ATA, camisa 9) vs. 2026-03-07 e 2026-03-15 (LE, camisa 6). O grupo 2026 bate exatamente com squad_members:nicolas (camisa 6, lateral-esquerdo).

**Resultado**: 
- **undefined** — `EXACT_IDENTITY` (confiança 0.95) — membros: `squad_members:nicolas`, `guess_players:nicolas_vichiatto_da_silva`, `lineup_matches:nicolas` (só partidas: 2026_atleticogo_goiano_final_ida, 2026_atleticogo_goiano_final_volta)
- **undefined** — `EXACT_IDENTITY` (confiança 0.9) — membros: `lineup_matches:nicolas` (só partidas: 2021_csa_brB_g4, 2021_guarani_brB_acesso)
  - _Sem nenhuma outra fonte associada hoje (não está em career_players/guess_players) — se vier a ser incluído em outra fonte no futuro, associar por este nome._

**Membros NÃO atribuídos a nenhum dos lados** (viram alias ambíguo — ver seção "Aliases ambíguos" abaixo, nunca fundidos silenciosamente):
- `goias_players_dart:178` — Entrada 'Nicolas' (bare, sem posição/data/camisa) do autocomplete — não há nenhum dado nesta fonte pra decidir entre Nicolas Vichiatto da Silva e Nicolas Godinho Johann. Fica fora de AMBOS os `members` — o alias 'nicolas' é modelado como AMBIGUOUS_ALIAS (aponta pras duas pessoas, nunca resolvido sozinho) em canonical_aliases.json, nunca fundido silenciosamente num dos dois lados.

### `michael_split` — DESMEMBRAR (pessoas diferentes)

**Motivo**: Investigação nos dados já exportados (seguindo a instrução do usuário de checar a data da partida): a única aparição de lineup_matches:michael é de 1999-12-12 (final do acesso da Série B de 1999) — 18 anos antes da passagem de Michael Richard Delgado de Oliveira (2017-2019). A data NÃO confirma a fusão que a instrução original condicionava — reportado honestamente como evidência CONTRA associar as duas.

**Evidência**:
  - **[interna]** career_players + guess_players + player_identity_references concordam em período 2017-2019, camisa 11, posição ponta/atacante — núcleo confirmado (Michael Richard Delgado de Oliveira).
  - **[interna]** lineup_matches:michael é a partida 1999_santacruz_brB_titulo, 1999-12-12 — fora de qualquer sobreposição plausível com 2017-2019.

**Resultado**: 
- **undefined** — `EXACT_IDENTITY` (confiança 0.9) — membros: `career_players:michael`, `guess_players:michael`, `player_identity_references:michael`
- **undefined** — `PROBABLE_IDENTITY` (confiança 0.4) — membros: `lineup_matches:michael` (só partidas: 1999_santacruz_brB_titulo)
  - _Nome completo não determinado — sem outra fonte associada. Não confundir com o Michael moderno (2017-2019) em nenhuma exportação futura._

### `dieguinho_reclassify` — RECLASSIFICAR (mesma pessoa, identidade automática estava errada)

**Motivo**: O Dieguinho do Goiás é Jackson Diego Ibraim Fagundes — já atuou como volante, lateral-direito e meio-campista/meia de criação. O conflito de posição (LD em guess_players vs. MC em lineup_matches) é polivalência real, não sinal de identidade diferente. Desde v3.1, goias_players_dart:174 ('Dieguinho' bare) uniu com este mesmo cluster automático — sem ambiguidade aqui (reclassify não desmembra, o registro só corrobora o nome, sem precisar de atribuição por partida/período).

**Evidência**:
  - **[externa]** Fornecido pelo usuário: Jackson Diego Ibraim Fagundes, já jogou como volante/lateral-direito/meia.

**Resultado**: mantido como 1 pessoa — **undefined** — `EXACT_IDENTITY` (confiança 0.9), era `AMBIGUOUS_IDENTITY` no motor automático.
- **Modelo de posição**: primária = meio-campo; secundárias = lateral-direito, volante. Posição por partida (lineup_matches) continua granular — nunca decide identidade sozinha quando já há corroboração de outro tipo.

### `erik_reclassify` — RECLASSIFICAR (mesma pessoa, identidade automática estava errada)

**Motivo**: Confirmado por fonte externa + pela própria carreira completa já presente em career_players (não só o trecho is_goias): Erik Nascimento de Lima, Goiás 2013-2015, camisa 11. career_players.club_career já lista 2019-2020 no Yokohama F. Marinos (Japão), incompatível com qualquer passagem 2020 no Goiás — o "anos 2020" de player_identity_references está incorreto.

**Evidência**:
  - **[externa]** Fornecido pelo usuário: Erik Nascimento de Lima, Goiás profissional 2013-2015, camisa 11; em 2020 estava no futebol japonês.
  - **[interna]** career_players:erik.club_career (carreira completa, não filtrada por is_goias) já mostra 2019-2020 Yokohama F. Marinos, 2021-2022 Changchun Yatai, 2023-2026 de volta ao Japão — sem nenhuma passagem 2020 no Goiás em lugar nenhum do próprio dataset.

**Resultado**: mantido como 1 pessoa — **undefined** — `EXACT_IDENTITY` (confiança 0.9), era `AMBIGUOUS_IDENTITY` no motor automático.
- **Correção de conteúdo pendente** (fora do escopo desta reconciliação): `lib/features/arena/games/player_identity/domain/player_identity_references.dart`, campo `period (id: erik)` — valor atual "anos 2020" — Não corresponde a nenhuma passagem real pelo Goiás — corrigir quando a migração de dado for implementada, fora do escopo desta reconciliação.

### `fabiano_reclassify` — RECLASSIFICAR (mesma pessoa, identidade automática estava errada)

**Motivo**: Investigação nos dados já exportados: as 3 aparições de lineup_matches:fabiano são todas de 2006 (Copa Libertadores), ao lado de Harlei/Rogério Corrêa/Júlio Santos/Cléber Goiano/Danilo Portugal/Romerito. guess_players:fabiano tem academy_club=Flamengo, goias_debut_year=2006, posição zag — bate exatamente com esse grupo (defensor que jogou 1x de MC, mesmo padrão de polivalência do Dieguinho). Nome completo pesquisado e confirmado nesta rodada (v3.1, item 10 do pedido): Fabiano Cézar Viegas.

**Evidência**:
  - **[interna]** lineup_matches:fabiano: 2006_newells_lib_grupos (2006-01-01, DEF), 2006_cuenca_lib_1fase (2006-02-01, MC), 2006_estudiantes_lib_oitavas_volta (2006-05-04, DEF) — todas a mesma campanha da Libertadores 2006.
  - **[interna]** guess_players:fabiano.goias_debut_year=2006 corrobora exatamente.
  - **[externa]** [Fabiano Cézar Viegas — 'o jogador com mais jogos disputados pelo Goiás na Copa Libertadores da América de 2006' (10 partidas), passagem 2006-2007, zagueiro.](https://www.futeboldegoyaz.com.br/jogadores/3714/jogador)
  - **[externa]** [Fabiano Cézar Viegas, nascido 04/08/1975, zagueiro — Flamengo (1993-1999) → Atlético-PR → Kashima Antlers/Vegalta Sendai (Japão) → Atlético-PR → Flamengo → Goiás (2006).](https://pt.wikipedia.org/wiki/Fabiano_Cezar_Viegas)
  - **[externa]** [BDFutbol — corrobora identidade e posição (central defender).](https://www.bdfutbol.com/en/j/j33761.html)

**Resultado**: mantido como 1 pessoa — **undefined** — `EXACT_IDENTITY` (confiança 0.85), era `AMBIGUOUS_IDENTITY` no motor automático.
- **Proveniência biográfica, campo a campo** (nunca conflatar clube de formação com clube anterior ao Goiás):
  - `fullName`: **Fabiano Cézar Viegas** — fonte: external (futeboldegoyaz.com.br/jogadores/3714; pt.wikipedia.org/wiki/Fabiano_Cezar_Viegas; bdfutbol.com/en/j/j33761) [3 fontes externas independentes concordam]
  - `birthDate`: **1975-08-04** — fonte: external (futeboldegoyaz.com.br/jogadores/3714; pt.wikipedia.org/wiki/Fabiano_Cezar_Viegas) [2 fontes externas independentes concordam]
  - `position`: **zagueiro (central defender)** — fonte: local+external (guess_players.fabiano.position=zag (local); bdfutbol.com/en/j/j33761 (externa, 'central defender'))
  - `formationClub`: **Flamengo** — fonte: external (pt.wikipedia.org/wiki/Fabiano_Cezar_Viegas). _clube onde iniciou a carreira profissional, 1993, aos 18 anos — NÃO o clube imediatamente anterior ao Goiás_
    - _Campo local equivalente_: guess_players.fabiano.academy_club='Flamengo' — CORRETO como clube de formação, o campo local já significa isso; o erro foi meu, na análise anterior, ao apresentar academy_club como se fosse 'clube anterior ao Goiás' — não é erro da fonte local.
  - `priorCareerFull`: **Flamengo (1993-1999) → Atlético-PR → Kashima Antlers/Vegalta Sendai (Japão, ~3 temporadas) → Atlético-PR (retorno) → Flamengo (retorno)** — fonte: external (pt.wikipedia.org/wiki/Fabiano_Cezar_Viegas) _Não existe em NENHUMA fonte local hoje — nem career_players (Fabiano não está cadastrado lá) nem guess_players (só tem academy_club, sem carreira completa)._
  - `clubImmediatelyBeforeGoias`: **Flamengo (2ª passagem, retorno)** — fonte: external (pt.wikipedia.org/wiki/Fabiano_Cezar_Viegas). _coincide de NOME com o clube de formação por acaso — são dois fatos temporais distintos (1993 vs. retorno pré-2006), nunca deduzir um do outro_
  - `joinedGoias`: **2006** — fonte: local+external (guess_players.fabiano.goias_debut_year=2006 (local); futeboldegoyaz.com.br/jogadores/3714, passagem 2006-2007 (externa); lineup_matches:fabiano, 3 partidas todas 2006 (local))

**Aviso pro futuro**: O usuário mencionou um jogador moderno 'Fabiano Monroe Alves de Oliveira' (meia, nascido 2007-11-17) que NÃO aparece em nenhuma fonte atual do dataset. Quando ele for cadastrado em qualquer fonte futura, checar ativamente contra este registro (Fabiano Cézar Viegas, nascido 1975) antes de reaproveitar o slug 'fabiano' — mesmo padrão de colisão do caso Danilo.

### `tadeu_annotation` — ANOTAR (identidade automática já estava certa, anexa dado extra)

**Motivo**: 398 (squad_members) e 400 (career_players) não são um conflito de dado no sentido de "qual fonte está errada" — são duas leituras do mesmo fato em momentos diferentes. 400 é o valor confirmado em 28/08/2026 (Goiás 2-1 São Bernardo, passport_matches:pe_cb52680435343cc4); 398 é um snapshot anterior a essa partida.

**Evidência**:
  - **[externa]** Fornecido pelo usuário: Tadeu completou 400 partidas oficiais pelo Goiás em 28/08/2026, contra o São Bernardo.
  - **[interna]** passport_matches:pe_cb52680435343cc4 = Goiás 2-1 São Bernardo, 2026-08-28 — mesma partida citada pelo usuário, já presente no export de partidas.

**Resultado**: identidade NÃO muda (já era `EXACT_IDENTITY` no motor automático) — só anexa dado estruturado extra pra quando `player_club_spells`/`player_club_stats` forem implementados:
- **Baseline vivo**: Tadeu Antônio Ferreira × goias — `appearances=400`, `as_of_date=2026-08-28`, `as_of_match_id=pe_cb52680435343cc4`, `source=manual_verified`. Supera 398 (`squad_members`) — snapshot desatualizado, não incorreto — só anterior à partida de 28/08/2026.

### `walter_annotation` — ANOTAR (identidade automática já estava certa, anexa dado extra)

**Motivo**: O trecho "2019" de player_identity_references não é dado suspeito — é uma passagem real (recontratação/integração ao elenco) sem jogos oficiais disputados, porque a suspensão por doping foi ampliada antes da reestreia. career_players está INCOMPLETO por não listar essa terceira passagem, não errado.

**Evidência**:
  - **[externa]** Fornecido pelo usuário: Walter recontratado em 2019, suspensão por doping ampliada antes de reestrear pelo Goiás.
  - **[interna]** As 5 aparições de lineup_matches:walter são todas 2012-2013 (camisa 18) — nenhuma de 2019, consistente com uma passagem sem jogo oficial.

**Resultado**: identidade NÃO muda (já era `EXACT_IDENTITY` no motor automático) — só anexa dado estruturado extra pra quando `player_club_spells`/`player_club_stats` forem implementados:
- **Passagens (Walter Henrique da Silva × goias)**:
  - 2012-2013 — `loan`, ? jogos conhecidos
  - 2016-2017 — `loan`, ? jogos conhecidos
  - 2019 — `permanent`, 0 jogos conhecidos — _Integrado ao elenco, suspensão por doping ampliada antes da reestreia — passagem real com 0 jogos, não pendência de verificação._

## Aliases ambíguos (`canonical_aliases.json`, status `AMBIGUOUS_ALIAS`)

`canonical_aliases.json` NÃO é `UNIQUE(alias_normalized)` — um alias pode apontar pra 2+ `canonicalId` quando homônimos são reais. Todo consumidor (Flutter, seed SQL futuro) precisa checar `status` antes de resolver um alias por lookup determinístico: `RESOLVED` = 1 pessoa só, seguro pra lookup direto; `AMBIGUOUS_ALIAS` = 2+ pessoas, NUNCA resolver sozinho, sempre pedir contexto (data da partida, camisa, posição) ou perguntar ao humano.

| Alias | Status | Person IDs |
|---|---|---|
| `danilo` | `AMBIGUOUS_ALIAS` | Danilo Cunha da Silva (`34d6fed1…`) — Danilo Gabriel de Andrade (`c628f9d8…`) |
| `michael` | `AMBIGUOUS_ALIAS` | Michael Richard Delgado de Oliveira (`13c239d9…`) — Michael (1999, elenco do acesso à Série A) (`fdea65d0…`) |
| `nicolas` | `AMBIGUOUS_ALIAS` | Nicolas Vichiatto da Silva (`a597dae2…`) — Nicolas Godinho Johann (`28e672db…`) |

Total: **3** aliases ambíguos em 385 no índice inteiro — todos os 3 já existiam ANTES de dobrar `goias_players.dart` (são os mesmos 3 splits: Danilo/Michael/Nicolas). O nome bare "Nicolas" do autocomplete (`goias_players_dart:178`) contribui pra essa MESMA entrada ambígua (já não é mais um caso à parte, ver override `nicolas_split.unassignedMembers` acima) — nenhuma ambiguidade nova, nenhuma fusão silenciosa.

## Invariantes do dataset canônico (verificadas de verdade, não só declaradas)

```
TOTAL canonical people                              295
TOTAL aliases (índice)                               385
TOTAL source records (6 fontes)                      621
source records mapped to exactly 1 person            619
source records intentionally contextual/split        1  (ex.: lineup_matches:nicolas, dividido por matchIdFilter)
source records intentionally unassigned/ambiguous    1  (ex.: goias_players_dart:178 'Nicolas' bare)
source records unresolved/perdidos                   0
people with zero source records                      0
ambiguous aliases                                    3
duplicate canonical IDs                              0
duplicate person mappings (não-intencionais)         0
```

```
✓ UUID de pessoa único                       PASS
✓ nenhuma fusão silenciosa                    PASS
✓ homônimo não vira alias determinístico      PASS (3 marcados AMBIGUOUS_ALIAS, nenhum resolvido sozinho)
✓ source record nunca aponta p/ 2 pessoas      PASS (exceto split contextual explícito, ver acima)
✓ split contextual tem regra explícita         PASS (matchIdFilter obrigatório e disjunto — verificado, não só declarado)
✓ todas as 215 entradas do autocomplete classificadas   PASS (215/215)
✓ nenhuma pessoa sem source record             PASS
✓ todo source record contabilizado             PASS (621/621)
```

Fonte destes números: `canonical_stats.json.invariants`, recalculado do zero a cada execução de `apply_overrides.mjs` — nunca hardcoded.

## Testes conceituais (`tooling/multiclub/test_live_data_model.mjs`)

13 testes, 0 falhas, contra `live_data_model.mjs` (implementação de referência em memória — não é o schema real, prova o desenho antes do INSERT):

| # | Nome | Garante |
|---|---|---|
| 1 | upsert 10x com a mesma (personId, clubId, matchId) produz 1 linha só | Mesma partida sincronizada 10x não duplica (idempotência) |
| 2 | SUBSTITUTE_USED conta como appearance | Reserva que ENTROU conta como aparição |
| 3 | UNUSED_SUBSTITUTE não conta como appearance | Reserva NÃO utilizado NÃO conta |
| 4 | titular (STARTED) conta como appearance | Titular conta como aparição |
| 5 | baseline 400 (as_of 2026-08-28) + 1 nova aparição real = 401 | Tadeu: baseline + delta, 400→401 |
| 6 | sincronizar a MESMA próxima partida 5x não passa de 401 | Idempotência + baseline juntos (não duplica no acumulado) |
| 7 | spell com appearances=0 e registrationType=permanent é válido | Walter: passagem real com 0 jogos é válida, não erro |
| 8 | spell com appearances negativo é inválido | Sanity check do validador de spell |
| 9 | pessoa com 3 posições registradas mantém todas, só 1 primária | Dieguinho: multi-position sem colapsar pra uma só |
| 10 | trocar a posição primária não apaga as secundárias | Multi-position: troca de primária é segura |
| 11 | canonical_people_candidates.json tem Danilo/Nicolas/Michael como pares SEPARADOS | Danilo separado; Nicolas separado por contexto/data; Michael 1999 separado do Michael 2017-2019 — direto no dataset REAL gerado, não um mock |
| 12 | nenhum DISTINCT_PEOPLE sobra sem resolver no dataset canônico | Nenhuma colisão sem override fica silenciosamente 1 linha só |
| 13 | YEAR só aceita ano, MONTH exige ano+mês, DAY exige os 3 | Precisão temporal (`joined_at`/`left_at`) |

`club_id UUID` e `canonical match identity` não têm teste JS dedicado (são regras de schema SQL puro — `clubs.id uuid`, `canonical_match_id generated always as...` — sem lógica de aplicação pra testar isoladamente); `canonicalMatchId()` em `live_data_model.mjs` é exercitado indiretamente pelos testes 1, 5 e 6 (todo `AppearanceLedger`/`resolveLiveAppearances` usa `canonical_match_id`, nunca um id de fonte solto).

## Confirmações finais

- Nenhuma alteração em código Flutter.
- Nenhuma alteração em tabela existente do Supabase.
- Nenhum INSERT em `people` (ou qualquer outra tabela) gerado.
- Nenhuma execução realizada contra o Supabase (a migration `20260901000000_create_people.sql` continua não aplicada).
- `docs/multiclub/16_live_data_architecture.md` atualizado com club_id UUID, baseline+delta, idempotência, reserva usado/não-usado, identidade canônica de partida, precisão temporal e posições múltiplas — ainda design, nada implementado.
- Nenhum commit feito.

## Reprodutibilidade

```bash
node tooling/multiclub/reconcile_players.mjs           # motor automático (6 fontes) -> candidates.json + stats.json
node tooling/multiclub/apply_overrides.mjs             # funde com overrides -> canonical_*.json + invariantes
node tooling/multiclub/render_reconciliation_report.mjs # gera este documento
node tooling/multiclub/test_live_data_model.mjs         # roda os 13 testes conceituais
```

IDs canônicos são determinísticos (hash da composição exata de fontes de cada pessoa) — mesma entrada produz o mesmo `canonicalId` toda vez.
