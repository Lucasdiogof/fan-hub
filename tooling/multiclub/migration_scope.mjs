// Escopo de migrations por clube — FONTE ÚNICA da lógica (db-push.mjs,
// db-status.mjs, run-sql-file.mjs, testes e CI futuro só consomem esta API).
//
// Problema que resolve (A2): `supabase/migrations/` é UMA cadeia compartilhada
// pelos 3 projetos, mas várias migrations só fazem sentido no Goiás. O Supabase
// CLI aplica tudo que não está no histórico remoto, então migrations só-Goiás
// chegariam ao Bragantino/Vila Nova. Aqui cada migration DECLARA o escopo em
// `supabase/migration_scopes.json` e o CLI só enxerga o recorte do clube.
//
// Princípios (fail closed):
//   * toda migration precisa de exatamente 1 entrada no manifesto; sem entrada,
//     entrada órfã, versão/arquivo duplicado, scope inválido, SHA diferente ou
//     clube desconhecido -> ABORTA antes de chamar CLI/Postgres. Nada é inferido
//     pelo nome ou pelo conteúdo do SQL.
//   * `global` = TODOS os clubes do registry, em qualquer conta Supabase.
//     `global` não se mistura com clube. Escopo de clube = só aquele(s) clube(s).
//   * a conta/organização Supabase NUNCA participa da decisão (accountLabel do
//     registry é informativo): o destino é sempre clube -> projectRef.
//   * nenhuma migration é renomeada, movida ou editada: o recorte é uma CÓPIA
//     num workdir temporário fora do repositório.
//
// SHA-256: calculado sobre o conteúdo com fim de linha normalizado (CRLF -> LF),
// porque o Git for Windows (core.autocrlf=true) reescreve o arquivo no disco e o
// hash dos bytes brutos mudaria entre checkouts sem o conteúdo mudar. ATENÇÃO:
// o hash prova SOMENTE que o arquivo não mudou depois que o manifesto foi criado.
// Ele NÃO prova que esses mesmos bytes foram aplicados, no passado, aos bancos
// existentes — nenhuma alegação retroativa é feita aqui.
import crypto from 'crypto';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadProjectsRegistry } from './db_target_resolver.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const ROOT = path.resolve(__dirname, '../..');
export const DEFAULT_MIGRATIONS_DIR = path.join(ROOT, 'supabase', 'migrations');
export const DEFAULT_MANIFEST_PATH = path.join(ROOT, 'supabase', 'migration_scopes.json');
export const MANIFEST_VERSION = 1;
export const GLOBAL_SCOPE = 'global';

const MIGRATION_FILE_RE = /^(\d{14})_([A-Za-z0-9_]+)\.sql$/;
const SHA256_RE = /^[0-9a-f]{64}$/;
const ENTRY_KEYS = ['version', 'file', 'scope', 'sha256', 'note'];

/** Erro com TODAS as violações encontradas (nunca só a primeira). */
export class ScopeError extends Error {
  constructor(errors) {
    const list = Array.isArray(errors) ? errors : [String(errors)];
    super(`ESCOPO DE MIGRATIONS INVÁLIDO (${list.length}):\n  - ${list.join('\n  - ')}`);
    this.name = 'ScopeError';
    this.errors = list;
  }
}

/** SHA-256 do conteúdo com CRLF -> LF (bytes 0x0D imediatamente antes de 0x0A
 * são descartados; qualquer outro byte é preservado). */
export function sha256Normalized(buffer) {
  const out = Buffer.allocUnsafe(buffer.length);
  let n = 0;
  for (let i = 0; i < buffer.length; i++) {
    if (buffer[i] === 0x0d && buffer[i + 1] === 0x0a) continue;
    out[n++] = buffer[i];
  }
  return crypto.createHash('sha256').update(out.subarray(0, n)).digest('hex');
}

export function sha256File(filePath) {
  return sha256Normalized(fs.readFileSync(filePath));
}

/** Clubes válidos = chaves do registry de projetos (sem `_comment` etc.). */
export function clubsFromRegistry(registry = loadProjectsRegistry()) {
  return Object.keys(registry).filter((k) => !k.startsWith('_'));
}

function resolveOpts(opts = {}) {
  return {
    migrationsDir: opts.migrationsDir ?? DEFAULT_MIGRATIONS_DIR,
    manifestPath: opts.manifestPath ?? DEFAULT_MANIFEST_PATH,
    clubs: opts.clubs ?? clubsFromRegistry(),
    tmpBase: opts.tmpBase ?? os.tmpdir(),
  };
}

function isInside(child, parent) {
  const norm = (p) => (process.platform === 'win32' ? path.resolve(p).toLowerCase() : path.resolve(p));
  const rel = path.relative(norm(parent), norm(child));
  return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
}

/** Valida manifesto <-> arquivos reais. Nunca lança por violação de regra:
 * devolve {ok, errors, entries}. (Lança só por bug de programação.) */
export function validateManifest(options = {}) {
  const { migrationsDir, manifestPath, clubs } = resolveOpts(options);
  const errors = [];

  // 1) arquivos reais
  const files = [];
  if (!fs.existsSync(migrationsDir) || !fs.statSync(migrationsDir).isDirectory()) {
    errors.push(`pasta de migrations inexistente: ${migrationsDir}`);
  } else {
    for (const d of fs.readdirSync(migrationsDir, { withFileTypes: true })) {
      if (d.isDirectory()) {
        errors.push(`subpasta em migrations não é permitida (o CLI não a lê): ${d.name}/`);
      } else if (!d.name.endsWith('.sql')) {
        errors.push(`arquivo que não é .sql na pasta de migrations: ${d.name}`);
      } else if (!MIGRATION_FILE_RE.test(d.name)) {
        errors.push(`nome fora do padrão <14 dígitos>_<nome>.sql: ${d.name}`);
      } else {
        files.push(d.name);
      }
    }
  }

  // 2) manifesto
  let manifest = null;
  if (!fs.existsSync(manifestPath)) {
    errors.push(`manifesto inexistente: ${manifestPath}`);
  } else {
    try {
      manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    } catch (e) {
      errors.push(`manifesto não é JSON válido: ${e.message}`);
    }
  }
  if (manifest !== null) {
    if (typeof manifest !== 'object' || Array.isArray(manifest)) {
      errors.push('manifesto: a raiz precisa ser um objeto');
      manifest = null;
    } else {
      if (manifest.version !== MANIFEST_VERSION) {
        errors.push(`manifesto: version deve ser ${MANIFEST_VERSION} (veio ${JSON.stringify(manifest.version)})`);
      }
      if (!Array.isArray(manifest.migrations)) {
        errors.push('manifesto: "migrations" precisa ser um array');
        manifest = null;
      }
    }
  }

  const entries = [];
  if (manifest) {
    const seenVersion = new Map();
    const seenFile = new Map();
    manifest.migrations.forEach((e, i) => {
      const tag = `entrada #${i + 1}${e && e.file ? ` (${e.file})` : ''}`;
      if (!e || typeof e !== 'object' || Array.isArray(e)) {
        errors.push(`${tag}: precisa ser um objeto`);
        return;
      }
      for (const k of Object.keys(e)) {
        if (!ENTRY_KEYS.includes(k)) errors.push(`${tag}: campo desconhecido "${k}"`);
      }
      for (const k of ENTRY_KEYS) {
        if (!(k in e)) errors.push(`${tag}: campo obrigatório ausente "${k}"`);
      }
      if (typeof e.version !== 'string' || !/^\d{14}$/.test(e.version)) {
        errors.push(`${tag}: version deve ser string de 14 dígitos`);
      }
      if (typeof e.file !== 'string' || !MIGRATION_FILE_RE.test(e.file)) {
        errors.push(`${tag}: file fora do padrão <14 dígitos>_<nome>.sql`);
      } else if (typeof e.version === 'string' && e.file.slice(0, 14) !== e.version) {
        errors.push(`${tag}: version ${e.version} não corresponde ao prefixo do arquivo`);
      }
      if (typeof e.sha256 !== 'string' || !SHA256_RE.test(e.sha256)) {
        errors.push(`${tag}: sha256 deve ser hex minúsculo de 64 caracteres`);
      }
      if (typeof e.note !== 'string' || e.note.trim() === '') {
        errors.push(`${tag}: note obrigatório (texto não vazio)`);
      }

      // scope
      let scopeOk = true;
      if (!Array.isArray(e.scope) || e.scope.length === 0) {
        errors.push(`${tag}: scope deve ser um array não vazio`);
        scopeOk = false;
      } else {
        const names = e.scope;
        if (names.some((s) => typeof s !== 'string')) {
          errors.push(`${tag}: scope só aceita strings`);
          scopeOk = false;
        } else {
          if (new Set(names).size !== names.length) {
            errors.push(`${tag}: scope com valores repetidos`);
            scopeOk = false;
          }
          if (names.includes(GLOBAL_SCOPE) && names.length > 1) {
            errors.push(`${tag}: combinação ambígua — "global" não pode vir junto de outro escopo (${names.join(' + ')})`);
            scopeOk = false;
          }
          for (const s of names) {
            if (s !== GLOBAL_SCOPE && !clubs.includes(s)) {
              errors.push(`${tag}: scope desconhecido "${s}" (válidos: ${[GLOBAL_SCOPE, ...clubs].join(', ')})`);
              scopeOk = false;
            }
          }
        }
      }

      // duplicidades
      if (typeof e.version === 'string') {
        if (seenVersion.has(e.version)) errors.push(`versão duplicada no manifesto: ${e.version}`);
        seenVersion.set(e.version, true);
      }
      if (typeof e.file === 'string') {
        if (seenFile.has(e.file)) errors.push(`arquivo duplicado no manifesto: ${e.file}`);
        seenFile.set(e.file, true);
      }

      // arquivo real + SHA
      if (typeof e.file === 'string' && MIGRATION_FILE_RE.test(e.file)) {
        const abs = path.join(migrationsDir, e.file);
        if (!files.includes(e.file) || !fs.existsSync(abs)) {
          errors.push(`${tag}: o manifesto aponta para uma migration inexistente`);
        } else if (typeof e.sha256 === 'string' && SHA256_RE.test(e.sha256)) {
          const actual = sha256File(abs);
          if (actual !== e.sha256) {
            errors.push(`${tag}: SHA-256 diferente do manifesto (arquivo alterado depois do manifesto?)`);
          }
        }
      }
      if (scopeOk) entries.push(e);
    });

    // cobertura 1:1 — todo arquivo precisa de entrada
    const inManifest = new Set(manifest.migrations.map((e) => e && e.file));
    for (const f of files) {
      if (!inManifest.has(f)) errors.push(`migration SEM entrada no manifesto: ${f}`);
    }
    // versões duplicadas entre arquivos reais (dois arquivos com o mesmo timestamp)
    const byVersion = new Map();
    for (const f of files) {
      const v = f.slice(0, 14);
      byVersion.set(v, [...(byVersion.get(v) ?? []), f]);
    }
    for (const [v, fl] of byVersion) {
      if (fl.length > 1) errors.push(`versão duplicada entre arquivos reais ${v}: ${fl.join(', ')}`);
    }
  }

  return { ok: errors.length === 0, errors, entries: errors.length === 0 ? entries : [], files };
}

/** Valida e devolve as entradas ordenadas por versão; lança ScopeError se inválido. */
export function assertValid(options = {}) {
  const r = validateManifest(options);
  if (!r.ok) throw new ScopeError(r.errors);
  return [...r.entries].sort((a, b) => a.version.localeCompare(b.version));
}

export function entryAllowsClub(entry, club) {
  return entry.scope[0] === GLOBAL_SCOPE || entry.scope.includes(club);
}

/** O recorte de um clube: {club, allowed[], excluded[]}, ordenado por versão.
 * Clube desconhecido ou manifesto inválido -> ScopeError (nada é resolvido). */
export function resolveForClub(club, options = {}) {
  const o = resolveOpts(options);
  if (typeof club !== 'string' || !o.clubs.includes(club)) {
    throw new ScopeError(`clube desconhecido "${club ?? ''}" (válidos: ${o.clubs.join(', ')})`);
  }
  const entries = assertValid(o);
  return {
    club,
    allowed: entries.filter((e) => entryAllowsClub(e, club)),
    excluded: entries.filter((e) => !entryAllowsClub(e, club)),
    migrationsDir: o.migrationsDir,
  };
}

/** Cria um workdir TEMPORÁRIO (fora do repositório) com só as migrations do
 * clube. Retorna {workdir, files, cleanup}. Em qualquer falha limpa o que criou
 * e lança ScopeError. Nunca toca em supabase/migrations nem em supabase/.temp. */
export function buildClubWorkdir(club, options = {}) {
  const o = resolveOpts(options);
  const view = resolveForClub(club, o);
  let workdir = null;
  const cleanup = () => {
    if (workdir && fs.existsSync(workdir)) fs.rmSync(workdir, { recursive: true, force: true });
  };
  try {
    workdir = fs.mkdtempSync(path.join(o.tmpBase, `fanhub-migrations-${club}-`));
    if (isInside(workdir, ROOT)) {
      throw new Error('workdir temporário caiu dentro do repositório versionado — recusado');
    }
    const migDir = path.join(workdir, 'supabase', 'migrations');
    fs.mkdirSync(migDir, { recursive: true });
    for (const e of view.allowed) {
      const dest = path.join(migDir, e.file);
      fs.copyFileSync(path.join(o.migrationsDir, e.file), dest);
      // re-confere a CÓPIA (fecha a janela entre validar e copiar)
      if (sha256File(dest) !== e.sha256) {
        throw new Error(`a cópia de ${e.file} não confere com o SHA do manifesto`);
      }
    }
    // config neutro: não herda project_id do Goiás nem qualquer seção futura
    // ([vault], [auth]...) do supabase/config.toml compartilhado.
    fs.writeFileSync(
      path.join(workdir, 'supabase', 'config.toml'),
      `# gerado por migration_scope.mjs — recorte temporário do clube "${club}"\nproject_id = "fanhub-${club}-migrations"\n`,
    );
    const copied = fs.readdirSync(migDir).sort();
    const expected = view.allowed.map((e) => e.file).sort();
    if (JSON.stringify(copied) !== JSON.stringify(expected)) {
      throw new Error('o conteúdo do workdir difere do recorte esperado');
    }
    return { workdir, files: copied, view, cleanup };
  } catch (err) {
    cleanup();
    throw err instanceof ScopeError
      ? err
      : new ScopeError(`erro na criação do workdir: ${err.message}`);
  }
}

/** Decide se um arquivo .sql pode ser executado contra `club`. Vale para
 * (a) arquivos dentro de supabase/migrations e (b) QUALQUER arquivo cujo
 * conteúdo (SHA normalizado) seja o de uma migration do manifesto — fecha o
 * atalho de copiar a migration para outro lugar. SQL que não é migration passa
 * (`inMigrations:false`). Bloqueio -> ScopeError, ANTES de qualquer conexão. */
export function checkFileForClub(filePath, club, options = {}) {
  const o = resolveOpts(options);
  if (typeof club !== 'string' || !o.clubs.includes(club)) {
    throw new ScopeError(`clube desconhecido "${club ?? ''}" (válidos: ${o.clubs.join(', ')})`);
  }
  const abs = path.resolve(filePath);
  const inDir = isInside(abs, o.migrationsDir);
  let sha = null;
  if (fs.existsSync(abs) && fs.statSync(abs).isFile()) sha = sha256File(abs);

  // Se está na pasta de migrations, o manifesto inteiro tem de estar íntegro.
  // Fora dela, só validamos se o conteúdo coincidir com alguma migration.
  let entries;
  if (inDir) {
    entries = assertValid(o);
  } else {
    const r = validateManifest(o);
    if (!r.ok) {
      // manifesto quebrado + arquivo externo: não dá pra provar que NÃO é uma
      // migration -> fail closed.
      throw new ScopeError(r.errors);
    }
    entries = r.entries;
  }

  let entry = null;
  if (inDir) {
    entry = entries.find((e) => e.file === path.basename(abs)) ?? null;
    if (!entry) throw new ScopeError(`migration SEM entrada no manifesto: ${path.basename(abs)}`);
  } else if (sha) {
    entry = entries.find((e) => e.sha256 === sha) ?? null;
  }
  if (!entry) return { inMigrations: false, entry: null, allowed: true };

  if (!entryAllowsClub(entry, club)) {
    throw new ScopeError(
      `BLOQUEADO por escopo: ${entry.file} é "${entry.scope.join('+')}" e não pode rodar no clube "${club}"` +
        (inDir ? '' : ' (arquivo fora de supabase/migrations com o mesmo conteúdo de uma migration)'),
    );
  }
  return { inMigrations: inDir, entry, allowed: true };
}

/** Texto padrão da visão (usado por db-push, db-status e dry-run). */
export function formatView(view) {
  const lines = [];
  lines.push(`Migrations incluídas (${view.allowed.length}):`);
  for (const e of view.allowed) lines.push(`  + ${e.file}  [${e.scope.join('+')}]`);
  lines.push(`Migrations excluídas por escopo (${view.excluded.length}):`);
  for (const e of view.excluded) lines.push(`  - ${e.file}  [${e.scope.join('+')}]`);
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// CLI utilitária:  check | plan <clube> | sha <arquivo>
// ---------------------------------------------------------------------------
function isMain() {
  return process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

if (isMain()) {
  const [cmd, arg] = process.argv.slice(2);
  try {
    if (cmd === 'check') {
      const entries = assertValid();
      const g = entries.filter((e) => e.scope[0] === GLOBAL_SCOPE).length;
      console.log(`OK — ${entries.length} migrations com escopo válido (${g} global, ${entries.length - g} de clube).`);
    } else if (cmd === 'plan' && arg) {
      const v = resolveForClub(arg);
      console.log(`Club: ${arg}\n${formatView(v)}`);
    } else if (cmd === 'sha' && arg) {
      console.log(sha256File(path.resolve(arg)));
    } else {
      console.error('Uso: node tooling/multiclub/migration_scope.mjs check | plan <clube> | sha <arquivo>');
      process.exit(1);
    }
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
}
