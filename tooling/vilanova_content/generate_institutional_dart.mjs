// Gera os dados institucionais estáticos do Vila Nova (história e linha do
// tempo) a partir do pacote de pesquisa `docs/vila_nova_data/data/*.json`.
// Só entra o que está `READY`. Rodar de novo depois de atualizar o pacote:
//   node tooling/vilanova_content/generate_institutional_dart.mjs && dart format lib/features/club/data
import { readFileSync, writeFileSync } from 'node:fs';

const root = new URL('../../', import.meta.url);
const read = (p) => JSON.parse(readFileSync(new URL(p, root), 'utf8'));
const dart = (s) =>
  "'" + s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('$', '\\$') + "'";

const SOURCE_NAMES = {
  'https://www.vilanovafc.com.br/historico': 'Vila Nova FC — Histórico',
  'https://www.vilanovafc.com.br/titulos': 'Vila Nova FC — Títulos',
  'https://www.vilanovafc.com.br/estrutura': 'Vila Nova FC — Estrutura',
  'https://www.cbf.com.br/futebol-brasileiro/noticias/copa-verde': 'CBF — Copa Verde',
  'https://portal.al.go.leg.br/noticias/124777/campanha-nas-redes-sociais-lembra-a-contribuicao-da-alego-com-os-primeiros-times-de-futebol-da-capital-goiana':
    'Assembleia Legislativa de Goiás',
};

const sections = read('docs/vila_nova_data/data/history.json').sections.filter(
  (s) => s.status === 'READY',
);
let history = `import 'package:goias_app/features/club/domain/entities/club_history_section.dart';

/// Fonte: \`docs/vila_nova_data/data/history.json\` (pacote de pesquisa, texto
/// original redigido a partir do site oficial — vilanovafc.com.br/historico e
/// /titulos — e da Assembleia Legislativa de Goiás). Só seções \`READY\`.
/// GERADO por \`tooling/vilanova_content/generate_institutional_dart.mjs\`:
/// corrigir no pacote e regenerar, nunca editar à mão.
class VilaNovaHistoryData {
  const VilaNovaHistoryData._();

  static const List<ClubHistorySection> sections = [
`;
for (const s of sections) {
  history += `    ClubHistorySection(
      period: ${dart(s.period)},
      title: ${dart(s.title)},
      paragraphs: [
${s.paragraphs.map((p) => `        ${dart(p)},`).join('\n')}
      ],
    ),
`;
}
history += '  ];\n}\n';

const events = read('docs/vila_nova_data/data/timeline.json').events.filter(
  (e) => e.status === 'READY',
);
let timeline = `import 'package:goias_app/features/club/domain/entities/club_timeline_event.dart';

/// Fonte: \`docs/vila_nova_data/data/timeline.json\` (só eventos \`READY\`), cada
/// um com a fonte original. GERADO por
/// \`tooling/vilanova_content/generate_institutional_dart.mjs\`.
class VilaNovaTimelineData {
  const VilaNovaTimelineData._();

  static const List<ClubTimelineEvent> events = [
`;
for (const e of events) {
  const name = SOURCE_NAMES[e.source_url];
  if (!name) throw new Error(`fonte sem nome mapeado: ${e.source_url}`);
  timeline += `    ClubTimelineEvent(
      year: ${e.year},
      title: ${dart(e.title)},
      description: ${dart(e.description)},
      sourceName: ${dart(name)},
      sourceUrl: ${dart(e.source_url)},
    ),
`;
}
timeline += '  ];\n}\n';

writeFileSync(new URL('lib/features/club/data/vilanova_history_data.dart', root), history);
writeFileSync(new URL('lib/features/club/data/vilanova_timeline_data.dart', root), timeline);
console.log(`história: ${sections.length} seções · linha do tempo: ${events.length} eventos`);
