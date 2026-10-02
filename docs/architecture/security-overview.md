# Visão geral de segurança

> **Análise estática.** Baseada somente no que está versionado no repositório (commit `e90de17`). Não houve requisição de rede, acesso a banco, nem tentativa de exploração. O **estado vivo** dos três projetos Supabase (grants reais, funções aplicadas, se os scripts de hardening foram executados), as regras do Cloudflare (WAF/rate limit), os *secrets* efetivamente configurados e as restrições de chave no Google Cloud **não foram verificados**. Nenhuma correção foi aplicada: este documento só registra achados.
>
> Nenhum valor de segredo é reproduzido. Severidades refletem impacto técnico comprovável no código lido; confiança `CONFIRMADO` = leitura direta do código/SQL, `POSSÍVEL` = depende de estado que não pôde ser visto.

## 1. Resumo

| Severidade | Qtd. | Itens |
|---|---:|---|
| Crítico | 0 | — |
| **Alto** | 1 | S-01 |
| Médio | 4 | S-02, S-03, S-04, SC-01 |
| Médio/Baixo | 1 | S-05 |
| Baixo | ~12 | S-06, S-08, W-01, W-02, W-03, W-05, C-01, C-02, C-05, `notifications-test-trigger`, … |
| Info | ~9 | W-04, W-06, C-03, C-04, C-06, C-07, C-08, SC-02, SC-03 |

**Segredos: limpo.** Nenhum segredo privado está versionado (ver §2).

## 2. Segredos

| O quê | Onde | Avaliação |
|---|---|---|
| `service_role` | só em `supabase/functions/*` (runtime Deno) | **Nunca** referenciado em `lib/`, assets ou `web/` (confirmado) |
| Chaves `sb_publishable_*` do Supabase | `lib/core/club/*_club_config.dart` (e em um teste e em um script de auditoria) | Públicas por desenho; a proteção real é **RLS + grants** |
| Config cliente do Firebase | `android/app/src/*/google-services.json`, `ios/Runner/Firebase/*/GoogleService-Info.plist` | Públicas por desenho; recomenda-se restringir por pacote/bundle no Google Cloud. Projeto Firebase **único** para os 3 clubes |
| DSN do Sentry | `lib/core/config/sentry_config.dart` | Só permite enviar eventos; risco é spam de eventos |
| `.dev.vars`, `.env*`, `*.jks`, `android/key.properties`, `supabase/.temp` | `.gitignore` | Ignorados; nenhum rastreado |
| Connection strings | `tooling/multiclub/*.ps1` | Montadas a partir de variáveis/prompt; sem senha real |

## 3. Supabase — autorização

**RLS:** 58/58 tabelas do baseline e `passport_matches_excluded` têm RLS. Todas as policies `using (true)` são `SELECT` em catálogos públicos; dados do usuário usam `auth.uid()`; tabelas de serviço usam `using (false)`. Todas as funções `SECURITY DEFINER` revisadas fixam `search_path`.

### S-01 — ALTO (CONFIRMADO no SQL; POSSÍVEL no banco vivo): IDOR anônimo nas RPCs `passport_*`

- **Onde:** `supabase/migrations/20260904000000_canonical_baseline.sql`, linhas ~2263–2639.
- **O quê:** `passport_summary`, `passport_attendance_breakdown`, `passport_attended_matches`, `passport_memorable_match_id` e `passport_stadium_summary` são `SECURITY DEFINER`, filtram por `coalesce(p_user_id, auth.uid())` (confiam no id enviado pelo cliente) e têm `grant execute ... to anon, authenticated, service_role`. `passport_ranking` é público e devolve `user_id`.
- **Impacto:** quem tiver a chave *publishable* (embutida em todo build) pode coletar uids no ranking e ler a presença em jogos de qualquer usuário.
- **Contexto:** o próprio repositório descreve este vetor e o corrige em `supabase/passport_harden_per_user_rpcs.sql` e `supabase/passport_revoke_anon_execute.sql` — mas esses são **scripts soltos**, fora da cadeia `supabase/migrations/` e dos `bootstrap.sql`. Um projeto novo montado pela cadeia oficial nasce com a versão vulnerável **a menos que** o script tenha sido aplicado à mão. O Vila Nova tem `hasPassport: true`.
- **Mitigação sugerida:** promover os dois scripts a migration idempotente e rodar `tooling/passport_security/run_authenticated_idor_test.mjs` contra cada projeto (não há CI que o faça).

### S-02 — MÉDIO/ALTO (CONFIRMADO no SQL; POSSÍVEL no vivo): `REVOKE ... FROM PUBLIC` não remove `anon`

O baseline faz só `revoke all on function ... from public` e concede a `authenticated`. O repositório documenta (`docs/multiclub/32_etapa_m3_2_report.md`) que o Supabase concede `EXECUTE` a `anon` e `service_role` por *default privileges*, e que as migrations legadas faziam `revoke` explícito desses papéis. Em projeto novo, `arena_ranking_for_club` e `arena_user_detail_for_club` (esta sem checagem de `auth.uid()`) ficam chamáveis por `anon`.

### S-03 — MÉDIO (CONFIRMADO): `cpf_is_taken` é executável por `anon`

Serve de **oráculo** para saber se um CPF específico está cadastrado (dado pessoal, LGPD). Sem *rate limit* visível. O app usa a RPC no pré-check do cadastro; a unicidade já é garantida por índice `UNIQUE` em `profiles.cpf`. Alternativas: resposta genérica, *rate limit* ou checar apenas no `signUp`.

### S-04 — MÉDIO (CONFIRMADO; sobe para ALTO quando houver pagamento real): preço e status controlados pelo cliente

- `create_store_order_for_club` grava `p_status`, `p_subtotal`, `p_discount_amount`, `p_shipping_cost`, `p_coupon_code`, `unit_price` e `payment` exatamente como recebidos, e a policy de `INSERT` permite inserir direto na tabela.
- `tickets` e `ticket_orders` têm policies de `INSERT` **e `UPDATE`** `auth.uid() = user_id`, permitindo ao dono editar `status`, `price`, `refunded_at` e `half_price_*` do próprio registro. O app insere pedidos e ingressos direto (`mock_ticket_repository.dart`).
- Hoje o risco é contido porque não há cobrança real; ele cresce se esses registros passarem a conceder acesso ou fulfilment sem revalidação no servidor. O pagamento da loja é simulado e **nenhum PAN/CVV é guardado** (só os 4 últimos dígitos).

### S-05 — MÉDIO/BAIXO (CONFIRMADO): check-in e pontuação confiam no cliente

`upsert_membership_checkin_ticket_for_club` é `SECURITY INVOKER`, não verifica sócio ativo, janela do jogo nem local. `arena_record_score_for_club` limita pontos por tipo de evento, mas `p_event_type`, `p_attempt_number` e `p_was_revealed` são declarados pelo cliente, permitindo fraude de ranking. Impacto em integridade de gamificação, sem dado sensível.

### Demais pontos (Baixo/Info)

- **S-06:** o baseline concede privilégios amplos (incluindo `TRUNCATE`) a `anon`/`authenticated` em quase todas as tabelas; só a RLS protege. Revogar escrita em tabelas de catálogo reduziria a dependência.
- **S-07:** `create_store_order_for_club` e funções de trigger de endereço são `INVOKER` sem `search_path` fixo; o ranking expõe nome completo e avatar de quem pontuou (intencional, mas considerar apelido).
- **S-08:** buckets sem `file_size_limit` nem `allowed_mime_types`.

## 4. Cloudflare Worker (`src/`)

Superfície: GETs públicos de dados públicos e dois POSTs administrativos (`x-sync-key`).

- **W-01 (Baixo):** `/api/image-proxy` usa **allowlist fechada** (não é SSRF aberto), mas a chave de cache é a URL completa (parâmetros extras contornam o cache), repassa `content-type` sem exigir `image/*`, segue redirects e não limita tamanho.
- **W-02 (Baixo):** `slug` (notícias) e `matchId` (OneFootball) entram em URLs de hosts fixos sem validação; impacto baixo.
- **W-03 (Baixo):** chaves de sync comparadas com `!==` (não constante) e sem *rate limit*; as rotas respondem 404 sem chave.
- **W-04 (Info):** CORS `*` e sem WAF/rate limit versionados (dados públicos, sem credencial).
- **W-05 (Baixo):** o Flutter Web servido por `ASSETS` não tem CSP nem `X-Frame-Options`.
- **W-06 (Info):** o mesmo KV é compartilhado pelos 3 Workers e o mesmo `APIFY_TOKEN`; a separação entre clubes é por convenção de chave.

## 5. Edge Functions

As funções de notificação e de limpeza usam `rejectUnlessServiceCaller` (comparação em tempo constante); `delete-account` identifica o usuário só pelo JWT e não exige reautenticação recente (Info). `notifications-test-trigger` compara o secret com `!==` e não usa o *service caller* (Baixo) — convém não deixá-la implantada em produção.

## 6. Cliente Flutter

- **C-01 (Baixo/Info):** sessão do Supabase em `shared_preferences` (padrão do SDK) e `android:allowBackup` não desativado, então o Auto Backup do Android pode copiar o token.
- **C-02 (Baixo, POSSÍVEL):** `sendDefaultPii=false` é correto, mas `tracesSampleRate=1.0`, `dio.addSentry()` e erros do ViaCEP podem levar a URL com o **CEP** do usuário ao Sentry; não há `beforeSend`.
- **C-03 (Info):** sem deep links, sem WebView e sem tráfego *cleartext*; links externos via `launchUrl` sem validar esquema (Baixo).
- **C-04 (Info):** release exige `key.properties` (bom); não há `--obfuscate` verificável no repositório.
- **C-05 (Baixo):** validações de CPF, idade e máscaras só existem no cliente; `profiles_update_own` permite alterar `cpf`/`birth_date`.
- **C-06 a C-08 (Info):** PII (CPF, telefone, nascimento, endereço) protegida por RLS de dono, mas trafega em `user_metadata` no `signUp`; exclusão de conta existe (validar se o cascade cobre pedidos com PII — FKs para `auth.users` **NÃO VERIFICADAS**).

## 7. Cadeia de suprimentos e CI

- **SC-01 (Médio/Baixo):** `.github/workflows/sync_x_posts.yml` roda com `contents: write` e acesso aos *secrets* do X e `VILANOVA_SYNC_KEY`, instalando `Scweet>=5.3,<6` **sem versão/hash fixos** e com *actions* fixadas por tag (não SHA). Uma release comprometida do pacote executaria com esses privilégios. A automação de scraping com cookies de sessão do X também é risco de conta/ToS.
- **SC-02 (Baixo):** `package.json` sem scripts `pre/postinstall`, lockfiles presentes, mas `devDependencies` com ranges `^` e `intl: any`.
- **SC-03 (Info):** `node_modules/` e `build/` não são rastreados.

## 8. Lacunas desta análise

- Banco vivo (grants, `EVENT TRIGGER rls_auto_enable`, objetos criados só pelo dashboard) e deploy real das Edge Functions: **não verificados**.
- `archive/` e ~100 SQLs soltos: só amostrados; `lib/**` foi inspecionado por busca dirigida, não lido integralmente; iOS nativo e o app web não foram auditados em profundidade.
