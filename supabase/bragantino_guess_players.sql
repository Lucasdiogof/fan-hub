-- Quem Vestiu o Manto? — 50 cards do Bragantino, adaptados ao schema REAL
-- de `guess_players` a partir do pacote docs/bragantino_data/new_data/
-- quem_vestiu_o_manto_50_FINAL_v3.json, 2026-09-08.
--
-- Mapeamentos importantes (NUNCA automáticos/assumidos):
--   * `origin_club` só virou `academy_club` (dica "BASE") quando o
--     próprio pacote já marcava "(base)" explicitamente — 8 dos 50. Os
--     outros 42 ficam com `academy_club = null`: `origin_club` no
--     pacote é o clube de ORIGEM/transferência, não necessariamente a
--     categoria de base — não é a mesma coisa, e assumir isso seria
--     inventar formação que não foi confirmada.
--   * `club_debut_year` NUNCA = `first_bragantino_season` do pacote
--     (temporada de elenco != estreia em campo, o próprio pacote já
--     alertava pra essa diferença). Confirmado por fonte própria só pra
--     Tiago Volpi (estreia 15/01/2026 vs EC São José) — os outros 49
--     ficam `club_debut_year = null` até pesquisa dedicada por jogador.
--   * 46 das 50 fotos já resolvem de verdade via
--     `ClubConfig.assets.guessPlayerPhotos` (ver `bragantino_club_config.dart`):
--     as 10 do elenco atual são as MESMAS URLs do CDN oficial do
--     `bragantino_squad_members.sql`; 36 das 40 históricas pedidas
--     chegaram em 2026-09-08 e viraram assets locais em
--     `lib/assets/games/guess_player/bragantino/`. Só 4 continuam sem
--     foto (Cesar Haydar, Ligger, Edimar, Gonzalo Fornari) — `imageUrl`
--     resolve `null` pra esses até o arquivo chegar (nunca um
--     placeholder). Foto resolvida NÃO significa `data_status='verified'`
--     sozinha — ainda precisa das 4 dicas completas.
--   * `data_status = 'verified'` só quando as 4 dicas E a foto existem —
--     hoje só o Tiago Volpi bate nisso. Todo o resto fica `incomplete`
--     (ainda aparece no autocomplete/comparação, só não é sorteável como
--     segredo, ver `GuessPlayer.eligibleAsSecret`).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.guess_players (id, club_id, name, display_name, aliases, position, shirt_number, academy_club, club_debut_year, photo_key, data_status, sort_order) values
('braga_manto_01', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Tiago Volpi', 'Tiago Volpi', '["Tiago Volpi"]'::jsonb, 'gol', 18, 'São José-RS / Fluminense (base)', 2026, 'tiago-volpi', 'verified', 1),
('braga_manto_02', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Andrés Hurtado', 'Andrés Hurtado', '["Andrés Hurtado"]'::jsonb, 'ld', 34, null, null, 'andres-hurtado', 'incomplete', 2),
('braga_manto_03', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Alix Vinícius', 'Alix Vinícius', '["Alix Vinícius"]'::jsonb, 'zag', 4, null, null, 'alix-vinicius', 'incomplete', 3),
('braga_manto_04', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gustavo Marques', 'Gustavo Marques', '["Gustavo Marques"]'::jsonb, 'zag', 16, null, null, 'gustavo-marques', 'incomplete', 4),
('braga_manto_05', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Juninho Capixaba', 'Juninho Capixaba', '["Juninho Capixaba"]'::jsonb, 'le', 29, null, null, 'juninho-capixaba', 'incomplete', 5),
('braga_manto_06', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Fabinho', 'Fabinho', '["Fabinho"]'::jsonb, 'vol', 5, null, null, 'fabinho', 'incomplete', 6),
('braga_manto_07', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Rodriguinho', 'Rodriguinho', '["Rodriguinho"]'::jsonb, 'mei', 20, null, null, 'rodriguinho', 'incomplete', 7),
('braga_manto_08', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Lucas Barbosa', 'Lucas Barbosa', '["Lucas Barbosa"]'::jsonb, 'ata', 21, 'Novorizontino / Santos (base)', null, 'lucas-barbosa', 'incomplete', 8),
('braga_manto_09', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Henry Mosquera', 'Henry Mosquera', '["Henry Mosquera"]'::jsonb, 'ata', 30, null, null, 'henry-mosquera', 'incomplete', 9),
('braga_manto_10', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Vinicinho', 'Vinicinho', '["Vinicinho"]'::jsonb, 'ata', 17, 'Red Bull Bragantino II', null, 'vinicinho-pereira', 'incomplete', 10),
('braga_manto_11', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Júlio César', 'Júlio César', '["Júlio César"]'::jsonb, 'gol', 1, null, null, 'julio_cesar', 'incomplete', 11),
('braga_manto_12', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Cleiton', 'Cleiton', '["Cleiton"]'::jsonb, 'gol', 18, null, null, 'cleiton', 'incomplete', 12),
('braga_manto_13', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Aderlan', 'Aderlan', '["Aderlan"]'::jsonb, 'ld', 13, null, null, 'aderlan', 'incomplete', 13),
('braga_manto_14', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Weverton', 'Weverton', '["Weverton"]'::jsonb, 'ld', 17, null, null, 'weverton', 'incomplete', 14),
('braga_manto_15', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Fabrício Bruno', 'Fabrício Bruno', '["Fabrício Bruno"]'::jsonb, 'zag', 14, null, null, 'fabricio_bruno', 'incomplete', 15),
('braga_manto_16', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Léo Realpe', 'Léo Realpe', '["Léo Realpe"]'::jsonb, 'zag', 2, null, null, 'leo_realpe', 'incomplete', 16),
('braga_manto_17', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Natan', 'Natan', '["Natan"]'::jsonb, 'zag', 21, null, null, 'natan', 'incomplete', 17),
('braga_manto_18', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Cesar Haydar', 'Cesar Haydar', '["Cesar Haydar"]'::jsonb, 'zag', 24, null, null, 'cesar_haydar', 'incomplete', 18),
('braga_manto_19', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Léo Ortiz', 'Léo Ortiz', '["Léo Ortiz"]'::jsonb, 'zag', 3, null, null, 'leo_ortiz', 'incomplete', 19),
('braga_manto_20', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Ligger', 'Ligger', '["Ligger"]'::jsonb, 'zag', 4, null, null, 'ligger', 'incomplete', 20),
('braga_manto_21', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Weverson Costa', 'Weverson Costa', '["Weverson Costa"]'::jsonb, 'le', 26, 'São Paulo (base)', null, 'weverson_costa', 'incomplete', 21),
('braga_manto_22', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Luan Cândido', 'Luan Cândido', '["Luan Cândido"]'::jsonb, 'le', 29, null, null, 'luan_candido', 'incomplete', 22),
('braga_manto_23', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Edimar', 'Edimar', '["Edimar"]'::jsonb, 'le', 6, null, null, 'edimar', 'incomplete', 23),
('braga_manto_24', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Guilherme Lopes', 'Guilherme Lopes', '["Guilherme Lopes"]'::jsonb, 'le', 31, 'Cruzeiro / Red Bull Brasil (base)', null, 'guilherme_lopes', 'incomplete', 24),
('braga_manto_25', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Jadsom', 'Jadsom', '["Jadsom"]'::jsonb, 'vol', 5, null, null, 'jadsom', 'incomplete', 25),
('braga_manto_26', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Eric Ramires', 'Eric Ramires', '["Eric Ramires"]'::jsonb, 'mc', 16, null, null, 'eric_ramires', 'incomplete', 26),
('braga_manto_27', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Raul', 'Raul', '["Raul"]'::jsonb, 'vol', 23, null, null, 'raul', 'incomplete', 27),
('braga_manto_28', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Ricardo Ryller', 'Ricardo Ryller', '["Ricardo Ryller"]'::jsonb, 'vol', 25, null, null, 'ricardo_ryller', 'incomplete', 28),
('braga_manto_29', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Praxedes', 'Praxedes', '["Praxedes"]'::jsonb, 'mc', 25, null, null, 'praxedes', 'incomplete', 29),
('braga_manto_30', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Emiliano Martínez', 'Emiliano Martínez', '["Emiliano Martínez"]'::jsonb, 'vol', 40, null, null, 'emiliano_martinez', 'incomplete', 30),
('braga_manto_31', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Claudinho', 'Claudinho', '["Claudinho"]'::jsonb, 'mei', 10, null, null, 'claudinho', 'incomplete', 31),
('braga_manto_32', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Vitinho', 'Vitinho', '["Vitinho"]'::jsonb, 'mei', 30, null, null, 'vitinho', 'incomplete', 32),
('braga_manto_33', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Thonny Anderson', 'Thonny Anderson', '["Thonny Anderson"]'::jsonb, 'mei', 31, null, null, 'thonny_anderson', 'incomplete', 33),
('braga_manto_34', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Lucas Evangelista', 'Lucas Evangelista', '["Lucas Evangelista"]'::jsonb, 'mc', 8, null, null, 'lucas_evangelista', 'incomplete', 34),
('braga_manto_35', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Chrigor', 'Chrigor', '["Chrigor"]'::jsonb, 'ata', 18, null, null, 'chrigor', 'incomplete', 35),
('braga_manto_36', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Tomás Cuello', 'Tomás Cuello', '["Tomás Cuello"]'::jsonb, 'ata', 28, null, null, 'tomas_cuello', 'incomplete', 36),
('braga_manto_37', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Jan Hurtado', 'Jan Hurtado', '["Jan Hurtado"]'::jsonb, 'ata', 27, null, null, 'jan_hurtado', 'incomplete', 37),
('braga_manto_38', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Bruno Tubarão', 'Bruno Tubarão', '["Bruno Tubarão"]'::jsonb, 'mei', 20, null, null, 'bruno_tubarao', 'incomplete', 38),
('braga_manto_39', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Artur', 'Artur', '["Artur"]'::jsonb, 'pd', 7, null, null, 'artur', 'incomplete', 39),
('braga_manto_40', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Ytalo', 'Ytalo', '["Ytalo"]'::jsonb, 'ata', 15, null, null, 'ytalo', 'incomplete', 40),
('braga_manto_41', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gabriel Novaes', 'Gabriel Novaes', '["Gabriel Novaes"]'::jsonb, 'ata', 35, null, null, 'gabriel_novaes', 'incomplete', 41),
('braga_manto_42', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Bruninho', 'Bruninho', '["Bruninho"]'::jsonb, 'ata', 36, 'Red Bull Bragantino (base)', null, 'bruninho', 'incomplete', 42),
('braga_manto_43', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Gonzalo Fornari', 'Gonzalo Fornari', '["Gonzalo Fornari"]'::jsonb, 'ata', 42, null, null, 'gonzalo_fornari', 'incomplete', 43),
('braga_manto_44', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Alerrandro', 'Alerrandro', '["Alerrandro"]'::jsonb, 'ata', 9, null, null, 'alerrandro', 'incomplete', 44),
('braga_manto_45', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Helinho', 'Helinho', '["Helinho"]'::jsonb, 'pd', 11, null, null, 'helinho', 'incomplete', 45),
('braga_manto_46', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Leandrinho', 'Leandrinho', '["Leandrinho"]'::jsonb, 'ata', 22, 'Ituano / Ponte Preta (base)', null, 'leandrinho', 'incomplete', 46),
('braga_manto_47', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Luis Phelipe', 'Luis Phelipe', '["Luis Phelipe"]'::jsonb, 'ata', 34, null, null, 'luis_phelipe', 'incomplete', 47),
('braga_manto_48', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Pedro Naressi', 'Pedro Naressi', '["Pedro Naressi"]'::jsonb, 'vol', 19, null, null, 'pedro_naressi', 'incomplete', 48),
('braga_manto_49', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Uillian Correia', 'Uillian Correia', '["Uillian Correia"]'::jsonb, 'vol', 8, 'Athletico-PR (base)', null, 'uillian_correia', 'incomplete', 49),
('braga_manto_50', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Matheus Jesus', 'Matheus Jesus', '["Matheus Jesus"]'::jsonb, 'mc', 11, null, null, 'matheus_jesus', 'incomplete', 50)
on conflict (id) do update set
  club_id = excluded.club_id, name = excluded.name, display_name = excluded.display_name,
  aliases = excluded.aliases, position = excluded.position, shirt_number = excluded.shirt_number,
  academy_club = excluded.academy_club, club_debut_year = excluded.club_debut_year,
  photo_key = excluded.photo_key, data_status = excluded.data_status, sort_order = excluded.sort_order;
