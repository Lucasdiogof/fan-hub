-- Elenco profissional masculino do Red Bull Bragantino — 2026.
-- Data de corte: 2026-09-06 (fonte ao vivo, ver abaixo).
--
-- FONTE PRIMÁRIA: API oficial do site do clube (redbullbragantino.com,
-- endpoint /v3/api/graphql/.../feed, filtro person-profiles + tag do time
-- masculino profissional, sort=athleteNumber) — 30 atletas (docCount=30,
-- sem paginação). Nome/posição ampla/número/nacionalidade/data e local de
-- nascimento/foto vêm de lá.
--
-- Posição GRANULAR: quando o site só dava "Meio-campo"/"Atacante"
-- genérico, cruzada com oGol/Transfermarkt/Sofascore/Wikipedia (2ª
-- rodada de revalidação, 2026-09-06, a pedido do usuário). Os 6 casos
-- reabertos:
--   Gustavo Neves (#22)      -> Meia (Meios-campistas). Também documentado
--                              como articulador ofensivo e "segundo
--                              volante", mas a função PRINCIPAL não é
--                              volante — usar Meia como principal, não
--                              promover a função secundária.
--   Matheus Fernandes (#35)  -> Volante (Volantes). Wikipédia PT confirma
--                              volante; outras fontes citam "Meia" como
--                              secundária (não representada no schema —
--                              só 1 campo de posição por jogador).
--   Fernando (#11)           -> Centroavante (Atacantes). Confirmado
--                              explicitamente ("plays as a Centroavante/
--                              Centre Forward") por fonte dedicada,
--                              cruzando com a divulgação oficial da
--                              renovação de contrato do próprio clube em
--                              03/09/2026 (até 31/12/2028 — dado de
--                              contrato NÃO entra aqui: squad_members não
--                              tem coluna de vigência contratual).
--   Davi Gomes (#27)         -> Ponta-esquerda (Atacantes). Confirmado
--                              por infobox de fonte enciclopédica
--                              (Ponta Esquerda / Left Wing), pé destro.
--   Herrera (#32)            -> Ponta-direita (Atacantes). "Right winger"
--                              como rótulo principal encontrado; também
--                              documentado atuando pela esquerda
--                              (secundária, não representada aqui).
--   Marcelinho (#57)         -> Meia-atacante (Atacantes). ATENÇÃO
--                              HOMÔNIMO: o atleta É Marcelo Braz da
--                              Silva, nascido 16/08/2004, Jaguariúna/SP
--                              — confirmado por múltiplas fontes
--                              convergentes (idade/cidade/altura batem),
--                              nunca confundido com outro "Marcelinho"/
--                              "Marcelo Sales" da busca. Fontes divergem
--                              entre meia ofensivo e ponta-direita; a
--                              convergência (mais fontes) aponta meia
--                              ofensivo -> Meia-atacante.
--
-- Com isso: 30 de 30 jogadores READY. Nenhum permanece em aberto nesta
-- rodada.
--
-- height_cm/foot só preenchidos onde uma fonte confiável deu o dado
-- explicitamente — a maioria fica null (DATA_GAP, não bloqueia). Sem
-- clubes anteriores/jogos/gols/assistências (fora do schema, e não
-- pesquisado jogador a jogador nesta rodada). Sem coluna de contrato no
-- schema atual — a renovação do Fernando fica só documentada aqui em
-- comentário, não em coluna.
--
-- photo_url = foto oficial do próprio clube (CDN deles,
-- img.redbullbragantino.com) — nunca asset baixado/versionado no repo.
-- Nenhuma foto de jogador do Goiás em nenhum fallback.
--
-- club_id = canonicalClubId REAL do Bragantino (51683d2a-ea1d-57c6-8014-
-- 996146f242e7). UPSERT por id (slug estável do próprio site) — nunca
-- DELETE indiscriminado.
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
('fernando', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Fernando', 'Fernando dos Santos Pedro', 11, 'Centroavante', 'Atacantes', '1999-03-01', 'Brasil', 176, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/fprkgnqp9d2vxoojwwkm/fernando-dos-santos', '[]'::jsonb, 9),
('vanderlan-barbosa', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Vanderlan', 'Vanderlan Barbosa da Silva', 12, 'Lateral-esquerdo', 'Laterais-esquerdos', '2002-09-07', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/bxmewr1kq5dsd0bj00zj/vanderlan-barbosa', '[]'::jsonb, 10),
('pedro-henrique', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Pedro Henrique', 'Pedro Henrique Ribeiro Gonçalves', 14, 'Zagueiro', 'Zagueiros', '1995-10-02', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ooluvaimjnwrctr2n9b1/pedro-henrique', '[]'::jsonb, 11),
('nacho-sosa', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Nacho Sosa', 'Nacho Sosa', 15, 'Volante', 'Volantes', '2003-08-31', 'Uruguai', null, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jyq65jf2b4mitc9ptvh3/nacho-sosa', '[]'::jsonb, 12),
('gustavo-marques', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gustavo Marques', 'Gustavo Marques', 16, 'Zagueiro', 'Zagueiros', '2001-10-09', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/igzcyqrbhmeftf5jdfea/gustavo-marques', '[]'::jsonb, 13),
('vinicinho-pereira', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Vinicinho Pereira', 'Vinicius Mendonça Pereira', 17, 'Ponta-esquerda', 'Atacantes', '2004-02-20', 'Brasil', 174, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/okbny04aehkxfeibt2sd/vinicius-pereira', '[]'::jsonb, 14),
('tiago-volpi', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Tiago Volpi', 'Tiago Volpi', 18, 'Goleiro', 'Goleiros', '1990-12-19', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jedmn2u3wlf6t5ypatw4/tiago-volpi', '[]'::jsonb, 15),
('rodriguinho', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Rodriguinho', 'Rodrigo Huendra Almeida Mendonça', 20, 'Meia-atacante', 'Atacantes', '2004-03-16', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/pl8nxfp0taccry13ltbz/rodrigo-huendra', '[]'::jsonb, 16),
('lucas-barbosa', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Lucas Barbosa', 'Lucas Barbosa', 21, 'Ponta-direita', 'Atacantes', '2001-02-22', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/xqq5qy3b4zcnmgx1nzmy/lucas-barbosa', '[]'::jsonb, 17),
('gustavo-neves', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gustavo Neves', 'Gustavo Ribeiro Neves', 22, 'Meia', 'Meios-campistas', '2004-04-23', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ibizygywliemtfpao2ym/gustavo-neves', '[]'::jsonb, 18),
('agustin-santanna', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Agustín Sant''Anna', 'Agustín Sant''Anna', 23, 'Lateral-direito', 'Laterais-direitos', '1997-09-27', 'Uruguai', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jpl4p5muw5ig7soozo5d/agustin-santanna', '[]'::jsonb, 19),
('davi-gomes', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Davi Gomes', 'Davi Gomes de Alvarenga', 27, 'Ponta-esquerda', 'Atacantes', '2005-06-06', 'Brasil', 172, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/nvsbeqs6lv8vr2a0hk3w/davi-gomes', '[]'::jsonb, 20),
('juninho-capixaba', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Juninho Capixaba', 'Juninho Capixaba', 29, 'Lateral-esquerdo', 'Laterais-esquerdos', '1997-07-06', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/qcknkekf5tdbpqoog7a3/juninho-capixaba', '[]'::jsonb, 21),
('henry-mosquera', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Henry Mosquera', 'Henry Mosquera', 30, 'Ponta-esquerda', 'Atacantes', '2001-11-15', 'Colômbia', 175, 'Destro', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/zqtva3yctr01nfzobltl/henry-mosquera', '[]'::jsonb, 22),
('herrera', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Herrera', 'José María Herrera Ares', 32, 'Ponta-direita', 'Atacantes', '2003-04-16', 'Argentina', 172, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/wakdlvlk1vsuprzcki3j/jose-herrera', '[]'::jsonb, 23),
('andres-hurtado', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Andrés Hurtado', 'Andrés Hurtado', 34, 'Lateral-direito', 'Laterais-direitos', '2001-12-23', 'Equador', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/gpgsjiqrtc7jpzewhkyb/andres-hurtado', '[]'::jsonb, 24),
('matheus-fernandes', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Matheus Fernandes', 'Matheus Fernandes Siqueira', 35, 'Volante', 'Volantes', '1998-06-30', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/osevymluayy2fvatat1h/matheus-fernandes', '[]'::jsonb, 25),
('fabricio', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Fabrício', 'Fabrício Oliveira de Souza', 37, 'Goleiro', 'Goleiros', '2000-06-15', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/d7f8fnmquyo5w8g2oejm/goleiro-fabricio', '[]'::jsonb, 26),
('caue', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Cauê', 'Cauê Nascimento Santos', 51, 'Lateral-esquerdo', 'Laterais-esquerdos', '2006-12-13', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/hwdyuh3zb0rziw6uti4h/caue-nascimento-santos', '[]'::jsonb, 27),
('gustavo-reis', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gustavo Reis', 'Gustavo Reis', 56, 'Goleiro', 'Goleiros', '2005-06-10', 'Brasil', null, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ryj16iqsieanvoojcnth/gustavo-reis', '[]'::jsonb, 28),
('marcelinho', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Marcelinho', 'Marcelo Braz da Silva', 57, 'Meia-atacante', 'Atacantes', '2004-08-16', 'Brasil', 178, null, 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/ltda85wbzbkjjiipnt6z/marcelinho-braz', '[]'::jsonb, 29)
on conflict (id) do update set
  club_id = excluded.club_id, name = excluded.name, full_name = excluded.full_name,
  shirt_number = excluded.shirt_number, position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality, height_cm = excluded.height_cm,
  foot = excluded.foot, photo_url = excluded.photo_url, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();
