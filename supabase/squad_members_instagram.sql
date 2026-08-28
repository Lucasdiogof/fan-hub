-- Instagram de cada jogador do elenco — lista passada pelo usuário.
-- Idempotente (é um UPDATE puro, pode rodar de novo sem problema).

update public.squad_members as t
set instagram_url = v.url
from (values
  ('tadeu', 'https://www.instagram.com/tadeu/'),
  ('ezequiel', 'https://www.instagram.com/e.oliveira03/'),
  ('murillo_victorio', 'https://www.instagram.com/murillocvictorio/'),
  ('thiago_rodrigues', 'https://www.instagram.com/thiagorodrigues73oficial/'),
  ('luisao', 'https://www.instagram.com/luisdoria03/'),
  ('lucas_ribeiro', 'https://www.instagram.com/lucasribeiro3080/'),
  ('luiz_felipe', 'https://www.instagram.com/luiz_felipe/'),
  ('ramon_menezes', 'https://www.instagram.com/ramonroma_/'),
  ('murilo_camara', 'https://www.instagram.com/murilocamaraa/'),
  ('rodrigo_soares', 'https://www.instagram.com/rodrigosoares02/'),
  ('marcos_vinicius', 'https://www.instagram.com/marcosvsantos_/'),
  ('nicolas', 'https://www.instagram.com/nicolasvecchiato/'),
  ('danilo', 'https://www.instagram.com/danilocunha66/'),
  ('djalma', 'https://www.instagram.com/djalmasilva06/'),
  ('lourenco', 'https://www.instagram.com/joao.lourenco97/'),
  ('filipe_machado', 'https://www.instagram.com/f.machado96/'),
  ('baldoria', 'https://www.instagram.com/g_baldoria/'),
  ('juninho', 'https://www.instagram.com/ojuninholiveira8/'),
  ('lucas_rodrigues', 'https://www.instagram.com/lucasrmc35/'),
  ('gege', 'https://www.instagram.com/gegemarques94/'),
  ('lucas_lima', 'https://www.instagram.com/lucaslima/'),
  ('brayann', 'https://www.instagram.com/brayannbrito/'),
  ('wellington_rato', 'https://www.instagram.com/wellingtonratooficial/'),
  ('pedrinho', 'https://www.instagram.com/pedrinho__04/'),
  ('anselmo_ramon', 'https://www.instagram.com/anselmoramon09/'),
  ('cadu', 'https://www.instagram.com/caduzin_04/'),
  ('felipe_clemente', 'https://www.instagram.com/f.clemente10/'),
  ('jean_carlos', 'https://www.instagram.com/jeeancarlos_05/'),
  ('halerrandrio', 'https://www.instagram.com/halerrandrio7/'),
  ('esli_garcia', 'https://www.instagram.com/esligram/'),
  ('kadu_sousa', 'https://www.instagram.com/kadusousa_40/')
) as v(id, url)
where t.id = v.id;
