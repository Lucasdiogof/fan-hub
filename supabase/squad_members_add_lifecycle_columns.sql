-- Elenco: adiciona colunas de ciclo de vida do atleta no clube.
--
-- Motivo: refresh do elenco 2026 do Bragantino (pacote docs/bragantino_data)
-- trouxe uma saída real (Pedro Henrique -> Al Ettifaq, 06/09/2026) e a
-- arquitetura existente não tinha NENHUMA forma de marcar isso — só
-- `club_history` (histórico de OUTROS clubes na carreira, não usado pra
-- "saiu deste clube"). Sem essa coluna, a única opção seria apagar a linha
-- (proibido: "nunca deleção destrutiva, mesmo quando o atleta sai").
--
-- `active` (default true): quem está fora do elenco atual vira `false`,
-- nunca é removido da tabela. `departed_at`/`departed_to`: só metadado,
-- opcionais, preenchidos quando existir uma saída confirmada.
--
-- Aditivo/idempotente, roda igual nos dois projetos Supabase (schema
-- convergente): Goiás (yonozsdgyrhgqrvydbnr) e Bragantino
-- (yrgyzkaaudyzmsqwzecj). Não altera nenhuma linha existente (DEFAULT true
-- preenche todo mundo já cadastrado como ativo, comportamento idêntico ao
-- de hoje).

alter table public.squad_members add column if not exists active boolean not null default true;
alter table public.squad_members add column if not exists departed_at date;
alter table public.squad_members add column if not exists departed_to text;
