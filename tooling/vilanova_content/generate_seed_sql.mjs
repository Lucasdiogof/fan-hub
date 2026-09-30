// Gera os seeds SQL de conteúdo do Vila Nova (diretoria, transparência,
// elenco e Arena) a partir do pacote de pesquisa `docs/vila_nova_data/`. Só
// entra o que está `READY`. Nunca refaz pesquisa: só adapta ao contrato que
// o app já lê (mesmo schema do Goiás/Bragantino, canonical baseline).
//
//   node tooling/vilanova_content/generate_seed_sql.mjs
//
// Adaptações pacote -> app (todas deliberadas, nenhuma inventa dado):
//   * `is_club` (pacote) -> `is_goias` (chave LEGADA que o app lê como
//     "passagem pelo clube ativo", ver career_player_repository.dart e
//     club_history_entry.dart);
//   * `position_group` do elenco é DERIVADO da posição, porque o pacote usa
//     grupos genéricos ("Defensores") e a tela agrupa por
//     `positionGroupOrder` (Zagueiros/Laterais-direitos/...);
//   * `photo_url` do elenco fica null: o pacote aponta pra uma PASTA do
//     Google Drive, não pra uma imagem;
//   * `club_history` do elenco fica vazio: está REVIEW no pacote (sem
//     períodos);
//   * quiz: EASY/MEDIUM/HARD -> códigos internos torcedor/esmeraldino/
//     fanatico (check do schema; o texto mostrado usa o gentílico do clube);
//   * escalação: o XI é REORDENADO por linha (goleiro -> ataque) e, dentro da
//     linha, da direita pra esquerda — é assim que FormationLayoutService
//     desenha o campo (ordem da lista = slot);
//   * transparência: `document_date` = last-modified do próprio PDF (o
//     pacote só tem o ano; mesmo critério do Bragantino), conferido por
//     HTTP em 2026-09-29.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const PKG = path.join(ROOT, 'docs/vila_nova_data');
const OUT = path.join(ROOT, 'supabase');
const CLUB_ID = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e';
const read = (p) => JSON.parse(fs.readFileSync(path.join(PKG, p), 'utf8'));

const s = (v) => (v === null || v === undefined ? 'null' : `'${String(v).replace(/'/g, "''")}'`);
const n = (v) => (v === null || v === undefined ? 'null' : String(Number(v)));
const j = (v) => `${s(JSON.stringify(v))}::jsonb`;
const slug = (t) =>
  t.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');

const GUARD = `do $$
begin
  if not exists (select 1 from public.clubs where id = '${CLUB_ID}' and slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;
`;

function header(title, source, extra = '') {
  return `-- ${title}
-- GERADO por \`node tooling/vilanova_content/generate_seed_sql.mjs\` a partir de
-- ${source} — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do
-- Bragantino (a trava abaixo para se não for). Idempotente.${extra ? `\n--\n${extra}` : ''}

${GUARD}
`;
}

function upsert(table, cols, rows) {
  const set = cols.filter((c) => c !== 'id').map((c) => `${c} = excluded.${c}`).join(', ');
  return `insert into public.${table} (${cols.join(', ')}) values
${rows.map((r) => `  (${r.join(', ')})`).join(',\n')}
on conflict (id) do update set ${set};
`;
}

const outputs = {};

// ------------------------------------------------------------- diretoria
{
  const L = read('data/leadership.json');
  const sections = [];
  const members = [];
  L.sections.forEach((sec, si) => {
    const sid = `vn_${slug(sec.name)}`;
    sections.push([s(sid), s(sec.name), n(si)]);
    sec.members.forEach((m, mi) => {
      // Mesma pessoa pode ter 2 cargos na mesma seção (ex.: 2º vice e
      // comunicação) -> id inclui a posição, nunca colide.
      members.push([s(`${sid}_${String(mi).padStart(2, '0')}_${slug(m.name)}`), s(sid), s(m.name), s(m.role), s(m.photo_url), n(mi)]);
    });
  });
  outputs['vilanova_club_board.sql'] =
    header(
      'Diretoria do Vila Nova (club_board_sections/club_board_members).',
      'docs/vila_nova_data/data/leadership.json',
      `-- ${members.length} pessoas em ${sections.length} seções, conforme o site oficial
-- (vilanovafc.com.br/diretoria). O pacote registra divergência com a página
-- da FGF (presidente) — seguimos o site do clube, ver conflicts no JSON.`,
    ) +
    upsert('club_board_sections', ['id', 'title', 'sort_order'], sections) +
    '\n' +
    upsert('club_board_members', ['id', 'section_id', 'name', 'role', 'photo_url', 'sort_order'], members);
}

// --------------------------------------------------------- transparência
{
  const T = read('data/transparency.json');
  // last-modified do próprio PDF (HTTP HEAD, 2026-09-29), convertido pra data
  // local de Brasília.
  const PDF_DATE = {
    'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2025-912670.pdf': '2026-04-23',
    'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2024-716240.pdf': '2025-04-30',
    'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2023-045380.pdf': '2024-05-01',
    'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2022-457690.pdf': '2023-04-28',
    'https://www.vilanovafc.com.br/files/estatuto-social-vila-nova-futebol-clube-2025-297680.pdf': '2025-11-07',
  };
  const topics = [];
  const docs = [];
  T.topics.forEach((t, ti) => {
    const tid = `vn_${slug(t.title)}`;
    topics.push([s(tid), s(t.title), n(ti)]);
    t.documents
      .filter((d) => d.status === 'READY')
      .forEach((d, di) => {
        const date = PDF_DATE[d.pdf_url];
        if (!date) throw new Error(`sem data conferida pro PDF ${d.pdf_url}`);
        docs.push([s(`${tid}_${slug(d.title)}`), s(tid), s(d.title), s(date), s(d.pdf_url), n(di)]);
      });
  });
  outputs['vilanova_club_transparency.sql'] =
    header(
      'Transparência do Vila Nova (club_transparency_topics/documents).',
      'docs/vila_nova_data/data/transparency.json',
      '-- document_date = last-modified do próprio PDF (o pacote só traz o ano).',
    ) +
    upsert('club_transparency_topics', ['id', 'title', 'sort_order'], topics) +
    '\n' +
    upsert('club_transparency_documents', ['id', 'topic_id', 'title', 'document_date', 'pdf_url', 'sort_order'], docs);
}

// ------------------------------------------------------------------ elenco
const GROUP_BY_POSITION = {
  Goleiro: 'Goleiros',
  Zagueiro: 'Zagueiros',
  'Lateral-direito': 'Laterais-direitos',
  'Lateral-esquerdo': 'Laterais-esquerdos',
  Volante: 'Volantes',
  Meia: 'Meios-campistas',
  Atacante: 'Atacantes',
  Centroavante: 'Atacantes',
  Ponta: 'Atacantes',
};
const GROUP_ORDER = ['Goleiros', 'Zagueiros', 'Laterais-direitos', 'Laterais-esquerdos', 'Volantes', 'Meios-campistas', 'Atacantes'];
{
  const players = read('data/squad_current.json').players.filter((p) => p.status === 'READY');
  const sorted = players
    .map((p) => {
      const group = GROUP_BY_POSITION[p.position];
      if (!group) throw new Error(`posição sem grupo: ${p.position} (${p.name})`);
      return { ...p, group };
    })
    .sort((a, b) => GROUP_ORDER.indexOf(a.group) - GROUP_ORDER.indexOf(b.group) || (a.shirt_number ?? 999) - (b.shirt_number ?? 999));
  const rows = sorted.map((p, i) => [
    s(p.id), s(CLUB_ID), s(p.name), s(p.full_name), n(p.shirt_number), s(p.position), s(p.group),
    s(p.birth_date), s(p.nationality), n(p.height_cm), s(p.foot), 'null', s(p.instagram_url),
    `'[]'::jsonb`, n(i), 'true',
  ]);
  outputs['vilanova_squad_members.sql'] =
    header(
      'Elenco profissional atual do Vila Nova (squad_members).',
      'docs/vila_nova_data/data/squad_current.json',
      `-- ${rows.length} atletas. photo_url null (o pacote aponta pra pasta do Drive,
-- não imagem) e club_history vazio (REVIEW no pacote) — ver cabeçalho do gerador.`,
    ) +
    upsert(
      'squad_members',
      ['id', 'club_id', 'name', 'full_name', 'shirt_number', 'position', 'position_group', 'birth_date', 'nationality', 'height_cm', 'foot', 'photo_url', 'instagram_url', 'club_history', 'sort_order', 'active'],
      rows,
    );
}

// -------------------------------------------------------------------- quiz
{
  const DIFF = { EASY: 'torcedor', MEDIUM: 'esmeraldino', HARD: 'fanatico' };
  const qs = read('arena/quiz.json').questions.filter((q) => q.status === 'READY');
  const counters = {};
  const rows = qs.map((q) => {
    const d = DIFF[q.difficulty];
    if (!d) throw new Error(`dificuldade desconhecida ${q.difficulty} em ${q.id}`);
    if (q.options.length !== 4 || !(q.correct_index >= 0 && q.correct_index < 4)) throw new Error(`pergunta malformada ${q.id}`);
    counters[d] = (counters[d] ?? 0) + 1;
    return [s(q.id), s(CLUB_ID), s(d), s(q.question), `jsonb_build_array(${q.options.map(s).join(', ')})`, n(q.correct_index), n(counters[d])];
  });
  outputs['vilanova_quiz_questions.sql'] =
    header(
      'Quiz do Vila Nova (quiz_questions).',
      'docs/vila_nova_data/arena/quiz.json',
      `-- ${rows.length} perguntas READY (${Object.entries(counters).map(([k, v]) => `${k} ${v}`).join(', ')}).
-- difficulty usa os códigos internos do schema; o texto mostrado ao jogador
-- usa o gentílico do clube ativo ("Colorado"), nunca "Esmeraldino".`,
    ) + upsert('quiz_questions', ['id', 'club_id', 'difficulty', 'question', 'options', 'correct_index', 'sort_order'], rows);
}

// --------------------------------------------------------------- escalação
const ROWS = {
  '4-4-2': [1, 4, 4, 2],
  '4-3-3': [1, 4, 3, 3],
  '3-5-2': [1, 3, 5, 2],
  '4-2-3-1': [1, 4, 2, 3, 1],
};
// Profundidade (goleiro -> ataque). Laterais ficam entre zagueiro e volante:
// numa linha de 4 atrás entram com os zagueiros; no 3-5-2 (linha de 3 atrás)
// sobram pra linha de 5 como alas — exatamente o desenho real.
const DEPTH = { GOL: 0, ZAG: 1, LD: 1.5, LE: 1.5, VOL: 2, MC: 2.3, MEI: 2.6, PD: 2.8, PE: 2.8, ATA: 4 };
const SIDE = { LD: 0, PD: 0, LE: 2, PE: 2 }; // resto = centro (1)
export function orderXi(formation, xi) {
  const rows = ROWS[formation];
  if (!rows) throw new Error(`formação não suportada: ${formation}`);
  const sorted = xi.map((p, i) => ({ p, i })).sort((a, b) => DEPTH[a.p.pos] - DEPTH[b.p.pos] || a.i - b.i);
  const out = [];
  let k = 0;
  for (const size of rows) {
    const line = sorted.slice(k, k + size);
    k += size;
    line.sort((a, b) => (SIDE[a.p.pos] ?? 1) - (SIDE[b.p.pos] ?? 1) || a.i - b.i);
    out.push(line.map((x) => x.p));
  }
  if (k !== 11) throw new Error(`formação ${formation} não soma 11`);
  return out;
}
{
  const L = read('arena/lineups.json').lineups.filter((l) => l.status === 'READY');
  const layout = [];
  const rows = L.map((l, i) => {
    if (l.xi.length !== 11) throw new Error(`${l.id}: XI com ${l.xi.length}`);
    const lines = orderXi(l.formation, l.xi);
    layout.push(`--   ${l.id} ${l.formation}: ${lines.map((ln) => ln.map((p) => p.pos).join(' ')).join(' | ')}`);
    const lineup = lines.flat().map((p) => ({ pos: p.pos, no: null, name: p.name, answer: p.answer, aliases: p.aliases ?? [] }));
    return [s(l.id), s(CLUB_ID), s(l.competition), s(l.season), s(l.phase), s(l.date), s(l.venue), s(l.home_team), s(l.away_team), n(l.home_score), n(l.away_score), s(l.formation), s(l.formation_confidence), j(lineup), n(i), 'true'];
  });
  outputs['vilanova_lineup_matches.sql'] =
    header(
      'Adivinhe a Escalação do Vila Nova (lineup_matches).',
      'docs/vila_nova_data/arena/lineups.json',
      `-- ${rows.length} partidas READY. Camisa (no) sempre null: nunca inferida.
-- XI reordenado por linha e da direita pra esquerda (FormationLayoutService):
${layout.join('\n')}`,
    ) +
    upsert('lineup_matches', ['id', 'club_id', 'competition', 'season', 'phase', 'match_date', 'venue', 'home_team', 'away_team', 'home_score', 'away_score', 'formation', 'formation_confidence', 'lineup', 'display_order', 'is_active'], rows);
}

// ----------------------------------------------------------------- carreira
{
  const toApp = (e) => ({ period: e.period, team: e.team, appearances: e.appearances ?? null, goals: e.goals ?? null, loan: e.loan ?? false, is_goias: e.is_club === true });
  const ps = read('arena/career_path.json').players.filter((p) => p.status === 'READY');
  const rows = ps.map((p, i) => {
    if (!p.club_career.some((e) => e.is_club === true)) throw new Error(`${p.id} sem passagem pelo Vila`);
    return [s(p.id), s(CLUB_ID), s(p.answer), j(p.accepted_answers ?? [p.answer]), s(p.position), j(p.club_career.map(toApp)), j((p.national_teams ?? []).map(toApp)), n(i + 1), 'true'];
  });
  outputs['vilanova_career_players.sql'] =
    header(
      'Adivinhe pela Carreira do Vila Nova (career_players).',
      'docs/vila_nova_data/arena/career_path.json',
      `-- ${rows.length} jogadores READY. \`is_goias\` é a chave LEGADA que o app lê como
-- "passagem pelo clube ativo" (aqui: pelo Vila Nova), vinda de \`is_club\` no pacote.`,
    ) + upsert('career_players', ['id', 'club_id', 'answer', 'accepted_answers', 'position', 'club_career', 'national_teams', 'sort_order', 'is_active'], rows);
}

// ------------------------------------------------------- quem vestiu o manto
{
  const cards = read('arena/guess_player.json').cards.filter((c) => c.status === 'READY');
  const rows = cards.map((c, i) => [
    s(c.id), s(CLUB_ID), s(c.name), s(c.display_name), j(c.aliases ?? []), s(c.position), n(c.shirt_number),
    s(c.academy_club), s(c.nationality_code), s(c.nationality_name), n(c.club_debut_year),
    // Sem foto local ainda (ASSET_GAP): photo_key null, o jogo cai no placeholder.
    'null',
    s((c.missing_fields ?? []).length ? 'incomplete' : 'verified'), n(i + 1), 'true',
  ]);
  outputs['vilanova_guess_players.sql'] =
    header(
      'Quem Vestiu o Manto do Vila Nova (guess_players).',
      'docs/vila_nova_data/arena/guess_player.json',
      `-- ${rows.length} cartas READY. data_status = verified só quando o pacote não lista
-- campo faltando; senão incomplete. photo_key null até existirem as fotos.`,
    ) + upsert('guess_players', ['id', 'club_id', 'name', 'display_name', 'aliases', 'position', 'shirt_number', 'academy_club', 'nationality_code', 'nationality_name', 'club_debut_year', 'photo_key', 'data_status', 'sort_order', 'is_active'], rows);
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  for (const [file, sql] of Object.entries(outputs)) {
    fs.writeFileSync(path.join(OUT, file), sql);
    console.log(`${file}: ${(sql.match(/^  \(/gm) ?? []).length} linhas`);
  }
}
