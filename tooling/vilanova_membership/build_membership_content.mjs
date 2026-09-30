// Gera o conteúdo do Sócio Tigrão (Vila Nova) a partir da API pública do
// provedor de adesão (Ingressos SA, a mesma fonte dos planos no F7):
//
//   GET https://vilanova.ingressosa.com.br/public/api/v1/socio/faq
//   GET https://vilanova.ingressosa.com.br/public/api/v1/socio/terms-of-use
//   GET https://vilanova.ingressosa.com.br/public/api/v1/socio/general-configuration-portal
//
// Saídas (não editar à mão — corrigir aqui e regenerar + `dart format`):
//   - docs/vila_nova_data/sources/socio_tigrao/*.json  (resposta crua, evidência)
//   - lib/assets/content/vilanova_membership_faq.json  (formato do FAQ do app)
//   - lib/features/membership/data/vilanova_regulation_content.dart
//
// Uso:  node tooling/vilanova_membership/build_membership_content.mjs [--offline]
//   --offline  relê os JSON já salvos em sources/ em vez de chamar a API.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const API = 'https://vilanova.ingressosa.com.br/public/api/v1/socio';
const SOURCES = path.join(ROOT, 'docs/vila_nova_data/sources/socio_tigrao');
const FAQ_OUT = path.join(ROOT, 'lib/assets/content/vilanova_membership_faq.json');
const REG_OUT = path.join(ROOT, 'lib/features/membership/data/vilanova_regulation_content.dart');
const offline = process.argv.includes('--offline');

// A configuração geral do portal traz muito mais que o WhatsApp (inclusive
// chave pública do gateway de pagamento) — guarda-se só o que é usado.
const KEEP_ONLY = {
  'general-configuration-portal': (json) => {
    const c = Array.isArray(json.content) ? json.content[0] : json;
    return { content: [{ whatsappLink: c.whatsappLink }] };
  },
};

async function load(name) {
  const file = path.join(SOURCES, `${name}.json`);
  if (offline) return JSON.parse(fs.readFileSync(file, 'utf8'));
  const res = await fetch(`${API}/${name}`);
  if (!res.ok) throw new Error(`${name}: HTTP ${res.status}`);
  const raw = await res.json();
  const json = KEEP_ONLY[name] ? KEEP_ONLY[name](raw) : raw;
  fs.mkdirSync(SOURCES, { recursive: true });
  fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n');
  return json;
}

function decode(text) {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&ordm;/g, 'º')
    .replace(/&ordf;/g, 'ª');
}

function paragraphsOf(html) {
  return html
    .split(/<\/p>|<br\s*\/?>/i)
    .map((p) => decode(p.replace(/<[^>]+>/g, '')).replace(/\s+/g, ' ').trim())
    .filter((p) => p && p !== '.');
}

// ---------------------------------------------------------------- WhatsApp
const portal = await load('general-configuration-portal');
const portalConfig = Array.isArray(portal.content) ? portal.content[0] : portal;
const whatsappUrl = String(portalConfig.whatsappLink ?? '').replace(/"/g, '');
const digits = whatsappUrl.match(/wa\.me\/55(\d{2})(\d{4,5})(\d{4})$/);
if (!digits) throw new Error(`whatsappLink inesperado: ${whatsappUrl}`);
const whatsappLabel = `(${digits[1]}) ${digits[2]}-${digits[3]}`;

// --------------------------------------------------------------------- FAQ
const faq = await load('faq');
const faqItems = (faq.content ?? faq).filter((q) => q.isActive && !q.isDeleted);

// Ajustes editoriais (documentados, nunca silenciosos):
//  1. As respostas (nov/2024) citam WhatsApps antigos e divergentes entre si
//     — (62) 98343-7324 e (62) 98343-7323. O canal atual do próprio portal
//     (`whatsappLink` da configuração geral) é o que o botão "Falar com
//     atendimento" abre; o texto passa a citar o mesmo número, pra o app
//     nunca mandar o torcedor pra dois contatos diferentes.
//  2. "Preciso renovar meu plano ou a renovação é automática?" tem na fonte
//     a resposta de OUTRA pergunta (forma de pagamento, palavra por palavra)
//     — fica fora até o clube corrigir; nunca inventamos a resposta.
const SKIP = new Set(['Preciso renovar meu plano ou a renovação é automática?']);
const CATEGORY_OF = [
  [/cart[ãa]o/i, 'cartao', 'Cartão do Sócio'],
  [/plano/i, 'planos', 'Planos'],
  [/boleto|pagamento|parcela/i, 'pagamento', 'Pagamento'],
];

const categories = new Map();
for (const q of faqItems) {
  const question = decode(q.title).trim();
  if (SKIP.has(question)) continue;
  const [, id, title] = CATEGORY_OF.find(([re]) => re.test(question)) ?? [null, 'geral', 'Dúvidas Gerais'];
  if (!categories.has(id)) categories.set(id, { id: `socio-tigrao-${id}`, title, items: [] });
  const cat = categories.get(id);
  const answer = paragraphsOf(q.content).map((text) => ({
    type: 'paragraph',
    spans: [
      {
        text: text.replace(/(?:nosso )?whatsapp \(62\) 98343-732[34]/gi, `WhatsApp ${whatsappLabel}`),
      },
    ],
  }));
  cat.items.push({ id: `${cat.id}-${cat.items.length + 1}`, question, answer });
}
const order = ['cartao', 'planos', 'pagamento', 'geral'];
const faqJson = {
  categories: order.filter((k) => categories.has(k)).map((k) => categories.get(k)),
};
fs.writeFileSync(FAQ_OUT, JSON.stringify(faqJson, null, 2) + '\n');

// -------------------------------------------------------------- Regulamento
const terms = await load('terms-of-use');
const term = (terms.content ?? terms).find((t) => t.isActive) ?? (terms.content ?? terms)[0];
const paras = paragraphsOf(term.content);
// Capítulo = "<romano> - DA/DO/DAS/DOS ..." em caixa alta (I a IX). Os
// subtítulos dos planos ("I – PLANO PRATA") e os incisos do capítulo VIII
// ("I - Estar rigorosamente...") também começam com romano, mas não com
// DA/DO — ficam dentro do corpo do capítulo.
const CHAPTER = /^([IVX]+)\s*[-–]\s*(D[AO]S?\s.+)$/;
const introParts = [];
const sections = [];
for (const p of paras) {
  const m = p.match(CHAPTER);
  if (m && m[2] === m[2].toUpperCase()) {
    sections.push({ title: m[2].trim(), body: [] });
  } else if (sections.length === 0) {
    if (!/^regulamento$/i.test(p)) introParts.push(p);
  } else {
    sections[sections.length - 1].body.push(p);
  }
}
if (sections.length < 5) throw new Error(`regulamento: só ${sections.length} capítulos — template mudou?`);

const titleCase = (s) =>
  s.toLowerCase().replace(/(^|\s)(\p{L})/gu, (_, sp, ch) => sp + ch.toUpperCase())
    .replace(/\b(Da|Do|Das|Dos|De|E|Ao)\b/g, (w) => w.toLowerCase())
    .replace(/^(\p{L})/u, (c) => c.toUpperCase())
    .replace(/Sócio-tigrão/g, 'Sócio-Tigrão');

const dartString = (s) => `'${s.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$').replace(/\n/g, '\\n')}'`;
const updatedAt = term.updatedAt.slice(0, 10);
const dart = `// GERADO por tooling/vilanova_membership/build_membership_content.mjs a
// partir da API pública do provedor de adesão do Sócio Tigrão
// (vilanova.ingressosa.com.br/public/api/v1/socio/terms-of-use) — não
// editar à mão. Texto oficial, sem reescrita: "${decode(term.title).trim()}",
// ${decode(term.observation ?? '').trim() || 'sem versão informada'}, atualizado pelo clube em ${updatedAt}.

import 'package:goias_app/features/membership/domain/entities/regulation_section.dart';

const vilaNovaRegulationUpdatedAt = '${updatedAt}';

const vilaNovaMembershipRegulationIntro =
    ${dartString(introParts.join('\n\n'))};

const vilaNovaMembershipRegulationSections = <RegulationSection>[
${sections
  .map(
    (s, i) => `  RegulationSection(
    index: ${i + 1},
    title: ${dartString(titleCase(s.title))},
    body: ${dartString(s.body.join('\n\n'))},
  ),`,
  )
  .join('\n')}
];
`;
fs.writeFileSync(REG_OUT, dart);

console.log(`WhatsApp do portal: ${whatsappUrl} (${whatsappLabel})`);
console.log(`FAQ: ${faqJson.categories.map((c) => `${c.title} ${c.items.length}`).join(' · ')} (pulada: ${[...SKIP].length})`);
console.log(`Regulamento: ${sections.length} capítulos, atualizado em ${updatedAt}`);
