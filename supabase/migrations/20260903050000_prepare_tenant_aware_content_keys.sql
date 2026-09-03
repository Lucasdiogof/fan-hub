-- ============================================================================
-- M2.2B-A — Additive tenant-aware BRIDGE constraints (CONTENT / person_id).
-- NÃO aplicada ainda (arquivo local, aguardando revisão). 0 db push.
--
-- Só ADITIVO: cria UNIQUE INDEX composto (club_id, person_id) AO LADO da
-- UNIQUE(person_id) legada. Nada é removido aqui — a UNIQUE(person_id)
-- global continua (por isso um 2º clube ainda NÃO pode repetir a mesma
-- pessoa; bridge != enforcement). O drop da legada é M2.2B-B, depois do M3.4.
--
-- Backward-compatible: como a UNIQUE(person_id) legada já garante que
-- person_id é único, o superset (club_id, person_id) é trivialmente único —
-- este índice nunca falha sobre os dados atuais (validado ao vivo 2026-09-02:
-- 0 person_id duplicado em career/guess/squad). SEM predicate parcial: um
-- UNIQUE normal do PostgreSQL já trata NULLs como distintos, então
-- (club_id, person_id) já permite múltiplas linhas com person_id NULL no
-- mesmo clube (career=9, guess=81 NULLs) E a mesma pessoa em clubes
-- diferentes — sem precisar de WHERE. Índice COMPLETO (não-parcial) é melhor
-- para futura inferência de ON CONFLICT (club_id, person_id) e promoção a
-- constraint em M2.2B-B. Nunca usar NULLS NOT DISTINCT (mudaria a semântica).
--
-- Lock: tabelas minúsculas (career=30, guess=173, squad=31) — CREATE INDEX
-- é instantâneo; sem CONCURRENTLY (roda dentro da transação da migration).
-- ============================================================================

do $$
begin
  if (select count(*) from public.clubs) <> 1 then
    raise exception 'M2.2B-A abortado: esperava exatamente 1 clube (janela single-club), achou %', (select count(*) from public.clubs);
  end if;
  if not exists (select 1 from public.clubs where id = '4c16340d-300c-5ab2-903f-17519db9b146') then
    raise exception 'M2.2B-A abortado: clube Goiás canônico ausente';
  end if;
end $$;

create unique index career_players_club_person_uidx
  on public.career_players (club_id, person_id);

create unique index guess_players_club_person_uidx
  on public.guess_players (club_id, person_id);

create unique index squad_members_club_person_uidx
  on public.squad_members (club_id, person_id);

-- NOTA: a PK editorial (id) de career_players/guess_players/squad_members/
-- lineup_matches/quiz_questions NÃO ganha bridge aqui — o swap pra
-- PRIMARY KEY (club_id, id) em M2.2B-B constrói o próprio índice, e nenhum
-- app/RPC/FK depende da PK(id) como conflict target (conteúdo é read-only no
-- app; RPCs fazem `where id=... and club_id=...`). Bridge redundante evitado.
