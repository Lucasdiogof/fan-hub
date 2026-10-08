<p align="center">
  <img src="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" width="112" alt="Ícone do Goiás App">
</p>

<h1 align="center">Goiás App</h1>

<p align="center">
  App do torcedor do Goiás: jogos, conteúdo do clube, mídia, ingressos, sócio e uma Arena de minigames num só lugar.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/Cloudflare_Workers-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Workers">
  <img src="https://img.shields.io/badge/plataformas-Android_·_iOS_·_Web-555555" alt="Plataformas: Android, iOS e Web">
</p>

<p align="center">
  <a href="README.md">English</a> · <b>Português</b> · <a href="README.es.md">Español</a>
</p>

---

O Goiás App reúne num só app, para o torcedor do Goiás, a agenda de jogos, o placar ao vivo, a história do clube, notícias e redes sociais, ingressos, sócio torcedor, loja e um conjunto de jogos. É um produto independente: não é um app oficial e não representa parceria nem endosso do Goiás Esporte Clube.

Tecnicamente, o app é construído sobre o **Fan Hub**, uma base multi-clube: um único código Flutter que gera um build separado para cada clube, cada um com o próprio backend.

## Disponibilidade

- **Android**, **iOS** e **Web (PWA instalável)**, a partir de uma única base em Flutter.
- **Idiomas**: português (Brasil), inglês e espanhol, com escolha independente do idioma do aparelho.
- **Temas**: claro, escuro ou seguindo o sistema.

## Telas

### O que o torcedor usa

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/home.webp" width="220" alt="Tela inicial do app com o próximo jogo, contagem regressiva e acesso a ingressos"><br><sub><b>Home</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/matches.webp" width="220" alt="Aba Jogos com o próximo jogo, botão de ingressos e a lista de partidas da rodada"><br><sub><b>Partidas</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/standings.webp" width="220" alt="Tabela de classificação da Série B com o Goiás destacado"><br><sub><b>Classificação</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/calendar.webp" width="220" alt="Aba Jogos com o calendário mensal de partidas"><br><sub><b>Jogos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/socio.webp" width="220" alt="Tela do programa de sócio com os planos disponíveis"><br><sub><b>Sócio</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/store.webp" width="220" alt="Loja do app com categorias de produtos e acesso a compras e pedidos"><br><sub><b>Loja</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/club.webp" width="220" alt="Menu do clube rolado: Ídolos, Diretoria, Elenco, Hino &amp; Músicas, Transparência e Parceiros"><br><sub><b>O Clube</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/anthem.webp" width="220" alt="Player do hino com controles de reprodução, volume e letra"><br><sub><b>Hino &amp; Músicas</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/guess-shirt.webp" width="220" alt="Jogo em que o torcedor adivinha o nome do jogador da camisa 11 letra a letra, com teclado na tela"><br><sub><b>Adivinhe a Escalação</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/guess-player.webp" width="220" alt="Adivinhe o Jogador: tabela de carreira com clubes, jogos e gols e campo para chutar o nome"><br><sub><b>Adivinhe o Jogador</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/identity-quiz.webp" width="220" alt="Pergunta do teste de identidade futebolística com quatro frases para escolher"><br><sub><b>Identidade Futebolística</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/identity-result.webp" width="220" alt="Resultado “O Refinado” com marcas e atributos do estilo de jogo"><br><sub><b>Que craque você é?</b></sub></td></tr>
</table>

### Clube e conteúdo

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/club-home.webp" width="220" alt="Menu institucional do clube com História, Títulos, Ídolos, Diretoria, Elenco e Hino"><br><sub><b>Menu do clube</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/titles.webp" width="220" alt="Tela de títulos do clube com a contagem de títulos principais e os anos de cada campeonato"><br><sub><b>Títulos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/board.webp" width="220" alt="Tela da diretoria do clube com gestão executiva e in memoriam"><br><sub><b>Diretoria</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/idols.webp" width="220" alt="Lista de ídolos do clube com foto, período e uma descrição curta"><br><sub><b>Ídolos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/squad.webp" width="220" alt="Elenco do clube em grade, com foto e número de cada jogador"><br><sub><b>Elenco</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/player.webp" width="220" alt="Perfil de um jogador com número, idade, nacionalidade, altura, pé e carreira"><br><sub><b>Perfil do jogador</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/transparency.webp" width="220" alt="Tela de transparência com editais, estatuto e exercícios organizados por ano"><br><sub><b>Transparência</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/songs.webp" width="220" alt="Lista com as versões do hino e as músicas da torcida"><br><sub><b>Hino &amp; Músicas</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/document.webp" width="220" alt="Edital de convocação aberto no visualizador de PDF com botão de compartilhar"><br><sub><b>Documentos</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/partners.webp" width="220" alt="Grade com as marcas parceiras do clube"><br><sub><b>Parceiros</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/media.webp" width="220" alt="Aba Mídia com publicações do Instagram do clube e abas de notícias, YouTube e X"><br><sub><b>Mídia</b></sub></td></tr>
</table>

### Ingressos e sócio

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/tickets.webp" width="220" alt="Tela de ingressos com o próximo evento, botão de compra e acesso rápido a meus ingressos e pedidos"><br><sub><b>Ingressos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/ticket-sectors.webp" width="220" alt="Seleção de setores e quantidade de ingressos por categoria, com setor do visitante"><br><sub><b>Setores</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/purchase.webp" width="220" alt="Resumo da compra com itens, total, dados dos titulares e aviso de demonstração"><br><sub><b>Resumo da compra</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/purchased.webp" width="220" alt="Confirmação de ingresso comprado com atalho para Meus ingressos"><br><sub><b>Compra concluída</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/my-tickets.webp" width="220" alt="Lista de ingressos próximos e histórico, com selo de demonstração e ação de reembolso"><br><sub><b>Meus ingressos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/ticket.webp" width="220" alt="Ingresso digital com dados do jogo, setor, titular e QR code, marcado como demonstração"><br><sub><b>Ingresso</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/member-signup.webp" width="220" alt="Primeira etapa do cadastro de sócio, com plano escolhido e dados de acesso"><br><sub><b>Cadastro de sócio</b></sub></td></tr>
</table>

### Arena e passaporte

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/arena.webp" width="220" alt="Arena Esmeraldina com o próximo jogo, Escalação da Torcida, Passaporte e desafios"><br><sub><b>Arena Esmeraldina</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/challenges.webp" width="220" alt="Desafios da Arena: Quiz do Verdão, Adivinhe a Escalação, Adivinhe o Jogador e Quem Vestiu o Manto"><br><sub><b>Desafios</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/crowd.webp" width="220" alt="Escalação da Torcida: campo com a formação mais votada e o percentual de cada jogador"><br><sub><b>Time da torcida</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/pitch.webp" width="220" alt="Montagem da escalação no campo com escolha de formação e botão de confirmar"><br><sub><b>Escale seu time</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/guess-lineup.webp" width="220" alt="Adivinhe a Escalação: campo com a escalação de uma partida histórica a ser descoberta camisa a camisa"><br><sub><b>Campo da escalação</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/who-wore.webp" width="220" alt="Quem Vestiu o Manto: foto desfocada de um ex-jogador, busca por nome e tabela de pistas"><br><sub><b>Quem Vestiu o Manto?</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/who-wore-hit.webp" width="220" alt="Resultado de Quem Vestiu o Manto com a foto revelada e o número de tentativas"><br><sub><b>Resposta certa</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/passport.webp" width="220" alt="Passaporte com a temporada, jogos em que o torcedor esteve e resultado de cada um"><br><sub><b>Passaporte Esmeraldino</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/pt-BR/trajectory.webp" width="220" alt="Resumo da trajetória do torcedor com jogos, estádios, temporadas, vitórias, gols e jogo mais memorável"><br><sub><b>Minha trajetória</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/pt-BR/ranking.webp" width="220" alt="Ranking da Torcida com posição, avatar, nome e pontuação de cada participante"><br><sub><b>Ranking da Torcida</b></sub></td></tr>
</table>

## Funcionalidades

**Início**
- Último resultado, próximo jogo e atalhos para o clube, a Arena e a loja.

**Jogos**
- Próximo jogo, rodada atual com navegação entre rodadas, calendário mensal e tabela de classificação completa com o clube em destaque.
- Detalhe da partida com placar, linha do tempo de eventos, estatísticas e escalações em campinho.
- Placar ao vivo com indicador de jogo em andamento.

**Clube**
- História, títulos por competição e ano, ídolos, diretoria e elenco, com perfil e carreira de cada jogador.
- Hino e músicas da torcida com player de áudio e letra na tela.
- Documentos de transparência organizados por categoria, abertos em PDF dentro do app e compartilháveis.
- Parceiros.

**Mídia**
- Notícias do clube lidas dentro do app, além de Instagram, YouTube e X num feed só, com filtro por plataforma.

**Sócio torcedor**
- Planos com benefícios, adesão passo a passo com busca de endereço pelo CEP, regulamento e perguntas frequentes.

**Ingressos**
- Fluxo de ingresso para o próximo jogo: setor, categoria (inteira, meia e outras) e quantidade, resumo da compra com os titulares e confirmação.
- "Meus ingressos" com próximos jogos e histórico, e ingresso digital com QR code, também disponível em PDF.

**Loja**
- Catálogo por categoria, carrinho, checkout e histórico de pedidos.

**Arena Esmeraldina**
- **Escalação da Torcida**: o torcedor vota na escalação do próximo jogo e vê o time mais votado.
- **Quiz** sobre a história do clube, com níveis de dificuldade.
- **Adivinhe a Escalação**: monte a escalação de uma partida histórica, camisa por camisa.
- **Adivinhe o Jogador**: descubra o jogador pelas pistas da carreira (clubes, jogos e gols).
- **Quem Vestiu o Manto?**: foto desfocada e pistas reveladas a cada tentativa.
- **Testes de perfil**: um quiz de identidade no futebol que associa o torcedor a um perfil de jogador, e um teste de identidade tática.
- **Ranking da torcida**: pontuação somada entre os jogos, com visão geral, mensal e semanal.

**Passaporte Esmeraldino**
- O torcedor registra os jogos a que foi, temporada a temporada, com ranking do passaporte e um resumo "Minha trajetória" com seus números.

**Notificações**
- Push para eventos da partida ao vivo (início, gols, intervalo, segundo tempo e fim de jogo), com preferências por usuário.

**Conta**
- Cadastro com verificação de e-mail, login, recuperação de senha, dados pessoais, endereços, avatar, e termos de uso e política de privacidade no app.
- Exclusão de conta pelo próprio usuário.

## Arquitetura

- **Um código, um build por clube.** A identidade, o conteúdo e as features de cada clube ficam numa configuração de clube escolhida no build (`APP_CLUB` mais flavors de Android/iOS). Features que um clube não oferece somem da navegação e são bloqueadas no roteador.
- **Backend isolado por clube.** Cada clube tem o próprio projeto Supabase e o próprio Cloudflare Worker, com as mesmas migrations e o mesmo código de Worker. O isolamento dos dados vem dessa separação física; as colunas `club_id` são uma segunda camada defensiva.
- **Duas fontes de dados no app.**
  - O **Cloudflare Worker** (TypeScript) entrega dados esportivos públicos, notícias e o feed de redes sociais, com cache por endpoint, armazenamento em KV, sincronizações agendadas e proxy de imagens.
  - O **Supabase** guarda tudo que é ligado a um usuário ou ao conteúdo do clube: autenticação, sócio, ingressos e pedidos, conteúdo da Arena, progresso e rankings, e o passaporte.
- **Regras no servidor.** As tabelas têm Row Level Security, e as escritas que afetam pontuação, ranking, sócio ou pedidos passam por RPCs `security definer`: o cliente nunca define os próprios resultados.
- **Jogos ao vivo.** O app consulta os dados da partida ao vivo a cada 45 segundos. No servidor, um job `pg_cron` chama a cada minuto uma Edge Function que detecta os eventos da partida e envia push pelo Firebase Cloud Messaging. O app não usa Supabase Realtime.
- **Comércio em modo demonstração.** Setores e preços de ingresso e o catálogo da loja vêm de dados locais, e não existe gateway de pagamento. Pedidos, ingressos e check-ins do usuário são gravados no Supabase atrás de interfaces de repositório, então um provedor real pode ser conectado sem mudar as telas.
- **App Flutter** com Clean Architecture organizada por feature (domain, data, presentation), Cubits para estado, `get_it` para injeção de dependência e `go_router`. Um controle de versão pode exigir atualização do app quando uma versão mínima é definida.
- **Observabilidade** com Sentry.

## Tecnologias

| Camada | Tecnologia |
| --- | --- |
| App | Flutter, Dart |
| Estado | `flutter_bloc` (Cubit) + `equatable` |
| DI / Navegação | `get_it`, `go_router` |
| Rede | `dio` (Worker), `supabase_flutter` (Supabase) |
| Backend | Supabase: Auth, PostgreSQL, RLS, RPCs, Storage, Edge Functions (Deno), `pg_cron` |
| Borda | Cloudflare Workers (TypeScript), Workers KV |
| Push | Firebase Cloud Messaging |
| Motor de minigame | Flame |
| Observabilidade | Sentry |
| Testes | `flutter_test`, Vitest (Worker) |

## Estrutura do projeto

```
lib/
├── core/           configuração e capacidades do clube, DI, rotas, tema, l10n, rede
├── features/       home, match, club, squad, news, social, membership, ticket, store,
│                   arena, crowd_lineup, passport, notifications, partners, profile,
│                   auth, release_gate, splash
├── shared/         widgets reutilizáveis
└── l10n/           arquivos ARB por idioma e por clube

src/                Cloudflare Worker (dados esportivos, notícias, feed social, proxy de imagens)
supabase/           migrations, SQL e Edge Functions
docs/architecture/  notas de arquitetura, fluxo de dados, multi-clube, segurança e testes
```

## Rodando localmente

Requisitos: Flutter (canal stable) e Node.js para o Worker.

```bash
flutter pub get
flutter run --flavor goias --dart-define=APP_CLUB=goias
```

Na web, `--flavor` não é usado:

```bash
flutter run -d chrome --dart-define=APP_CLUB=goias
```

Worker (Cloudflare):

```bash
npm install
npm run dev:worker
```

Verificações:

```bash
flutter analyze
flutter test
npm run test:worker
```

Mais detalhes em [`docs/architecture`](docs/architecture/README.md).

## Status do projeto

Em desenvolvimento. As funções de comércio (ingressos, loja e pagamento do sócio) rodam em modo demonstração, sem pagamento real.

## Licença

Nenhuma licença open source é concedida. O código está visível como parte de um portfólio; todos os direitos reservados.

O Goiás App é um produto independente. Não representa parceria, contrato ou endosso oficial do Goiás Esporte Clube. O nome, o escudo e as demais marcas do clube pertencem aos seus respectivos donos.

## Sobre

Desenvolvido por Lucas Diogo França. Case: [lucksrei.com/projects/fan-hub](https://lucksrei.com/projects/fan-hub/)
