// Emits a .d.ts tree for the console UI kit into console/dist/types so the
// design-sync converter can extract real <Name>Props contracts (the console is
// a Next.js app with no library build, so nothing else produces declarations).
// Run from the repo root: `node .design-sync/build-dts.mjs`.
import { createRequire } from 'node:module';
import { mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const consoleDir = resolve(here, '../console');
const require = createRequire(resolve(consoleDir, 'package.json'));
const ts = require('typescript');

const uiDir = resolve(consoleDir, 'components/ui');
const outDir = resolve(consoleDir, 'dist/types');
const uiFiles = readdirSync(uiDir).filter((f) => f.endsWith('.tsx')).sort();

rmSync(outDir, { recursive: true, force: true });
const program = ts.createProgram(
  [...uiFiles.map((f) => resolve(uiDir, f)), resolve(consoleDir, 'lib/utils.ts')],
  {
    declaration: true,
    emitDeclarationOnly: true,
    noEmit: false,
    outDir,
    rootDir: consoleDir,
    jsx: ts.JsxEmit.Preserve,
    target: ts.ScriptTarget.ES2017,
    module: ts.ModuleKind.ESNext,
    moduleResolution: ts.ModuleResolutionKind.Bundler,
    strict: true,
    skipLibCheck: true,
    esModuleInterop: true,
    baseUrl: consoleDir,
    paths: { '@/*': ['./*'] },
    lib: ['lib.dom.d.ts', 'lib.dom.iterable.d.ts', 'lib.esnext.d.ts'],
  },
);
const result = program.emit();
const diags = ts.getPreEmitDiagnostics(program).concat(result.diagnostics);
for (const d of diags) {
  const msg = ts.flattenDiagnosticMessageText(d.messageText, '\n');
  const loc = d.file ? `${d.file.fileName}:${d.file.getLineAndCharacterOfPosition(d.start).line + 1}` : '';
  console.error(`  ! ${loc} ${msg}`);
}
if (result.emitSkipped) { console.error('declaration emit skipped'); process.exit(1); }

mkdirSync(outDir, { recursive: true });
const barrel = uiFiles.map((f) => `export * from './components/ui/${basename(f, '.tsx')}';`).join('\n') + '\n';
writeFileSync(resolve(outDir, 'index.d.ts'), barrel);
console.log(`wrote ${outDir}/index.d.ts (${uiFiles.length} modules)`);
