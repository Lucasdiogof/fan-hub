-- ============================================================================
-- Quem Vestiu o Manto (Goiás) — regra de CLUBE FORMADOR (aprovada pelo
-- usuário em 2026-10-02): só vale com fonte explícita ("revelado por",
-- "formado/criado nas categorias de base", "cria da base"). Não vale primeiro
-- clube profissional, clube da estreia, clube mais antigo do currículo nem ter
-- jogado jovem lá. Sem fonte explícita, o campo fica vazio — e (mudança de
-- código no mesmo commit) formador vazio NÃO impede mais o sorteio: a pista
-- aparece como "Desconhecido".
--
-- Levantamento: OneDrive/Desktop/auditoria-arena-goias-clube-formador.xlsx
-- (59 jogadores com estreia antes de 2008 e status != verified; Wikipédia pt).
--
-- Bloco 1 — correções com fonte explícita:
--   * Caíco: "Foi revelado nas categorias da base do Internacional"
--     (pt.wikipedia.org/wiki/Caíco) — banco tinha Grêmio;
--   * Nonato: "Nonato começou nas divisões de base do Tuna Luso"
--     (pt.wikipedia.org/wiki/Nonato) — banco tinha Bahia.
-- Bloco 2 — 26 valores sem fonte explícita viram null.
-- Bloco 3 — Araújo vira null: Central × Porto segue em aberto e o
--   'Porto-PE' que estava no banco não tem fonte explícita de base.
-- Ficam como estão (decisão do usuário): Lúcio Bala e Michel Santana seguem
-- vazios (termos "descoberto por olheiro"/"surgiu para o futebol" não
-- bastam) e os 12 que agora têm fonte (mantidos).
-- Nenhum status muda.
-- ============================================================================

do $$
declare v text;
begin
  if (select academy_club from public.guess_players where id = 'caico') is distinct from 'Grêmio'
     or (select academy_club from public.guess_players where id = 'nonato') is distinct from 'Bahia' then
    raise exception 'Caíco/Nonato fora do esperado — aborta.';
  end if;

  if (select academy_club from public.guess_players where id = 'araujo') is distinct from 'Porto-PE' then
    raise exception 'Araújo fora do esperado — aborta.';
  end if;

  select string_agg(e.id, ', ') into v
  from (values
    ('luvanor', 'Goiás'),
    ('fagundes', 'Goiânia'),
    ('jorge_batata', 'São Borja-RS'),
    ('niltinho', 'Goiânia'),
    ('dalton', 'Goiânia'),
    ('richard', 'Goiás'),
    ('kleber', 'Goiás'),
    ('augusto', 'Gama'),
    ('evandro', 'Goiás'),
    ('dill', 'Brasília'),
    ('nenem', 'Palmeiras'),
    ('renato_silva', 'Goiás'),
    ('alexandre', 'Valeriodoce'),
    ('cleber_goiano', 'Vila Nova'),
    ('danilo_portugal', 'Goiás'),
    ('dimba', 'Sobradinho-DF'),
    ('gil_baiano', 'Bahia'),
    ('rodrigo_calaca', 'Goiás'),
    ('simao', 'Nacional-SP'),
    ('andre_dias', 'Palestra de São Bernardo'),
    ('aldo', 'Atlético-MG'),
    ('andre_leone', 'Primavera-SP'),
    ('julio_santos', 'São Paulo'),
    ('rafael_dias', 'Goiás'),
    ('roni', 'São Paulo'),
    ('fabiano', 'Flamengo')
  ) as e(id, ac)
  left join public.guess_players g using (id)
  where g.id is null or g.academy_club is distinct from e.ac or g.data_status = 'verified';
  if v is not null then raise exception 'formador fora do esperado (ou verified): % — aborta.', v; end if;
end $$;

-- Bloco 1
update public.guess_players set academy_club = 'Internacional' where id = 'caico';
update public.guess_players set academy_club = 'Tuna Luso' where id = 'nonato';

-- Bloco 2
update public.guess_players set academy_club = null
where id in ('luvanor', 'fagundes', 'jorge_batata', 'niltinho', 'dalton', 'richard', 'kleber', 'augusto', 'evandro', 'dill', 'nenem', 'renato_silva', 'alexandre', 'cleber_goiano', 'danilo_portugal', 'dimba', 'gil_baiano', 'rodrigo_calaca', 'simao', 'andre_dias', 'aldo', 'andre_leone', 'julio_santos', 'rafael_dias', 'roni', 'fabiano');

-- Bloco 3
update public.guess_players set academy_club = null where id = 'araujo';

do $$
begin
  if (select count(*) from public.guess_players where id in ('luvanor', 'fagundes', 'jorge_batata', 'niltinho', 'dalton', 'richard', 'kleber', 'augusto', 'evandro', 'dill', 'nenem', 'renato_silva', 'alexandre', 'cleber_goiano', 'danilo_portugal', 'dimba', 'gil_baiano', 'rodrigo_calaca', 'simao', 'andre_dias', 'aldo', 'andre_leone', 'julio_santos', 'rafael_dias', 'roni', 'fabiano') and academy_club is null) <> 26 then
    raise exception 'Pós: os 26 não ficaram vazios.';
  end if;
  if (select academy_club from public.guess_players where id = 'caico') <> 'Internacional'
     or (select academy_club from public.guess_players where id = 'nonato') <> 'Tuna Luso' then
    raise exception 'Pós: Caíco/Nonato.';
  end if;
  if (select academy_club from public.guess_players where id = 'araujo') is not null
     or (select academy_club from public.guess_players where id = 'lucio') is not null
     or (select academy_club from public.guess_players where id = 'michel_santana') is not null then
    raise exception 'Pós: Araújo, Lúcio Bala e Michel Santana têm de ficar vazios.';
  end if;
  if (select count(*) from public.guess_players where data_status = 'verified') <> 79 then
    raise exception 'Pós: total de verified mudou.';
  end if;
end $$;
