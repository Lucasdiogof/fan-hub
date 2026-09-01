// Parser genérico de `INSERT INTO ... (cols) VALUES (...), (...);` do Postgres,
// pensado pra reler os arquivos supabase/*.sql deste projeto e virar JSON.
// Não conecta em nenhum banco — é puramente um parser de texto SQL estático.
// Reaproveitável: se os arquivos SQL forem re-exportados de um dump real do
// Supabase no mesmo formato de INSERT, basta rodar de novo.

/**
 * Acha o índice do parêntese de fechamento correspondente ao de `openIndex`
 * (que deve apontar pra um '('), respeitando strings entre aspas simples
 * (com escape '' pra aspas literais) e comentários de linha `--`.
 */
function findMatchingParen(text, openIndex) {
  let depth = 0;
  let inString = false;
  for (let i = openIndex; i < text.length; i++) {
    const c = text[i];
    if (inString) {
      if (c === "'") {
        if (text[i + 1] === "'") { i++; continue; }
        inString = false;
      }
      continue;
    }
    if (c === "'") { inString = true; continue; }
    if (c === '-' && text[i + 1] === '-') {
      const nl = text.indexOf('\n', i);
      i = nl === -1 ? text.length : nl;
      continue;
    }
    if (c === '(') depth++;
    else if (c === ')') {
      depth--;
      if (depth === 0) return i;
    }
  }
  throw new Error('Parêntese não fechado a partir do índice ' + openIndex);
}

/** Divide `text` em pedaços separados por `sep` no nível 0 de parênteses/colchetes, fora de strings. */
function splitTopLevel(text, sep = ',') {
  const parts = [];
  let depth = 0;
  let inString = false;
  let start = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inString) {
      if (c === "'") {
        if (text[i + 1] === "'") { i++; continue; }
        inString = false;
      }
      continue;
    }
    if (c === "'") { inString = true; continue; }
    if (c === '(' || c === '[') depth++;
    else if (c === ')' || c === ']') depth--;
    else if (c === sep && depth === 0) {
      parts.push(text.slice(start, i));
      start = i + 1;
    }
  }
  parts.push(text.slice(start));
  return parts.map((p) => p.trim()).filter((p) => p.length > 0);
}

/** Converte um token de valor SQL cru (já sem vírgulas externas) num valor JS. */
function parseValue(raw) {
  raw = raw.trim();
  // remove cast final, ex.: `'...'::jsonb`, `123::int`, `ARRAY[...]::text[]`
  const castMatch = raw.match(/^([\s\S]*)::[\w\s.\[\]]+$/);
  if (castMatch) raw = castMatch[1].trim();

  if (/^null$/i.test(raw)) return null;
  if (/^true$/i.test(raw)) return true;
  if (/^false$/i.test(raw)) return false;
  if (/^now\(\)$/i.test(raw)) return null; // timestamp gerado, não é dado real
  if (/^-?\d+$/.test(raw)) return parseInt(raw, 10);
  if (/^-?\d+\.\d+$/.test(raw)) return parseFloat(raw);

  // literais tipados do Postgres: `date '...'`, `time '...'`
  let typed = raw.match(/^(?:date|time|timestamp|timestamptz)\s+'([^']*)'$/i);
  if (typed) return typed[1];
  // `(timestamp '...' at time zone '...')` — devolve só o literal local,
  // o fuso já vem separado na coluna display_timezone.
  typed = raw.match(/^\(\s*timestamp\s+'([^']*)'\s+at\s+time\s+zone\s+'[^']*'\s*\)$/i);
  if (typed) return typed[1];

  if (raw.startsWith("ARRAY[") && raw.endsWith(']')) {
    const inner = raw.slice('ARRAY['.length, -1);
    return splitTopLevel(inner, ',').map(parseValue);
  }

  if (raw.startsWith("'") && raw.endsWith("'")) {
    const inner = raw.slice(1, -1).replace(/''/g, "'");
    const t = inner.trim();
    if ((t.startsWith('{') && t.endsWith('}')) || (t.startsWith('[') && t.endsWith(']'))) {
      try { return JSON.parse(inner); } catch { /* não era JSON de verdade, cai pra string */ }
    }
    return inner;
  }

  return raw; // token não reconhecido (ex.: chamada de função) — devolve cru
}

/**
 * Extrai todos os `INSERT INTO public.<table> (<cols>) VALUES (...), ...;`
 * de um texto SQL, devolvendo `{ table, columns, rows }[]` — `rows` é uma
 * lista de objetos já tipados (jsonb parseado, null real, etc).
 */
export function parseInserts(sqlText) {
  const results = [];
  const insertRe = /insert\s+into\s+public\.(\w+)\s*\(/gi;
  let m;
  while ((m = insertRe.exec(sqlText)) !== null) {
    const table = m[1];
    const colsOpen = m.index + m[0].length - 1; // índice do '('
    const colsClose = findMatchingParen(sqlText, colsOpen);
    const columns = splitTopLevel(sqlText.slice(colsOpen + 1, colsClose), ',').map((c) => c.trim());

    // Acha "values" logo depois do fechamento das colunas.
    const afterCols = sqlText.slice(colsClose + 1);
    const valuesMatch = afterCols.match(/^\s*values\s*/i);
    if (!valuesMatch) continue;
    let cursor = colsClose + 1 + valuesMatch[0].length;

    const rows = [];
    while (true) {
      // pula espaço/quebra de linha antes do próximo '('
      while (cursor < sqlText.length && /\s/.test(sqlText[cursor])) cursor++;
      if (sqlText[cursor] !== '(') break;
      const tupleClose = findMatchingParen(sqlText, cursor);
      const tupleInner = sqlText.slice(cursor + 1, tupleClose);
      const rawValues = splitTopLevel(tupleInner, ',');
      const row = {};
      columns.forEach((col, idx) => {
        row[col] = idx < rawValues.length ? parseValue(rawValues[idx]) : null;
      });
      rows.push(row);
      cursor = tupleClose + 1;
      while (cursor < sqlText.length && /\s/.test(sqlText[cursor])) cursor++;
      if (sqlText[cursor] === ',') { cursor++; continue; }
      break; // fim da lista de tuplas (próximo é `on conflict`, `;`, etc.)
    }

    results.push({ table, columns, rows });
  }
  return results;
}

/**
 * Extrai o padrão `UPDATE ... FROM (VALUES (...), ...) AS v(col1, col2, ...) WHERE ...`
 * usado pela migration de auditoria de estádios. Devolve `{ columns, rows }`
 * (rows já tipadas) — cada row é uma correção a aplicar por `id`.
 */
export function parseUpdateFromValues(sqlText) {
  const valuesIdx = sqlText.search(/from\s*\(\s*values/i);
  if (valuesIdx === -1) return null;
  const openParen = sqlText.indexOf('(', sqlText.indexOf('values', valuesIdx));
  const tuplesStart = (() => {
    // pula "values" e espaço até o primeiro '('
    let i = sqlText.indexOf('values', valuesIdx) + 'values'.length;
    while (/\s/.test(sqlText[i])) i++;
    return i;
  })();

  const rows = [];
  let cursor = tuplesStart;
  while (sqlText[cursor] === '(') {
    const tupleClose = findMatchingParen(sqlText, cursor);
    const rawValues = splitTopLevel(sqlText.slice(cursor + 1, tupleClose), ',');
    rows.push(rawValues.map(parseValue));
    cursor = tupleClose + 1;
    while (cursor < sqlText.length && /\s/.test(sqlText[cursor])) cursor++;
    if (sqlText[cursor] === ',') {
      cursor++;
      while (cursor < sqlText.length && /\s/.test(sqlText[cursor])) cursor++;
      continue;
    }
    break;
  }

  // depois da lista de tuplas vem `) as v( col1, col2, ... )`
  const asMatch = sqlText.slice(cursor).match(/^\)\s*as\s+\w+\s*\(/i);
  if (!asMatch) throw new Error('Não achei o alias "as v(...)" depois da lista de VALUES.');
  const colsOpen = cursor + asMatch[0].length - 1;
  const colsClose = findMatchingParen(sqlText, colsOpen);
  const columns = splitTopLevel(sqlText.slice(colsOpen + 1, colsClose), ',').map((c) => c.trim());

  const typedRows = rows.map((vals) => {
    const row = {};
    columns.forEach((col, idx) => { row[col] = idx < vals.length ? vals[idx] : null; });
    return row;
  });

  return { columns, rows: typedRows };
}

/**
 * Extrai o padrão `WITH <nome> (col1, col2, ...) AS ( VALUES (...), ... )`
 * usado pelo import de `passport_matches` (a fonte real do dado vem da CTE,
 * o `INSERT ... SELECT * FROM <nome>` depois só encaminha). Devolve
 * `{ name, columns, rows }` já tipadas.
 */
export function parseWithValuesCte(sqlText) {
  const m = sqlText.match(/with\s+(\w+)\s*\(/i);
  if (!m) return null;
  const name = m[1];
  const colsOpen = m.index + m[0].length - 1;
  const colsClose = findMatchingParen(sqlText, colsOpen);
  const columns = splitTopLevel(sqlText.slice(colsOpen + 1, colsClose), ',').map((c) => c.trim());

  const afterCols = sqlText.slice(colsClose + 1);
  const asValuesMatch = afterCols.match(/^\s*as\s*\(\s*values\s*/i);
  if (!asValuesMatch) throw new Error('CTE sem "as (values ...)" logo depois das colunas.');
  let cursor = colsClose + 1 + asValuesMatch[0].length;

  const rows = [];
  while (sqlText[cursor] === '(') {
    const tupleClose = findMatchingParen(sqlText, cursor);
    const rawValues = splitTopLevel(sqlText.slice(cursor + 1, tupleClose), ',');
    const row = {};
    columns.forEach((col, idx) => { row[col] = idx < rawValues.length ? parseValue(rawValues[idx]) : null; });
    rows.push(row);
    cursor = tupleClose + 1;
    while (cursor < sqlText.length && /\s/.test(sqlText[cursor])) cursor++;
    if (sqlText[cursor] === ',') {
      cursor++;
      while (cursor < sqlText.length && /\s/.test(sqlText[cursor])) cursor++;
      continue;
    }
    break;
  }

  return { name, columns, rows };
}

/**
 * Extrai patches simples de uma linha só: `UPDATE tbl SET col = 'v', ... WHERE id = 'x';`
 * (sem FROM/VALUES). Devolve `{ table, id, patch }` ou `null` se não bater
 * com esse formato pontual.
 */
export function parseSingleRowUpdate(sqlText) {
  const m = sqlText.match(/update\s+public\.(\w+)\s+set\s+([\s\S]*?)\s+where\s+id\s*=\s*'([^']*)'/i);
  if (!m) return null;
  const [, table, setClause, id] = m;
  const patch = {};
  for (const assignment of splitTopLevel(setClause, ',')) {
    const eq = assignment.indexOf('=');
    if (eq === -1) continue;
    const col = assignment.slice(0, eq).trim();
    if (col === 'updated_at') continue; // timestamp gerado, não é dado real
    patch[col] = parseValue(assignment.slice(eq + 1));
  }
  return { table, id, patch };
}
