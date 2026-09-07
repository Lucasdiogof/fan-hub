# Handoff — Competições do Goiás-app

Recebi um pacote de coleta/normalização de competições para o Goiás-app.

## O que você deve fazer

1. Leia `README.md`, `config/scope.json`, `schema.sql` e `config/verified_source_catalog.json` antes de mexer no app.
2. Execute primeiro uma coleta pequena para validar o ambiente:
   ```bash
   python run.py --only brasileirao_a --output output_test
   ```
3. Inspecione `output_test/validation_report.json` e corrija **o parser**, se a estrutura HTML atual da fonte tiver mudado. Não corrija os dados manualmente para mascarar falha de parser.
4. Depois execute a coleta integral de todas as competições configuradas em `config/scope.json`.
5. Rode novamente a validação.
6. Somente após a auditoria, crie/migre as tabelas do Supabase e importe os dados normalizados.
7. Implemente a tela Flutter consumindo o Supabase, nunca o site externo diretamente.

## Regras obrigatórias

- Não inventar dados ausentes.
- `null` é válido quando a fonte não possui informação.
- Guardar `source_url` e IDs externos.
- O formato pertence à **edição/fase**, não ao campeonato global.
- Não criar `if CampeonatoGoiano => formato X`.
- A UI precisa funcionar com:
  - pontos corridos;
  - grupos;
  - grupos + mata-mata;
  - fase inicial + mata-mata;
  - mata-mata puro;
  - ida e volta;
  - jogo único;
  - pênaltis;
  - preliminares/playoffs;
  - regulamentos diferentes entre anos da mesma competição.
- Temporada em andamento não é erro de coleta.
- Partida anulada/cancelada não pode ser tratada como jogo normal só porque existe placar histórico.
- Placar de pênaltis deve ficar separado do placar da partida.
- Times devem ser normalizados por entidade + aliases; não duplicar clube por variação de nome.
- Não duplicar estádio por abreviação/variação textual quando houver ID externo confiável.

## Dados que quero aproveitar na UI

Além de jogos e tabela, use quando houver:

- campeão e vice;
- classificação final;
- artilheiro/artilharia;
- número de jogos e gols;
- média de gols;
- melhor ataque;
- melhor defesa;
- maior goleada;
- maiores sequências;
- regulamento;
- fases e grupos;
- estádios;
- detalhes da partida;
- escalações/formações;
- técnicos;
- gols/cartões/substituições;
- arbitragem;
- público/renda.

Não carregue todos os detalhes de partida na listagem principal. Use queries/DTOs leves e carregamento sob demanda na tela de detalhe.

## Estrutura de navegação esperada

Competições
→ Campeonato
→ Temporada/Edição
→ Resumo da edição
→ Fases disponíveis dinamicamente
→ Classificação / Jogos / Mata-mata / Artilharia / Estatísticas / Regulamento
→ Detalhe da partida

As abas exibidas devem depender da disponibilidade real de dados da edição.

## Antes de considerar concluído

Quero um relatório com:

- competições importadas;
- edições por competição;
- partidas por edição;
- edições com artilharia;
- edições com classificação;
- edições com regulamento;
- edições com warnings;
- partidas sem data;
- partidas sem estádio;
- partidas anuladas/canceladas;
- duplicidades encontradas e resolvidas;
- aliases de clubes resolvidos;
- campos que a fonte não fornece historicamente.

Não esconda warnings. Quero saber exatamente onde há lacunas da fonte.
