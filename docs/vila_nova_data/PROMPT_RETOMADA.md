# Prompt para retomar o flavor Vila Nova (colar na nova conta/sessão)

> Abra o ambiente de desenvolvimento na pasta `C:\Users\lucas\AndroidStudioProjects` e cole tudo abaixo da linha.

---

Vamos continuar o **flavor Vila Nova** do app **fan-hub** (`C:\Users\lucas\AndroidStudioProjects\fan-hub`), o 3º clube do app, depois de Goiás e Bragantino. Responda sempre em português do Brasil.

**Antes de qualquer coisa, leia na íntegra:**
1. `fan-hub/docs/vila_nova_data/HANDOFF_ESTADO.md`: estado completo, o que foi feito, próximos passos em ordem, decisões pendentes, receita de auditoria e armadilhas.
2. `fan-hub/docs/multiclub/60_vilanova_seeds_runbook.md`: como o banco do Vila foi aplicado (e como aplicar seeds novos).
3. `git log --oneline -10` no fan-hub, pra confirmar que o local está em `bff9886` ou depois. **O local está 7+ commits à frente de `origin/main` (`a80e03a`), sem push.** Confirme com o usuário antes de subir.

**Resumo do ponto em que paramos (2026-09-30):**
- **No ar em `origin/main`:** F0–F7. Infraestrutura, config, marca (#C33D41), `/clube`, Supabase real (`vkybbrfvmexevakknlsi`, 468 partidas / 78 venues), F4 (diretoria/transparência/elenco), F5 (Arena com os 6 jogos), F6 (Passaporte) e F7 (Sócio Tigrão, 4 planos reais anuais, checkout externo). A correção do vazamento de Ingressos/Loja do Goiás também já subiu: o Bragantino voltou para `hasTickets: false`.
- **Commitado localmente, SEM PUSH:**
  - 31 fotos reais do elenco/Manto (hotlink AVIF do site oficial). O seed já está aplicado no banco real e `guess_player` está ligado;
  - cores: sucesso = dourado (o Vila nunca usa verde), erro mais vivo (`0xFFD7263D`), com teste de regressão;
  - marca d'água de estádio vermelha no card "Arena Vila Nova" da Home (`tooling/vilanova_brand/build_arena_stadium.py`);
  - handoff atualizado com o teste ao vivo no emulador e o achado do template de e-mail.
- **Testado ao vivo pelo usuário no emulador Android:** login, Home, Arena e Sócio funcionando. "Sem conexão" na Home é esperado: `hasMatches: false` até o F8.
- **O que falta, em ordem:**
  1. push dos commits locais (com o aval do usuário);
  2. confirmar num device que as fotos AVIF do Elenco/Manto renderizam (ainda ninguém viu);
  3. F8: Worker `wrangler.vilanova.toml` (jogos, notícias, Instagram), `supabaseRedirectUrl` e Auth Site URL no dashboard;
  4. template de e-mail "Confirm signup" do Supabase do Vila: copiar o de Goiás/Bragantino (`{{ .Token }}`, código de 6 dígitos) antes de reativar a confirmação de e-mail. Hoje "Confirm email" está desligado;
  5. F9: QA de isolamento dos 3 flavors e revisão visual;
  6. Loja e Ingressos (do Vila e do Bragantino) só quando houver pesquisa real;
  7. `hasPartners`: aguarda a auditoria de patrocinadores de 2026.
- **Decisão (c) sobre `career_path`:** está ligado com os 30 do elenco atual. Se o usuário preferir os nomes históricos da pesquisa externa, basta trocar o seed.
- **Fluxo de pesquisa:** o roteiro de continuação da pesquisa está em `docs/vila_nova_data/PROMPT_PESQUISA_CONTINUACAO_2026-09-30.md` (a mensagem de correções está no handoff §6; o próximo lote do Passaporte é **2018**). Ainda não foi enviado. Os ZIPs chegam em `C:\Users\lucas\OneDrive\Desktop\vila_nova_*.zip`; o último auditado foi o `v1_3`. Receita no handoff §7: depois do simulador OK, aplicar no banco real via `run-sql-file.mjs` e reconferir com `verify-vilanova-live.mjs`.
- **Acesso ao Supabase do Vila:** a connection string (session pooler) vai numa env var `VILANOVA_DB_URL`. Ela não fica salva em lugar nenhum; peça ao usuário quando precisar.

**Como eu gosto de trabalhar:**
- modo automático, sem pedir aprovação a cada passo;
- commit no fim de cada fase, e me diga o que falta antes do push;
- nunca invente dado: só `READY` entra no app;
- o Vila é rival do Goiás, então zero reaproveitamento de dado, asset ou texto dele;
- antes de ligar qualquer jogo da Arena, reauditar o dado real (contagens, elegibilidade), sem confiar só no `status: READY`;
- sempre rode `flutter test` e compare as auditorias de tooling com o HEAD antes de concluir (elas reescrevem `archive/`/`data_export/`: restaure com `git checkout`);
- mantenha `HANDOFF_ESTADO.md` atualizado a cada entrega, e atualize o hash do commit no topo depois de cada commit.

**O que eu quero agora:** [escolha e apague as outras]
- (a) dar push dos commits locais
- (b) auditar o ZIP novo da pesquisa externa: `C:\Users\lucas\OneDrive\Desktop\<nome>.zip`
- (c) começar o F8 (Worker + Auth redirect)
- (d) F9: QA de isolamento e revisão visual
