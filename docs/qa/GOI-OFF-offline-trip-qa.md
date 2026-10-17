# QA offline da viagem (GOI-OFF-001/002/003)

Origem: 9 screenshots reais do iPhone em modo avião (15/10/2026). Este
arquivo registra causa, correção e o que foi — ou não — validado.

## Causa raiz (GOI-OFF-002)
Todo tráfego do Supabase passa por `SessionAwareHttpClient`, que **não tinha
timeout**, e o Postgrest repetia a consulta 3x (1s/2s/4s). Sem rede, o
`send` nativo podia ficar pendente por minutos: Diretoria, Transparência,
Sócio, Elenco (overlay do `GlobalLoading` em O Clube) e Arena/Desafios
ficavam em spinner/overlay sem saída. Jogos e Notícias (Dio, timeout 10s)
já falhavam rápido — por isso mostravam o erro.

## Correções
| Ponto | O que mudou |
|---|---|
| `SessionAwareHttpClient` | teto de 10s por resposta (90s p/ upload em stream); estouro = `TimeoutException` (mappers já tratam como rede). Auth converte em `ClientException` (retentável pelo GoTrue). |
| `main.dart` | `PostgrestClientOptions(retryCount: 1)` — espera máxima finita. |
| Diretoria / Transparência / Elenco | última consulta bem-sucedida salva (`JsonSnapshotCache`, JSON cru + data); offline serve a cópia com aviso "conteúdo salvo em <data>"; sem cópia: mensagem offline localizada + "Tentar novamente". Cubits com 1 fetch por vez e sem emit após `close`. |
| Home / Jogos / Mídia | `OfflineSnapshotInterceptor` (Dio): salva a última resposta de notícias e rotas `/api/football/*` (exceto `fixtures/:id`); só serve quando há falha de rede/timeout, até 7d (notícias) / 14d (jogos). Partida salva `live`/`halftime` volta como `unknown` sem minuto — nunca "ao vivo" falso. Banner de desatualizado + "Tentar novamente" em Jogos e Mídia. |
| Loja | não tocada. |
| Conteúdo embarcado | História, Títulos, Ídolos e Hino já são assets/Dart (`club_*_data.dart`) e nunca dependeram de rede. |

## Validação — o que foi realmente executado
- `flutter analyze`: sem issues. `flutter test` (suíte completa): 1864 passaram.
- Testes novos: timeout HTTP, cache de snapshots, fallback do repositório da
  Diretoria (online → offline → online) e cubit (retry, 1 fetch), interceptor
  (sem visita, com visita, live nunca servido, expirado, fixture não cacheada).
  Usam fakes/mocks **apenas em teste**; não são evidência de aparelho real.

## NÃO validado (bloqueado/pendente)
- Modo avião em iPhone/Android reais, primeira instalação offline e retorno
  online no aparelho; web não exercitado.
- Sócio Esmeralda: o loader vinha do mesmo timeout ausente (tela já tinha
  erro + "Tentar novamente"); confirmar no aparelho.
- Arena/Desafios: o overlay (`GlobalLoading`) agora termina pelo timeout das
  consultas; jogos sem cache de perguntas mostram erro ao tocar. Confirmar.
- Fotos remotas (diretoria, elenco, ídolos, escalações, notícias, parceiros) agora usam `ClubNetworkImage` (cache em disco): só aparecem offline se já foram vistas com internet; senão mostram iniciais/número.
- Arena: quiz, escalação, carreira e adivinhe o jogador têm fallback embarcado do Goiás e armazenamento local com `catch`; o ranking guarda o placar público por período (nunca a posição da conta) e offline mostra a cópia com aviso de desatualizado; sem cópia, mensagem offline + "Tentar novamente". Respostas de período antigo são descartadas. Não verificado em aparelho.
