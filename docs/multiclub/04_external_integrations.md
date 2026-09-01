# 04 — Integrações Externas e APIs

> Mapeamento de todo tráfego de rede que sai do app (Flutter `lib/`), do Worker Cloudflare (`src/`) e das Edge Functions do Supabase (`supabase/functions/`). Gerado em 2026-09-01.

O app Flutter quase nunca fala diretamente com terceiros — a "inteligência" externa (OneFootball, scraping do site oficial, Instagram/Apify, YouTube) vive toda no Worker `goias-app.lucasdiogo1234.workers.dev` (`wrangler.toml` na raiz do repo, código em `src/`). O Flutter só chama diretamente: ViaCEP, IBGE e downloads de PDF/imagem.

---

### OneFootball
- **URL base**: `https://api.onefootball.com/web-experience/pt-br/{time|competicao|match}/...`
- **Tipo**: API JSON interna do site (não documentada publicamente), proxiada pelo Worker
- **Dados**: próximo jogo, rodada atual, detalhe de partida (escalação, eventos, estatísticas), classificação
- **Onde é consumida**: `src/football/providers/onefootball_provider.ts:130-377`; rotas `src/football/{standings,currentRound,team,teamSeason,fixtureDetails}.ts`; Flutter consome via backend próprio (`lib/features/match/data/datasources/football_remote_data_source.dart`)
- **Autenticação**: não
- **Depende de ID/slug do Goiás?**: sim — `GOIAS_ONEFOOTBALL_SLUG="goias-1863"` e `ONEFOOTBALL_COMPETITION_SLUG="brasileirao-serie-b-superbet-119"` em `wrangler.toml:29,35` (este segundo muda a cada temporada)
- **Serviria pra outro clube só trocando o ID?**: parcialmente. Os slugs já são config, mas as ROTAS do Worker são hardcoded pra um único clube — o endpoint se chama `/api/football/team/goias` (`src/index.ts:29`, comentário em `src/football/team.ts:18`: "Só existe /team/goias por enquanto — o app tem um único time"), e as chaves de cache também (`football.team.goias`). Multi-clube exigiria generalizar a rota (ex.: `/team/:clubSlug`), não é só troca de 1 variável.
- **Estabilidade**: não documentada oficialmente — endpoint interno reverse-engineered (comentado em `wrangler.toml:10-17`). O próprio `wrangler.toml` registra que dois outros provedores (campeonato-brasileiro-api, TheSportsDB) já foram removidos por fricção/rate limit.

### Site oficial do Goiás — Notícias (goiasec.com.br)
- **URL base**: `https://www.goiasec.com.br/noticias` e `/noticias/{slug}`
- **Tipo**: scraping de HTML (HTMLRewriter do Cloudflare + regex)
- **Dados**: listagem e conteúdo integral de notícias, parseado de um site Next.js sem API pública
- **Onde é consumida**: `src/news/scraper.ts` (`scrapeNewsList:31`, `scrapeNewsArticle:127`); Flutter via `/api/news` e `/api/news/:id`
- **Autenticação**: não (só User-Agent de bot `GoiasAppBot/1.0`)
- **Depende de ID/slug do Goiás?**: sim — `SITE_ORIGIN` hardcoded (`https://www.goiasec.com.br`), parser acoplado ao template HTML específico
- **Serviria pra outro clube só trocando o ID?**: **não**. É scraping estrutural de UM site (marcadores como classe `desc-post-interno`, `bg-[#004C1B]` — comentado em `scraper.ts:118-121`). Outro clube com outro site precisaria de parser novo do zero.
- **Estabilidade**: frágil por natureza — o próprio código documenta que qualquer mudança de template quebra a extração silenciosamente (`article.ts:9-13`, `available: false` é o fallback esperado).

### Site oficial do Goiás — CDN estático (static.goiasec.com.br)
- **Tipo**: hospedagem de arquivos estáticos
- **Dados**: imagens de notícias, PDFs de transparência (URLs individuais hardcoded em `supabase/club_transparency.sql`)
- **Serviria pra outro clube só trocando o ID?**: não — é o CDN do site de um clube específico.

### Instagram (via Apify)
- **URL base**: `https://api.apify.com/v2/actor-tasks/{taskId}/run-sync-get-dataset-items`
- **Tipo**: scraping-as-a-service de terceiro, disparado por Cron Trigger do Worker
- **Dados**: posts recentes do Instagram do Goiás
- **Onde é consumida**: `src/social/instagram_sync.ts:123-142`, só pelo `scheduled()` do Worker 3x/dia + rota admin protegida; resultado persistido no Workers KV
- **Autenticação**: sim — Bearer token (`APIFY_TOKEN`, secret) + `APIFY_INSTAGRAM_TASK_ID="81AnzgCcTifiDW6VH"` (não-secret, `wrangler.toml:42`)
- **Depende de ID/slug do Goiás?**: sim — a Task Apify está fixada em `@goiasoficial` (configurado no painel Apify, fora deste repo)
- **Serviria pra outro clube só trocando o ID?**: **sim, em princípio** — bastaria criar/trocar a Task apontando pro handle do outro clube. É o mais "plugável" dos três provedores sociais.
- **Estabilidade**: depende de scraping não-oficial do Instagram — sujeito a rate limit/bloqueio da Meta; falhas não sobrescrevem o KV (mantém último dado válido).

### YouTube Data API v3 (Google)
- **URL base**: `https://www.googleapis.com/youtube/v3/{channels|playlistItems|videos}`
- **Tipo**: API oficial do Google, REST, com chave
- **Dados**: vídeos recentes do canal `@TVGoias`
- **Onde é consumida**: `src/social/providers/youtube_provider.ts` (3 chamadas), ativado condicionalmente se `YOUTUBE_API_KEY` existir
- **Autenticação**: sim — API key (secret do Worker)
- **Depende de ID/slug do Goiás?**: sim — `TV_GOIAS_HANDLE = '@TVGoias'` hardcoded (canal do parceiro de mídia, não do clube em si)
- **Serviria pra outro clube só trocando o ID?**: **sim, o mais simples de todos** — trocar a constante do handle (a API key é da conta Google do desenvolvedor, reutilizável).
- **Estabilidade**: API oficial e documentada, com cota diária.

### X / Twitter (@goiasoficial)
- **Tipo**: **NÃO é integração ao vivo** — é um snapshot estático (`src/social/data/x_posts.json`), embutido no build do Worker, atualizado manualmente/offline por um script Python (`scripts/social/sync_x_posts.py`) usando a lib não-oficial "Scweet" (scraping autenticado do X)
- **Onde é consumida**: `src/social/providers/x_provider.ts:2,21` (import direto do JSON)
- **Autenticação**: só no processo offline de sync (`X_AUTH_TOKEN`), nunca em runtime do Worker
- **Depende de ID/slug do Goiás?**: sim — `HANDLE = "goiasoficial"` hardcoded no script Python
- **Serviria pra outro clube só trocando o ID?**: parcialmente — trocaria o handle e rodaria o script de novo, mas é processo **manual/offline por pessoa**, não troca de config em produção.
- **Estabilidade**: **muito frágil e não-oficial** — X não tem API pública gratuita pra esse uso; Scweet quebra a qualquer mudança do X. **Achado importante**: "posts do X" hoje não atualiza sozinho.

### Firebase Cloud Messaging (push)
- **Tipo**: API oficial do Google (FCM HTTP v1), OAuth2/service account
- **Onde é consumida**: token obtido no cliente (`push_notification_service.dart:79`), envio real por `supabase/functions/notifications-dispatch/index.ts:148` via `FCM_SERVICE_ACCOUNT_JSON`
- **Depende de ID/slug do Goiás?**: não diretamente — depende do projeto Firebase configurado, mas o mecanismo é genérico (a lógica "gol do Goiás" está na Edge Function, é regra de negócio, não a integração em si)
- **Serviria pra outro clube só trocando o ID?**: sim — cada app teria seu próprio projeto Firebase.
- **Estabilidade**: oficial, documentada, estável.

### ViaCEP
- **URL base**: `https://viacep.com.br/ws/{cep}/json/`
- **Tipo**: API pública REST, sem chave
- **Onde é consumida**: `lib/features/membership/data/viacep_data_source.dart:13,27`
- **Depende de ID/slug do Goiás?**: não — genérica, zero acoplamento
- **Serviria pra outro clube só trocando o ID?**: sim, direto.

### IBGE — Localidades
- **URL base**: `https://servicodados.ibge.gov.br/api/v1/localidades/estados/{uf}/municipios`
- **Tipo**: API pública oficial do governo brasileiro
- **Onde é consumida**: `lib/features/membership/data/ibge_location_data_source.dart:11-13`
- **Serviria pra outro clube só trocando o ID?**: sim, já totalmente genérica.

### CDN do Instagram (proxy de imagem)
- **Tipo**: proxy de imagem (contorna CORS/hotlink-protection)
- **Onde é consumida**: `src/media/imageProxy.ts:12-13,52-59`, espelhado em `lib/shared/utils/image_proxy.dart:13-17`
- **Depende de ID/slug do Goiás?**: não — infraestrutura genérica.

### Sentry
- **Tipo**: SaaS de monitoramento de erros
- **Onde é consumida**: `lib/core/config/sentry_config.dart`, inicializado em `lib/main.dart:62-68`
- **Depende de ID/slug do Goiás?**: não — conta do desenvolvedor, não do clube.

### Futebol de Goyaz (futeboldegoyaz.com.br)
- **Tipo**: scraping via pacote Python standalone (`_competitions_pkg/goias_app_competitions/`), executado manualmente fora do runtime do app
- **Dados**: histórico completo de competições — edições, jogos, classificações, artilharia, escalações históricas
- **Onde é consumida**: **NÃO é consumida em runtime hoje.** `README.md:9` descreve o pipeline pretendido: "Futebol de Goyaz → coletor → JSON/JSONL → validação → Supabase → Flutter" — **pipeline pausado antes da etapa de Supabase**, sem tabela nem UI consumindo isso ainda (confirma memória do projeto).
- **Depende de ID/slug do Goiás?**: parcialmente — o coletor puxa a competição inteira (não filtra por clube na fonte)
- **Serviria pra outro clube só trocando o ID?**: sim, em grande parte — a arquitetura já é "edição/fase sem hardcode de formato por campeonato", adaptar seria majoritariamente sobre quais competições incluir no escopo.
- **Estabilidade**: não-oficial, mas o pacote já tem rate-limiting e cache próprios por respeito ao site de origem.

### Cloudflare Workers KV (SOCIAL_FEED_KV)
- **Tipo**: infraestrutura da própria conta Cloudflare (não é fonte de terceiro)
- **Dados**: cache dos últimos posts do Instagram (populado pelo Cron + Apify)
- **Serviria pra outro clube só trocando o ID?**: sim, infraestrutura reutilizável com namespace próprio por clube.

---

## Observações adicionais

1. Além de OneFootball + notícias + feed social, o app também depende de ViaCEP, IBGE, Firebase/FCM, Sentry e um pipeline histórico ainda não plugado (Futebol de Goyaz) — superfície de rede real maior do que o "óbvio".
2. **X/Twitter não é integração ao vivo** — é JSON estático sincronizado manualmente. Isso é essencial saber antes de planejar Juventude: "posts do X" hoje não é algo que atualiza sozinho.
3. O acoplamento ao Goiás nas rotas do Worker é maior do que sugerem as variáveis de ambiente. `wrangler.toml` já parametriza os slugs do OneFootball, mas os **nomes das rotas** (`/api/football/team/goias`), **chaves de cache** (`football.team.goias`) e o **scraper de notícias** (hardcoded pra `goiasec.com.br`) são específicos de um único clube.
4. **YouTube e Apify/Instagram são os mais "plugáveis"** (trocar handle/Task ID). **ViaCEP, IBGE, FCM e Sentry já são genéricos**. **Site oficial (notícias) e Futebol de Goyaz exigem trabalho real por clube** (scraping/parser específico não generaliza).
5. Links de saída (abertos via `url_launcher`, nunca fetched pelo app) não contam como "fonte de dado": `lib/features/profile/data/social_links_data.dart`, `membership_contact_config.dart`, `club_titles_data.dart`/`club_timeline_data.dart`/`club_history_data.dart`, `partners_data.dart` — só guardam URL estática pra abrir no navegador.
6. O Supabase em si não foi tratado como "fonte externa" aqui — é o backend próprio do app, presumivelmente replicável 1:1 por clube (cada app teria seu próprio projeto ou schema Supabase).
