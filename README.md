# Goiás EC — App do Torcedor

Aplicativo oficial (não-oficial, em desenvolvimento) do ecossistema digital do torcedor esmeraldino: acompanhar jogos e classificação, comprar ingresso, virar Sócio Esmeralda e seguir as redes do clube, tudo num só lugar.

- **App**: Flutter (Android, iOS, Web)
- **Backend**: Cloudflare Worker (TypeScript) — agrega dados públicos de futebol e das redes sociais do clube
- **Auth/Conta**: Supabase (e-mail + senha)

## Funcionalidades

### Início
- Cabeçalho com identidade do clube.
- Card de contagem regressiva para a próxima partida do Goiás (desaparece automaticamente na hora do jogo).
- Banner do Sócio Esmeralda.
- Carrossel de parceiros oficiais.

### Jogos
- Classificação da Série B, com o Goiás destacado.
- Rodada atual (todos os jogos, com placar parcial e indicador "ao vivo" enquanto a partida está em andamento, e placar final quando encerrada), com navegação pras rodadas anteriores/seguintes.
- Próximo jogo e últimos resultados do Goiás.
- Detalhes de cada partida: placar, timeline de eventos e escalações titulares.

### Notícias
- Leitor nativo de matérias do clube, com backend próprio de scraping.

### Ingressos
- Setores do estádio disponíveis para compra.

### Sócio Esmeralda
- **Não-sócio**: vitrine com os seis planos oficiais (Nossa Gente, Nossa História, Nossa Garra, Nossa Glória, Nossa Família, Plano VIP) em carrossel, com página de detalhes por plano.
- **Associação em 3 etapas** (dados de acesso, dados cadastrais, endereço) + revisão, com pré-preenchimento a partir do cadastro do usuário e aceite obrigatório do Regulamento do Sócio Esmeralda.
- **Sócio ativo**: carteirinha digital, plano atual com benefícios, próximo jogo com check-in (preparado, sem integração real ainda), e opções de gestão (Minha Associação, Dependentes, Pagamentos, Histórico).
- **Regulamento do Sócio Esmeralda**: leitura completa dentro do app, organizada por seção com índice navegável.
- **Dúvidas Frequentes**: 33 perguntas oficiais do programa, com busca e filtro por categoria.
- FAQ e Regulamento são servidos pelo Supabase (editáveis pelo dashboard sem novo build), com fallback local se a tabela estiver vazia ou sem rede. A associação em si (planos, cadastro, carteirinha) ainda roda sobre um repositório mock local — pronta pra trocar por uma integração real sem reescrever telas.

### Arena Esmeraldina
- **Escalação da Torcida**: em destaque no topo quando há próximo jogo — torcedores votam na escalação provável do Goiás e veem o time mais escalado pela torcida.
- Hub de minigames sobre a história e o elenco do Goiás: **Quiz do Verdão**, **Adivinhe a Escalação** (escalações de partidas históricas), **Adivinhe o Jogador** (pela trajetória na carreira) e **Quem Vestiu o Manto?** (jogador secreto por foto embaçada e pistas).
- Progresso e ranking persistentes entre os jogos, com conteúdo (perguntas, partidas, jogadores) servido pelo Supabase.

### O Clube
- Hub institucional com identidade do clube: **História**, **Linha do Tempo**, **Títulos** (34 títulos oficiais) e **Hino & Músicas**.
- Reaproveita as telas de **Elenco** e **Parceiros**.

### Mídia (Goiás na Rede)
- Feed unificado de X (Twitter) e YouTube, com filtro por plataforma.

### Perfil e Parceiros
- Dados do usuário autenticado, com edição de dados pessoais, troca de senha e upload de avatar.
- Tema claro/escuro.
- Rede de parceiros do clube, com benefícios.

### Conta
- Login, cadastro, recuperação de senha e confirmação de e-mail via Supabase Auth.
- Termos de Uso e Política de Privacidade.
- Exclusão de conta (remove a conta e todos os dados vinculados, com dupla confirmação).

## Arquitetura

Clean Architecture por feature, sem geração de código:

```
lib/
  core/           # DI (get_it), roteamento (go_router), tema, config, network
  features/
    <feature>/
      domain/       # entidades, contratos de repositório
      data/         # DTOs, datasources, implementações (reais e mock)
      presentation/ # Cubits (flutter_bloc), páginas, widgets
  shared/         # widgets e utilitários reaproveitados entre features
```

- **Estado**: `flutter_bloc` (Cubit) + `equatable`.
- **DI**: `get_it`.
- **Navegação**: `go_router`, com redirecionamento automático baseado no estado de autenticação.
- **Rede**: `dio`, com repositórios mock e reais atrás da mesma interface — a UI nunca sabe qual está usando.

## Backend (Cloudflare Worker)

Fica em `src/`, escrito em TypeScript, deployado via `git push` (deploy automático ligado ao repositório).

| Rota | Descrição |
|---|---|
| `GET /api/football/standings` | Classificação da Série B |
| `GET /api/football/current-round` | Jogos da rodada atual |
| `GET /api/football/team/goias` | Próximo jogo e últimos resultados do Goiás |
| `GET /api/football/fixtures/:id` | Detalhes de uma partida |
| `GET /api/football/discover` | Utilitário de setup (achar IDs do Goiás nos provedores) |
| `GET /api/social/feed` | Feed social unificado (X + YouTube) |

Fontes de dados esportivos gratuitas (sem custo, sem chave sensível): `campeonato-brasileiro-api` (classificação e rodada atual) + TheSportsDB (próximo jogo e resultados recentes do Goiás). Respostas cacheadas por endpoint (`_lib/cache.ts`), com `CACHE_VERSION` em `wrangler.toml` para invalidar o cache quando o formato mudar.

Os posts do X são sincronizados uma vez por dia por uma GitHub Action (`.github/workflows/sync_x_posts.yml`), que faz scraping do perfil oficial via Scweet e commita o resultado em `src/social/data/x_posts.json` — o Worker lê esse arquivo em build time, sem chamada externa em runtime.

## Rodando o projeto

### App Flutter

```bash
flutter pub get
flutter run
```

A configuração do Supabase já vem com valores padrão embutidos (`lib/core/config/supabase_config.dart`); para apontar para outro projeto, sobrescreva via `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

### Worker (Cloudflare)

```bash
npm install
npm run dev:worker   # ambiente local
npm run deploy       # deploy manual, se precisar
```

Na prática o deploy é automático a cada `git push` para a branch principal — normalmente não é preciso rodar `wrangler deploy` manualmente.

## Testes e qualidade

```bash
flutter analyze
flutter test
```
