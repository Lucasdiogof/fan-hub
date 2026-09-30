# Vila Nova Data — Etapa 1 (v0.1)

**Snapshot:** 2026-09-29  
**App code:** `vilanova`  
**Escopo:** pesquisa e conteúdo. Esta entrega **não inicia a Etapa 2 / prompts de implementação**.

## Regra editorial aplicada

O pacote segue a política pedida: dado não confirmado não é completado por suposição. `READY` significa publicável para o recorte indicado; `REVIEW` tem evidência mas ainda possui conflito, cobertura parcial ou campo crítico não auditado; `GAP` significa que o dado ainda não foi encontrado/fechado. Toda divergência relevante fica documentada.

No Passaporte, estádio só é preenchido quando a fonte da partida informa explicitamente o local. O mandante nunca é usado para inferir estádio.

## O que já está forte

- Identidade básica, fundação, cidade, apelidos, estádio/CT e estrutura institucional.
- História em 7 seções e linha do tempo com 30 marcos.
- Principais títulos oficiais conforme o acervo do clube, com torneios históricos de natureza ainda não classificada mantidos em `REVIEW`.
- Diretoria e comissão técnica atuais.
- Elenco oficial: **31/31 atletas** cadastrados. O pertencimento ao elenco e a posição são `READY`; campos biográficos ausentes permanecem `null`.
- Integrações principais: site, notícias, loja, sócio, ingressos, redes e OneFootball ID 2865.
- Loja: catálogo parcial com **12 produtos** detalhados; a própria loja reportava 125 produtos no snapshot.
- Ingressos: setores e faixas de preços recentes do OBA, incluindo regra observada de meia e acesso Sócio Tigrão.
- Arena Quiz: **45/45 perguntas READY**.
- Passaporte 2026: **55 registros** (51 concluídos + 4 agendados conhecidos), todos com estádio específico na fonte.

## Passaporte — cobertura

O arquivo `passport/passport_audit_manifest.json` contém uma linha para **cada ano de 1943 a 2026**.

Neste v0.1, somente **2026** foi trabalhado como lote. Os anos 1943–2025 aparecem como `NO_SOURCE` com nota explícita de que isso significa **“nenhuma fonte auditada neste lote ainda”**, e não que fontes históricas não existam.

Para 2026, a cobertura sobre os jogos que estavam expostos nas fontes primárias consultadas neste lote é **55/55 = 100%**. Mesmo assim, o ano permanece `PARTIAL`, pois:
1. `expected_total` ainda não foi fixado por segunda fonte independente;
2. as rodadas 35–38 da Série B ainda não estavam publicadas com data/horário/local no snapshot;
3. falta a auditoria cruzada integral competição por competição.

Portanto, **não é correto chamar 2026 de CLOSED ainda**.

## REVIEW principais

- `branding.json`: nomes das cores estão confirmados, mas HEX não foi inventado; o manual/escudo vetorial precisa ser efetivamente inspecionado para medir valores.
- `integrations.json`: ID do OneFootball está confirmado; slug interno da competição permanece pendente.
- `honors.json`: alguns torneios antigos constam no acervo oficial, mas ainda precisam ser classificados como oficiais x amistosos em fonte federativa/hemeroteca.
- `idols.json`: 10 nomes já sustentados como ídolos/figuras históricas, mas período, estatísticas e foto individual ainda precisam de auditoria.
- `membership.json`: acesso de Prata/Ouro/Rubi aparece em publicação oficial; preços dos planos vieram de fonte jornalística contemporânea e ficam em `REVIEW` até regulamento/página oficial.
- `partners.json`: FatalFans e Volt estão sustentados; a lista completa de patrocinadores ativos no snapshot ainda está incompleta.
- `arena/career_path.json`: 30 candidatos já têm sequência de clubes capturada, porém períodos, empréstimos e números por passagem precisam ser auditados.
- `arena/guess_player.json`: 31 atletas atuais cadastrados como candidatos; ainda não atinge 50 READY.

## GAPs principais

- Passaporte histórico completo de 1943–2025.
- 15 escalações históricas completas e confirmadas.
- 50 cartas READY de “Quem Vestiu o Manto”.
- Perfis factuais suficientes para `player_identity.json` e `tactical_identity.json`.
- Destaques financeiros (receita líquida, resultado e dívida): os PDFs oficiais foram catalogados, mas os números não foram extraídos neste lote.
- Regulamento oficial detalhado do Sócio Tigrão.
- Instagram de boa parte do elenco; somente perfis com vínculo suficientemente confirmado foram preenchidos.
- URLs diretas de fotos individuais/ídolos em todos os casos.
- Catálogo integral dos 125 produtos da loja.

## Conflitos documentados

1. **Breno Bora — nascimento:** uma página secundária exibe tabela com 07/02/2006, enquanto o corpo e bases esportivas apontam 22/05/2002. Mantido 2002-05-22 com conflito em `squad_current.json`.
2. **Willian Formiga — nascimento:** há referência a 21/01/1995 e bases apontando 22/01/1995. Mantido 1995-01-22 provisoriamente; conflito registrado.
3. **Higor Meritão — altura:** 184 cm x 186 cm em fontes diferentes. `height_cm` ficou `null`.
4. **Rio Branco-ES x Vila Nova — Copa Verde 2026:** CBF e ge fixam 24/03/2026; uma referência indexada divergiu. Usado 24/03, mantendo nota de conflito.
5. **Presidência:** a página oficial atual aponta Fábio Brasil de Castro; cadastro externo da FGF aparecia defasado com Hugo Bravo. O snapshot usa a fonte oficial do clube.

## Observações de segurança editorial

- Nenhum texto, imagem ou dado do Goiás foi reaproveitado como informação do Vila.
- Hino: só metadados; nenhuma letra foi reproduzida.
- Fotos não foram baixadas nem embutidas; `assets_todo.md` aponta fontes.
- Campos ausentes ficam `null`.
- IDs usam prefixo `vn_` e devem permanecer estáveis depois da publicação.

## Próximos lotes de pesquisa

A prioridade lógica depois deste v0.1 é: fechar 2026 com segunda fonte e R35–R38 quando publicadas; depois pesquisar o Passaporte de trás para frente (2025, 2024, ...), atualizando o audit manifest a cada ano; em paralelo, concluir Arena histórica, ídolos e perfis dos jogadores. A Etapa 2 só deve começar depois da aprovação explícita da Etapa 1.
