# Vila Nova — F3: conteúdo institucional (`/clube`)

Data: 2026-09-29. Fonte: `docs/vila_nova_data/data/` (pacote v1.2). Capability ligada: **`hasClubContent`**.

## O que entrou
| Seção | Conteúdo | Arquivo |
|---|---|---|
| História | 7 seções (1938 → 2026) | `lib/features/club/data/vilanova_history_data.dart` (**gerado**) |
| Linha do tempo | 30 marcos, cada um com fonte | `vilanova_timeline_data.dart` (**gerado**) |
| Títulos | 31: Série C ×3, Goiano ×16, Segunda Divisão ×2, Copa Goiás ×3, Copa Leonino Caiado ×3, Taça Cidade de Goiânia ×3, Taça Goiás ×1 | `vilanova_titles_data.dart` |
| Campanhas | vice da Copa Verde em 2021, 2022 e 2024 (nunca contam como título) | idem |
| Ídolos | 9 publicados (tier 1) + 4 retidos | `vilanova_idols_data.dart` |

História e linha do tempo são geradas do JSON do pacote por `tooling/vilanova_content/generate_institutional_dart.mjs` (depois, rodar `dart format`). Para corrigir texto, corrigir **no pacote** e regenerar.

## Decisões editoriais
- **Ídolos**: o app só publica o tier 1.
  - Tier 1: READY com fonte que chama o jogador de ídolo, ou com marcos concretos pelo clube (Rafael Donato, `evidenceExplicitIdol: false`, mesmo critério do Bragantino).
  - Retidos (tier 2): **Túlio**, com totais em conflito (pacote 104j/92g × Wikipedia/oGol 58j/51g), e **Willian Formiga**, em atividade no elenco. Bé e Max estão em REVIEW (tier 3).
  - Número de jogos/gols só aparece quando a fonte cobre a passagem inteira (o de Guilherme é parcial, então o texto não cita número).
  - Sem fotos ainda: o card mostra as iniciais.
- **Títulos fora (DATA_GAP)**: Torneio Início e Torneio Goiânia-Anápolis (falta classificar oficial × amistoso) e os vices da Copa Centro-Oeste 1999–2001 (REVIEW). O Quadrangular Joaquim Coelho (1970, amistoso) aparece só na linha do tempo.
- **Goiano = 16**, como no site oficial (a Wikipedia cita 17). A Segunda Divisão 2015 foi conferida na FGF: o Vila caiu no Goiano de 2014.
- **Parceiros ficam desligados** (`hasPartners=false`): a lista do pacote está incompleta (2 nomes, máster não confirmado), e um dos patrocinadores é uma plataforma de conteúdo adulto, o que pede decisão editorial do usuário.
- **Músicas**: vazio. O pacote só tem metadados, sem letra, por direitos autorais.
- **Texto limpo de bastidor**: 5 frases do pacote falavam da pesquisa em vez do clube ("não fixam neste lote…", "listadas pelo acervo oficial", "listado pelo clube"). Foram reescritas **no pacote**, usando só fatos já READY, e cada item alterado ganhou um `editorial_note`. Um teste trava essas palavras.

## Verificação
- `test/core/club/vilanova_identity_isolation_test.dart`: 24 testes, incluindo o conteúdo do F3 (classes certas, 16 Goianos / 3 Séries C, vice fora dos títulos, Túlio não publicado, 9 ídolos, nenhum texto de outro clube ou de bastidor, linha do tempo ordenada e com fonte).
- `flutter test`: **1540 passaram**, 1 skip. `flutter analyze` sem issue nos arquivos do Vila.
- Auditorias de conteúdo por clube (`test_multiclub_runtime_content_scope`, `test_m4_critical_club_leakage`): as mesmas falhas do HEAD, nenhuma nova. Artefatos regenerados restaurados.
- **Revisão visual** (golden temporário, não commitado) de `/clube`, Títulos, Ídolos, História e Linha do tempo, nos modos claro e escuro, com a paleta do Vila: sem overflow, contagens certas, escudo no header.
