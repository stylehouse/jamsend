// scripts/find-cycles.mjs — quick static import-cycle finder over src/.
//  Regex-parses import/export-from specifiers, resolves $lib + relative to real files,
//   builds the graph, reports every elementary cycle (deduped). Throwaway diagnostic.
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs'
import { join, dirname, resolve } from 'node:path'

const ROOT = resolve('.')
const SRC = join(ROOT, 'src')
const LIB = join(SRC, 'lib')

function walk(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (e === 'node_modules' || e === '.svelte-kit') continue
    const p = join(dir, e)
    const s = statSync(p)
    if (s.isDirectory()) walk(p, out)
    else if (/\.(svelte|ts|js)$/.test(e)) out.push(p)
  }
  return out
}

const files = walk(SRC)
const fileSet = new Set(files)

// resolve a specifier from importerDir to a real file in our graph (or null if external)
function resolveSpec(spec, importerDir) {
  let base
  if (spec.startsWith('$lib/')) base = join(LIB, spec.slice('$lib/'.length))
  else if (spec === '$lib') base = LIB
  else if (spec.startsWith('./') || spec.startsWith('../')) base = resolve(importerDir, spec)
  else return null // bare/external/$app/$env
  // try exact, then extensions, then index
  const cands = [
    base,
    base + '.ts', base + '.js', base + '.svelte',
    base + '.svelte.ts',
    join(base, 'index.ts'), join(base, 'index.js'),
  ]
  for (const c of cands) if (fileSet.has(c)) return c
  return null
}

// Match an import/export statement, capturing the whole clause so we can drop type-only ones.
//  Vite's runtime HMR graph excludes `import type ...` / `export type ... from` (stripped by the
//   TS/Svelte compiler), so counting them fabricates cycles. We also strip a leading inline
//    `{ type X, ... }` only-types case crudely: if EVERY named specifier is `type`-prefixed, skip.
const stmtRe = /(?:^|\n)\s*(import|export)(\s+type\b)?([^;\n]*?)\bfrom\s*['"]([^'"]+)['"]|import\s*['"]([^'"]+)['"]|import\s*\(\s*['"]([^'"]+)['"]\s*\)/g

function clauseIsAllType(clause) {
  // clause like ` { type A, type B } ` or ` Foo, { type A } ` — true only if there are named
  //  specifiers AND every one is `type`-prefixed AND there's no default/namespace binding.
  const braced = clause.match(/\{([^}]*)\}/)
  if (!braced) return false
  const before = clause.slice(0, clause.indexOf('{')).replace(/[\s,]/g, '')
  if (before) return false // default or namespace import → runtime edge
  const names = braced[1].split(',').map(s => s.trim()).filter(Boolean)
  return names.length > 0 && names.every(n => /^type\s/.test(n))
}

const graph = new Map() // file -> Set(file)
for (const f of files) {
  const txt = readFileSync(f, 'utf8')
  const deps = new Set()
  let m
  while ((m = stmtRe.exec(txt))) {
    const kw = m[1], typeKw = m[2], clause = m[3] || '', spec = m[4] || m[5] || m[6]
    if (!spec) continue
    if (m[6]) continue                           // dynamic `import(...)` — its own HMR boundary, NOT a static cycle edge
    if (typeKw) continue                         // `import type ...` / `export type ... from` — no runtime edge
    if (clause && clauseIsAllType(clause)) continue  // `import { type A, type B }` — all elided
    const r = resolveSpec(spec, dirname(f))
    if (r && r !== f) deps.add(r)
  }
  graph.set(f, deps)
}

// Tarjan SCC — any SCC of size>1 is a cycle cluster; size-1 with self-edge too.
let idx = 0
const stack = [], onStack = new Set(), index = new Map(), low = new Map(), sccs = []
function sc(v) {
  index.set(v, idx); low.set(v, idx); idx++; stack.push(v); onStack.add(v)
  for (const w of graph.get(v) || []) {
    if (!index.has(w)) { sc(w); low.set(v, Math.min(low.get(v), low.get(w))) }
    else if (onStack.has(w)) low.set(v, Math.min(low.get(v), index.get(w)))
  }
  if (low.get(v) === index.get(v)) {
    const comp = []
    let w
    do { w = stack.pop(); onStack.delete(w); comp.push(w) } while (w !== v)
    if (comp.length > 1 || (graph.get(v)?.has(v))) sccs.push(comp)
  }
}
for (const v of graph.keys()) if (!index.has(v)) sc(v)

const rel = p => p.replace(ROOT + '/', '')
console.log(`scanned ${files.length} files; found ${sccs.length} cyclic SCC(s)\n`)
sccs.sort((a, b) => b.length - a.length)
for (const comp of sccs) {
  console.log(`── SCC (${comp.length} files) ──`)
  for (const f of comp) {
    const inComp = [...(graph.get(f) || [])].filter(d => comp.includes(d)).map(rel)
    console.log(`  ${rel(f)}\n      → ${inComp.join('\n      → ')}`)
  }
  console.log()
}
