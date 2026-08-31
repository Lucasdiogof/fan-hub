-- ============================================================================
-- RPC nova pro Passaporte: numeros da trajetoria do usuario (vitorias,
-- empates, derrotas, jogos em casa/fora, gols) sobre TODAS as partidas
-- FINISHED marcadas como "Eu fui", em qualquer temporada -- nunca so o ano
-- selecionado na tela (isso ja existe via passport_matches_for_year).
--
-- security definer + filtro por auth.uid() = mesmo padrao das outras RPCs
-- deste modulo (passport_summary, passport_ranking, etc.) -- so leitura,
-- nao muda nenhuma tabela.
-- ============================================================================

create or replace function public.passport_attendance_breakdown()
returns table (
  total_attended int,
  wins int,
  draws int,
  losses int,
  home_games int,
  away_games int,
  goals_for int,
  goals_against int
)
language sql
security definer
set search_path = public
stable
as $$
  select
    count(*)::int,
    count(*) filter (where m.outcome = 'WIN')::int,
    count(*) filter (where m.outcome = 'DRAW')::int,
    count(*) filter (where m.outcome = 'LOSS')::int,
    count(*) filter (where m.goias_is_home)::int,
    count(*) filter (where not m.goias_is_home)::int,
    coalesce(sum(m.goias_score), 0)::int,
    coalesce(sum(m.opponent_score), 0)::int
  from public.passport_attendances a
  join public.passport_matches m on m.id = a.match_id
  where a.user_id = auth.uid()
    and a.attended = true
    and m.status = 'FINISHED';
$$;

grant execute on function public.passport_attendance_breakdown() to authenticated;
