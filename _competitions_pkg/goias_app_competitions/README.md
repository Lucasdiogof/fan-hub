# Goiás-app — Base de Competições

Pacote para coletar, normalizar, auditar e entregar ao Goiás-app o histórico das competições selecionadas.

## Objetivo

Transformar dados públicos de competições em uma base própria e rastreável:

`Futebol de Goyaz -> coletor -> JSON/JSONL normalizado -> validação -> Supabase -> Flutter`

O Flutter **não** deve fazer scraping em runtime.

## Escopo inicial

O arquivo `config/scope.json` está configurado para buscar **todas as edições disponíveis na fonte** de:

- Campeonato Brasileiro Série A
- Campeonato Brasileiro Série B
- Campeonato Brasileiro Série C
- Campeonato Brasileiro Série D
- Copa do Brasil
- Campeonato Goiano
- Campeonato Goiano Segunda Divisão
- Campeonato Goiano Terceira Divisão
- Copa Verde
- Copa Centro Oeste
- Copa dos Campeões
- Copa Leonino Caiado
- Copa Goiás
- Copa Brasil Central
- Torneio Centro-Oeste
- Torneio Centro-Sul
- Copa Libertadores da América
- Copa Sul-Americana
- Copa do Mundo

## O que o coletor tenta preservar

### Competição / edição
- competição
- temporada/edição
- campeão e classificação final quando expostos pela fonte
- status da edição
- URL de origem

### Estrutura dinâmica
- fases
- grupos
- rodadas
- pontos corridos
- mata-mata
- ida/volta
- preliminares/playoffs
- pênaltis
- formatos híbridos

**Regra:** formato é propriedade da **edição/fase**, nunca uma regra global hardcoded do campeonato.

### Classificação
- posição
- pontos
- jogos
- vitórias
- empates
- derrotas
- gols pró
- gols contra
- saldo
- aproveitamento
- classificações extras quando disponíveis

### Jogos
- mandante/visitante
- data/hora
- estádio
- placar normal
- placar de pênaltis separado
- fase/rodada
- status (jogado, agendado, adiado, anulado/cancelado, abandonado, desconhecido)
- observações da fonte

### Artilharia
- posição
- jogador
- clube
- gols
- vínculo com a edição
- URL da fonte

### Estatísticas da edição
- jogos
- gols
- média de gols
- melhor ataque
- melhor defesa
- maior goleada
- maior invencibilidade
- sequência de vitórias
- sequência de derrotas
- sequência sem vitórias

### Detalhe de partida, quando a fonte oferece
- escalações
- formação
- técnico
- banco
- gols
- cartões
- substituições
- arbitragem
- público
- renda

A disponibilidade varia por ano/competição. Campo ausente vira `null`; **não há preenchimento por chute**.

## Arquivos de saída

Após executar o coletor, `output/` terá:

- `manifest.json`
- `competitions.json`
- `editions.json`
- `stages.json`
- `groups.json`
- `rounds.json`
- `edition_statistics.json`
- `regulations.json`
- `final_classification.json`
- `sources.json`
- `matches.jsonl` (each row carries `stage_id`/`group_id`/`round_id`)
- `standings.jsonl` (each row carries `stage_id`/`group_id`)
- `scorers.jsonl`
- `validation_report.json`

JSONL é usado nas tabelas grandes para evitar um único JSON gigantesco e permitir processamento em streaming.

`stages.json`/`groups.json`/`rounds.json` são derivados em memória (sem rede) pelo `collector/normalize.py` a partir do texto que o parser já extrai (`stage_name_raw`/`round_name_raw` nas partidas, `group_name_raw` na classificação) — nunca hardcoded por campeonato. Rodam automaticamente no fim de `run.py` e também podem ser reconstruídos sozinhos, sem tocar na rede, com `python run.py --validate-only --output <pasta>`.

## Instalação

```bash
python -m venv .venv
# Windows
.venv\\Scripts\\activate
# macOS/Linux
# source .venv/bin/activate

pip install -r requirements.txt
```

## Coleta completa

```bash
python run.py --scope config/scope.json --output output
```

Para testar primeiro uma competição:

```bash
python run.py --only brasileirao_a --output output_test
```

Para coletar apenas referências de partidas, sem abrir o detalhe de cada jogo:

```bash
python run.py --skip-match-details --output output_light
```

## Auditoria

```bash
python run.py --validate-only --output output
```

O `validation_report.json` verifica, entre outros pontos:

- IDs de partidas duplicados
- total de partidas coletadas versus estatísticas da edição quando comparável
- total de gols dos jogos versus total informado pela página de estatísticas
- pênaltis incompletos
- partidas sem equipes identificadas
- quantidade de linhas de classificação e artilharia por edição

Diferença em temporada em andamento é um **warning**, não deve ser automaticamente tratada como corrupção.

## Cache / retomada

As páginas baixadas são cacheadas por URL em `.cache/`. Isso permite retomar uma coleta sem baixar tudo novamente e também reduz carga no site de origem.

Por padrão há atraso entre requisições. Não remova o rate limit agressivamente.

## Supabase

`schema.sql` contém uma proposta de schema relacional. A importação pode ser feita depois que o JSON for auditado.

Recomendação:

1. coletar;
2. validar;
3. revisar `validation_report.json`;
4. resolver aliases de clubes;
5. importar no Supabase;
6. só então apontar a UI para as tabelas definitivas.

## Para a implementação

Entregue **este ZIP inteiro**, não apenas os JSONs. Instrua:

> Use `output/` como fonte de verdade depois da execução/auditoria. Não invente dados ausentes. Não codifique formato por nome de campeonato. Monte a UI a partir de edition/stage/group/round. Preserve `source_url`, status e campos nulos. Use `schema.sql` como referência, ajustando somente ao padrão arquitetural atual do goias-app.

## Limitação importante

Este pacote contém o coletor, schema, escopo e exemplos verificados. A execução integral depende de acesso HTTP ao site de origem. O ambiente em que este pacote foi montado não disponibiliza download HTTP em lote para o runtime de arquivos; por isso o ZIP não finge conter dezenas de milhares de partidas que não foram materializadas localmente. O coletor foi feito justamente para gerar o conjunto integral de forma reproduzível no ambiente do desenvolvimento/desenvolvimento com internet.

Para dados históricos, ausência na fonte permanece ausência. Para 2026 e outras edições em andamento, dados podem mudar após nova execução.
