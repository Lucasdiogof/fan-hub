// Resolve/registra o Goiás no club registry e gera a migration de seed de
// `public.clubs` com o UUID literal e estável — nunca gen_random_uuid(),
// nunca derivado do slug.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadClubRegistry, saveClubRegistry, resolveClubId, registerNewClub } from './club_registry.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const REGISTRY_PATH = path.join(__dirname, 'clubs_registry.json');
const MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902030000_seed_clubs.sql');

const CLUBS = [
  { registryLookupKey: 'goias', slug: 'goias', name: 'Goiás Esporte Clube', shortName: 'Goiás' },
];

const registry = loadClubRegistry(REGISTRY_PATH);
const rows = [];
for (const c of CLUBS) {
  const resolved = resolveClubId(registry, c.registryLookupKey);
  const entry = resolved.status === 'matched' ? resolved.entry : registerNewClub(registry, c.registryLookupKey);
  rows.push({ id: entry.clubId, canonicalClubKey: entry.canonicalClubKey, slug: c.slug, name: c.name, shortName: c.shortName });
}
saveClubRegistry(REGISTRY_PATH, registry);

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }

const header = `-- ============================================================================
-- Seed de \`public.clubs\` — SOMENTE Goiás Esporte Clube. id vem do club
-- registry persistido (tooling/multiclub/clubs_registry.json), NUNCA
-- gen_random_uuid(), NUNCA derivado do slug — se o slug for corrigido no
-- futuro, o id permanece o mesmo (o registry casa por registryLookupKey,
-- um identificador interno separado do valor da coluna slug).
--
-- GERADA por tooling/multiclub/generate_clubs_seed.mjs — NUNCA editar à
-- mão.
--
-- club_id é IDENTIDADE persistente; slug é atributo mutável. Por isso o
-- conflito é resolvido por (id), nunca por (slug):
--   - mesmo id + mesmo slug já presentes -> idempotente, ON CONFLICT (id)
--     DO NOTHING não faz nada, seguro reaplicar.
--   - slug já usado por uma linha com id DIFERENTE -> NÃO deve ser
--     absorvido silenciosamente. Nunca usar ON CONFLICT (slug) DO UPDATE
--     (isso preservaria o id ERRADO). O guard abaixo detecta esse caso
--     ANTES do INSERT e lança uma exceção explícita — sem ele, a própria
--     UNIQUE(slug) da tabela já rejeitaria o INSERT (erro genérico do
--     Postgres), mas preferimos uma mensagem que deixa claro O QUE
--     aconteceu.
-- ============================================================================

`;

const guardBlocks = rows.map((r) => `do $$
declare
  existing_id uuid;
begin
  select id into existing_id from public.clubs where slug = ${sqlString(r.slug)};
  if existing_id is not null and existing_id <> ${sqlString(r.id)}::uuid then
    raise exception 'clubs.slug % já existe com id % (esperado ${r.id}) — conflito de identidade de clube, PARE e investigue antes de continuar. Nunca fazer UPDATE silencioso do id.', ${sqlString(r.slug)}, existing_id;
  end if;
end $$;
`).join('\n');

const insertHeader = `
insert into public.clubs (id, slug, name, short_name)
values
`;
const valuesLines = rows.map((r, i) => {
  const comma = i === rows.length - 1 ? '' : ',';
  return `  (${sqlString(r.id)}, ${sqlString(r.slug)}, ${sqlString(r.name)}, ${sqlString(r.shortName)})${comma}`;
});
const footer = `\non conflict (id) do nothing;\n`;
const sql = header + guardBlocks + insertHeader + valuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

console.log(JSON.stringify({ migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'), rows }, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
