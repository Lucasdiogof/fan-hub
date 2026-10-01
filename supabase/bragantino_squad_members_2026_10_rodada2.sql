-- Pendências do elenco do Bragantino — RODADA 2 (2026-10-01). Pesquisa do
-- pesquisa externa (prompt em docs/multiclub/PROMPT_PESQUISA_PENDENCIAS_RODADA2_2026-10-01.md),
-- fontes oficiais conferidas:
--   * Gabriel Girotto: 1,70 m — ficha oficial do Internacional na contratação
--     (internacional.com.br/noticias/masculino/inter-contrata-meio-campista-gabriel,
--     Gabriel Girotto Franco, 10/07/1992);
--   * Tiago Volpi: 1,88 m — ficha oficial do São Paulo FC
--     (saopaulofc.net/tiago-volpi-e-do-tricolor-goleiro-e-mais-um-reforco-para-2019,
--     Tiago Luis Volpi, 19/12/1990);
--   * Cauê: SEM fonte de prioridade 1 ou 2 (a CBF confirma a identidade, sem
--     altura). Os 186 cm gravados no banco real em 2026-09-09 não têm origem
--     registrada -> removidos (decisão combinada com o usuário).
-- Segue pendente: Agustín Sant'Anna (170/173/175, nenhuma fonte oficial) —
-- o 173 do banco fica como está.
--
-- Rodar SÓ no projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj), depois de
-- _2026_10_pendencias.sql. Idempotente: cada UPDATE confere o valor que estava
-- no banco real em 2026-10-01.

do $$
begin
  if not exists (select 1 from public.clubs where id = '51683d2a-ea1d-57c6-8014-996146f242e7') then
    raise exception 'este não é o projeto Supabase do Bragantino -- PARE';
  end if;
end $$;

update public.squad_members set height_cm = 170, updated_at = now() where id = 'gabriel' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and (height_cm is null or height_cm = 171);
update public.squad_members set height_cm = 188, updated_at = now() where id = 'tiago-volpi' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and (height_cm is null or height_cm = 189);
update public.squad_members set height_cm = null, updated_at = now() where id = 'caue' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm = 186;
