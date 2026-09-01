-- ============================================================================
-- Ajuste pontual só no estádio do próprio Goiás — "Estádio Hailé Pinheiro
-- (Serrinha)" vira só "Estádio Hailé Pinheiro" na exibição. Não é uma regra
-- geral: os outros ~48 estádios importados que também têm apelido entre
-- parênteses mantêm o parênteses de propósito, porque nesses casos o
-- apelido costuma ser o nome mais reconhecido (Maracanã, Mineirão,
-- Beira-Rio, Vila Belmiro...) — só o Hailé Pinheiro é o caso onde o nome
-- oficial sozinho já é como todo mundo chama.
-- ============================================================================

update public.venues
set
  canonical_name = 'Estádio Hailé Pinheiro',
  display_name = 'Estádio Hailé Pinheiro',
  updated_at = now()
where id = 'venue_2285f4815de3';
