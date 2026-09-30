# Prompt para retomar o flavor Vila Nova (colar na nova conta/sessão)

> Abra o ambiente de desenvolvimento na pasta `C:\Users\lucas\AndroidStudioProjects` e cole tudo abaixo da linha.

---

Vamos continuar o **flavor Vila Nova** do app **fan-hub** (`C:\Users\lucas\AndroidStudioProjects\fan-hub`), o 3º clube do app, depois de Goiás e Bragantino. Responda sempre em português do Brasil.

**Antes de qualquer coisa, leia na íntegra:**
1. `fan-hub/docs/vila_nova_data/HANDOFF_ESTADO.md`: estado completo, o que foi feito, próximos passos em ordem, decisões pendentes, receita de auditoria e armadilhas.
2. `fan-hub/docs/multiclub/60_vilanova_seeds_runbook.md`: como o banco do Vila foi aplicado (e como aplicar seeds novos).
3. `git log --oneline -15` no fan-hub, pra confirmar que o local está em `afafbb7` ou depois — **local está 12 commits à frente de `origin/main` (`dc4acb1`), nada pushado ainda**, confirme com o usuário antes de dar push.

**Resumo do ponto em que paramos (2026-09-29/30):**
- **Feito, commitado, SEM PUSH:**
  - F0–F3: infraestrutura, config, marca (#C33D41), `/clube` (história/timeline/títulos/ídolos);
  - Perfis de jogador (10) e técnico (6) da Arena convertidos pro motor real (`creativity/definition/leadership/intensity/technique/tactics` e `x/y/pressing/blockHeight/risk/structuralFluidity`) e calibrados por busca local (jogadores 8%–14% cada, técnicos 16,4%–16,9% cada, nenhum domina/fica inalcançável);
  - Pacote de pesquisa v1.3 aplicado: Passaporte 2019 fechado (60/60, 0 estádio UNKNOWN, 3 conflitos resolvidos) — total agora é **468 partidas / 78 venues** em 8 anos (2019–2026);
  - **Projeto Supabase do Vila criado pelo usuário** (`vkybbrfvmexevakknlsi`) e **o runbook inteiro foi aplicado de verdade** (não só simulado): 7 migrations + `bootstrap.sql` + os 17 seeds, tudo verificado ao vivo (`tooling/multiclub/verify-vilanova-live.mjs`) — 0 órfão, 0 venue sem uso, RPCs do Passaporte respondendo certo. `supabaseUrl`/`supabasePublishableKey` já estão em `vilanova_club_config.dart`;
  - **F4 ligado** (diretoria/transparência/elenco — não precisou mudar código, só o banco existir);
  - **F5 ligado parcialmente**: `quiz`, `lineup`, `player_identity`, `tactical_identity`, `career_path` estão em `enabledArenaGames`. `guess_player` (Manto) **NÃO** está ligado — bloqueio real: `GuessPlayer.eligibleAsSecret` exige foto e não existe `guessPlayerPhotos` pro Vila ainda (0/50 cartas elegíveis pro sorteio hoje).
- **O que falta, em ordem:** F6 (ligar `hasPassport`, dado já pronto no banco), F7 (Sócio/Loja/Ingressos, pacote em REVIEW), F8 (Worker + `supabaseRedirectUrl` + Auth Site URL no dashboard — adiado de propósito até aqui), F9 (QA + revisão visual).
- **Decisão (c) sobre `career_path`:** liguei com os 30 do elenco atual pra não travar o F5 inteiro. Se o usuário preferir esperar os nomes históricos da pesquisa externa, é só avisar — troca sem custo (mesma capability, só o conteúdo do seed muda).
- **Fluxo de pesquisa:** a pesquisa externa manda ZIPs incrementais pra `C:\Users\lucas\OneDrive\Desktop\vila_nova_*.zip`. Você audita (receita no handoff §7 — inclui agora um passo extra: depois do simulador OK, aplicar o seed novo no banco real via `run-sql-file.mjs` e reconferir com `verify-vilanova-live.mjs`), aplica em `docs/vila_nova_data/`, regenera os seeds, e devolve ao usuário uma mensagem pronta pra colar na ferramenta de pesquisa com as correções (a última está pronta no handoff §6, pede o próximo lote do Passaporte = **2018**).
- **Acesso ao Supabase do Vila:** `tooling/multiclub/supabase_projects_registry.json` tem o projeto registrado (`vilanova`, ref `vkybbrfvmexevakknlsi`, `envVar: VILANOVA_DB_URL`). Rodar SQL/seeds precisa da connection string (session pooler) numa env var `VILANOVA_DB_URL` — se o usuário não tiver mandado nesta sessão, peça de novo (não fica salva em lugar nenhum, por segurança).

**Como eu gosto de trabalhar:**
- modo automático, sem pedir aprovação a cada passo;
- commit no fim de cada fase, e me diga o que falta antes do push;
- nunca invente dado: só `READY` entra no app;
- o Vila é rival do Goiás, então zero reaproveitamento de dado/asset/texto dele;
- antes de ligar qualquer jogo da Arena, reauditar o dado real (contagens, elegibilidade) igual foi feito pro Bragantino — não confiar só no `status: READY` do pacote de pesquisa;
- sempre rode `flutter test` e compare as auditorias de tooling com o HEAD antes de concluir (elas reescrevem `archive/`/`data_export/`: restaure com `git checkout`);
- mantenha `HANDOFF_ESTADO.md` atualizado a cada entrega, e atualize o hash do commit no topo do arquivo depois de cada commit.

**O que eu quero agora:** [escolha e apague as outras]
- (a) auditar o ZIP novo da pesquisa externa: `C:\Users\lucas\OneDrive\Desktop\<nome>.zip`
- (b) ligar o F6 (Passaporte) — dado já pronto no banco, só falta `hasPassport: true`
- (c) resolver o F7 (Sócio/Loja/Ingressos) com o que já existe no pacote (REVIEW)
- (d) começar a resolver o ASSET_GAP das fotos do "Quem Vestiu o Manto" pra poder ligar `guess_player`
