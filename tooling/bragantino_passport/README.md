# Passaporte do Bragantino — pipeline por lote

Reconstrução, lote a lote, do histórico de partidas oficiais do Red Bull
Bragantino / Clube Atlético Bragantino (uma única história de clube). Nunca
copia dado do Goiás; nunca infere estádio pelo mandante; nunca publica
horário/estádio sem fonte específica da partida.

## Estratégia

Começa do período mais recente (2026) e retrocede ano a ano. Cada lote vira
um arquivo `source/bragantino_passport_<ano>.json` + uma SQL de seed
`supabase/bragantino_passport_matches_<ano>_seed.sql`, sempre idempotente
(`ON CONFLICT (id) DO UPDATE`).

## Lotes

| Lote | Ano | Status | Partidas | Fonte primária |
|---|---|---|---|---|
| 1 | 2026 | READY (local, não aplicado) | 59 | OneFootball (`api.onefootball.com/web-experience`) |
| 2 | 2025 | NÃO INICIADO — oGol identificado como backbone viável (`ogol.com.br/equipe/red-bull-bragantino`), extração completa requer parsing do HTML bruto (WebFetch resumiu só a fase Paulista) | — | oGol (a confirmar) |

## Por que 2026 usa OneFootball e temporadas passadas provavelmente não vão

A página de TIME do OneFootball (`/time/<slug>/resultados` e `/jogos`) só
mostra uma janela rolante (resultados recentes + próximos jogos) — funciona
perfeitamente pra a temporada corrente, mas não tem histórico de anos
anteriores. Temporadas fechadas (2025 pra trás) precisam de uma fonte com
arquivo histórico de verdade (oGol, CBF, FPF, RSSSF, Wikipedia) — ver
prioridade de fontes no prompt original do usuário.

## Descoberta relevante (2026-09-06)

O Bragantino jogou toda a temporada 2026 num estádio TEMPORÁRIO (Estádio
Municipal Cícero de Souza Marques, em Bragança Paulista) — o estádio
histórico do clube (Nabi Abi Chedid) foi demolido em 2025 (última partida
20/04/2025) pra construção da "Arena Red Bull". Ou seja: qualquer partida
de 2025 pra trás jogada em casa NUNCA foi no Cícero de Souza Marques — é
exatamente o tipo de erro que a regra "nunca inferir estádio pelo
mandante" existe pra evitar.

## Scripts

- `validate_batch.mjs <ano>` — valida um lote já gerado (IDs únicos, datas,
  placares, consistência mandante/visitante, regra crítica de estádio,
  SQL bem formada). Uso: `node validate_batch.mjs 2026`.

## Tabela

`supabase/bragantino_passport_matches.sql` cria `public.bragantino_passport_matches`
— tabela PRÓPRIA do Bragantino (não a `public.passport_matches` do Goiás,
que não tem `club_id` e nunca foi tenantizada). Ver comentário no topo
desse arquivo pra a decisão arquitetural em aberto (tabela própria vs.
unificar com `club_id` numa etapa futura).
