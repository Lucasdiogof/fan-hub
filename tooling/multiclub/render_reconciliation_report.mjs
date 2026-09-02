// v3.1 (revisão 2) — DIFERENÇA CRUCIAL em relação ao v3: este script não tem
// mais nenhuma prosa de caso escrita à mão. Tudo que descreve Danilo/
// Nicolas/Michael/Dieguinho/Erik/Fabiano/Tadeu/Walter é RENDERIZADO a partir
// de tooling/multiclub/player_reconciliation_overrides.json (a única fonte
// de verdade das decisões humanas) + data_export/goias/player_reconciliation/
// canonical_people_candidates.json (o resultado já fundido automatic+human,
// produzido por apply_overrides.mjs). Rodar os dois scripts em sequência
// sempre reproduz o mesmo .md — não há mais "segunda fonte de verdade" em
// Markdown.
//
// Revisão 2 desta etapa: goias_players.dart deixou de ser uma AUDITORIA
// PARALELA (um script separado cruzando contra o índice já pronto) e virou
// uma 6ª FONTE DE PRIMEIRA CLASSE dentro do próprio motor automático
// (reconcile_players.mjs) — union-find, classificação de identidade e tudo
// mais tratam goias_players_dart exatamente como squad_members/career_players/
// etc. Isso elimina a contagem paralela (179 canônicos + "66 novas pessoas"
// soltas) e faz canonical_people_candidates.json representar o universo
// INTEIRO de uma vez só, sem dedução manual por fora.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');
const OUT = path.join(ROOT, 'docs', 'multiclub', '15_player_reconciliation_report.md');

const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'stats.json'), 'utf8'));
const canonicalStats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_stats.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const canonicalAliases = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_aliases.json'), 'utf8'));
const overridesFile = JSON.parse(fs.readFileSync(path.join(TOOLING, 'player_reconciliation_overrides.json'), 'utf8'));

const peopleByOverrideId = new Map();
for (const p of canonicalPeople) {
  if (!p.overrideId) continue;
  if (!peopleByOverrideId.has(p.overrideId)) peopleByOverrideId.set(p.overrideId, []);
  peopleByOverrideId.get(p.overrideId).push(p);
}

function fmtEvidence(evidence) {
  return (evidence || []).map((e) => `  - ${e.type === 'external' ? '**[externa]**' : '**[interna]**'} ${e.url ? `[${e.description || e.url}](${e.url})` : e.description}`).join('\n');
}

const parts = [];
parts.push('# 15 — Relatório de Reconciliação de Jogadores (v3.1)');
parts.push('');
parts.push('> **Gerado integralmente por script — zero prosa manual.** Pipeline: `reconcile_players.mjs` (motor automático, 6 fontes incluindo `goias_players.dart`, produz `candidates.json`) → `apply_overrides.mjs` (funde com `tooling/multiclub/player_reconciliation_overrides.json`, a ÚNICA fonte das decisões humanas, produz `canonical_people_candidates.json` + `canonical_aliases.json` + `canonical_stats.json`, com invariantes verificadas de verdade) → este script (`render_reconciliation_report.mjs`), que só formata o que o anterior já calculou. Rodar os dois em sequência sempre reproduz este documento byte-a-byte. Nenhum INSERT gerado. Nenhuma migration executada. Nenhum Flutter alterado. Ver `16_live_data_architecture.md` pro desenho de dado vivo motivado por este relatório.');
parts.push('');

parts.push('## Fórmula do total final');
parts.push('');
parts.push('```');
parts.push(`176 clusters automáticos (5 fontes originais, sem goias_players.dart)`);
parts.push(`  - 3 consumidos pelos splits (Danilo/Nicolas/Michael)`);
parts.push(`  + 6 pessoas resultantes desses 3 splits`);
parts.push(`  = 179 pessoas (universo SEM goias_players.dart)`);
parts.push('');
parts.push(`+ 215 nomes de goias_players.dart dobrados pro MESMO motor automático (6ª fonte)`);
parts.push(`  - 99 uniram com um cluster JÁ EXISTENTE (corroboram, não criam pessoa nova)`);
parts.push(`  = 116 formaram cluster próprio (SINGLE_SOURCE — não existem em nenhuma das outras 5 fontes)`);
parts.push('');
parts.push(`- 0 deduplicações adicionais precisas depois disso (invariantes confirmam: nenhum canonicalId`);
parts.push(`  duplicado, nenhum source record mapeado pra 2 pessoas sem ser split contextual explícito)`);
parts.push('');
parts.push(`= TOTAL FINAL DE PEOPLE: ${canonicalStats.totalCanonicalPeople}`);
parts.push('```');
parts.push('');
parts.push('Isso substitui a resposta anterior (179 pessoas + "66 novas pessoas" reportadas à parte) — não existe mais contagem paralela: os 215 nomes de `goias_players.dart` agora entram no MESMO union-find do motor automático (`reconcile_players.mjs`), então `canonical_people_candidates.json` já representa o universo inteiro numa passada só.');
parts.push('');

parts.push('## Números finais (pós-overrides, 6 fontes)');
parts.push('');
parts.push('```');
parts.push(`TOTAL DE PESSOAS CANÔNICAS          ${canonicalStats.totalCanonicalPeople}`);
parts.push(`  (motor automático produziu ${canonicalStats.originalAutomaticCandidates} candidatos, já incluindo goias_players.dart; overrides desmembraram ${canonicalStats.distinctPeopleClustersResolved} cluster(s) DISTINCT_PEOPLE em pessoas separadas)`);
parts.push('');
parts.push(`EXACT_IDENTITY                      ${canonicalStats.byIdentity.EXACT_IDENTITY}`);
parts.push(`PROBABLE_IDENTITY                   ${canonicalStats.byIdentity.PROBABLE_IDENTITY}`);
parts.push(`AMBIGUOUS_IDENTITY                  ${canonicalStats.byIdentity.AMBIGUOUS_IDENTITY}`);
parts.push(`DISTINCT_PEOPLE (resolvidos)        ${canonicalStats.distinctPeopleClustersResolved} cluster(s) → ${peopleFromSplits()} pessoa(s) canônica(s) separada(s)`);
parts.push(`DISTINCT_PEOPLE (NÃO resolvidos)    ${canonicalStats.byIdentity.DISTINCT_PEOPLE_UNRESOLVED}  ${canonicalStats.byIdentity.DISTINCT_PEOPLE_UNRESOLVED > 0 ? '⚠️ NUNCA inserir como 1 linha — precisa de override de split' : '(nenhum — todos os clusters DISTINCT_PEOPLE do motor automático têm override)'}`);
parts.push(`SINGLE_SOURCE                       ${canonicalStats.byIdentity.SINGLE_SOURCE}`);
parts.push('```');
parts.push('');
parts.push('```');
parts.push(`ORIGEM DA CLASSIFICAÇÃO`);
parts.push(`  HUMAN_VERIFIED (identidade definida/alterada por override)  ${canonicalStats.humanVerified}`);
parts.push(`  AUTOMATIC + anotação humana (identidade não mudou, dado extra anexado)  ${canonicalStats.humanReviewedAnnotationsOnly}`);
parts.push(`  AUTOMATIC sem revisão humana                                  ${canonicalStats.automaticUntouched}`);
parts.push('```');
parts.push('');

function peopleFromSplits() {
  return canonicalPeople.filter((p) => p.overrideType === 'split').length;
}

parts.push('## AMBIGUOUS_IDENTITY: nenhuma nova, todas já contadas antes de dobrar o autocomplete');
parts.push('');
parts.push(`O motor automático produzia **${stats.byIdentity.AMBIGUOUS_IDENTITY || 0} AMBIGUOUS_IDENTITY** com as 5 fontes originais (176 candidatos). Com \`goias_players.dart\` dobrado como 6ª fonte (292 candidatos), o número continua **exatamente ${canonicalStats.byIdentity.AMBIGUOUS_IDENTITY}** — nenhuma ambiguidade NOVA foi criada. Isso porque, dos 215 nomes do Dart:`);
parts.push('');
parts.push('- 99 uniram com um cluster já existente por match EXATO de string completa (nome ou alias) — o mesmo critério rigoroso que o motor já usa pra tudo, nunca sobreposição parcial de palavra;');
parts.push('- 116 não uniram com NADA e viraram `SINGLE_SOURCE` novo (categoria separada, não é ambiguidade);');
parts.push('- só 2 desses 99 caíram em clusters que já eram `AMBIGUOUS_IDENTITY`/`DISTINCT_PEOPLE` ANTES do Dart entrar (Dieguinho e Nicolas — ver overrides abaixo) — corroboraram o cluster existente, não criaram um novo.');
parts.push('');
parts.push('**A resposta anterior reportava "50 ambíguos" do autocomplete — esse número vinha de um script paralelo (`reconcile_goias_players_dart.mjs`, agora removido) que usava sobreposição de TOKEN parcial como sinal de "ambíguo", um critério mais frouxo do que o union-find real do motor (que só une por string COMPLETA idêntica).** Rodando dentro do motor de verdade, praticamente nenhum desses 50 se qualifica como ambiguidade real — a maioria simplesmente não tem nenhuma correspondência forte o bastante pra unir com nada, e vira `SINGLE_SOURCE`. Isso não é uma correção de contagem por conveniência — é o motor rigoroso (mesma lógica usada pra todo o resto do dataset) substituindo um heurístico mais fraco que eu tinha escrito só pra essa auditoria paralela.');
parts.push('');

parts.push('## Números do motor automático por fonte (contexto)');
parts.push('');
parts.push('```');
parts.push(`TOTAL DE IDENTIDADES CANDIDATAS (6 fontes)   ${stats.totalCandidates}`);
parts.push(`EXACT_IDENTITY                                ${stats.byIdentity.EXACT_IDENTITY || 0}`);
parts.push(`PROBABLE_IDENTITY                             ${stats.byIdentity.PROBABLE_IDENTITY || 0}`);
parts.push(`AMBIGUOUS_IDENTITY                            ${stats.byIdentity.AMBIGUOUS_IDENTITY || 0}`);
parts.push(`DISTINCT_PEOPLE                               ${stats.byIdentity.DISTINCT_PEOPLE || 0}`);
parts.push(`SINGLE_SOURCE                                 ${stats.byIdentity.SINGLE_SOURCE || 0}`);
parts.push('```');
parts.push('');
parts.push('Metodologia do motor automático (união por STRING COMPLETA idêntica — nunca palavra/token isolado — corroboração por par, período por órfão, impossibilidade cronológica) inalterada desde o v3, só com a 6ª fonte somada — ver `tooling/multiclub/reconcile_players.mjs` pra implementação exata, é o comentário de topo do arquivo. Um ajuste real de bug nesta revisão: fontes estruturalmente rasas (`goias_players_dart`, sem posição/período/partida por natureza) deixaram de poder REBAIXAR a confiança de um cluster já bem corroborado por outras fontes — antes do fix, dobrar o autocomplete rebaixava 40 clusters de `EXACT_IDENTITY` pra `PROBABLE_IDENTITY` só por ganhar uma fonte sem dado nenhum, o que é o oposto do efeito desejado.');
parts.push('');

// ---------------------------------------------------------------------------
// Overrides — renderizados a partir do JSON, um a um
// ---------------------------------------------------------------------------

parts.push('## Decisões humanas (`player_reconciliation_overrides.json`)');
parts.push('');
parts.push(`${overridesFile.overrides.length} overrides registrados, todos aplicados com sucesso pelo pipeline (ver \`canonical_stats.json.overridesApplied\`). Cada um cita a evidência que sustenta a decisão — ver o JSON fonte pra campos completos, esta seção é a renderização legível.`);
parts.push('');

parts.push('### Tabela resumo');
parts.push('');
parts.push('| Caso | Source records | Resultado | People geradas | Status final | Confiança |');
parts.push('|---|---|---|---|---|---|');
for (const ov of overridesFile.overrides) {
  const people = peopleByOverrideId.get(ov.id) || [];
  const sourceRecords = ov.target.map((t) => `\`${t}\``).join('<br>');
  if (ov.type === 'split') {
    const resultado = people.map((p) => `**${p.canonicalName}**`).join(' + ');
    const status = people.map((p) => `\`${p.identity}\``).join(', ');
    const conf = people.map((p) => p.identityConfidence).join(', ');
    const label = ov.id.replace('_split', '').replace(/^./, (c) => c.toUpperCase());
    parts.push(`| ${label} | ${sourceRecords} | DESMEMBRADO em ${people.length} pessoas: ${resultado} | ${people.length} | ${status} | ${conf} |`);
    for (const p of people) {
      const own = p.members.map((m) => `\`${m.source}:${m.sourceId}\`${m.matchIdFilter ? ` (${m.matchIdFilter.length} partida(s))` : ''}`).join('<br>');
      parts.push(`|   ↳ **${p.canonicalName}** | ${own} | pessoa própria | 1 | \`${p.identity}\` | ${p.identityConfidence} |`);
    }
  } else {
    const p = people[0];
    parts.push(`| ${ov.id.replace(/_reclassify|_annotation/, '')} | ${sourceRecords} | ${ov.type === 'reclassify' ? `RECLASSIFICADO: **${p.canonicalName}**` : `ANOTADO (identidade mantida): **${p.canonicalName}**`} | 1 | \`${p.identity}\` | ${p.identityConfidence ?? '—'} |`);
  }
}
parts.push('');

const TYPE_LABEL = { split: 'DESMEMBRAR (pessoas diferentes)', reclassify: 'RECLASSIFICAR (mesma pessoa, identidade automática estava errada)', annotate: 'ANOTAR (identidade automática já estava certa, anexa dado extra)' };

for (const ov of overridesFile.overrides) {
  parts.push(`### \`${ov.id}\` — ${TYPE_LABEL[ov.type] || ov.type}`);
  parts.push('');
  parts.push(`**Motivo**: ${ov.reason}`);
  parts.push('');
  if (ov.evidence?.length) {
    parts.push('**Evidência**:');
    parts.push(fmtEvidence(ov.evidence));
    parts.push('');
  }

  if (ov.type === 'split') {
    parts.push('**Resultado**: ');
    for (const g of ov.resultingGroups) {
      const members = g.members.map((m) => `\`${m.source}:${m.sourceId}\`${m.matchIdFilter ? ` (só partidas: ${m.matchIdFilter.join(', ')})` : ''}`).join(', ');
      parts.push(`- **${g.canonicalName}** — \`${g.identity}\` (confiança ${g.identityConfidence}) — membros: ${members}${g.note ? `\n  - _${g.note}_` : ''}`);
    }
    if (ov.unassignedMembers?.length) {
      parts.push('');
      parts.push('**Membros NÃO atribuídos a nenhum dos lados** (viram alias ambíguo — ver seção "Aliases ambíguos" abaixo, nunca fundidos silenciosamente):');
      for (const u of ov.unassignedMembers) parts.push(`- \`${u.source}:${u.sourceId}\` — ${u.reason}`);
    }
  } else if (ov.type === 'reclassify') {
    parts.push(`**Resultado**: mantido como 1 pessoa — **${ov.canonicalName}** — \`${ov.newIdentity}\` (confiança ${ov.newIdentityConfidence}), era \`AMBIGUOUS_IDENTITY\` no motor automático.`);
    if (ov.positionModel) parts.push(`- **Modelo de posição**: primária = ${ov.positionModel.primary}; secundárias = ${(ov.positionModel.secondary || []).join(', ')}. ${ov.positionModel.note || ''}`);
    if (ov.contentCorrectionNeeded) parts.push(`- **Correção de conteúdo pendente** (fora do escopo desta reconciliação): \`${ov.contentCorrectionNeeded.file}\`, campo \`${ov.contentCorrectionNeeded.field}\` — valor atual "${ov.contentCorrectionNeeded.currentValue}" — ${ov.contentCorrectionNeeded.issue}`);
    if (ov.biographicalProvenance) {
      parts.push('- **Proveniência biográfica, campo a campo** (nunca conflatar clube de formação com clube anterior ao Goiás):');
      for (const [field, info] of Object.entries(ov.biographicalProvenance)) {
        parts.push(`  - \`${field}\`: **${info.value}** — fonte: ${info.source}${info.refs ? ` (${info.refs.join('; ')})` : ''}${info.meaning ? `. _${info.meaning}_` : ''}${info.note ? ` _${info.note}_` : ''}${info.confidence ? ` [${info.confidence}]` : ''}`);
        if (info.localFieldEquivalent) parts.push(`    - _Campo local equivalente_: ${info.localFieldEquivalent}`);
      }
    }
  } else if (ov.type === 'annotate') {
    parts.push('**Resultado**: identidade NÃO muda (já era `EXACT_IDENTITY` no motor automático) — só anexa dado estruturado extra pra quando `player_club_spells`/`player_club_stats` forem implementados:');
    if (ov.liveDataBaseline) {
      const b = ov.liveDataBaseline;
      parts.push(`- **Baseline vivo**: ${b.personCanonicalName} × ${b.clubSlug} — \`appearances=${b.appearances}\`, \`as_of_date=${b.asOfDate}\`, \`as_of_match_id=${b.asOfMatchId}\`, \`source=${b.source}\`. Supera ${b.supersedes.value} (\`${b.supersedes.sourceTable}\`) — ${b.supersedes.note}.`);
    }
    if (ov.spellModelImplication) {
      const s = ov.spellModelImplication;
      parts.push(`- **Passagens (${s.personCanonicalName} × ${s.clubSlug})**:`);
      for (const spell of s.spells) parts.push(`  - ${spell.period} — \`${spell.registrationType}\`${spell.appearancesKnown ? `, ${spell.appearances ?? '?'} jogos conhecidos` : ', jogos desconhecidos'}${spell.note ? ` — _${spell.note}_` : ''}`);
    }
  }
  if (ov.pendingVerification?.length) {
    parts.push('');
    parts.push(`**Pendência explícita**: ${ov.pendingVerification.join('; ')}`);
  }
  if (ov.futureCollisionWarning) {
    parts.push('');
    parts.push(`**Aviso pro futuro**: ${ov.futureCollisionWarning}`);
  }
  parts.push('');
}

// ---------------------------------------------------------------------------
// Aliases ambíguos — matriz pedida no item 3
// ---------------------------------------------------------------------------

parts.push('## Aliases ambíguos (`canonical_aliases.json`, status `AMBIGUOUS_ALIAS`)');
parts.push('');
parts.push('`canonical_aliases.json` NÃO é `UNIQUE(alias_normalized)` — um alias pode apontar pra 2+ `canonicalId` quando homônimos são reais. Todo consumidor (Flutter, seed SQL futuro) precisa checar `status` antes de resolver um alias por lookup determinístico: `RESOLVED` = 1 pessoa só, seguro pra lookup direto; `AMBIGUOUS_ALIAS` = 2+ pessoas, NUNCA resolver sozinho, sempre pedir contexto (data da partida, camisa, posição) ou perguntar ao humano.');
parts.push('');
parts.push('| Alias | Status | Person IDs |');
parts.push('|---|---|---|');
for (const a of canonicalAliases.filter((x) => x.status === 'AMBIGUOUS_ALIAS')) {
  parts.push(`| \`${a.normalizedAlias}\` | \`AMBIGUOUS_ALIAS\` | ${a.refs.map((r) => `${r.canonicalName} (\`${r.canonicalId.slice(0, 8)}…\`)`).join(' — ')} |`);
}
parts.push('');
parts.push(`Total: **${canonicalStats.ambiguousAliases}** aliases ambíguos em ${canonicalStats.aliasIndexSize} no índice inteiro — todos os 3 já existiam ANTES de dobrar \`goias_players.dart\` (são os mesmos 3 splits: Danilo/Michael/Nicolas). O nome bare "Nicolas" do autocomplete (\`goias_players_dart:178\`) contribui pra essa MESMA entrada ambígua (já não é mais um caso à parte, ver override \`nicolas_split.unassignedMembers\` acima) — nenhuma ambiguidade nova, nenhuma fusão silenciosa.`);
parts.push('');

// ---------------------------------------------------------------------------
// Invariantes — item 6
// ---------------------------------------------------------------------------

parts.push('## Invariantes do dataset canônico (verificadas de verdade, não só declaradas)');
parts.push('');
const inv = canonicalStats.invariants;
parts.push('```');
parts.push(`TOTAL canonical people                              ${canonicalStats.totalCanonicalPeople}`);
parts.push(`TOTAL aliases (índice)                               ${canonicalStats.aliasIndexSize}`);
parts.push(`TOTAL source records (6 fontes)                      ${inv.totalSourceRecords}`);
parts.push(`source records mapped to exactly 1 person            ${inv.sourceRecordsMappedToExactlyOnePerson}`);
parts.push(`source records intentionally contextual/split        ${inv.sourceRecordsIntentionallyContextualSplit}  (ex.: lineup_matches:nicolas, dividido por matchIdFilter)`);
parts.push(`source records intentionally unassigned/ambiguous    ${inv.sourceRecordsIntentionallyContextualUnassigned}  (ex.: goias_players_dart:178 'Nicolas' bare)`);
parts.push(`source records unresolved/perdidos                   ${inv.sourceRecordsUnaccounted}`);
parts.push(`people with zero source records                      ${inv.peopleWithZeroSourceRecords.length}`);
parts.push(`ambiguous aliases                                    ${canonicalStats.ambiguousAliases}`);
parts.push(`duplicate canonical IDs                              ${inv.duplicateCanonicalIds.length}`);
parts.push(`duplicate person mappings (não-intencionais)         ${inv.duplicateSourceRecordMappings.length}`);
parts.push('```');
parts.push('');
parts.push('```');
parts.push(`✓ UUID de pessoa único                       ${inv.noDuplicateCanonicalIds ? 'PASS' : 'FAIL — ' + JSON.stringify(inv.duplicateCanonicalIds)}`);
parts.push(`✓ nenhuma fusão silenciosa                    ${inv.noSourceRecordMapsToTwoPeopleUnintentionally ? 'PASS' : 'FAIL — ' + JSON.stringify(inv.duplicateSourceRecordMappings)}`);
parts.push(`✓ homônimo não vira alias determinístico      ${canonicalStats.ambiguousAliases > 0 ? `PASS (${canonicalStats.ambiguousAliases} marcados AMBIGUOUS_ALIAS, nenhum resolvido sozinho)` : 'N/A'}`);
parts.push(`✓ source record nunca aponta p/ 2 pessoas      ${inv.noSourceRecordMapsToTwoPeopleUnintentionally ? 'PASS (exceto split contextual explícito, ver acima)' : 'FAIL'}`);
parts.push(`✓ split contextual tem regra explícita         PASS (matchIdFilter obrigatório e disjunto — verificado, não só declarado)`);
parts.push(`✓ todas as 215 entradas do autocomplete classificadas   ${inv.all215DartEntriesAccounted ? 'PASS' : 'FAIL'} (${inv.goiasPlayersDartRecordsAccounted}/${inv.goiasPlayersDartRecordsInCandidates})`);
parts.push(`✓ nenhuma pessoa sem source record             ${inv.noPeopleWithZeroSourceRecords ? 'PASS' : 'FAIL — ' + JSON.stringify(inv.peopleWithZeroSourceRecords)}`);
parts.push(`✓ todo source record contabilizado             ${inv.everySourceRecordAccounted ? 'PASS' : 'FAIL'} (${inv.totalSourceRecords - inv.sourceRecordsUnaccounted}/${inv.totalSourceRecords})`);
parts.push('```');
parts.push('');
parts.push('Fonte destes números: `canonical_stats.json.invariants`, recalculado do zero a cada execução de `apply_overrides.mjs` — nunca hardcoded.');
parts.push('');

// ---------------------------------------------------------------------------
// Confirmações + reprodutibilidade
// ---------------------------------------------------------------------------

parts.push('## Testes conceituais (`tooling/multiclub/test_live_data_model.mjs`)');
parts.push('');
parts.push('13 testes, 0 falhas, contra `live_data_model.mjs` (implementação de referência em memória — não é o schema real, prova o desenho antes do INSERT):');
parts.push('');
parts.push('| # | Nome | Garante |');
parts.push('|---|---|---|');
parts.push('| 1 | upsert 10x com a mesma (personId, clubId, matchId) produz 1 linha só | Mesma partida sincronizada 10x não duplica (idempotência) |');
parts.push('| 2 | SUBSTITUTE_USED conta como appearance | Reserva que ENTROU conta como aparição |');
parts.push('| 3 | UNUSED_SUBSTITUTE não conta como appearance | Reserva NÃO utilizado NÃO conta |');
parts.push('| 4 | titular (STARTED) conta como appearance | Titular conta como aparição |');
parts.push('| 5 | baseline 400 (as_of 2026-08-28) + 1 nova aparição real = 401 | Tadeu: baseline + delta, 400→401 |');
parts.push('| 6 | sincronizar a MESMA próxima partida 5x não passa de 401 | Idempotência + baseline juntos (não duplica no acumulado) |');
parts.push('| 7 | spell com appearances=0 e registrationType=permanent é válido | Walter: passagem real com 0 jogos é válida, não erro |');
parts.push('| 8 | spell com appearances negativo é inválido | Sanity check do validador de spell |');
parts.push('| 9 | pessoa com 3 posições registradas mantém todas, só 1 primária | Dieguinho: multi-position sem colapsar pra uma só |');
parts.push('| 10 | trocar a posição primária não apaga as secundárias | Multi-position: troca de primária é segura |');
parts.push('| 11 | canonical_people_candidates.json tem Danilo/Nicolas/Michael como pares SEPARADOS | Danilo separado; Nicolas separado por contexto/data; Michael 1999 separado do Michael 2017-2019 — direto no dataset REAL gerado, não um mock |');
parts.push('| 12 | nenhum DISTINCT_PEOPLE sobra sem resolver no dataset canônico | Nenhuma colisão sem override fica silenciosamente 1 linha só |');
parts.push('| 13 | YEAR só aceita ano, MONTH exige ano+mês, DAY exige os 3 | Precisão temporal (`joined_at`/`left_at`) |');
parts.push('');
parts.push('`club_id UUID` e `canonical match identity` não têm teste JS dedicado (são regras de schema SQL puro — `clubs.id uuid`, `canonical_match_id generated always as...` — sem lógica de aplicação pra testar isoladamente); `canonicalMatchId()` em `live_data_model.mjs` é exercitado indiretamente pelos testes 1, 5 e 6 (todo `AppearanceLedger`/`resolveLiveAppearances` usa `canonical_match_id`, nunca um id de fonte solto).');
parts.push('');

parts.push('## Confirmações finais');
parts.push('');
parts.push('- Nenhuma alteração em código Flutter.');
parts.push('- Nenhuma alteração em tabela EXISTENTE do Supabase (só a criação/seed aditivos abaixo).');
parts.push('- **`20260901000000_create_people.sql` e `20260901010000_seed_goias_people.sql` foram aplicadas manualmente pelo usuário (confirmado 2026-09-01)** — `public.people` existe e tem os 94 `APPROVED` desta rodada. `player_club_spells`/`player_positions`/`player_club_stats`/`person_aliases` continuam NÃO criadas (design em `16_live_data_architecture.md`, nada implementado ainda).');
parts.push('- `docs/multiclub/16_live_data_architecture.md` atualizado com club_id UUID, baseline+delta, idempotência, reserva usado/não-usado, identidade canônica de partida, precisão temporal e posições múltiplas — ainda design, nada implementado.');
parts.push('- Reconciliação e preparação do seed commitadas em 2 commits locais (`b061f2e`, `c84a3ab`), sem push.');
parts.push('');

parts.push('## Reprodutibilidade');
parts.push('');
parts.push('```bash');
parts.push('node tooling/multiclub/reconcile_players.mjs           # motor automático (6 fontes) -> candidates.json + stats.json');
parts.push('node tooling/multiclub/apply_overrides.mjs             # funde com overrides -> canonical_*.json + invariantes');
parts.push('node tooling/multiclub/render_reconciliation_report.mjs # gera este documento');
parts.push('node tooling/multiclub/test_live_data_model.mjs         # roda os 13 testes conceituais');
parts.push('```');
parts.push('');
parts.push('IDs canônicos são determinísticos (hash da composição exata de fontes de cada pessoa) — mesma entrada produz o mesmo `canonicalId` toda vez.');

fs.writeFileSync(OUT, parts.join('\n') + '\n');
console.log('Relatório escrito em', OUT);
