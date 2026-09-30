# Prompt para retomar o flavor Vila Nova (colar na nova conta/sessão)

> Abra o ambiente de desenvolvimento na pasta `C:\Users\lucas\AndroidStudioProjects` e cole tudo abaixo da linha.

---

Vamos continuar o **flavor Vila Nova** do app **fan-hub** (`C:\Users\lucas\AndroidStudioProjects\fan-hub`), o 3º clube do app, depois de Goiás e Bragantino. Responda sempre em português do Brasil.

**Antes de qualquer coisa, leia na íntegra:**
1. `fan-hub/docs/vila_nova_data/HANDOFF_ESTADO.md`: estado completo, o que foi feito, próximos passos em ordem, decisões pendentes, receita de auditoria e armadilhas.
2. `fan-hub/docs/multiclub/60_vilanova_seeds_runbook.md`: como aplicar o banco do Vila.
3. `git log --oneline -8` no fan-hub, pra confirmar que `origin/main` está em `777fded` ou depois.

**Resumo do ponto em que paramos:**
- **Feito e pushado:**
  - F0: flavor Android/iOS/web + Firebase;
  - F1: `vilaNovaClubConfig`, com todas as capabilities desligadas;
  - F2: marca oficial #C33D41, escudo e ícones gerados do PDF vetorial oficial;
  - F3: `/clube` com história, linha do tempo, 31 títulos e 9 ídolos;
  - os 16 seeds SQL (Passaporte 2020–2026, diretoria, transparência, elenco, quiz, escalações, carreira, Manto), testados num Postgres real (PGlite).
- **Bloqueio:** o projeto Supabase do Vila ainda não existe. O flavor compila, mas não sobe sem ele.
- **Fluxo de pesquisa:** a pesquisa externa manda ZIPs incrementais pra `C:\Users\lucas\OneDrive\Desktop\`. Você audita (receita no handoff §7), aplica em `docs/vila_nova_data/`, regenera os seeds, roda o simulador e me devolve uma mensagem pronta pra colar na ferramenta de pesquisa com as correções.

**Como eu gosto de trabalhar:**
- modo automático, sem pedir aprovação a cada passo;
- commit no fim de cada fase, e me diga o que falta antes do push;
- nunca invente dado: só `READY` entra no app;
- o Vila é rival do Goiás, então zero reaproveitamento de dado/asset/texto dele;
- sempre rode `flutter test` e compare as auditorias de tooling com o HEAD antes de concluir (elas reescrevem `archive/`/`data_export/`: restaure com `git checkout`);
- mantenha `HANDOFF_ESTADO.md` atualizado a cada entrega.

**O que eu quero agora:** [escolha e apague as outras]
- (a) auditar o ZIP novo da pesquisa externa: `C:\Users\lucas\OneDrive\Desktop\<nome>.zip`
- (b) criei o projeto Supabase do Vila: URL `<...>`, chave publishable `<...>`. Aplique o runbook e siga pra F4.
- (c) enquanto o Supabase não existe, converta e calibre os perfis de jogador/técnico da Arena (handoff §5)
- (d) decisão sobre parceiros: `<publicar / não publicar a FatalFans>`
