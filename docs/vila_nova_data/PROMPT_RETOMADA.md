# Prompt para retomar o flavor Vila Nova (colar na nova conta/sessão)

> Abra o ambiente de desenvolvimento na pasta `C:\Users\lucas\AndroidStudioProjects` e cole tudo abaixo da linha.

---

Vamos continuar o **flavor Vila Nova** do app **fan-hub** (`C:\Users\lucas\AndroidStudioProjects\fan-hub`), o 3º clube do app, depois de Goiás e Bragantino. Responda sempre em português do Brasil.

**Antes de qualquer coisa, leia na íntegra:**
1. `fan-hub/docs/vila_nova_data/HANDOFF_ESTADO.md`: estado completo, próximos passos em ordem (§3), mensagem pronta à pesquisa (§6), receita de auditoria (§7) e armadilhas (§8).
2. `fan-hub/docs/multiclub/60_vilanova_seeds_runbook.md`: como o banco do Vila foi aplicado e como aplicar seeds novos.
3. `git log --oneline -10` no fan-hub. Em 2026-09-30 **tudo foi commitado e pushado**; o local deve estar igual ao `origin/main` ou à frente só com trabalho novo.

**Resumo do ponto em que paramos (2026-09-30):**
- **No ar:** F0–F8. Config, marca, `/clube`, Supabase real (`vkybbrfvmexevakknlsi`), diretoria/transparência/elenco, Arena com os 6 jogos, Passaporte, Sócio Tigrão (planos, **FAQ, regulamento oficial e WhatsApp de atendimento**), e o **Worker próprio `vilanova-app.lucasdiogo1234.workers.dev`**: jogos (Home, aba Jogos), notícias do site oficial e rotas das redes.
- **O Worker do Vila é publicado pela CLI**, não pelo Git: `node tool/build_web_flavor.mjs vilanova` e depois `npx.cmd wrangler deploy --config wrangler.vilanova.toml`. Toda mudança em `lib/` ou `src/` que afete o Vila precisa desse redeploy.
- **Redes sociais do Vila:** X e Instagram vão para o KV, alimentados pelo GitHub Action `sync_x_posts.yml` (sem commit, então sem build do Cloudflare); o YouTube usa a API. **Ficam vazias até o usuário configurar os secrets** (handoff §3, item 2).
- **Passaporte 2010–2018 (v1.4):** auditado e commitado, mas **ainda NÃO aplicado no banco real**. Peça a connection string e siga o handoff §3, item 1.
- **O que falta, em ordem:** aplicar o Passaporte 2010–2018 no banco; os secrets/Apify do usuário; a Auth Site URL e o template de e-mail do Supabase; as estatísticas de carreira do elenco (pesquisa externa, pedido incluído na mensagem do §6); confirmar as fotos AVIF num device; Loja/Ingressos só com pesquisa real; a F9 (QA + revisão visual).
- **Fluxo de pesquisa:** os ZIPs da pesquisa externa chegam em `C:\Users\lucas\OneDrive\Desktop\vila_nova_*.zip`. Os antigos (até o v1.4) já foram aplicados e apagados. Audite pela receita do §7: depois do simulador OK, aplique no banco real com `run-sql-file.mjs` e reconfira com `verify-vilanova-live.mjs`.
- **Acesso ao Supabase do Vila:** a connection string (session pooler) vai numa env var `VILANOVA_DB_URL`. Ela não fica salva em lugar nenhum; peça ao usuário quando precisar.

**Como eu gosto de trabalhar:**
- modo automático, sem pedir aprovação a cada passo;
- commit no fim de cada fase, mas **push só em última instância**: acumule os commits e suba uma vez só, no fim, com o meu aval (cada push gasta minutos de build do Cloudflare nos Workers do Goiás e do Bragantino). O Worker do Vila é publicado pela CLI e não gasta build;
- nunca invente dado: só `READY` entra no app;
- o Vila é rival do Goiás, então zero reaproveitamento de dado, asset ou texto dele;
- antes de ligar qualquer jogo da Arena, reauditar o dado real (contagens, elegibilidade), sem confiar só no `status: READY`;
- sempre rode `flutter test` (e `npx.cmd vitest run` se mexer no Worker) e compare as auditorias de tooling com o HEAD antes de concluir (elas reescrevem `archive/`/`data_export/`: restaure com `git checkout`);
- mantenha `HANDOFF_ESTADO.md` atualizado a cada entrega.

**O que eu quero agora:** [escolha e apague as outras]
- (a) aplicar o Passaporte 2010–2018 no banco real (vou te passar a connection string)
- (b) auditar o ZIP novo da pesquisa externa: `C:\Users\lucas\OneDrive\Desktop\<nome>.zip`
- (c) terminar as redes sociais (já configurei os secrets / a Task do Apify)
- (d) F9: QA de isolamento e revisão visual
