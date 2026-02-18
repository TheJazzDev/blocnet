import {
  normalizeName,
  normalizeSymbol,
  toSlug,
  toWebsiteDomain,
} from './projects.canonical';

describe('projects.canonical', () => {
  it('normalizes project names', () => {
    expect(normalizeName('  My@@ Project  Name  ')).toBe('my project name');
  });

  it('normalizes symbols', () => {
    expect(normalizeSymbol(' bnt ')).toBe('BNT');
    expect(normalizeSymbol('')).toBeUndefined();
    expect(normalizeSymbol(undefined)).toBeUndefined();
  });

  it('slugifies names', () => {
    expect(toSlug('  My Cool Project!!  ')).toBe('my-cool-project');
  });

  it('extracts normalized website domains', () => {
    expect(toWebsiteDomain('https://www.Blocnet.io/path?q=1')).toBe(
      'blocnet.io',
    );
  });
});
