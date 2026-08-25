-- Adiciona o agrupamento por posição igual ao site oficial
-- (goiasec.com.br/elenco/futebol-profissional).
-- Rodar NESTA ORDEM:
--   1. Este arquivo (adiciona a coluna, ainda opcional)
--   2. squad_members_seed.sql de novo (agora populando position_group via upsert)
--   3. O ALTER final deste arquivo, comentado abaixo, depois que o seed já tiver rodado

alter table public.squad_members add column if not exists position_group text;

-- Depois de rodar squad_members_seed.sql (que agora inclui position_group),
-- rode esta linha pra travar a coluna como obrigatória:
-- alter table public.squad_members alter column position_group set not null;
