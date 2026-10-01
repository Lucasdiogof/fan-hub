-- Pendências da validação do elenco do Bragantino (2026-10-01), resolvidas
-- pela pesquisa de pendências (pesquisa externa; roteiro em
-- docs/multiclub/PROMPT_PESQUISA_PENDENCIAS_VALIDACAO_2026-10-01.md, conclusões
-- trazidas pelo usuário). Só o que veio CONFIRMADO:
--   * Eric Ramires: nascimento 2000-08-10 (CBF confirma 10/08/2000; o
--     2000-10-10 da ficha do clube está errado);
--   * altura de Pitta (183), Rodriguinho (185), Lucas Barbosa (193) e
--     Gustavo Neves (176).
-- Seguem SEM valor (pendentes, não preencher): altura de Agustín Sant'Anna
-- (170/173/175) e de Cauê (sem fonte prioritária). Com ressalva, também sem
-- valor: Gabriel Girotto (171 x 172) e Tiago Volpi (189 x 188).
-- Ryan Augusto e Bruninho continuam no clube (Ryan no Sub-20 e já usado no
-- profissional; Bruninho no profissional, voltou a treinar em 2026-06-29):
-- seguem ativos, nada muda.
--
-- ATENÇÃO (descoberto ao aplicar, 2026-10-01): o banco REAL já tinha alturas
-- gravadas em 2026-09-09 que os seeds do repo não registram (ogol): Pitta 185,
-- Lucas Barbosa 194, Rodriguinho 185, Gustavo Neves 176, Volpi 189, Girotto
-- 171, Sant'Anna 173 e Cauê 186. Por isso Pitta e Lucas Barbosa aceitam
-- também o valor antigo do banco (185 e 194) e são corrigidos para o valor
-- confirmado; os demais não mudam (já batem ou estão pendentes).
--
-- Rodar SÓ no projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj), DEPOIS de
-- bragantino_squad_members_2026_10_validation.sql. Idempotente: cada UPDATE
-- confere o valor antigo.

do $$
begin
  if not exists (select 1 from public.clubs where id = '51683d2a-ea1d-57c6-8014-996146f242e7') then
    raise exception 'este não é o projeto Supabase do Bragantino -- PARE';
  end if;
end $$;

update public.squad_members set birth_date = '2000-08-10', updated_at = now() where id = 'eric-ramires' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and birth_date = '2000-10-10';
update public.squad_members set height_cm = 183, updated_at = now() where id = 'pitta' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and (height_cm is null or height_cm = 185);
update public.squad_members set height_cm = 185, updated_at = now() where id = 'rodriguinho' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null;
update public.squad_members set height_cm = 193, updated_at = now() where id = 'lucas-barbosa' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and (height_cm is null or height_cm = 194);
update public.squad_members set height_cm = 176, updated_at = now() where id = 'gustavo-neves' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null;
