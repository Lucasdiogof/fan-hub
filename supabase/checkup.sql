-- Checkup geral num único SELECT (o editor do Supabase só mostra o
-- resultado do último statement, então isso junta tudo com UNION ALL).
-- Cada linha é um problema encontrado; se não voltar nenhuma linha, está tudo ok.

select 'squad_members: total != 31' as check, id::text as detail
from (select count(*) as id from public.squad_members) t
where id != 31

union all

select 'squad_members: id duplicado', id
from public.squad_members
group by id
having count(*) > 1

union all

select 'squad_members: camisa duplicada', name || ' (camisa ' || shirt_number || ')'
from public.squad_members a
where shirt_number is not null
  and exists (
    select 1 from public.squad_members b
    where b.shirt_number = a.shirt_number and b.id != a.id
  )

union all

select 'squad_members: campo obrigatório vazio', id
from public.squad_members
where name is null or position is null or position_group is null or trim(name) = ''

union all

select 'squad_members: position_group inválido', id || ' -> ' || coalesce(position_group, 'NULL')
from public.squad_members
where position_group is null or position_group not in (
  'Goleiros','Zagueiros','Laterais-direitos','Laterais-esquerdos',
  'Volantes','Meios-campistas','Atacantes'
)

union all

select 'squad_members: sort_order duplicado', sort_order::text || ' -> ' || string_agg(name, ', ')
from public.squad_members
group by sort_order
having count(*) > 1

union all

select 'squad_members: club_history vazio', id
from public.squad_members
where jsonb_array_length(club_history) = 0

union all

select 'match_lineup_votes: voto duplicado (mesmo user+jogo)', match_id || ' / ' || user_id
from public.match_lineup_votes
group by match_id, user_id
having count(*) > 1

union all

-- linha de resumo, sempre aparece (não é erro, é só contagem)
select 'RESUMO: squad_members total / match_lineup_votes total',
  (select count(*) from public.squad_members)::text || ' / ' ||
  (select count(*) from public.match_lineup_votes)::text;
