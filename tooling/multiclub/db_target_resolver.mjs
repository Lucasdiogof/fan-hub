// M4 (canonical baseline) — resolve, de forma segura, qual clube/projeto/
// workdir um comando de banco vai tocar. Nunca aceita URL digitada
// diretamente por um humano na hora — sempre vem de env var, nunca
// impressa inteira, fail-loud em qualquer ausência/mismatch. Ver
// docs/multiclub/50_m4_multi_supabase_cli_contract_correction.md e
// docs/multiclub/51_m4_canonical_baseline_implementation_report.md.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const REGISTRY_PATH = path.join(__dirname, 'supabase_projects_registry.json');

export function loadProjectsRegistry() {
  return JSON.parse(fs.readFileSync(REGISTRY_PATH, 'utf8'));
}

/** Extrai o project ref de uma connection string Supabase (direct ou
 * pooler) sem nunca logar a string inteira. Retorna null se não conseguir
 * (formato inesperado) — chamador decide se isso é fail-loud. Usa a classe
 * URL de verdade (nunca regex ingênua contra a string crua) porque o
 * usuário do pooler é `postgres.<ref>` seguido de `:<senha>@host` — uma
 * regex tipo `postgres\.([a-z0-9]+)@` erra (não bate) sempre que a senha
 * existe no meio, que é o caso normal — bug real encontrado pelo teste
 * fabricado de mismatch, corrigido antes de qualquer uso real. */
export function extractProjectRefFromDbUrl(dbUrl) {
  let parsed;
  try {
    parsed = new URL(dbUrl);
  } catch {
    return null;
  }
  // pooler: username = "postgres.<ref>"
  if (parsed.username?.startsWith('postgres.')) {
    return parsed.username.slice('postgres.'.length) || null;
  }
  // direct: host = "db.<ref>.supabase.co"
  const directMatch = parsed.host.match(/^db\.([a-z0-9]+)\.supabase\.co/);
  if (directMatch) return directMatch[1];
  return null;
}

/** Nunca retorna a connection string inteira — só o host, pra log seguro. */
export function sanitizeHostForLog(dbUrl) {
  try {
    const u = new URL(dbUrl);
    return u.host;
  } catch {
    return '<connection string malformada>';
  }
}

/**
 * Resolve o alvo (clube -> workdir + projectRef + connection string) de
 * forma fail-loud. NUNCA cai pro Goiás por omissão, NUNCA aceita um clube
 * fora do registry, NUNCA aceita a env var ausente.
 */
export function resolveTarget(clubArg) {
  const registry = loadProjectsRegistry();
  const validClubKeys = Object.keys(registry).filter((k) => !k.startsWith('_'));
  const club = !clubArg.startsWith('_') ? registry[clubArg] : undefined;
  if (!club) {
    throw new Error(
      `Clube "${clubArg}" não está em supabase_projects_registry.json ` +
        `(disponíveis: ${validClubKeys.join(', ')}). Nunca resolvido por padrão.`,
    );
  }

  const dbUrl = process.env[club.envVar];
  if (!dbUrl) {
    throw new Error(
      `${club.envVar}_REQUIRED=true — env var ausente. Nunca peço a senha ` +
        `interativamente, nunca invento, nunca uso outro clube no lugar. ` +
        `Exporte ${club.envVar} antes de rodar este comando.`,
    );
  }

  const actualRef = extractProjectRefFromDbUrl(dbUrl);
  if (!actualRef) {
    throw new Error(
      `Não consegui extrair um project ref reconhecível de ${club.envVar} ` +
        `(formato esperado: postgres.<ref>@... ou @db.<ref>.supabase.co). ` +
        `Fail-loud — nunca assumo que está certo sem conseguir checar.`,
    );
  }
  if (actualRef !== club.projectRef) {
    throw new Error(
      `MISMATCH: ${club.envVar} aponta pro projeto "${actualRef}", mas o ` +
        `clube "${clubArg}" está registrado com projectRef="${club.projectRef}" ` +
        `em supabase_projects_registry.json. PARE — a env var pode estar ` +
        `configurada errada (ex.: BRAGANTINO_DB_URL com a URL do Goiás por engano).`,
    );
  }

  return {
    club: clubArg,
    projectRef: club.projectRef,
    workdir: path.join(ROOT, club.workdir),
    writable: club.writable,
    dbUrl,
    hostSanitized: sanitizeHostForLog(dbUrl),
  };
}

export function printTargetBanner(target) {
  console.log('=== ALVO CONFIRMADO ===');
  console.log(`clube:            ${target.club}`);
  console.log(`project ref:      ${target.projectRef}`);
  console.log(`host (sanitized): ${target.hostSanitized}`);
  console.log(`workdir:          ${path.relative(process.cwd(), target.workdir)}`);
  console.log(`writable:         ${target.writable}`);
  console.log('========================');
}
