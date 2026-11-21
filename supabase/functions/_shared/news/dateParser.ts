const MONTHS: Record<string, number> = {
  jan: 1,
  janeiro: 1,
  fev: 2,
  fevereiro: 2,
  mar: 3,
  'março': 3,
  abr: 4,
  abril: 4,
  mai: 5,
  maio: 5,
  jun: 6,
  junho: 6,
  jul: 7,
  julho: 7,
  ago: 8,
  agosto: 8,
  set: 9,
  setembro: 9,
  out: 10,
  outubro: 10,
  nov: 11,
  novembro: 11,
  dez: 12,
  dezembro: 12,
};

// (?:de\s+)? exige espaço depois do "de" — sem isso, "de" casava de forma
// gulosa com o início de "dez"/"dezembro" e quebrava dezembro especificamente.
const DATE_PATTERN = /(\d{1,2})\s*(?:de\s+)?([a-zç]+)\.?\s*(?:de)?\s*(\d{4})/i;

/**
 * Converte os dois formatos de data em português usados pelo site oficial
 * pra ISO `YYYY-MM-DD`: "18 de agosto 2026" (listagem) e "18 ago. 2026"
 * (notícia individual). Retorna null se não reconhecer o formato — quem
 * chama decide o que fazer (string vazia, por exemplo), nunca inventa data.
 */
export function parsePortugueseDate(raw: string): string | null {
  const cleaned = raw.replace(/publicado/i, '').trim().toLowerCase();
  const match = cleaned.match(DATE_PATTERN);
  if (!match) return null;

  const day = Number(match[1]);
  const month = MONTHS[match[2]];
  const year = Number(match[3]);
  if (!month || !day || !year) return null;

  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}
