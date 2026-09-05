-- ============================================================================
-- Quem Vestiu o Manto — backfill COMPLETO de photo_key + os 5 jogadores
-- fechados na auditoria de 2026-09-05 (Michael, Marcelo Rangel, Apodi,
-- Dill, Tadeu). Rode no SQL Editor do Supabase do Goiás. NÃO é a Etapa que
-- resolve os outros ~130 jogadores ainda incompletos do catálogo — só o
-- que já tem dado pronto do lado Flutter e nunca chegou aqui.
--
-- CONTEXTO DO BUG (achado no Bloco 4, corrigido em
-- guess_player_repository.dart): `photo_key` só era resolvido contra
-- `squadPhotoAssets` (elenco atual). Os jogadores do acervo histórico
-- (`guessPlayerPhotoAssets`, ex-jogadores sem foto de elenco) sempre
-- tiveram photo_key NULL aqui no banco — o dado nunca chegou a ser escrito
-- nesta tabela, mesmo o commit "Add 41 historical player photos" (27/08)
-- tendo dado certo no Dart. Resultado: nenhum desses jogadores aparecia
-- com foto em produção (só no fallback local `guessPlayerCatalog`), e
-- nenhum deles podia ser sorteado como secreto (`eligibleAsSecret` exige
-- imageUrl != null).
--
-- AUDITORIA (rodada em cima do Dart + desta seed, ambos como commitados em
-- 2026-09-05 — ver relatório da conversa pra números completos):
--   45 chaves em guessPlayerPhotoAssets, 45 jogadores do catálogo
--   referenciam alguma delas (1:1, 0 assets órfãos, 0 referência quebrada).
--   Dessas 45: 44 já existem nesta tabela, TODAS com photo_key NULL hoje;
--   1 (Dill) não existe nesta tabela ainda.
--
-- ESCOPO DESTE ARQUIVO — só os campos abaixo, nada além:
--   PASSO 1: photo_key de 41 jogadores (só essa coluna, sempre = próprio
--            id — nunca nome/texto frágil, o id já é a chave estável da
--            tabela). Guardado por `photo_key is null`: nunca sobrescreve
--            um valor já preenchido manualmente por engano.
--   PASSO 2: Tadeu — só data_status (photo_key já estava correto).
--   PASSO 3-5: Michael / Marcelo Rangel / Apodi — os campos específicos
--            fechados na pesquisa deste bloco (nunca status/editorial
--            incidental além do que foi de fato pesquisado e decidido).
--   PASSO 6: Dill — INSERT novo, guardado por NOT EXISTS.
--
-- Idempotente: pode rodar quantas vezes quiser, nunca duplica Dill nem
-- reescreve um campo que já está no valor alvo.
-- ============================================================================

-- Antes de rodar, se quiser conferir o estado atual:
-- select id, photo_key, data_status, shirt_number, academy_club
-- from public.guess_players
-- where id in (
--   'alex_dias','bruno_melo','caio_vinicius','david','david_duarte',
--   'diego_caito','dudu_cearense','eduardo_sasha','egidio','elvis','erik',
--   'ernando','everton_morelli','fellipe_bastos','fernandao','harlei',
--   'jadilson','julian_palacios','lucas_halter','lucas_lovat','maguinho',
--   'matheus_peixoto','otacilio_neto','rafael_moura','rafael_toloi','renan',
--   'renan_oliveira','ricardo_goulart','rodrigo_andrade','romerito','souza',
--   'thiago_mendes','titi','tulio_maravilha','vitor','walter','willean_lepo',
--   'william_matheus','willian_oliveira','ze_hugo','ze_ricardo',
--   'tadeu_antonio_ferreira','michael','marcelo_rangel','apodi','dill'
-- )
-- order by id;
-- (o resultado esperado ANTES: photo_key null pros 41 + michael/
-- marcelo_rangel/apodi; tadeu já com photo_key='tadeu' mas data_status=
-- 'review'; dill nem aparece.)

-- ---------------------------------------------------------------------------
-- PASSO 1 — 41 jogadores do acervo histórico: só photo_key, sempre = id.
-- ---------------------------------------------------------------------------
update public.guess_players
set photo_key = id
where photo_key is null
  and id = any(array[
    'alex_dias','bruno_melo','caio_vinicius','david','david_duarte',
    'diego_caito','dudu_cearense','eduardo_sasha','egidio','elvis','erik',
    'ernando','everton_morelli','fellipe_bastos','fernandao','harlei',
    'jadilson','julian_palacios','lucas_halter','lucas_lovat','maguinho',
    'matheus_peixoto','otacilio_neto','rafael_moura','rafael_toloi','renan',
    'renan_oliveira','ricardo_goulart','rodrigo_andrade','romerito','souza',
    'thiago_mendes','titi','tulio_maravilha','vitor','walter','willean_lepo',
    'william_matheus','willian_oliveira','ze_hugo','ze_ricardo'
  ]);

-- ---------------------------------------------------------------------------
-- PASSO 2 — Tadeu: os 4 campos + photo_key já estavam certos (confirmados
-- de novo nesta auditoria contra Wikipédia/Lance!/release oficial do
-- Goiás EC) — só faltava tirar do 'review'.
-- ---------------------------------------------------------------------------
update public.guess_players
set data_status = 'verified'
where id = 'tadeu_antonio_ferreira'
  and data_status <> 'verified';

-- ---------------------------------------------------------------------------
-- PASSO 3 — Michael: clube formador (Goianésia, último clube antes do
-- Goiás) + foto + verified.
-- ---------------------------------------------------------------------------
update public.guess_players
set academy_club = 'Goianésia',
    photo_key = 'michael',
    data_status = 'verified'
where id = 'michael';

-- ---------------------------------------------------------------------------
-- PASSO 4 — Marcelo Rangel: camisa 1 (confirmada no perfil "Goiás 2020"
-- da esmeraldino.com) + clube formador (Chapecoense) + foto + verified.
-- ---------------------------------------------------------------------------
update public.guess_players
set shirt_number = 1,
    academy_club = 'Chapecoense',
    photo_key = 'marcelo_rangel',
    data_status = 'verified'
where id = 'marcelo_rangel';

-- ---------------------------------------------------------------------------
-- PASSO 5 — Apodi: nome completo + foto. NUNCA muda pra verified aqui —
-- a camisa 22 já cadastrada não foi corroborada por nenhuma fonte externa
-- consultada nesta auditoria (identidade e posição já eram corretas).
-- ---------------------------------------------------------------------------
update public.guess_players
set aliases = '["Luiz Diallisson de Souza Alves"]'::jsonb,
    photo_key = 'apodi'
where id = 'apodi';

-- ---------------------------------------------------------------------------
-- PASSO 6 — Dill (novo). Camisa deixada NULL de propósito: fontes
-- externas divergem entre 7 e 9, nenhuma primária resolve — nunca um
-- número chutado. Por isso data_status = 'review', não 'verified'.
-- ---------------------------------------------------------------------------
insert into public.guess_players (
  id, name, display_name, aliases, position, shirt_number, academy_club,
  nationality_code, nationality_name, club_debut_year, photo_key,
  data_status, sort_order, club_id
)
select
  'dill', 'Dill', 'Dill', '["Elpídio Barbosa Conceição"]'::jsonb, 'ata',
  null, 'Brasília', 'BR', 'Brasil', 1994, 'dill', 'review',
  (select coalesce(max(sort_order), 0) + 1 from public.guess_players),
  '4c16340d-300c-5ab2-903f-17519db9b146'
where not exists (select 1 from public.guess_players where id = 'dill');

-- Depois de rodar, pra conferir (repita a query "antes de rodar" acima) —
-- esperado: os 41 + michael/marcelo_rangel/apodi/tadeu com photo_key
-- preenchido; michael/marcelo_rangel/tadeu com data_status='verified';
-- apodi continua 'review'; dill aparece com photo_key='dill',
-- data_status='review', shirt_number NULL.
