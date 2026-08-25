import { describe, expect, it } from 'vitest';
import { cleanText, decodeEntities, stripTags } from './htmlText';

describe('stripTags', () => {
  it('removes simple tags', () => {
    expect(stripTags('<p>olá</p>')).toBe('olá');
  });

  it('removes several tags in sequence', () => {
    expect(stripTags('<div class="a"><span>x</span><b>y</b></div>')).toBe('xy');
  });

  it('leaves plain text untouched', () => {
    expect(stripTags('sem tags aqui')).toBe('sem tags aqui');
  });
});

describe('decodeEntities', () => {
  it('decodes &amp; but leaves entities it does not recognize alone', () => {
    // O site já entrega os acentos como UTF-8 puro, não como entidade — só
    // as entidades ASCII (nbsp/amp/quot/#39/lt/gt) precisam de tratamento.
    expect(decodeEntities('Goi&aacute;s &amp; Vila Nova')).toBe('Goi&aacute;s & Vila Nova');
    expect(decodeEntities('&quot;Eu sou Goi&aacute;s&quot;')).toBe('"Eu sou Goi&aacute;s"');
  });

  it('decodes nbsp, quot, apos, lt and gt', () => {
    expect(decodeEntities('a&nbsp;b')).toBe('a b');
    expect(decodeEntities('&quot;x&quot;')).toBe('"x"');
    expect(decodeEntities('&#39;x&#39;')).toBe("'x'");
    expect(decodeEntities('1 &lt; 2 &gt; 0')).toBe('1 < 2 > 0');
  });

  it('is a no-op on text without entities', () => {
    expect(decodeEntities('texto normal')).toBe('texto normal');
  });
});

describe('cleanText', () => {
  it('strips tags, decodes entities and collapses whitespace', () => {
    expect(cleanText('  <span>Goi&aacute;s</span>   \n  vence  ')).toBe(
      'Goi&aacute;s vence',
    );
  });

  it('collapses internal newlines and repeated spaces into one space', () => {
    expect(cleanText('linha um\n\n   linha dois')).toBe('linha um linha dois');
  });

  it('returns an empty string for tag-only input', () => {
    expect(cleanText('<div></div>')).toBe('');
  });
});
