export function stripTags(html: string): string {
  return html.replace(/<[^>]+>/g, '');
}

export function decodeEntities(text: string): string {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

export function cleanText(html: string): string {
  return decodeEntities(stripTags(html)).replace(/\s+/g, ' ').trim();
}
