-- Instagram de cada jogador do elenco do Bragantino — lista trazida pelo
-- usuário (rb_bragantino_instagram_players_2026-09-08.json), com fonte e
-- data de verificação por linha no arquivo original. Idempotente (UPDATE
-- puro, pode rodar de novo sem problema).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj)
-- — NUNCA no do Goiás.
--
-- Fabrício: verification_status=NOT_FOUND no levantamento -> instagram_url
-- fica null (não entra nesta lista) -> o botão de Instagram já some sozinho
-- na ficha dele (`squad_member_detail_page.dart` só renderiza o botão
-- `if (member.instagramUrl != null)`), nenhuma mudança de código necessária.
--
-- CORRIGIDO (2026-09-08) depois da 1ª rodada real: casamento por nome
-- devolveu 7 sem correspondência. Cruzei contra `bragantino_squad_members.sql`
-- (seed real, com os `name` exatos gravados) e achei a causa de 5 deles —
-- o JSON usa o nome completo/torcida, o banco usa o apelido/nome de jogo
-- oficial do clube:
--   Ignacio Sosa   -> banco tem 'Nacho Sosa'
--   Vinicinho      -> banco tem 'Vinicinho Pereira'
--   Isidro Pitta   -> banco tem 'Pitta'
--   Eduardo Sasha  -> banco tem 'Sasha'
--   José Herrera   -> banco tem 'Herrera'
-- Os outros 2 (Bruno Gonçalves, Ryan Augusto) NÃO aparecem em nenhum dos
-- dois seeds de elenco (`bragantino_squad_members.sql`,
-- `bragantino_squad_members_2026_09_refresh.sql`) — não são erro de nome,
-- simplesmente ainda não existem em `squad_members` (elenco reserva/sub
-- ainda não cadastrado, ou adição mais recente que o último refresh).
-- Ficam FORA desta lista de propósito — não inventar um `id`/linha pra
-- eles aqui. Se forem elenco profissional de verdade, cadastrar primeiro
-- via um refresh de elenco normal, depois rodar este UPDATE de novo.
update public.squad_members as t
set instagram_url = v.url, updated_at = now()
from (values
  ('Tiago Volpi', 'https://www.instagram.com/tiagovolpi_90/'),
  ('Cleiton', 'https://www.instagram.com/cleiton40/'),
  ('Gustavo Reis', 'https://www.instagram.com/gureis_1/'),
  ('Guzmán Rodríguez', 'https://www.instagram.com/guzrod04/'),
  ('Eduardo Santos', 'https://www.instagram.com/eduardosantos33_/'),
  ('Alix Vinícius', 'https://www.instagram.com/alix_vinicius/'),
  ('Gustavo Marques', 'https://www.instagram.com/gmarques001/'),
  ('Agustín Sant''Anna', 'https://www.instagram.com/agu.santanna/'),
  ('Andrés Hurtado', 'https://www.instagram.com/andres_hurtado53/'),
  ('Vanderlan', 'https://www.instagram.com/vansilva02/'),
  ('Juninho Capixaba', 'https://www.instagram.com/juninhocapixaba97/'),
  ('Cauê', 'https://www.instagram.com/cauenascimento_13/'),
  ('Fabinho', 'https://www.instagram.com/fabinhof05/'),
  -- Gabriel Girotto: handle "gabriel" é genérico demais pra ter certeza —
  -- verification_status=VERIFIED e verified_account=true no levantamento,
  -- mas vale conferir manualmente antes de confiar 100%.
  ('Gabriel Girotto', 'https://www.instagram.com/gabriel/'),
  ('Eric Ramires', 'https://www.instagram.com/ericramires00/'),
  ('Nacho Sosa', 'https://www.instagram.com/nachososa5/'),
  ('Rodriguinho', 'https://www.instagram.com/rodriguinho04_/'),
  ('Gustavo Neves', 'https://www.instagram.com/gustavoneves/'),
  ('Matheus Fernandes', 'https://www.instagram.com/matheusfernandes/'),
  ('Sasha', 'https://www.instagram.com/eduardosasha/'),
  ('Pitta', 'https://www.instagram.com/isidro_pitta09/'),
  ('Fernando', 'https://www.instagram.com/fernandosantos_99/'),
  ('Vinicinho Pereira', 'https://www.instagram.com/viniciuspereira.11/'),
  ('Lucas Barbosa', 'https://www.instagram.com/lucasbarbosa/'),
  ('Davi Gomes', 'https://www.instagram.com/davigomes_27/'),
  ('Henry Mosquera', 'https://www.instagram.com/henrymosquera/'),
  ('Herrera', 'https://www.instagram.com/joseherrera.26/'),
  ('Marcelinho', 'https://www.instagram.com/m.silvaa_04/'),
  ('Wallace Yan', 'https://www.instagram.com/oficial.wallaceyan/')
) as v(name, url)
where t.name = v.name
  and t.club_id = '51683d2a-ea1d-57c6-8014-996146f242e7';

-- Verificação: qualquer linha aqui é um nome que NÃO bateu com nenhum
-- atleta cadastrado no elenco do Bragantino (rode depois do UPDATE) —
-- deve dar ZERO linhas agora.
select v.name as nome_sem_correspondencia
from (values
  ('Tiago Volpi'), ('Cleiton'), ('Gustavo Reis'), ('Guzmán Rodríguez'),
  ('Eduardo Santos'), ('Alix Vinícius'), ('Gustavo Marques'),
  ('Agustín Sant''Anna'), ('Andrés Hurtado'),
  ('Vanderlan'), ('Juninho Capixaba'), ('Cauê'), ('Fabinho'),
  ('Gabriel Girotto'), ('Eric Ramires'), ('Nacho Sosa'), ('Rodriguinho'),
  ('Gustavo Neves'), ('Matheus Fernandes'),
  ('Sasha'), ('Pitta'), ('Fernando'), ('Vinicinho Pereira'),
  ('Lucas Barbosa'), ('Davi Gomes'), ('Henry Mosquera'), ('Herrera'),
  ('Marcelinho'), ('Wallace Yan')
) as v(name)
where not exists (
  select 1 from public.squad_members t
  where t.name = v.name and t.club_id = '51683d2a-ea1d-57c6-8014-996146f242e7'
);
