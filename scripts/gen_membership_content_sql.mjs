import { readFileSync } from 'node:fs';

function sqlStringLiteral(s) {
  return "'" + s.replace(/'/g, "''") + "'";
}

function jsonbLiteral(value) {
  return sqlStringLiteral(JSON.stringify(value)) + '::jsonb';
}

// ---------------------------------------------------------------------------
// FAQ
// ---------------------------------------------------------------------------
const faq = JSON.parse(
  readFileSync('lib/assets/content/membership_faq.json', 'utf8'),
);

const categoryRows = [];
const itemRows = [];

faq.categories.forEach((category, categoryIndex) => {
  categoryRows.push(
    '(' +
      [
        sqlStringLiteral(category.id),
        sqlStringLiteral(category.title),
        String(categoryIndex + 1),
      ].join(', ') +
      ')',
  );

  category.items.forEach((item, itemIndex) => {
    itemRows.push(
      '(' +
        [
          sqlStringLiteral(item.id),
          sqlStringLiteral(category.id),
          sqlStringLiteral(item.question),
          jsonbLiteral(item.answer),
          String(itemIndex + 1),
        ].join(', ') +
        ')',
    );
  });
});

console.error(
  `FAQ: ${categoryRows.length} categories, ${itemRows.length} items`,
);

const faqSql = `-- ============================================================================
-- FAQ do Sócio Esmeralda. Rode no SQL Editor do Supabase. As tabelas viram
-- a fonte da verdade; o app cai no asset local
-- (lib/assets/content/membership_faq.json) se estiverem vazias ou sem rede.
-- Leitura é pública; escrita só pelo dashboard/admin. \`answer\` guarda os
-- blocos de texto rico exatamente no mesmo formato que o app já usa
-- ({"type":"paragraph","spans":[...]} / {"type":"list","items":[[...]]}),
-- cada span podendo ter bold/link — não simplificar pra texto plano aqui,
-- senão perde a formatação.
-- ============================================================================

create table if not exists public.membership_faq_categories (
  id text primary key,
  title text not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.membership_faq_items (
  id text primary key,
  category_id text not null references public.membership_faq_categories(id) on delete cascade,
  question text not null,
  answer jsonb not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.membership_faq_categories enable row level security;
alter table public.membership_faq_items enable row level security;

drop policy if exists "read faq categories" on public.membership_faq_categories;
create policy "read faq categories" on public.membership_faq_categories
  for select using (true);

drop policy if exists "read faq items" on public.membership_faq_items;
create policy "read faq items" on public.membership_faq_items
  for select using (true);

insert into public.membership_faq_categories (id, title, sort_order) values
${categoryRows.join(',\n')}
on conflict (id) do nothing;

insert into public.membership_faq_items (id, category_id, question, answer, sort_order) values
${itemRows.join(',\n')}
on conflict (id) do nothing;
`;

console.log(faqSql);

// ---------------------------------------------------------------------------
// Regulamento — mesma versão/id/data que RegulationCatalog.current já usa
// no Dart (regulation_catalog.dart); só o corpo do markdown passa a poder
// vir do Supabase.
// ---------------------------------------------------------------------------
const regulationMarkdown = readFileSync(
  'lib/assets/legal/membership_regulation.md',
  'utf8',
);

const regulationSql = `-- ============================================================================
-- Regulamento do Sócio Esmeralda. Rode no SQL Editor do Supabase, depois do
-- SQL da FAQ acima (são independentes, mas mantidos juntos por virem do
-- mesmo pedido). A tabela vira a fonte da verdade pro CORPO do texto; o
-- app cai no asset local (lib/assets/legal/membership_regulation.md) se
-- estiver vazia ou sem rede. \`id\`/\`version\`/\`effective_at\` espelham
-- exatamente RegulationCatalog.current no Dart — nunca mude esses três só
-- pelo dashboard sem atualizar o Dart junto, já que o id de aceite do sócio
-- (regulationVersion, gravado na adesão) continua vindo do Dart, não daqui.
-- ============================================================================

create table if not exists public.membership_regulation_versions (
  id text primary key,
  version text not null,
  effective_at date not null,
  content_markdown text not null,
  is_current boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.membership_regulation_versions enable row level security;

drop policy if exists "read regulation versions" on public.membership_regulation_versions;
create policy "read regulation versions" on public.membership_regulation_versions
  for select using (true);

insert into public.membership_regulation_versions (id, version, effective_at, content_markdown, is_current) values
('socio-esmeralda-2026-03-26', '2026-03-26', '2026-03-26', ${sqlStringLiteral(regulationMarkdown)}, true)
on conflict (id) do nothing;
`;

console.log(regulationSql);
