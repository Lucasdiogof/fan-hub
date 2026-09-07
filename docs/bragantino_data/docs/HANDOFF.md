# Handoff de implementação

Use este pacote como fonte de dados do flavor `bragantino`. Primeiro leia `README.md`. Não redesenhe features do Goiás: reutilize a arquitetura existente e faça somente o mapeamento de conteúdo/club_id.

Prioridade:
1. importar o SQL de staging;
2. mapear cada dataset para as tabelas canônicas existentes;
3. preservar IDs existentes;
4. rodar testes de isolamento multiclube;
5. validar que nenhum texto/logo do Goiás aparece no Bragantino;
6. cadastrar as 15 partidas READY de escalação;
7. importar as perguntas READY e ignorar `review_candidates`;
8. atualizar roster sem deleção destrutiva;
9. deixar Lincom sem contador estatístico até conflito ser resolvido.


## Atualização final — 2026-09-07

- Lincom: conflito editorial resolvido. Usar **160 jogos / 72 gols**, todas as competições oficiais, snapshot dezembro/2016. Preservar em auditoria que fontes retrospectivas posteriores citam 73 gols.
- Passaporte Massa Bruta: matriz anual 2000–2026 auditada em `data/bragantino_passport_audit_manifest_v4.json`.
- Totais: 1.378 partidas oficiais realizadas em 2000–2025; 1.424 realizadas até 05/09/2026; 1.437 registros de calendário incluindo 1 adiado + 12 futuros de 2026.
- Regra temporal: `calendar_year` e `competition_edition` são campos distintos (especialmente Brasileirão 2020, que avançou por jan/fev de 2021).
- Regra de estádio: nunca inferir; preencher apenas quando houver confirmação MATCH_SPECIFIC.
- IMPORTANTE: este ZIP contém a auditoria/contagem completa do Passaporte, mas **não contém ainda as 1.251 linhas individuais de 2000–2023**. Não inventar essas partidas nem tratá-las como materializadas. As linhas 2024–2026 já haviam sido materializadas no projeto/Supabase conforme checkpoint anterior.
