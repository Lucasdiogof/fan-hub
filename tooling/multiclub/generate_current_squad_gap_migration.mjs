// Etapa F4.5 — gera (NÃO aplica) as migrations DML que corrigem as 2
// lacunas: 8 spells existentes que deveriam estar ongoing (UPDATE em
// linhas já registradas, mesma spellId/canonicalSpellKey — nunca cria
// spell novo) e 2 player_club_stats CLUB_TOTAL ausentes (INSERT +
// provenance). Consome exclusivamente current_squad_canonical_gap_fix_
// plan.json (gerado por build_current_squad_gap_fixes.mjs) — nenhuma
// lógica de evidência mora aqui, só serialização SQL.
//
// Endurecimentos da rodada de revisão (2026-09-02):
//   1) precondition EXATA por spell (não só "id existe") — detecta
//      qualquer drift entre a auditoria e o momento do push.
//   2) pós-condição valida o ELENCO INTEIRO (31 pessoas), não só os 8.
//   3) checa overlap entre TODOS os spells Goiás do elenco atual.
//   4) confirma que a proveniência (loan=true, expiração contratual) NÃO
//      foi apagada — só a linha canônica derivada foi atualizada.
//   5) confirma count(player_club_spells) antes==depois (nenhuma linha
//      nova criada, só UPDATE).
//   6) nenhuma referência a now()/current_date nas condições de negócio —
//      tudo usa os valores literais já auditados em 2026-09-02.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATIONS = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files');

const plan = JSON.parse(fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_fix_plan.json'), 'utf8'));
const GOIAS_CLUB_ID = plan.goiasClubId;

const spellFixable = plan.spellFixes.filter((f) => f.resolution === 'EXTEND_EXISTING_SPELL');
const statsFixable = plan.statsFixes.filter((f) => f.resolution === 'FIXABLE');

function sqlLiteral(v) {
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'number') return String(v);
  return `'${String(v).replace(/'/g, "''")}'`;
}
function eq(col, v) {
  return v === null || v === undefined ? `${col} is null` : `${col} = ${sqlLiteral(v)}`;
}

// ---------- migration 1: spell fixes ----------
if (spellFixable.length > 0) {
  const total = spellFixable.length;
  const idsList = spellFixable.map((f) => sqlLiteral(f.spellId)).join(', ');
  const squadPersonIdsValues = plan.currentSquadPersonIds.map((id) => `(${sqlLiteral(id)}::uuid)`).join(',\n    ');

  const preconditions = spellFixable
    .map((f) => {
      const b = f.before;
      const conds = [
        eq('person_id', b.personId),
        eq('club_id', b.clubId),
        'is_ongoing = false',
        eq('start_year', b.startYear),
        eq('start_month', b.startMonth),
        eq('start_date', b.startDate),
        eq('start_precision', b.startPrecision),
        eq('end_year', b.endYear),
        eq('end_month', b.endMonth),
        eq('end_date', b.endDate),
        eq('end_precision', b.endPrecision),
        eq('verification_status', b.verificationStatus),
      ].join('\n       and ');
      return `  -- ${f.canonicalName} (squad_members:${f.squadMemberId}) — estado exato auditado em 2026-09-02\n  if not exists (\n    select 1 from public.player_club_spells\n     where id = ${sqlLiteral(f.spellId)}\n       and ${conds}\n  ) then\n    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', ${sqlLiteral(f.spellId)}, ${sqlLiteral(f.canonicalName)};\n  end if;`;
    })
    .join('\n\n');

  const updates = spellFixable
    .map((f) => {
      const sets = [
        'is_ongoing = true',
        'end_year = null',
        'end_month = null',
        'end_date = null',
        'end_precision = null',
      ];
      if (f.after.startDate) {
        sets.push(`start_date = ${sqlLiteral(f.after.startDate)}`);
        sets.push(`start_precision = ${sqlLiteral(f.after.startPrecision)}`);
      }
      sets.push('updated_at = now()');
      return `  -- ${f.canonicalName} (squad_members:${f.squadMemberId}) — ${f.canonicalSpellKey}\n  update public.player_club_spells\n     set ${sets.join(',\n         ')}\n   where id = ${sqlLiteral(f.spellId)};`;
    })
    .join('\n\n');

  const provenanceIdsList = idsList;
  const totalProvenanceExpected = spellFixable.reduce((n, f) => n + (f.before.provenanceSourceCount || 0), 0);

  const spellSql = `-- Etapa F4.5 — corrige ${total} spells de player_club_spells que
-- estavam com is_ongoing=false e end_year/end_month futuros em relação a
-- hoje (2026-09-02). Causa raiz: squad_members.club_history authored o
-- término CONTRATUAL do empréstimo (data prevista de fim), não uma saída
-- já ocorrida — os 8 jogadores seguem no elenco atual (squad_members,
-- updated_at=2026-08-24). Nenhuma linha nova é criada: apenas UPDATE nas
-- spells já existentes, mesmo id/canonicalSpellKey preservados.
--
-- felipe_clemente também recebe um refinamento de start_precision
-- (MONTH -> DATE), usando uma data já presente na fonte cadastrada
-- (squad_members.club_history notes: "Chegou por empréstimo em
-- 21/08/2026"), nunca uma data pesquisada/nova.
--
-- A expiração contratual removida de end_* NÃO é apagada de verdade: ela
-- continua integralmente disponível em squad_members.club_history (fonte
-- bruta, intocada por esta migration) e referenciada pela proveniência já
-- registrada em player_club_spell_sources (source_record_key =
-- squad_members:<id>:club_history:<n>, evidence_type=PRIMARY,
-- relationship_type=LOAN, 1 linha por spell, verificado abaixo). O que
-- muda é só a leitura canônica derivada: "fim contratual previsto" !=
-- "fim real da passagem".
--
-- Nenhuma condição de negócio aqui usa now()/current_date — todos os
-- valores esperados são literais, auditados em 2026-09-02
-- (current_squad_canonical_gap_fix_plan.json). now() só aparece em
-- updated_at, que é housekeeping, nunca uma decisão de negócio.
--
-- Evidência completa: tooling/multiclub/current_squad_gap_evidence.json
-- Plano auditável: data_export/goias/player_reconciliation/current_squad_canonical_gap_fix_plan.json

do $$
declare
  v_total_spells_before int;
  v_total_spells_after int;
  v_provenance_before int;
  v_provenance_after int;
  v_bad_ongoing_count int;
  v_overlap_count int;
begin
  select count(*) into v_total_spells_before from public.player_club_spells;
  if v_total_spells_before <> ${plan.totalPlayerClubSpellsBeforeFix} then
    raise exception 'PRÉ-condição falhou: esperava % linhas em player_club_spells no total (contagem auditada em 2026-09-02), achou % — estado do banco divergiu do esperado, abortando', ${plan.totalPlayerClubSpellsBeforeFix}, v_total_spells_before;
  end if;

  select count(*) into v_provenance_before
    from public.player_club_spell_sources
   where spell_id in (${provenanceIdsList});
  if v_provenance_before <> ${totalProvenanceExpected} then
    raise exception 'PRÉ-condição falhou: esperava % linhas de proveniência pros % spells alvo (a evidência do vínculo precisa já existir antes de nularmos end_*), achou %', ${totalProvenanceExpected}, ${total}, v_provenance_before;
  end if;

  -- PRÉ: estado EXATO de cada um dos ${total} spells alvo, auditado em 2026-09-02.
  -- Detecta qualquer drift entre a auditoria e o momento do push — se
  -- qualquer campo divergir, aborta ANTES de tocar em qualquer linha.
${preconditions}

${updates}

  -- PÓS: nenhuma linha nova/removida em player_club_spells — só UPDATE.
  select count(*) into v_total_spells_after from public.player_club_spells;
  if v_total_spells_after <> v_total_spells_before then
    raise exception 'PÓS-condição falhou: player_club_spells tinha % linhas antes, tem % depois — deveria ser exatamente igual (só UPDATE, nunca INSERT/DELETE)', v_total_spells_before, v_total_spells_after;
  end if;

  -- PÓS: proveniência dos ${total} spells alvo continua intocada (nada apagado).
  select count(*) into v_provenance_after
    from public.player_club_spell_sources
   where spell_id in (${provenanceIdsList});
  if v_provenance_after <> v_provenance_before then
    raise exception 'PÓS-condição falhou: proveniência dos spells alvo mudou de % pra % linhas — esta migration nunca deveria tocar player_club_spell_sources', v_provenance_before, v_provenance_after;
  end if;

  -- PÓS: invariante do ELENCO ATUAL INTEIRO (31 pessoas), não só os ${total} corrigidos —
  -- exatamente 1 spell Goiás ongoing por pessoa (0 com nenhum, 0 com 2+).
  with target_people(person_id) as (
    values
    ${squadPersonIdsValues}
  ),
  ongoing_counts as (
    select tp.person_id, count(s.id) as ongoing_count
      from target_people tp
      left join public.player_club_spells s
        on s.person_id = tp.person_id
       and s.club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
       and s.is_ongoing = true
     group by tp.person_id
  )
  select count(*) into v_bad_ongoing_count from ongoing_counts where ongoing_count <> 1;
  if v_bad_ongoing_count <> 0 then
    raise exception 'PÓS-condição falhou: % pessoas do elenco atual (de 31) NÃO têm exatamente 1 spell Goiás ongoing — esperava 0', v_bad_ongoing_count;
  end if;

  -- PÓS: 0 overlap entre spells Goiás da MESMA pessoa, pro elenco inteiro
  -- (granularidade de mês — ongoing tratado como fim em 9999-12, mês
  -- ausente tratado como o mais abrangente pra cada lado: 1 no início,
  -- 12 no fim — checagem conservadora, nunca deixa passar um overlap real).
  with target_people(person_id) as (
    values
    ${squadPersonIdsValues}
  ),
  spells_bounds as (
    select s.id, s.person_id,
           (s.start_year * 12 + coalesce(s.start_month, 1)) as start_ord,
           case when s.is_ongoing then 999912
                else (s.end_year * 12 + coalesce(s.end_month, 12))
           end as end_ord
      from public.player_club_spells s
      join target_people tp on tp.person_id = s.person_id
     where s.club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
  )
  select count(*) into v_overlap_count
    from spells_bounds a
    join spells_bounds b on a.person_id = b.person_id and a.id < b.id
   where a.start_ord <= b.end_ord and b.start_ord <= a.end_ord;
  if v_overlap_count <> 0 then
    raise exception 'PÓS-condição falhou: % par(es) de spells Goiás sobrepostos pra alguma pessoa do elenco atual — esperava 0', v_overlap_count;
  end if;
end $$;
`;

  const ts1 = '20260902200000';
  fs.writeFileSync(path.join(MIGRATIONS, `${ts1}_fix_current_squad_ongoing_spells.sql`), spellSql);
  console.log('Gerado (não aplicado):', `${ts1}_fix_current_squad_ongoing_spells.sql`, `(${total} spells)`);
} else {
  console.log('Nenhum spell fixable — migration de spells NÃO gerada (regra: não criar migration vazia).');
}

// ---------- migration 2: stats fixes ----------
if (statsFixable.length > 0) {
  const blocks = statsFixable
    .map((f) => {
      const sourcesSql = f.sources
        .map((s) => {
          if (s.sourceType !== 'external_verified' && s.sourceType !== 'external_corroborating') {
            throw new Error(`sourceType desconhecido '${s.sourceType}' em ${f.squadMemberId} — não sei mapear pra source_role, abortando (nunca inventar BASELINE/role por default).`);
          }
          const role = s.sourceType === 'external_verified' ? 'PRIMARY' : 'CORROBORATING';
          return `    insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)\n    values (v_stat_id, ${sqlLiteral(s.sourceType)}, ${sqlLiteral(s.sourceRef)}, ${sqlLiteral(JSON.stringify(s))}::jsonb, ${sqlLiteral(role)}, ${sqlLiteral(f.asOfDate)}, ${sqlLiteral(s.detail)});`;
        })
        .join('\n');
      return `  -- ${f.canonicalName} (squad_members:${f.squadMemberId}, person_id=${f.personId})
  if not exists (select 1 from public.people where id = ${sqlLiteral(f.personId)}) then
    raise exception 'PRÉ-condição falhou: person_id % (%) não existe em people', ${sqlLiteral(f.personId)}, ${sqlLiteral(f.canonicalName)};
  end if;

  insert into public.player_club_stats (person_id, club_id, spell_id, stats_scope, appearances, goals, verification_status, data_mode, as_of_date, as_of_match_id)
  values (${sqlLiteral(f.personId)}, ${sqlLiteral(GOIAS_CLUB_ID)}, null, 'CLUB_TOTAL', ${f.appearances}, ${f.goals}, ${sqlLiteral(f.verificationStatus)}, ${sqlLiteral(f.dataMode)}, ${sqlLiteral(f.asOfDate)}, null)
  returning id into v_stat_id;

${sourcesSql}
`;
    })
    .join('\n');

  const personIdsList = statsFixable.map((f) => sqlLiteral(f.personId)).join(', ');
  const total = statsFixable.length;

  const statsSql = `-- Etapa F4.5 — adiciona ${total} linhas de player_club_stats (CLUB_TOTAL,
-- Goiás) para squad_members RESOLVED que ainda não tinham nenhum
-- CLUB_TOTAL: Ezequiel e Murillo Victorio, ambos ainda sem estreia pelo
-- time profissional do Goiás. appearances=0, goals=0 refletem uma
-- ausência de jogos CONFIRMADA (não "dado desconhecido") via ogol.com.br
-- (fonte externa estruturada), corroborada por uma 2ª fonte independente
-- por jogador. verification_status='PARTIAL' porque são fontes externas
-- secundárias, não confirmação oficial explícita do clube com o número —
-- nunca promovido a VERIFIED.
--
-- Semântica exata de "0": 0 aparições PROFISSIONAIS pelo Goiás (STARTED
-- ou SUBSTITUTE_USED, mesma semântica de player_match_appearances da
-- Etapa E). Nunca "0 vezes relacionado em súmula" nem "0 jogos de base" —
-- ambos os jogadores têm minutos reais registrados na base/sub-20/sub-23,
-- só nunca estrearam no time principal. Estar relacionado numa súmula
-- (UNUSED_SUBSTITUTE) NUNCA conta como appearance nesta ou em nenhuma
-- etapa futura.
--
-- as_of_date=2026-09-02 é obrigatório e literal: isto é um SNAPSHOT, não
-- um fato atemporal — se um dos dois estrear depois desta data, o "0"
-- continua historicamente correto e pode receber delta/live futuramente
-- (arquitetura baseline+delta da Etapa D/E, não implementada aqui).
--
-- Não recalcula/toca nenhuma das outras 29 linhas CLUB_TOTAL já
-- existentes.
--
-- Evidência completa: tooling/multiclub/current_squad_gap_evidence.json
-- Plano auditável: data_export/goias/player_reconciliation/current_squad_canonical_gap_fix_plan.json

do $$
declare
  v_stat_id uuid;
  v_before_count int;
  v_after_count int;
  v_after_sources_count int;
  v_after_primary_count int;
  v_duplicate_club_total int;
begin
  if not exists (select 1 from public.clubs where id = ${sqlLiteral(GOIAS_CLUB_ID)}) then
    raise exception 'PRÉ-condição falhou: club_id % (Goiás) não existe em clubs', ${sqlLiteral(GOIAS_CLUB_ID)};
  end if;

  -- PRÉ: nenhuma das ${total} pessoas alvo pode já ter uma linha CLUB_TOTAL no Goiás.
  select count(*) into v_before_count
    from public.player_club_stats
   where club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
     and stats_scope = 'CLUB_TOTAL'
     and person_id in (${personIdsList});
  if v_before_count <> 0 then
    raise exception 'PRÉ-condição falhou: esperava 0 linhas CLUB_TOTAL pré-existentes pras % pessoas alvo, achou %', ${total}, v_before_count;
  end if;

${blocks}
  -- PÓS: exatamente ${total} linhas CLUB_TOTAL agora existem pras pessoas alvo.
  select count(*) into v_after_count
    from public.player_club_stats
   where club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
     and stats_scope = 'CLUB_TOTAL'
     and person_id in (${personIdsList});
  if v_after_count <> ${total} then
    raise exception 'PÓS-condição falhou: esperava % linhas CLUB_TOTAL pras pessoas alvo, achou %', ${total}, v_after_count;
  end if;

  -- PÓS: 0 CLUB_TOTAL duplicado por pessoa (cada uma das ${total} exatamente 1).
  select count(*) into v_duplicate_club_total
    from (
      select person_id, count(*) as n
        from public.player_club_stats
       where club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
         and stats_scope = 'CLUB_TOTAL'
         and person_id in (${personIdsList})
       group by person_id
    ) x
   where x.n <> 1;
  if v_duplicate_club_total <> 0 then
    raise exception 'PÓS-condição falhou: % pessoa(s) alvo com CLUB_TOTAL duplicado (esperava exatamente 1 cada)', v_duplicate_club_total;
  end if;

  select count(*) into v_after_sources_count
    from public.player_club_stat_sources s
    join public.player_club_stats st on st.id = s.player_club_stat_id
   where st.club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
     and st.stats_scope = 'CLUB_TOTAL'
     and st.person_id in (${personIdsList});
  if v_after_sources_count <> ${statsFixable.reduce((n, f) => n + f.sources.length, 0)} then
    raise exception 'PÓS-condição falhou: esperava % linhas de provenance pras % stats novas, achou %', ${statsFixable.reduce((n, f) => n + f.sources.length, 0)}, ${total}, v_after_sources_count;
  end if;

  select count(*) into v_after_primary_count
    from public.player_club_stat_sources s
    join public.player_club_stats st on st.id = s.player_club_stat_id
   where st.club_id = ${sqlLiteral(GOIAS_CLUB_ID)}
     and st.stats_scope = 'CLUB_TOTAL'
     and st.person_id in (${personIdsList})
     and s.source_role = 'PRIMARY';
  if v_after_primary_count <> ${total} then
    raise exception 'PÓS-condição falhou: esperava exatamente 1 fonte PRIMARY por stat novo (% no total), achou %', ${total}, v_after_primary_count;
  end if;
end $$;
`;

  const ts2 = '20260902210000';
  fs.writeFileSync(path.join(MIGRATIONS, `${ts2}_add_current_squad_missing_club_total_stats.sql`), statsSql);
  console.log('Gerado (não aplicado):', `${ts2}_add_current_squad_missing_club_total_stats.sql`, `(${total} stats rows)`);
} else {
  console.log('Nenhum stats fixable — migration de stats NÃO gerada (regra: não criar migration vazia).');
}
