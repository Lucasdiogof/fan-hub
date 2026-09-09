-- Diretoria/Gestão do Red Bull Bragantino — reestruturação completa
-- (2026-09-09), substitui os 2 nomes da rodada anterior
-- (`bragantino_club_board.sql`) por um quadro real de 13 pessoas.
--
-- A Red Bull Bragantino Futebol Ltda. NÃO é modelada como clube associativo
-- tradicional (presidente+conselho) — é sociedade empresária limitada,
-- controlada pela Red Bull GmbH. O schema (`club_board_sections`/
-- `club_board_members`, name+role só, sem `area`/fonte/confiança) não
-- muda: 3 seções resolvem a separação de níveis pedida —
-- Executivo/Áreas/Institucional. Governança societária (Red Bull GmbH como
-- controladora) fica documentada só no arquivo de auditoria irmão
-- (`docs/bragantino_data/diretoria_auditoria_2026_09.md`), nunca como
-- "pessoa" no carrossel de dirigentes.
--
-- Evidência completa por pessoa (fonte/data/nível de confiança) também só
-- no arquivo de auditoria — o schema atual não tem coluna pra isso e não é
-- alterado só por isto (schema convergido Goiás/Bragantino, nunca mexer
-- sem necessidade).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj) — NUNCA no do Goiás.

insert into public.club_board_sections (id, title, sort_order) values
  ('diretoria_executiva', 'Gestão Executiva', 0),
  ('diretoria_areas', 'Gestão por Áreas', 1),
  ('diretoria_institucional', 'Institucional', 2)
on conflict (id) do update set title = excluded.title, sort_order = excluded.sort_order;

insert into public.club_board_members (id, section_id, name, role, sort_order) values
  -- GESTÃO EXECUTIVA — os 3 administradores societários (QSA da Red Bull
  -- Bragantino Futebol Ltda., Receita Federal, ago/2026) que também têm
  -- função executiva do dia a dia.
  ('andre_raul_rocha', 'diretoria_executiva', 'André Raul Rocha', 'CEO / Diretor Administrativo', 0),
  ('diego_cerri', 'diretoria_executiva', 'Diego Cerri', 'Diretor Esportivo', 1),
  ('luiz_felipe_monteiro_lemos', 'diretoria_executiva', 'Luiz Felipe Monteiro Lemos', 'Diretor Financeiro', 2),

  -- GESTÃO POR ÁREAS — lideranças funcionais (imersão Universidade do
  -- Futebol + FPF Academia no CPD, cruzada com fonte mais recente/forte
  -- disponível por pessoa; nomenclatura gerente vs. diretor/head segue a
  -- fonte mais atual, nunca promovida artificialmente).
  ('bernardo_caixeta_chaves', 'diretoria_areas', 'Bernardo Caixeta Chaves', 'Head de Marketing', 0),
  ('fabio_donatelli', 'diretoria_areas', 'Fabio Donatelli', 'Head Comercial', 1),
  ('henrique_motta', 'diretoria_areas', 'Henrique Motta', 'Head de TI e Transformação Digital', 2),
  ('lucas_bettine', 'diretoria_areas', 'Lucas Bettine', 'Gerente de Comunicação', 3),
  ('carolina_soares', 'diretoria_areas', 'Carolina Soares', 'Gerente de Recursos Humanos', 4),
  ('igor_melissopoulos', 'diretoria_areas', 'Igor Melissopoulos', 'Gerente Jurídico', 5),
  ('elisabete_freitas', 'diretoria_areas', 'Elisabete Freitas', 'Gerente de Infraestrutura', 6),
  ('miriam_medeiros', 'diretoria_areas', 'Miriam Medeiros', 'Gerente de Operações', 7),
  ('guilherme_macedo', 'diretoria_areas', 'Guilherme Macedo', 'Diretor de Projetos', 8),

  -- INSTITUCIONAL — papel honorário, nunca liderança executiva atual (ele
  -- não está no QSA como administrador).
  ('marco_antonio_abi_chedid', 'diretoria_institucional', 'Marco Antônio Abi Chedid', 'Presidente de Honra', 0)
on conflict (id) do update set
  section_id = excluded.section_id, name = excluded.name, role = excluded.role,
  sort_order = excluded.sort_order, updated_at = now();
