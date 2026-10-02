# Mapa de features

> Fonte: `lib/features/*`, `lib/core/club/*_club_config.dart` e os repositórios em `data/`. Método e limitações no [README](README.md). Itens não confirmados no código estão marcados **NÃO VERIFICADO**.

O app tem **18 features** em `lib/features/`. Cada uma segue (com desvios anotados) `presentation/` + `domain/` + `data/`.

## 1. Disponibilidade por clube (capabilities)

Definidas em `ClubCapabilities` (`lib/core/club/club_capabilities.dart`) e aplicadas em dois lugares: no `redirect` do router (`capability_route_gate.dart`, que leva a `/feature-unavailable`) e na composição das abas da Home.

| Capability | Goiás | Bragantino | Vila Nova |
|---|:-:|:-:|:-:|
| Partidas, notícias, social, clube, parceiros, sócio, passaporte | sim | sim | sim |
| Loja (`hasStore`) | sim | sim | **não** |
| Ingressos (`hasTickets`) | sim | **não** | sim |
| Escalação da torcida (`hasCrowdLineup`) | sim | **não** | **não** |
| Jogos da Arena habilitados | 6 | 6 | 6 |
| Modo de comércio (loja/ingressos/sócio) | `demo` | `demo` | `demo` |

Os 6 jogos da Arena: `quiz`, `lineup`, `career_path`, `guess_player`, `player_identity`, `tactical_identity` (o *Penalty* é uma rota à parte). Recursos exclusivos do Goiás: escalação da torcida (elenco fixo em `goias_squad.dart`), vídeo de splash e fallback offline dos minijogos.

## 2. Features

| Feature | Propósito | Backend utilizado | Observações |
|---|---|---|---|
| `arena` | Hub de minijogos e ranking | RPCs `arena_*_for_club`; tabelas `quiz_*`, `guess_players`, `career_players`, `lineup_*`, `arena_*`, `player_identity_results`, `tactical_identity_results` | Sub-features por jogo em `games/<jogo>/` (≈104 arquivos) e `ranking/`. Penalty é um `GameWidget` Flame em tela cheia e **não** pontua |
| `auth` | Login, cadastro em 3 passos com OTP, reset de senha | Supabase Auth, RPC `cpf_is_taken`, Edge `delete-account` | `AuthCubit` move router, push, cache e sócio |
| `club` | Conteúdo institucional (história, títulos, ídolos, diretoria, transparência, hino) | `club_board_*`, `club_transparency_*` | Muito conteúdo por clube em arquivos de dados |
| `crowd_lineup` | Voto na escalação da torcida por partida | `match_lineup_votes`, RPC `crowd_lineup_for_club` | Só Goiás |
| `home` | Aba Home e *shell* de 5 abas | usa `FootballRepository` e `CrowdLineupRepository` | Só `presentation/`; abas variam por capability |
| `match` | Jogos, calendário, competições, classificação, detalhe e ao vivo | Worker `/api/football/*` | *Polling* de 45 s; fonte externa OneFootball |
| `membership` | Sócio torcedor: planos, adesão, regulamento, FAQ, CEP | RPCs `get_my_membership_for_club`, `subscribe_to_plan_for_club`; `membership_faq_*`; ViaCEP/IBGE | Planos vêm de `ClubConfig.membershipProgram`, **não** do servidor; `checkIn` do repositório é *stub* |
| `news` | Notícias por clube | Worker `/api/news` | Scraping no Worker, parsers por clube |
| `notifications` | Preferências e serviço FCM | `user_notification_tokens`, `user_notification_preferences` | `PushNotificationService` fora de cubit |
| `partners` | Parceiros/patrocinadores | conteúdo local | Padrão enxuto |
| `passport` | Passaporte do torcedor: jogos presenciais, ranking, trajetória | 11 RPCs `passport_*` | Duas UIs (`v1`/`v2`, `PassportUiConfig.current = v2`) |
| `profile` | Perfil, dados, endereço, segurança, tema, idioma, excluir conta, termos | `profiles`, `user_addresses`, Storage `avatars` | Rota de notificações nunca é gateada por capability |
| `release_gate` | Tela de "atualização obrigatória" | `app_release_requirements` | Só `presentation/`; lógica em `core/release` |
| `social` | Feed de mídia (Instagram, X, YouTube) | Worker `/api/social/feed` | Agregado no Worker |
| `splash` | Splash em vídeo/logo estático | — | Só `presentation/`; pré-carrega `HomeCubit` |
| `squad` | Elenco e detalhe de jogador | tabela `squad_members` | Detalhe passa o modelo via `state.extra` |
| `store` | Catálogo, carrinho, checkout, pedidos, endereços | RPC `create_store_order_for_club`, `store_orders`, `delivery_addresses` | Catálogo é `MockStoreRepository` (JSON em assets); pedidos reais no Supabase |
| `ticket` | Ingressos, check-in, compra, meus pedidos | `tickets`, `ticket_orders`, `ticket_checkin_decisions`, RPC `upsert_membership_checkin_ticket_for_club`, Storage `half_price_proofs` | `MockTicketRepository`: setores/preços de fixture, dados do usuário **persistidos** no Supabase; sem gateway |

## 3. Como o "Mock" deve ser lido

`MockTicketRepository` e `MockStoreRepository` são ligados no DI em todos os builds (`injection_container.dart`). Eles **não** são só dados em memória:

- **Ingressos:** setores, preços e janelas vêm de fixtures (`mock_ticket_fixture.dart`, `goias_ticket_content.dart`, `vilanova_ticket_content.dart`), aplicados à partida real devolvida pelo Worker. Check-in, ingressos e pedidos do usuário são gravados no Supabase. Não há API nem pagamento reais.
- **Loja:** o catálogo é local (JSON em assets); cupons e frete são simulados (`VERDAO10`, `SOCIO15`, frete grátis acima de R$ 399,90); o pedido é criado pela RPC real.

O contrato de domínio (`TicketRepository`, `StoreRepository`) permite trocar a implementação sem mexer nas telas, segundo o comentário da própria classe. Riscos associados em [security-overview.md](security-overview.md) (S-04).

## 4. Dependência entre features

Imports entre features (contagem de arestas `imports`, derivada do grafo): quase todo o acoplamento aponta para `core` e `shared` — por exemplo `arena→core` (205), `membership→core` (129), `passport→core` (85), `store→core` (84), `arena→shared` (80). Medido sobre os imports de `lib/`: **nenhum** arquivo de `domain` importa `presentation` ou `data`, e há **um** caso de `presentation` de uma feature importando o `data` de outra (`squad/.../squad_member_detail_page.dart` → `profile/data/social_links_data.dart`). Outros tipos de acoplamento (por exemplo `core` → features) estão em [technical-debt.md](technical-debt.md).
