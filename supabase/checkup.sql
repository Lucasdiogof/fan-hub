-- ============================================================================
-- Checkup geral do banco — rode no SQL Editor do Supabase.
-- Cada linha retornada = um problema encontrado.
-- Se só aparecer as linhas de RESUMO, está tudo ok.
-- ============================================================================

-- ═══════════════════════════════════════════════════════════════════════════
-- SQUAD_MEMBERS
-- ═══════════════════════════════════════════════════════════════════════════

select '❌ squad_members: id duplicado' as check, id as detail
from public.squad_members group by id having count(*) > 1

union all

select '❌ squad_members: camisa duplicada', a.name || ' e ' || b.name || ' (camisa ' || a.shirt_number || ')'
from public.squad_members a
join public.squad_members b on b.shirt_number = a.shirt_number and b.id > a.id
where a.shirt_number is not null

union all

select '❌ squad_members: campo obrigatório vazio', id
from public.squad_members
where name is null or position is null or position_group is null or trim(name) = ''

union all

select '❌ squad_members: position_group inválido', id || ' → ' || coalesce(position_group, 'NULL')
from public.squad_members
where position_group not in (
  'Goleiros','Zagueiros','Laterais-direitos','Laterais-esquerdos',
  'Volantes','Meios-campistas','Atacantes'
)

union all

select '❌ squad_members: sort_order duplicado', sort_order::text || ' → ' || string_agg(name, ', ')
from public.squad_members group by sort_order having count(*) > 1

union all

select '❌ squad_members: club_history vazio', id
from public.squad_members where jsonb_array_length(club_history) = 0

-- ═══════════════════════════════════════════════════════════════════════════
-- QUIZ_QUESTIONS
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ quiz_questions: id duplicado', id
from public.quiz_questions group by id having count(*) > 1

union all

select '❌ quiz_questions: difficulty inválido', id || ' → ' || difficulty
from public.quiz_questions
where difficulty not in ('torcedor','esmeraldino','fanatico')

union all

select '❌ quiz_questions: correct_index fora do range', id || ' → idx=' || correct_index || ', options=' || jsonb_array_length(options)::text
from public.quiz_questions
where correct_index < 0 or correct_index >= jsonb_array_length(options)

union all

select '❌ quiz_questions: menos de 2 opções', id || ' → ' || jsonb_array_length(options)::text || ' opções'
from public.quiz_questions where jsonb_array_length(options) < 2

union all

select '❌ quiz_questions: pergunta vazia', id
from public.quiz_questions where trim(question) = '' or question is null

union all

select '❌ quiz_questions: sort_order duplicado na mesma difficulty', difficulty || ' sort=' || sort_order::text
from public.quiz_questions group by difficulty, sort_order having count(*) > 1

-- ═══════════════════════════════════════════════════════════════════════════
-- CAREER_PLAYERS
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ career_players: id duplicado', id
from public.career_players group by id having count(*) > 1

union all

select '❌ career_players: answer vazio', id
from public.career_players where trim(answer) = '' or answer is null

union all

select '❌ career_players: club_career vazio', id
from public.career_players where jsonb_array_length(club_career) = 0

union all

select '❌ career_players: sort_order duplicado', sort_order::text || ' → ' || string_agg(id, ', ')
from public.career_players group by sort_order having count(*) > 1

-- ═══════════════════════════════════════════════════════════════════════════
-- GUESS_PLAYERS
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ guess_players: id duplicado', id
from public.guess_players group by id having count(*) > 1

union all

select '❌ guess_players: data_status inválido', id || ' → ' || data_status
from public.guess_players
where data_status not in ('verified','review','incomplete')

union all

select '❌ guess_players: name ou display_name vazio', id
from public.guess_players
where trim(name) = '' or name is null or trim(display_name) = '' or display_name is null

union all

select '❌ guess_players: sort_order duplicado', sort_order::text || ' → ' || string_agg(id, ', ')
from public.guess_players group by sort_order having count(*) > 1

-- ═══════════════════════════════════════════════════════════════════════════
-- LINEUP_MATCHES
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ lineup_matches: id duplicado', id
from public.lineup_matches group by id having count(*) > 1

union all

select '❌ lineup_matches: formation_confidence inválido', id || ' → ' || formation_confidence
from public.lineup_matches
where formation_confidence not in ('confirmed','probable','estimated')

union all

select '❌ lineup_matches: lineup vazio', id
from public.lineup_matches where jsonb_array_length(lineup) = 0

union all

select '❌ lineup_matches: lineup size != formação (esperava 11)', id || ' → ' || formation || ' tem ' || jsonb_array_length(lineup)::text
from public.lineup_matches where jsonb_array_length(lineup) != 11

union all

select '❌ lineup_matches: display_order duplicado', display_order::text || ' → ' || string_agg(id, ', ')
from public.lineup_matches group by display_order having count(*) > 1

union all

select '❌ lineup_matches: placar negativo', id || ' → ' || home_score::text || 'x' || away_score::text
from public.lineup_matches where home_score < 0 or away_score < 0

-- ═══════════════════════════════════════════════════════════════════════════
-- MEMBERSHIP FAQ
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ membership_faq_categories: id duplicado', id
from public.membership_faq_categories group by id having count(*) > 1

union all

select '❌ membership_faq_items: id duplicado', id
from public.membership_faq_items group by id having count(*) > 1

union all

select '❌ membership_faq_items: category_id órfão', id || ' → cat=' || category_id
from public.membership_faq_items fi
where not exists (
  select 1 from public.membership_faq_categories fc where fc.id = fi.category_id
)

union all

select '❌ membership_faq_items: question vazia', id
from public.membership_faq_items where trim(question) = '' or question is null

union all

select '❌ membership_faq_categories: sem nenhum item', fc.id
from public.membership_faq_categories fc
where not exists (
  select 1 from public.membership_faq_items fi where fi.category_id = fc.id
)

-- ═══════════════════════════════════════════════════════════════════════════
-- MEMBERSHIP REGULATION
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ membership_regulation_versions: nenhuma versão', '0'
where not exists (select 1 from public.membership_regulation_versions)

-- ═══════════════════════════════════════════════════════════════════════════
-- USER PROGRESS (arena ranking)
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ user_game_item_progress: score negativo', user_id::text || ' / ' || game_id || ' / ' || item_id
from public.user_game_item_progress where score < 0

union all

select '❌ user_game_item_progress: game_id desconhecido', game_id || ' (' || count(*)::text || ' linhas)'
from public.user_game_item_progress
where game_id not in ('quiz','career_path','lineup','guess_player')
group by game_id

union all

select '❌ score_events: points_delta incoerente com scores', se.id::text
from public.score_events se
where se.new_item_score - se.previous_item_score != se.points_delta

-- ═══════════════════════════════════════════════════════════════════════════
-- MATCH_LINEUP_VOTES (crowd lineup)
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ match_lineup_votes: voto duplicado (user+match)', match_id || ' / ' || user_id::text
from public.match_lineup_votes group by match_id, user_id having count(*) > 1

union all

select '❌ match_lineup_votes: slots vazio', id::text
from public.match_lineup_votes where jsonb_array_length(slots) = 0

-- ═══════════════════════════════════════════════════════════════════════════
-- TICKETS (se a tabela existir — se tickets.sql ainda não rodou, ignora)
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '❌ tickets: status inválido', id::text || ' → ' || status
from public.tickets
where status not in ('active','cancelled','used','expired')

union all

select '❌ tickets: origin inválido', id::text || ' → ' || origin
from public.tickets
where origin not in ('purchase','membership_check_in')

union all

select '❌ tickets: compra sem order_id', id::text
from public.tickets where origin = 'purchase' and order_id is null

union all

select '❌ tickets: check-in duplicado (user+match)', user_id::text || ' / ' || match_id
from public.tickets
where origin = 'membership_check_in'
group by user_id, match_id having count(*) > 1

union all

select '❌ ticket_orders: status inválido', id::text || ' → ' || status
from public.ticket_orders
where status not in ('confirmed','pending','cancelled','refunded')

union all

select '❌ ticket_orders: total negativo', id::text || ' → ' || total::text
from public.ticket_orders where total < 0

union all

select '❌ ticket_checkin_decisions: decision inválida', user_id::text || ' → ' || decision
from public.ticket_checkin_decisions
where decision not in ('confirmed','declined')

-- ═══════════════════════════════════════════════════════════════════════════
-- PROFILES
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- RESUMO (sempre aparece — é só contagem, não é erro)
-- ═══════════════════════════════════════════════════════════════════════════

union all

select '📊 RESUMO', ''

union all
select '   squad_members', (select count(*) from public.squad_members)::text

union all
select '   quiz_questions', (select count(*) from public.quiz_questions)::text

union all
select '   career_players', (select count(*) from public.career_players)::text

union all
select '   guess_players', (select count(*) from public.guess_players)::text

union all
select '   lineup_matches', (select count(*) from public.lineup_matches)::text

union all
select '   membership_faq_categories', (select count(*) from public.membership_faq_categories)::text

union all
select '   membership_faq_items', (select count(*) from public.membership_faq_items)::text

union all
select '   membership_regulation_versions', (select count(*) from public.membership_regulation_versions)::text

union all
select '   user_game_item_progress', (select count(*) from public.user_game_item_progress)::text

union all
select '   score_events', (select count(*) from public.score_events)::text

union all
select '   match_lineup_votes', (select count(*) from public.match_lineup_votes)::text

union all
select '   profiles', (select count(*) from public.profiles)::text

union all
select '   ticket_checkin_decisions', (select count(*) from public.ticket_checkin_decisions)::text

union all
select '   ticket_orders', (select count(*) from public.ticket_orders)::text

union all
select '   tickets', (select count(*) from public.tickets)::text
;
