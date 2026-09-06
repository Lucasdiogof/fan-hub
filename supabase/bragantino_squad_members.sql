-- Elenco profissional masculino do Red Bull Bragantino — 2026.
-- Data de corte: 2026-09-06 (fonte ao vivo, ver abaixo).
--
-- FONTE PRIMÁRIA: API oficial do site do clube (redbullbragantino.com,
-- endpoint /v3/api/graphql/.../feed, filtro person-profiles + tag do time
-- masculino profissional, sort=athleteNumber) — 30 atletas retornados
-- (docCount=30, sem paginação). Nome/posição ampla/número/nacionalidade/
-- data e local de nascimento/foto vêm de lá. Posição GRANULAR (quando o
-- próprio site não distinguia "Meio-campo"/"Atacante" o suficiente) foi
-- cruzada com oGol/Transfermarkt/Sofascore/Wikipedia (fonte secundária).
--
-- Desta rodada, 24 de 30 jogadores entram como READY (posição granular
-- seguramente resolvida). 6 ficam de fora — DATA_GAP explícito, nunca um
-- palpite de lateral/zagueiro/lado de ponta:
--   Gustavo Neves (#22)      — fontes divergem entre meia-armador e
--                              segundo-volante, sem resolução segura.
--   Matheus Fernandes (#35)  — divergência entre volante (wikipedia PT),
--                              central-midfielder (wikipedia EN) e "Meia"
--                              (outras fontes).
--   Fernando (#11)           — confirmado "Atacante"/striker, mas nenhuma
--                              fonte resolve o lado (direita/esquerda).
--   José María Herrera (#32) — confirmado "winger", nenhuma fonte resolve
--                              lado nem se é mais centroavante.
--   Davi Gomes (#27)         — confirmado "Atacante", mas indícios de que
--                              seguia no sub-20 até recentemente; lado não
--                              resolvido.
--   Marcelinho Braz (#57)    — fontes divergem entre atacante, ponta-
--                              direita e até meio-campista.
--
-- height_cm/foot só preenchidos onde uma fonte secundária confiável deu o
-- dado explicitamente (a maioria fica null — DATA_GAP, não bloqueia o
-- elenco). club_history vazio em todos — "clubes anteriores" não
-- pesquisado nesta rodada pra todo o elenco (seria uma rodada própria,
-- jogador por jogador). Sem jogos/gols/assistências (fora do schema desta
-- tabela, e o pedido foi não misturar temporadas sem contexto).
--
-- photo_url = foto oficial do próprio clube (CDN deles,
-- img.redbullbragantino.com) — nunca asset baixado/versionado no repo,
-- mesmo padrão de URL remota que o restante do app já usa. Nenhuma foto
-- de jogador do Goiás em nenhum fallback.
--
-- club_id = canonicalClubId REAL do Bragantino (51683d2a-ea1d-57c6-8014-
-- 996146f242e7). UPSERT por id (slug estável do próprio site) — nunca
-- DELETE indiscriminado; jogador que sair do elenco no futuro é tratado
-- numa rodada própria, não apagando histórico às cegas.
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.squad_members
  (id, club_id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, photo_url, club_history, sort_order)
values
('cleiton', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Cleiton', 'Cleiton Shwengber', 1, 'Goleiro', 'Goleiros', '1997-08-19', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/gliozjfvi1mbxq88fibm/goleiro-cleiton', '[]'::jsonb, 0),
('guzman-rodriguez', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Guzmán Rodríguez', 'Guzmán Rodríguez', 2, 'Zagueiro', 'Zagueiros', '2000-02-08', 'Uruguai', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/oungld1gdkgty9infea9/gusman-rodriguez', '[]'::jsonb, 1),
('eduardo-santos', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Eduardo Santos', 'Eduardo Santos', 3, 'Zagueiro', 'Zagueiros', '1997-11-28', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/bovlwwskljpwv0mohnad/eduardo-santos', '[]'::jsonb, 2),
('alix-vinicius', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Alix Vinícius', 'Alix Vinícius', 4, 'Zagueiro', 'Zagueiros', '1999-11-06', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/znm8zwxnjyhio147m4ew/alix', '[]'::jsonb, 3),
('fabinho', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Fabinho', 'Fabinho Silva de Freitas', 5, 'Volante', 'Volantes', '2002-04-09', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/woqwrwsmzfhng3al0fla/fabinho-silva', '[]'::jsonb, 4),
('gabriel', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gabriel Girotto', 'Gabriel Girotto Franco', 6, 'Volante', 'Volantes', '1992-07-10', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/tukwutkmjoqaxqg50mnw/gabriel-girotto', '[]'::jsonb, 5),
('eric-ramires', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Eric Ramires', 'Eric dos Santos Rodrigues', 7, 'Volante', 'Volantes', '2000-10-10', 'Brasil', 172, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/psqhtbgaztpd3rztduwc/eric-ramires', '[]'::jsonb, 6),
('eduardo-sasha', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Sasha', 'Eduardo Sasha', 8, 'Centroavante', 'Atacantes', '1992-02-24', 'Brasil', 173, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ri5wldylalszuh5ylqlz/eduardo-sasha', '[]'::jsonb, 7),
('pitta', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Pitta', 'Isidro Miguel Pitta Saldívar', 9, 'Centroavante', 'Atacantes', '1999-08-14', 'Paraguai', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/kbsjydtiammmj0dktmmm/isidro-pitta', '[]'::jsonb, 8),
('vanderlan-barbosa', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Vanderlan', 'Vanderlan Barbosa da Silva', 12, 'Lateral-esquerdo', 'Laterais-esquerdos', '2002-09-07', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/bxmewr1kq5dsd0bj00zj/vanderlan-barbosa', '[]'::jsonb, 9),
('pedro-henrique', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Pedro Henrique', 'Pedro Henrique Ribeiro Gonçalves', 14, 'Zagueiro', 'Zagueiros', '1995-10-02', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ooluvaimjnwrctr2n9b1/pedro-henrique', '[]'::jsonb, 10),
('nacho-sosa', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Nacho Sosa', 'Nacho Sosa', 15, 'Volante', 'Volantes', '2003-08-31', 'Uruguai', null, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jyq65jf2b4mitc9ptvh3/nacho-sosa', '[]'::jsonb, 11),
('gustavo-marques', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gustavo Marques', 'Gustavo Marques', 16, 'Zagueiro', 'Zagueiros', '2001-10-09', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/igzcyqrbhmeftf5jdfea/gustavo-marques', '[]'::jsonb, 12),
('vinicinho-pereira', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Vinicinho Pereira', 'Vinicius Mendonça Pereira', 17, 'Ponta-esquerda', 'Atacantes', '2004-02-20', 'Brasil', 174, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/okbny04aehkxfeibt2sd/vinicius-pereira', '[]'::jsonb, 13),
('tiago-volpi', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Tiago Volpi', 'Tiago Volpi', 18, 'Goleiro', 'Goleiros', '1990-12-19', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jedmn2u3wlf6t5ypatw4/tiago-volpi', '[]'::jsonb, 14),
('rodriguinho', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Rodriguinho', 'Rodrigo Huendra Almeida Mendonça', 20, 'Meia-atacante', 'Atacantes', '2004-03-16', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/pl8nxfp0taccry13ltbz/rodrigo-huendra', '[]'::jsonb, 15),
('lucas-barbosa', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Lucas Barbosa', 'Lucas Barbosa', 21, 'Ponta-direita', 'Atacantes', '2001-02-22', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/xqq5qy3b4zcnmgx1nzmy/lucas-barbosa', '[]'::jsonb, 16),
('agustin-santanna', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Agustín Sant''Anna', 'Agustín Sant''Anna', 23, 'Lateral-direito', 'Laterais-direitos', '1997-09-27', 'Uruguai', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jpl4p5muw5ig7soozo5d/agustin-santanna', '[]'::jsonb, 17),
('juninho-capixaba', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Juninho Capixaba', 'Juninho Capixaba', 29, 'Lateral-esquerdo', 'Laterais-esquerdos', '1997-07-06', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/qcknkekf5tdbpqoog7a3/juninho-capixaba', '[]'::jsonb, 18),
('henry-mosquera', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Henry Mosquera', 'Henry Mosquera', 30, 'Ponta-esquerda', 'Atacantes', '2001-11-15', 'Colômbia', 175, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/zqtva3yctr01nfzobltl/henry-mosquera', '[]'::jsonb, 19),
('andres-hurtado', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Andrés Hurtado', 'Andrés Hurtado', 34, 'Lateral-direito', 'Laterais-direitos', '2001-12-23', 'Equador', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/gpgsjiqrtc7jpzewhkyb/andres-hurtado', '[]'::jsonb, 20),
('fabricio', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Fabrício', 'Fabrício Oliveira de Souza', 37, 'Goleiro', 'Goleiros', '2000-06-15', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/d7f8fnmquyo5w8g2oejm/goleiro-fabricio', '[]'::jsonb, 21),
('caue', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Cauê', 'Cauê Nascimento Santos', 51, 'Lateral-esquerdo', 'Laterais-esquerdos', '2006-12-13', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/hwdyuh3zb0rziw6uti4h/caue-nascimento-santos', '[]'::jsonb, 22),
('gustavo-reis', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gustavo Reis', 'Gustavo Reis', 56, 'Goleiro', 'Goleiros', '2005-06-10', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ryj16iqsieanvoojcnth/gustavo-reis', '[]'::jsonb, 23)
on conflict (id) do update set
  club_id = excluded.club_id, name = excluded.name, full_name = excluded.full_name,
  shirt_number = excluded.shirt_number, position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality, height_cm = excluded.height_cm,
  foot = excluded.foot, photo_url = excluded.photo_url, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();
