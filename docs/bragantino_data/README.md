# RB Bragantino — Content Pack

**Snapshot:** 07/09/2026
**club_id:** `51683d2a-ea1d-57c6-8014-996146f242e7`
**app code:** `bragantino`
**external team id:** `4734`

## O que está dentro

- `club.json`: identidade e política histórica CAB → Red Bull Bragantino.
- `honors.json`: títulos e campanhas (vice separado de título).
- `bragantino_club_timeline_seed_v1.json`: timeline histórica.
- `stadiums.json`: Cícero de Souza Marques, Nabi Abi Chedid e nova arena.
- `leadership.json`: snapshot administrativo.
- `partners.json`: parceiros/patrocinadores 2026.
- `transparency_financials.json`: números auditados disponíveis para cards de transparência.
- `squad_2026_snapshot.json`: snapshot de atividade do elenco em 07/09/2026 + transferências recentes.
- `idols_and_icons.json`: ídolos/símbolos seguros para conteúdo.
- `trajectories_seed.json`: seeds editoriais para trajetórias.
- `bragantino_lineup_shortlist_v2.json`: **15 partidas READY**, cada uma com XI completo.
- `quiz_questions_seed_v3.json`: **44 perguntas READY** + quarentena de perguntas que ainda não devem ser publicadas.
- `001_bragantino_content_seed.sql`: seed PostgreSQL/Supabase isolado em JSONB.
- `source_catalog.json`: fontes para auditoria/future refresh.

## Regras de integração

1. Não tratar Clube Atlético Bragantino e Red Bull Bragantino como clubes diferentes.
2. Sul-Americana 2021 é **vice-campeonato/campanha**, não título.
3. Não publicar total histórico de gols/jogos de **Lincom** enquanto o conflito do checkpoint não estiver resolvido.
4. O arquivo `squad_2026_snapshot.json` é um snapshot de evidência atual; não delete atletas da tabela canônica apenas porque eles não aparecem nele.
5. Músicas/cânticos ficaram fora do escopo por decisão do usuário.
6. Passaporte ficou fora deste pacote de conteúdo principal.
7. Para `Adivinhe a Escalação`, não inferir número de camisa; usar somente o XI nominal validado.

## Ordem recomendada

`club → honors/timeline → stadiums → leadership/partners → idols/trajectories → quiz → lineups → transparency → squad refresh`

## SQL

O SQL cria apenas `public.club_content_seed`, sem alterar tabelas atuais do app. Depois é possível mapear cada `dataset_key` para as tabelas reais do schema do projeto. Isso evita quebrar o Supabase antes de comparar o schema atual.
