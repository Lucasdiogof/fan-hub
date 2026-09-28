# Prompt de continuação — Pesquisa de estádios do Passaporte Esmeraldino (Goiás)

Cole isso inteiro na outra sessão.

---

Estou continuando uma pesquisa histórica de longo prazo no repo `fan-hub` (Flutter, GitHub `Lucasdiogof/fan-hub`, branch `main`). O objetivo é preencher o campo `venue_name` (estádio) de todas as partidas históricas do Goiás Esporte Clube num dataset CSV (feature "Passaporte Esmeraldino"), catalogando de 1943 até hoje.

**Estado atual: 1.943/2.102 = 92,44% confirmado.** Faltam **159** pendências no escopo oficial. Commit mais recente: `c6aeb49`, já pushado em `main`.

## Onde estão os arquivos
Tudo em `tooling/esmeraldino_passport/research/`:
- `passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1943.csv` — checkpoint canônico atual (o número no nome = contagem confirmada real).
- `GOIAS_PENDENCIAS_ESTADIOS_1943.csv` — só as linhas ainda `UNKNOWN` (159 linhas), pra não precisar vasculhar o CSV inteiro.
- `checkpoint_goias_estadios_2026-09-27.md` — log narrativo **append-only** de TUDO que já foi tentado, com o que funcionou e o que não funcionou, seção por seção numerada. **Leia a seção 44 e 45 (as últimas) antes de começar** — evita repetir trabalho.
- `_gen_pendencias.mjs` — script que calcula a contagem REAL confirmada (nunca confie em um número dito de cabeça). Uso: `node _gen_pendencias.mjs <checkpoint.csv> <saida_pendencias.csv>`. Ele imprime `2102-scope confirmado: N / 2102 = P%`.
- `_apply_by_id.mjs` — aplica confirmações por ID exato de linha via um JSON `{"hist-f80-XXXX": {venue_name, venue_city, venue_state, source_url, note}}`. Uso: `node _apply_by_id.mjs <entrada.csv> <saida.csv> <dados.json>`.
- `_apply_confronto_generic.mjs` — script mais antigo, só serve pra linhas `dataset_origin='historical_futebol80'` com `date_original` em formato `DD/mon/AAAA` (não usar pro bucket moderno).

## Regra ABSOLUTA e inegociável (o usuário já repetiu isso várias vezes)
**NUNCA confirmar um estádio por convenção de mando de campo, padrão histórico, cidade, probabilidade, ou "essa competição sempre foi nesse estádio".** Só aplicar quando uma fonte amarra especificamente **data + clubes + placar + estádio** daquele jogo exato (ou duas fontes independentes que corroborem). Se não tiver certeza, deixa `UNKNOWN` e documenta a tentativa no log — não inventa.

Exceções específicas já aceitas nesta pesquisa (usadas com moderação, sempre documentando no `conflict_note`):
- **Divergência de data de até 1-2 dias** é aceitável SE placar+adversário+contexto (rodada, competição) deixarem inequívoco que é a mesma partida. Nesse caso NÃO mude a data original do CSV — mantenha e documente a divergência.
- **Placar diferente mas identificação de partida inequívoca** (mesma data, competição e rodada, nenhum outro candidato possível): pode aplicar o estádio mesmo assim, documentando o conflito de placar no `conflict_note` SEM alterar `score_display`/`home_score`/`away_score` (isso fica pro usuário decidir depois). Só faça isso quando a identificação for realmente sólida (ficha com escalação/arbitragem/rodada nomeada, não só um confronto genérico). Se o placar mudar o RESULTADO (vitória virando derrota/empate) E a identificação for mais fraca, é mais seguro não aplicar nada e só documentar o achado.

## Ritual obrigatório a cada lote de confirmações
1. Aplicar as confirmações (via `_apply_by_id.mjs` ou edição direta do CSV).
2. Rodar `node _gen_pendencias.mjs <checkpoint.csv> <saida>.csv` pra saber a contagem REAL (nunca confiar em número de cabeça).
3. Renomear o checkpoint e as pendências pro número real confirmado.
4. Apagar os arquivos do checkpoint anterior (`git rm` ou `rm` — sempre commitados juntos, então dá pra recuperar do git se precisar).
5. Adicionar uma nova seção numerada em `checkpoint_goias_estadios_2026-09-27.md` (nunca editar seções antigas, só adicionar no fim).
6. `git add` + `git commit` (mensagem em português, direto ao ponto) + `git push origin main`.
7. Reportar pro usuário em português: quantas confirmações novas, % atual, backlog restante, principais achados/becos sem saída.

## Técnicas que funcionam bem (fonte principal: `futeboldegoyaz.com.br`, "FdG")
1. **Achar ID de clube via WebSearch:** `WebSearch({query: 'site:futeboldegoyaz.com.br "<Nome do Clube>"'})` geralmente acha uma ficha de partida qualquer daquele clube. Abra a ficha e pegue o link `<a href="https://www.futeboldegoyaz.com.br/clubes/<ID>/clube">` — é o ID do clube.
2. **Confronto direto** (`https://www.futeboldegoyaz.com.br/clubes/469/<ID_rival>/confronto`, Goiás=469): mostra todas as partidas entre os dois clubes. Use o navegador embutido (não fetch automático — o resumo automático já errou dados várias vezes nesta pesquisa) e rode isto no console via `javascript_tool`:
   ```js
   const rows=[];document.querySelectorAll('tr').forEach(tr=>{const cells=Array.from(tr.querySelectorAll('td')).map(td=>td.textContent.trim());if(cells.length>=3 && /^\d{2}\/\d{2}\/AAAA$/.test(cells[0])){const links=Array.from(tr.querySelectorAll('a')).map(a=>a.getAttribute('href'));rows.push(cells.join(' | ')+' >> '+links.join(','));}});rows.join('\n')||'NONE';
   ```
   (troque `AAAA` pelo ano que interessa). A 4ª coluna, quando existe, é o estádio.
3. **Ficha individual da partida** (`/partidas/<ID>/partida`): quando tem escalação completa + arbitragem + público/renda, é a evidência mais forte possível — nome do estádio, cidade e até a rodada exata aparecem.
4. **Edição de campeonato, aba de estatísticas** (`/campeonatos/<ID_edicao>/edicao?aba=es`): lista TODOS os clubes participantes daquela edição de uma vez, cada um linkado com seu ID. Ótimo pra descobrir vários IDs de clube de uma vez quando é competição pequena/regional. Pra achar o ID da edição certa: `https://www.futeboldegoyaz.com.br/campeonatos` lista os campeonatos, cada um tem um link `/campeonatos/<ID>/campeonato` que por sua vez lista as edições por ano.
5. Depois de aplicar, sempre rodar `_gen_pendencias.mjs` — nunca confiar de cabeça.

## Becos sem saída já confirmados (NÃO reprocessar sem fonte nova)
- **Campeonato Goiano de 1976 (13 linhas) e 1984 (13 linhas):** checagem exaustiva contra TODOS os adversários já mapeados de cada ano — campo de estádio genuinamente vazio na FdG pras 26 partidas, mesmo quando o placar bate exato e o MESMO adversário tem estádio preenchido em anos vizinhos. Buraco real da fonte, não falha de busca.
- **WildStat (wildstat.com):** bloqueado por Cloudflare (403/challenge JS) tanto pro navegador quanto pro fetch automático. Se aparecer um clube só catalogado lá, tentar achar ele também na FdG antes de desistir (rendeu 4 confirmações independentes nesta sessão).
- **De ~1985 em diante, o Campeonato Goiano na FdG praticamente não tem estádio pra ninguém** (confirmado em múltiplas sessões anteriores). A maioria das ~100+ pendências de 1985-1999 provavelmente cai nesse buraco — mas ainda vale testar caso a caso se o adversário já tem ID mapeado, só não espere alto retorno.
- **Operário de Várzea Grande-MT, Tiradentes-PI, Joinville-SC:** sem ID achado na FdG até agora (tentado via WebSearch e via edições de campeonato). Pode tentar de novo com abordagem diferente (ex.: Wikipédia do clube pode ter link direto pro perfil dele em bases de dados, ou tentar `ogol.com.br`/outras fontes já usadas em sessões anteriores).
- **Campinas-GO e Ferroviário-GO** (clubes de Goiás dos anos 1960-70): ID nunca achado na FdG apesar de várias tentativas.

## Onde focar agora (maior retorno esperado, na ordem)
1. **Ler as 159 linhas de `GOIAS_PENDENCIAS_ESTADIOS_1943.csv`** e separar por: (a) adversário já tem ID mapeado em alguma sessão anterior (ver lista completa na memória/log) — tentar confronto direto primeiro; (b) adversário sem ID — tentar achar via WebSearch antes de desistir.
2. **Competições nacionais (Brasileiro/Copa Brasil/Taça de Ouro/Taça de Prata) dos anos 1970-80 contra clubes de fora de Goiás** — essas tendem a ter fichas ricas na FdG quando o clube tem página (Dom Bosco-MT, Central-PE, Sergipe-SE, Grêmio Maringá-PR já resolvidos assim nesta sessão). Prioridade: achar os IDs que ainda faltam (Tiradentes-PI, Joinville-SC, Operário-VG) e qualquer outro clube pequeno de fora de Goiás com pendência.
3. **Campeonato Goiano de anos ENTRE 1963-1975 e 1977-1983** (fora dos dois anos já fechados como sem fonte) contra adversários com ID já mapeado — ainda não testado exaustivamente linha por linha, pode render mais confirmações tipo `hist-f80-0895` (tolerância de 1 dia) ou `hist-f80-1048`/`1305` (bate exato).
4. Só depois disso, tentar as pendências mais antigas/difíceis (Torneio Início de 1952/55/57/66, Copa Goiás 1971, Torneio Integração Nacional) — essas já foram tentadas exaustivamente em sessões anteriores (ver o `.md`) e o retorno esperado é baixo, mas documentar qualquer nova tentativa mesmo que sem sucesso.

## O que o usuário quer
Ele disse "focar nos 100%" — trabalhe de forma autônoma e contínua, sem pausar pra perguntar a cada linha. Só pare pra perguntar se: (a) encontrar um conflito de placar que muda o RESULTADO da partida e a identificação não for sólida o suficiente pra decidir sozinho; (b) esgotar as fontes conhecidas e não tiver mais ideia de onde procurar; (c) o usuário pedir. Sempre commitar e reportar em português ao fim de cada lote, seguindo o ritual acima.

Boa pesquisa.
