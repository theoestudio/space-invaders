/**
 * Copies the Godot export (../build/web, from `make export`) into public/ for
 * Workers static assets, swapping index.wasm for a gzipped index.wasm.gz.
 */
import { cpSync, existsSync, readFileSync, rmSync, writeFileSync, statSync } from 'node:fs';
import { gzipSync, constants } from 'node:zlib';
import { join } from 'node:path';

const src = new URL('../../build/web/', import.meta.url).pathname;
const out = new URL('../public/', import.meta.url).pathname;

if (!existsSync(join(src, 'index.html'))) {
  throw new Error(`no web export at ${src}; run \`make export\` from the repo root first`);
}
rmSync(out, { recursive: true, force: true });
cpSync(src, out, { recursive: true });
rmSync(join(out, 'index.wasm'));
const wasm = readFileSync(join(src, 'index.wasm'));
writeFileSync(join(out, 'index.wasm.gz'), gzipSync(wasm, { level: constants.Z_BEST_COMPRESSION }));
const mb = (p: string) => (statSync(p).size / 1048576).toFixed(1);
console.log(`staged ${out}: index.wasm ${mb(join(src, 'index.wasm'))} MB -> index.wasm.gz ${mb(join(out, 'index.wasm.gz'))} MB`);
