// Compiles the console's Tailwind v4 theme + safelisted utilities into a
// static stylesheet the design-sync converter can ship (cfg.cssEntry).
// Run from the repo root: `node .design-sync/build-css.mjs`.
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const consoleDir = resolve(here, '../console');
const require = createRequire(resolve(consoleDir, 'package.json'));
const postcss = require('postcss');
const tailwind = require('@tailwindcss/postcss');

const from = resolve(here, 'tailwind/entry.css');
const to = resolve(consoleDir, '.ds-css/styles.css');
const css = readFileSync(from, 'utf8');
const result = await postcss([tailwind({ base: consoleDir, optimize: { minify: true } })]).process(css, { from, to });
mkdirSync(dirname(to), { recursive: true });
writeFileSync(to, result.css);
console.log(`wrote ${to} (${(result.css.length / 1024).toFixed(1)} KB)`);

// Also emit a tokens-only stylesheet (the :root custom properties from
// globals.css, verbatim) as a tiny pseudo-package under console/node_modules,
// because the converter only copies tokens from a package (cfg.tokensPkg +
// cfg.tokensGlob). This keeps tokens/ and the README token index listing the
// design tokens instead of Tailwind's internal --tw-* variables. Regenerated on
// every build; node_modules is never committed.
const globals = readFileSync(resolve(consoleDir, 'app/globals.css'), 'utf8');
const root = globals.match(/^:root\s*\{[\s\S]*?^\}/m)?.[0];
if (!root) throw new Error('globals.css: no :root block found');
const tokensPkgDir = resolve(consoleDir, 'node_modules/@blocnet/console-tokens');
mkdirSync(tokensPkgDir, { recursive: true });
writeFileSync(resolve(tokensPkgDir, 'package.json'), JSON.stringify({ name: '@blocnet/console-tokens', version: '0.1.0', private: true }, null, 2) + '\n');
writeFileSync(resolve(tokensPkgDir, 'tokens.css'), `/* Blocnet console design tokens - extracted verbatim from app/globals.css :root */\n${root}\n`);
console.log(`wrote ${tokensPkgDir}/tokens.css`);
