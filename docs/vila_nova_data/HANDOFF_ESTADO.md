# Flavor Vila Nova — handoff de estado (atualizado 2026-09-29, v1.2)

> Leia isto primeiro ao retomar em outra conta/sessão. Tudo aqui está **fora do git** (nada commitado ainda).

## Contexto e fluxo combinado

Criar o 3º flavor do fan-hub, **`vilanova`** (Vila Nova FC, Goiânia-GO), seguindo o mesmo padrão do Bragantino:

1. **A pesquisa externa** entrega um pacote de dados em ZIPs incrementais (v0.1, v0.2…), cada um trazendo só os arquivos alterados mais o `manifest.json`.
2. **A auditoria confere** cada ZIP: extrai no scratchpad, aplica em ordem sobre o pacote, valida a consistência, confere alguns fatos na web e copia para `fan-hub/docs/vila_nova_data/`. Depois devolve ao usuário uma mensagem pronta para colar na ferramenta de pesquisa, com as correções.
3. Quando o usuário aprovar a Etapa 1, a **pesquisa escreve os prompts F0–F9** (um por fase) e a **implementação segue**, fase a fase. Cada fase termina com commit e PARE.

- Roteiro original da pesquisa: `docs/vila_nova_data/PROMPT_PESQUISA.md` (define estrutura, formatos e as fases F0–F9).
- Referências de padrão no repo: `lib/core/club/bragantino_club_config.dart`, `docs/multiclub/47_m4_bragantino_onboarding_design.md`, `docs/bragantino_data/`, `tooling/bragantino_passport/`.

## Estado atual do pacote: **v1.2** (em `docs/vila_nova_data/`)

Os ZIPs originais estão em `C:\Users\lucas\OneDrive\Desktop\vila_nova_data_etapa1_v0_*.zip` e `vila_nova_data_passport_v0_7_incremental.zip`. O v0.1 é completo; os demais são incrementais, aplicados na ordem 0.2 → 0.3 → 0.4 → 0.5 → 0.6 → 0.7.

| Área | Situação |
|---|---|
| Identidade (`club.json`) | ✅ Fundado em 29/07/1943; torcida "Colorado"; apelido Tigrão/Tigre; estádio OBA; CT Vila do Tigre. Nomes sugeridos: Arena do Tigre / Passaporte Colorado / loja Nação Colorada / Sócio Tigrão |
| Cores (`branding.json`) | ✅ extraído: **#C33D41** (manual oficial, pág. 9); o pacote segue com null de propósito. Fonte: PDF vetorial oficial (`vetor-escudo-vila-nova-fc-oficial-pdf-713650.pdf`, com o manual linkado no json) |
| Integrações | ✅ OneFootball team id **2865** (slug `vila-nova`). O slug da competição está em REVIEW. Site, notícias (`/noticias/<id>-<slug>`), redes, loja `lojadovila.com.br`, sócio/ingressos em ingressosa, 3 endereços de retirada |
| História / timeline | ✅ 7 seções / 30 marcos |
| Títulos (`honors.json`) | ✅ 16 Goianos (1961/62/63, 69, 73, 77/78/79/80, 82, 84, 93, 95, 2001, 2005, 2025), conforme o site oficial; 3 Séries C (1996, 2015, 2020). Torneio Início e Goiânia-Anápolis em REVIEW. ⚠ A Wikipedia conta 17 Goianos (pedido à pesquisa: registrar como conflito) |
| Ídolos | 11 READY + 4 REVIEW. ⚠ **Túlio**: o pacote diz 104j/92g (Zerozero); Wikipedia/oGol somam 58j/51g → precisa voltar para REVIEW |
| Diretoria / transparência | ✅ Diretoria e comissão atuais; PDFs catalogados; destaques financeiros não extraídos |
| Elenco (`squad_current.json`) | ✅ 31 atletas (há 3 conflitos biográficos documentados) |
| Sócio | REVIEW: preços vieram de jornal; falta o regulamento oficial |
| Loja | 12 de ~125 produtos |
| Ingressos | ✅ setores e preços do OBA |
| Quiz | ✅ 45 READY (v0.2 trocou as perguntas perecíveis). Sobram "estádio atual" e "capacidade atual do OBA": aceitável |
| Escalações | ✅ 15 READY, estruturalmente ok (Cuiabá 4x2 conferido na web). ⚠ Todas de 2015 para cá |
| Carreira | 30 READY, estruturalmente ok. ⚠ **As 30 são do elenco atual**: pedido para trocar ≥15 por nomes históricos |
| Quem Vestiu o Manto | ✅ 50 READY (há campos null, mas o jogo aceita). ⚠ Nenhuma estreia antes de 2013 |
| Perfil jogador/técnico | ⚠ **Formato errado (culpa do prompt original)** — ver abaixo |
| Passaporte | **408 jogos em 7 anos, 68 venues** (v1.2). Detalhe na tabela abaixo. **1943–2019: não pesquisado; próximo lote = 2019** |

### Passaporte por ano (conferido com `node docs/vila_nova_data/validate_passport.js docs/vila_nova_data`)

| Ano | Jogos | Status | Estádio confirmado | Conferência externa |
|---|---|---|---|---|
| 2026 | 55 | PARTIAL | 55/55 | faltam R35–R38 e a 2ª fonte. ⚠ 3 jogos da Copa do Brasil com `calendar_year` em string `"2026"` (tem que ser número) |
| 2025 | 62 | CLOSED | 62/62 | Série B 11V14E13D ✔ (Wikipedia), finais do Goiano ✔ |
| 2024 | 62 | CLOSED | 50/62 | Série B 16V7E15D, 55 pts ✔ (FGF) |
| 2023 | 56 | CLOSED | 45/56 | Série B 17V10E11D, 61 pts ✔ (pt.wikipedia) |
| 2022 | 62 | CLOSED | 14/62 | Série B 9V20E9D, 47 pts ✔ (pt.wikipedia) |
| 2021 | 78 | CLOSED | 24/78 | inclui o resto da temporada 2020 jogado em 2021 (pandemia): Série C 2020, Goiano 2020, Copa Verde 2020. O manifest conta por edição (`GOIANO_2020` etc.), é esperado |
| 2020 | 33 | CLOSED | 23/33 | Série C 2020: 21 jogos aqui + 5 em 2021 = 26 ✔ |

Nos anos de pandemia, os estádios desconhecidos são UNKNOWN honesto (nunca inferido). Um jogo com pênaltis e placar do tempo normal diferente de empate só aparece quando o confronto foi decidido no agregado (Cuiabá 4x2 em 2024, Brasiliense 1x3 em 2021): está correto.

### Perfis de jogador/técnico: como é de verdade no app

O motor é **único para todos os clubes**, com perguntas fixas. Cada clube só fornece **referências**:

- **Jogador** (`lib/features/arena/games/player_identity/domain/*_references.dart`): 6 atributos de 0 a 100 (`creativity, definition, leadership, intensity, technique, tactics`). Goiás e Bragantino têm **21** referências cada.
- **Técnico** (`tactical_identity/domain/*_coach_references.dart`): `x` (posse −, vertical +), `y` (dogmático −, pragmático +), mais `pressing, blockHeight, risk, structuralFluidity`. Goiás e Bragantino têm **12** cada.
- A pesquisa externa entregou 8 dimensões de 0 a 10, com perguntas próprias, para 10 jogadores e 6 técnicos. Aproveitam-se **nomes e evidências**. A conversão para a escala do app fica a cargo da implementação, **calibrada no motor**: todos os perfis precisam aparecer como Top 1 e nenhum pode passar de 20% (ver o comentário no topo de `bragantino_player_identity_references.dart`).

## Implementação no app (andamento)

| Fase | Estado |
|---|---|
| F0 infraestrutura | ✅ commit `00ec2fe` (outra sessão) + apps Firebase criados. Ver `docs/multiclub/57_vilanova_f0_infra.md` |
| F1 config do clube | ✅ `vilaNovaClubConfig` no registry, tudo desligado. Ver `docs/multiclub/58_vilanova_f1_f2_config_marca.md` |
| F2 marca | ✅ cor oficial #C33D41 (manual, pág. 9); escudo/ícones/login a partir do PDF vetorial (`tooling/vilanova_brand/build_brand_assets.py`) |
| F3 conteúdo institucional | ✅ história, timeline, 31 títulos, 9 ídolos; `hasClubContent` ligado; parceiros desligados (decisão editorial pendente). Ver `docs/multiclub/59_vilanova_f3_conteudo_institucional.md` |
| F4 → F9 | pendentes (F4 diretoria/elenco e daí em diante precisam do Supabase) |

**Bloqueio do usuário:** criar o projeto Supabase do Vila Nova. Sem ele o flavor compila, mas não sobe (`SupabaseConfig` falha alto com URL null). Depois: baseline + `infra/supabase/clubs/vilanova/bootstrap.sql` + chaves na config.

## Erros já achados e ainda NÃO corrigidos no pacote

0. Passaporte 2026: `calendar_year` em string nos 3 jogos `vn_official_cdb_2026_f*` (no import dá pra normalizar sozinho).
1. Passaporte 2025, jogo de 13/03 (Copa do Brasil, 2ª fase, 6–0): o adversário é **Rio Branco-VN** (Venda Nova do Imigrante), não Rio Branco-ES.
2. Túlio: números em conflito (ver acima).
3. Goianos: registrar o conflito 16 × 17.

## Pendências (quem faz o quê)

**Pesquisa externa (mensagem já enviada, ou a enviar; texto abaixo):**
- corrigir os erros 1–3;
- perfis: 21 jogadores e 12 técnicos, só com nome, período, função e evidências de estilo;
- carreira: ≥15 nomes históricos;
- escalações: ≥5 anteriores a 2000; Manto: ≥10 cartas com estreia antes de 2005;
- Passaporte: **próximo lote é 2019** (v1.2 cobriu 2024 → 2020), depois retrocedendo ano a ano até 1943;
- fechar 2026 (R35–R38 + 2ª fonte); loja completa; regulamento/preços oficiais do sócio.

**Implementação (depois da aprovação ou em paralelo):**
- F3 feita; da F4 em diante precisa do Supabase do Vila (dá pra adiantar os seeds SQL e a conversão dos perfis da Arena);
- converter e calibrar os perfis no motor.

**Usuário:** criar o projeto Supabase e o app no Firebase Fan Hub, baixar credenciais e as imagens listadas em `assets_todo.md`.

## Mensagem pendente à pesquisa (se ainda não foi enviada)

```
v0.7 aplicado — 2025 ficou excelente (62/62, estádios todos confirmados, bati com Wikipedia/ge).

1. Correção: vn_…_20250313 (Copa do Brasil 2ª fase, 6–0) o adversário é Rio Branco-VN (Rio Branco de Venda Nova, Venda Nova do Imigrante-ES), não Rio Branco-ES — são clubes diferentes. Corrija o nome e o venue/alias se necessário. Confira também se o "Rio Branco-ES" da Copa Verde 2026 é mesmo o Rio Branco AC.
2. Honors: registre em conflicts que a Wikipedia conta 17 Goianos contra 16 do site oficial (mantenha o oficial).
3. Lembrete: as correções da Arena pedidas depois do v0.6 (perfis 21 jogadores/12 técnicos só com evidência de estilo, 15 carreiras históricas, Túlio em REVIEW, escalações pré-2000, Manto pré-2005) ainda não vieram. Pode entregar em um ZIP separado enquanto segue o Passaporte.

Próximo lote do Passaporte: 2024.
```

## Como auditar o próximo ZIP (receita)

1. Extrair no scratchpad; aplicar **em ordem de versão** sobre uma cópia de `docs/vila_nova_data/`.
2. Validar o Passaporte com `node docs/vila_nova_data/validate_passport.js <pasta_do_pacote>`: ele cobre todos os anos e todas as regras abaixo. Para o resto, validar:
   - JSONs parseiam;
   - no Passaporte: `outcome` × placar do tempo normal (**pênaltis = DRAW**, com a disputa em `penalty_*`), `club_score` × lado do Vila, `score_display`, IDs únicos, estádio só com `MATCH_SPECIFIC`, todo estádio presente em `venues.json`, total por competição contra o `passport_audit_manifest.json`;
   - na Arena: XI = 11 com 1 GOL, posições válidas, `is_club` nas carreiras, IDs e nomes únicos.
3. Conferir 2–3 fatos na web: campanha do ano, finais, adversários com nomes parecidos.
4. Copiar para `docs/vila_nova_data/` e devolver a mensagem de correções à pesquisa.
