# Adivinhe a Escalação — Bragantino

Curadoria dos desafios do clube a partir do pool `LINEUP_SHORTLIST_V2`
(`tooling/bragantino_passport/source/lineup_shortlist_v2.json`). **Não
refaz pesquisa** — só decide o que do pool pode virar desafio no app.

```bash
node tooling/bragantino_lineup/select_challenges.mjs --target 24
node --test tooling/bragantino_lineup/select_challenges.test.mjs
```

## Estado atual: 0 publicáveis (bloqueio de DADO, não de arquitetura)

| | |
|---|---|
| Avaliadas | 123 |
| Publicáveis | **0** |
| Rejeitadas | 123 |
| Motivos | `SEM_FORMACAO` (123), `SEM_POSICAO_POR_JOGADOR` (123) |

O contrato do jogo (`LineupMatchRepository._map`) exige **formação** — é
dela que o `FormationLayoutService` gera os 11 slots do campo — e uma
**posição por jogador**. A ficha do oGol, fonte do pool, não traz nenhum
dos dois; conferido inclusive no HTML já baixado (os únicos "formation"
que aparecem lá são de "information"/"informação").

Não dá pra inferir: a ordem em que o oGol lista os titulares sugere
GOL→defesa→meio→ataque, mas **não diz quantos são de cada linha**, então
escolher entre 4-4-2, 4-3-3 ou 3-5-2 poria um zagueiro desenhado no ataque
— exatamente o encaixe visual forçado que a regra proíbe.

Tentar resolver posição pelo elenco 2026 também não fecha: só 17 dos 46
atletas distintos do pool ainda estão no clube. Os mais frequentes são
justamente ex-jogadores (Jhon Jhon em 63 partidas, Lucas Evangelista em
55, Luan Cândido em 46, Nathan Mendes em 45). **Nenhuma** das 123
partidas tem os 11 resolvíveis com segurança.

## O que falta pra publicar

Por partida: `formation` (uma das conhecidas pelo
`FormationLayoutService`) e `position` por jogador, no catálogo canônico
(`GOL, LD, ZAG, LE, VOL, MC, MEI, ATA`), com o XI **ordenado** goleiro →
defesa → meio → ataque, cada linha da direita pra esquerda (convenção do
dataset do Goiás, ver `FormationLayoutService`).

Com isso no pool, `select_challenges.mjs` publica sem nenhuma mudança no
app: o repositório, a tela e o ranking já são club-aware.

## Regras de publicabilidade

Aplicadas por `evaluateMatch` (uma partida só passa se **nenhuma** falhar):

- `XI_INCOMPLETO` — diferente de 11 titulares.
- `SEM_FORMACAO` / `FORMACAO_DESCONHECIDA` — sem formação, ou fora das 8
  que o app conhece.
- `SEM_POSICAO_POR_JOGADOR` / `POSICAO_FORA_DO_CATALOGO` — posição
  ausente ou inventada.
- `POSICOES_NAO_BATEM_COM_A_FORMACAO` — soma das linhas ≠ 11, ou o
  primeiro do XI não é o goleiro.
- `SEM_NOME_PARA_RESPOSTA` — jogador sem nome (a resposta do puzzle).

## Balanceamento

`selectBalanced` não escolhe por data. Pontua cada candidata pelo quanto
ela **adiciona** de variedade (adversário pesa 3×, competição e ano 1×,
mando 0,5×) e descarta partidas com escalação idêntica ou >80% igual a
uma já escolhida — pra não virar 24 desafios com praticamente o mesmo
time. Com pool pequeno ele para em vez de encher de repetição.

## Histórico

`HISTORICAL_LINEUPS` continua `PENDING_RESEARCH` e **vazio**. A primeira
temporada pode sair só de partidas recentes, mas nada aqui trata isso
como "a história do clube": as duas categorias entram no mesmo pipeline
(`select_challenges.mjs` já lê as duas), então partida histórica publica
depois sem migration nem refactor.
