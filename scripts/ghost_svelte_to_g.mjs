// ghost_svelte_to_g.mjs — port a .svelte ghost (methods merged onto the House by M.eatfunc({...})) to a .g, and PROVE the port.
//  spec/Aprac_todo.md §0 item 1: put legacy code on TheACode.  A .svelte ghost and a .g are the same thing in two syntaxes —
//   a bag of methods eatfunc merges — so this is a transform, not a rewrite.  What the .g compiler can't carry is reported,
//    and any method it had to change is named.
//
//   node scripts/ghost_svelte_to_g.mjs src/lib/O/Story.svelte Ghost/O/Story.g        # write the .g + print the report
//   node scripts/ghost_svelte_to_g.mjs --prove src/lib/O/Story.svelte src/lib/gen/O/Story.go
//        # after compiling the .g (LocalGen): same members, same bodies (printed by TypeScript, comments dropped)
//
//  What the .g compiler accepts (probed 2026-10-22 with LocalGen): a header `[async ]name(params)[: Ret]:` at column 0, the body
//   indented below it and copied VERBATIM (so bodies keep their 8-space indent and template strings are untouched); typed
//    params and return types pass through.  It does NOT accept: braces in a header (an object default, a destructured
//     param), a getter, a data property, or any body line at column 0 (it ends the method).  Those are rewritten when it can be
//      done exactly, and refused otherwise.
import fs from 'node:fs'
import ts from 'typescript'

// --allow-async=a,b: sync methods the .g compiler may make async (nested awaits it can't lose) because their callers ignore
//  the return value.  What still changes: a sync throw becomes a rejection.  Named here so the choice is on record
const allow_async = new Set((process.argv.find(a => a.startsWith('--allow-async=')) || '').replace('--allow-async=', '').split(',').filter(Boolean))
const args = process.argv.slice(2).filter(a => !a.startsWith('--allow-async='))
const prove = args[0] === '--prove'
if (prove) args.shift()
const [src_path, out_path] = args
if (!src_path || !out_path) {
    console.error('usage: ghost_svelte_to_g.mjs [--prove] <ghost.svelte> <out.g | gen.go>')
    process.exit(2)
}

// the <script> of a .svelte or .go, and where it starts (so positions map back to lines)
function script_of(path) {
    const text = fs.readFileSync(path, 'utf8')
    const m = text.match(/<script[^>]*>([\s\S]*?)<\/script>/)
    if (!m) throw new Error('no <script> in ' + path)
    const after = text.slice(text.indexOf(m[0]) + m[0].length).trim()
    return { code: m[1], markup: after }
}

// the object literal handed to eatfunc, and the statements around it
function eatfunc_object(sf) {
    let found = null
    const visit = (node) => {
        if (found) return
        if (ts.isCallExpression(node) && ts.isPropertyAccessExpression(node.expression) && node.expression.name.text === 'eatfunc'
            && node.arguments[0] && ts.isObjectLiteralExpression(node.arguments[0])) {
            found = node.arguments[0]
            return
        }
        ts.forEachChild(node, visit)
    }
    visit(sf)
    return found
}

const member_name = (m) => m.name && (ts.isIdentifier(m.name) || ts.isStringLiteral(m.name)) ? m.name.text : m.name?.getText()

// a member's body printed by TypeScript, then transpiled to JS: comments and TYPES dropped, whitespace normalised — what
//  --prove compares.  Types can't change what runs, so a port that only touched a type is identical
const printer = ts.createPrinter({ removeComments: true })
const js = (text) => ts.transpileModule('(' + text + ')', { compilerOptions: { target: ts.ScriptTarget.ESNext, removeComments: true } }).outputText.replace(/\s+/g, ' ').trim()
function printed(sf, m) {
    if (ts.isMethodDeclaration(m)) {
        const params = m.parameters.map(p => printer.printNode(ts.EmitHint.Unspecified, p, sf)).join(', ')
        const body = m.body ? printer.printNode(ts.EmitHint.Unspecified, m.body, sf) : ''
        const async = m.modifiers?.some(x => x.kind === ts.SyntaxKind.AsyncKeyword) ? 'async ' : ''
        return { kind: 'method', text: js(`{ ${async}m(${params}) ${body} }`) }
    }
    if (ts.isPropertyAssignment(m)) return { kind: 'property', text: js(printer.printNode(ts.EmitHint.Expression, m.initializer, sf)) }
    return { kind: ts.SyntaxKind[m.kind], text: m.getText(sf) }
}

function members_of(path) {
    const { code } = script_of(path)
    const sf = ts.createSourceFile(path, code, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS)
    const obj = eatfunc_object(sf)
    if (!obj) throw new Error('no eatfunc({...}) in ' + path)
    return { sf, code, obj, members: obj.properties }
}

if (prove) {
    const a = members_of(src_path), b = members_of(out_path)
    const A = new Map(a.members.map(m => [member_name(m), printed(a.sf, m)]))
    const B = new Map(b.members.map(m => [member_name(m), printed(b.sf, m)]))
    // the module level: every statement outside onMount, printed, except the props line (a .svelte's M, a .go's H) and the
    //  .go's own header imports, which it always has
    const outer_of = (x) => x.sf.statements.filter(st => !st.getText(x.sf).includes('eatfunc(') && !/\$props\(\)/.test(st.getText(x.sf)))
        .map(st => printer.printNode(ts.EmitHint.Unspecified, st, x.sf))
    const oa = outer_of(a), ob = new Set(outer_of(b))
    for (const st of oa) {
        const key = 'module: ' + st.split('\n')[0].slice(0, 50)
        A.set(key, { kind: 'module', text: st })
        B.set(key, { kind: 'module', text: ob.has(st) ? st : '(changed or missing)' })
    }
    const declared = (() => { try { return JSON.parse(fs.readFileSync(out_path.replace(/\.go$/, '.port.json').replace('src/lib/gen/', 'Ghost/'), 'utf8')) } catch { return { rewritten: {} } } })()
    let same = 0, differ = [], missing = [], extra = [], compiler_H = []
    for (const [name, x] of A) {
        // a data property ported as a method of the same name returning it (Story's story_matching)
        const y = B.get(name)
        if (!y) { missing.push(name); continue }
        if (x.text === y.text) { same++; continue }
        // the .g compiler's own: it gives a body that mentions H a `const H = this` (even when H is only an object key)
        if (y.text.replace(/(m\([^)]*\) \{) const H = this;/, '$1') === x.text) { same++; compiler_H.push(name); continue }
        if (process.env.PROVE_SHOW === name) {
            // the first place the two differ, with some context either side
            const yt = y.text.replace(/(m\([^)]*\) \{) const H = this;/, '$1')
            let k = 0; while (k < x.text.length && x.text[k] === yt[k]) k++
            console.log('--- ' + name + ' @' + k + '\n  was: …' + x.text.slice(Math.max(0, k - 120), k + 160) + '\n  now: …' + yt.slice(Math.max(0, k - 120), k + 160))
        }
        if (declared.rewritten?.[name] || declared.module?.[name]) { differ.push(name + '  (declared: ' + (declared.rewritten?.[name] || declared.module[name]) + ')'); continue }
        differ.push(name)
    }
    for (const name of B.keys()) if (!A.has(name) && !/^Ghostmeta_/.test(name)) extra.push(name)
    console.log(`members ${A.size} · identical ${same} · differ ${differ.length} · missing ${missing.length} · extra ${extra.length}`)
    if (compiler_H.length) console.log(`  (identical but for the compiler's \`const H = this\`: ${compiler_H.join(', ')})`)
    for (const d of differ) console.log('  differ  ' + d)
    for (const d of missing) console.log('  MISSING ' + d)
    for (const d of extra) console.log('  extra   ' + d)
    const undeclared = differ.filter(d => !d.includes('(declared:'))
    // the .go must LOAD: no name bound twice at module level (the header's imports + the ghost's own) — Vite's svelte plugin
    //  refuses the module, esbuild's parse doesn't notice
    const bound = new Map()
    for (const st of b.sf.statements) {
        const names = []
        if (ts.isImportDeclaration(st) && st.importClause) {
            if (st.importClause.name) names.push(st.importClause.name.text)
            const nb = st.importClause.namedBindings
            if (nb && ts.isNamedImports(nb)) for (const e of nb.elements) names.push(e.name.text)
            if (nb && ts.isNamespaceImport(nb)) names.push(nb.name.text)
        }
        if (ts.isVariableStatement(st)) for (const d of st.declarationList.declarations) if (ts.isIdentifier(d.name)) names.push(d.name.text)
        if ((ts.isFunctionDeclaration(st) || ts.isClassDeclaration(st)) && st.name) names.push(st.name.text)
        for (const n of names) bound.set(n, (bound.get(n) || 0) + 1)
    }
    const twice = [...bound].filter(([, k]) => k > 1).map(([n]) => n)
    console.log(`module bindings unique: ${twice.length ? 'NO — ' + twice.join(', ') : 'yes'}`)
    // the second check — the COMPILER carried the .g faithfully: rebuild each member from the .g's own text (header line, body
    //  below it) and compare it with the .go.  Every member must match (bar the compiler's const H), declared rewrites or not —
    //   so a sugar misfire hidden inside a rewritten member still shows
    let faithful_bad = []
    const g_path = out_path.replace('src/lib/gen/', 'Ghost/').replace(/\.go$/, '.g')
    if (fs.existsSync(g_path)) {
        const gl = fs.readFileSync(g_path, 'utf8').split('\n')
        const head = /^(async )?([A-Za-z_$][\w$]*)\((.*)\)(: .*)?:$/
        const parts = []
        for (let i = 0; i < gl.length; i++) {
            const mm = gl[i].match(head)
            if (!mm) continue
            let j = i + 1
            while (j < gl.length && !/^\S/.test(gl[j])) j++
            parts.push(`${mm[1] || ''}${mm[2]}(${mm[3]})${mm[4] || ''} {\n${gl.slice(i + 1, j).join('\n')}\n},`)
        }
        const pseudo = '<script lang="ts">\nonMount(async () => { await H.eatfunc({\n' + parts.join('\n') + '\n}) })\n</script>\n'
        const tmp = out_path + '.pseudo.svelte'
        fs.writeFileSync(tmp, pseudo)
        try {
            const g = members_of(tmp)
            const G = new Map(g.members.map(m => [member_name(m), printed(g.sf, m)]))
            for (const [name, x] of G) {
                const y = B.get(name)
                if (!y) { faithful_bad.push(name + ' (not in the .go)'); continue }
                // and its other own: a method holding an await anywhere is made async
                const yy = y.text.replace(/(m\([^)]*\) \{) const H = this;/, '$1')
                const xa = x.text.replace('({ m(', '({ async m(')
                if (![x.text, xa].includes(y.text) && ![x.text, xa].includes(yy)) faithful_bad.push(name)
                if (process.env.PROVE_SHOW === name) { const xx = x.text.replace("({ m(", "({ async m("); let k = 0; while (k < xx.length && xx[k] === yy[k]) k++; console.log("--- faithful " + name + " @" + k + "\n  g:  …" + xx.slice(Math.max(0,k-100), k+120) + "\n  go: …" + yy.slice(Math.max(0,k-100), k+120)) }
            }
        } finally { fs.rmSync(tmp) }
        console.log(`compiler faithful to the .g: ${faithful_bad.length ? 'NO — ' + faithful_bad.join(', ') : 'yes, every member'}`)
    }
    process.exit(missing.length || undeclared.length || extra.length || faithful_bad.length || twice.length ? 1 : 0)
}

// ---- convert ----
const { code, markup } = script_of(src_path)
const { sf, obj, members } = members_of(src_path)
const lines_of = (s) => s.split('\n')
const report = { refused: [], rewritten: {}, notes: [] }
if (markup) report.notes.push('markup after </script> is NOT carried (a .g has none): ' + markup.slice(0, 80))

// the module level: everything in <script> outside the onMount(eatfunc) — imports, consts, lets — goes into IMPORT(),
//  except `let { M } = $props()` (a .go gets H)
const outer = []
let eat_stmt = null
for (const st of sf.statements) {
    if (ts.isExpressionStatement(st) && st.getText(sf).includes('eatfunc(')) { eat_stmt = st; continue }
    // a compiled .go's header already imports TheC (Stuff) and onMount (svelte): importing either again REDECLARES it and the
    //  module won't load ("Identifier 'TheC' has already been declared" — Vite's svelte plugin; esbuild's parse doesn't check).
    //   Those specifiers are dropped from the ghost's own imports
    if (ts.isImportDeclaration(st) && st.importClause?.namedBindings && ts.isNamedImports(st.importClause.namedBindings)) {
        const from = st.moduleSpecifier.text
        const given = { '$lib/Stuff.svelte': ['TheC'], 'svelte': ['onMount'] }[from] || []
        const els = st.importClause.namedBindings.elements
        const keep = els.filter(e => !given.includes(e.name.text))
        if (keep.length !== els.length && !st.importClause.isTypeOnly) {
            const lead = st === sf.statements[0] ? '' : st.getFullText(sf).slice(0, st.getStart(sf) - st.getFullStart())
            const dropped = els.filter(e => given.includes(e.name.text)).map(e => e.name.text)
            report.module = report.module || {}
            report.module['module: ' + printer.printNode(ts.EmitHint.Unspecified, st, sf).split('\n')[0].slice(0, 50)] = dropped.join(', ') + ' dropped: the .go header imports them already'
            if (keep.length || st.importClause.name) {
                const def = st.importClause.name ? st.importClause.name.text + (keep.length ? ', ' : '') : ''
                outer.push(lead + `import ${def}${keep.length ? '{ ' + keep.map(e => e.getText(sf)).join(', ') + ' }' : ''} from "${from}"`)
            }
            continue
        }
    }
    // the first statement's leading comments are the file's header — said once, at the top of the .g, not inside IMPORT()
    const text = st === sf.statements[0] ? '\n' + (code.slice(0, st.getStart(sf)).match(/[ \t]*$/)[0]) + code.slice(st.getStart(sf), st.getEnd()) : st.getFullText(sf)
    if (/\$props\(\)/.test(text)) { report.notes.push('dropped: ' + st.getText(sf).trim()); continue }
    outer.push(text)
}
const first = sf.statements[0]
const head_comments = (ts.getLeadingCommentRanges(code, first.getFullStart()) || []).map(r => code.slice(r.pos, r.end)).join('\n')
const outer_text = outer.join('')

// does anything inside onMount besides eatfunc happen (code after eatfunc, other awaits)?  Then refuse: it wouldn't be carried
if (eat_stmt) {
    const call = eat_stmt.expression
    const fn = ts.isCallExpression(call) ? call.arguments[0] : null
    if (fn && (ts.isArrowFunction(fn) || ts.isFunctionExpression(fn)) && ts.isBlock(fn.body) && fn.body.statements.length > 1) {
        report.refused.push('onMount does more than eatfunc: ' + fn.body.statements.slice(1).map(s => s.getText(sf).slice(0, 60)).join(' | '))
    }
}

// the ghost's data properties — each is ported as a method returning it, so the ghost's OWN reads of it (this.P) become calls
//  (this.P()).  Story's `...this.story_matching` threw "not iterable" on the live runner when this was missed (2026-10-22)
const data_props = new Set(members.filter(m => ts.isPropertyAssignment(m)).map(m => member_name(m)))
const out = []
const dedent4 = (s) => lines_of(s).map(l => l.startsWith('    ') ? l.slice(4) : l.replace(/^\t/, '')).join('\n')
out.push(dedent4(head_comments).trim())
out.push('')
out.push('IMPORT()')
// verbatim: the compiler takes 4 spaces off each IMPORT() line, which is exactly the .svelte's own indent — except inside a
//  template string, whose content then changes (--prove compares the module level too, so it shows)
const outer_lines = lines_of(outer_text.replace(/^\s*\n/, ''))
const outer_col0 = outer_lines.filter(l => /^\S/.test(l))
if (outer_col0.length) report.refused.push(`module level: ${outer_col0.length} line(s) at column 0 would end IMPORT() — first: ${outer_col0[0].slice(0, 60)}`)
for (const l of outer_lines) out.push(l)
report.module = report.module || {}
for (const st of sf.statements) {
    if (st === eat_stmt || /\$props\(\)/.test(st.getText(sf))) continue
    let has_tpl = false
    const look = (n) => { if (ts.isTemplateLiteral(n) || ts.isNoSubstitutionTemplateLiteral(n)) { if (n.getText(sf).includes('\n')) has_tpl = true } ts.forEachChild(n, look) }
    look(st)
    if (has_tpl) report.module['module: ' + printer.printNode(ts.EmitHint.Unspecified, st, sf).split('\n')[0].slice(0, 50)] = 'a multi-line template string at module level: IMPORT() takes 4 spaces off each of its lines'
}
out.push('')

for (const m of members) {
    const name = member_name(m)
    // comments and regions between members: carried, dedented to column 0
    const lead = (ts.getLeadingCommentRanges(code, m.getFullStart()) || []).map(r => code.slice(r.pos, r.end))
    for (const c of lead) out.push(dedent4(c.replace(/^\s+/, '')))
    if (ts.isMethodDeclaration(m)) {
        const async = m.modifiers?.some(x => x.kind === ts.SyntaxKind.AsyncKeyword) ? 'async ' : ''
        let params = m.parameters.map(p => p.getText(sf)).join(', ')
        let ret = m.type ? ': ' + m.type.getText(sf) : ''
        // braces in a return type break the header too; types don't run, so it says any
        if (/[{}]/.test(ret)) { ret = ': any'; report.rewritten[name] = (report.rewritten[name] ? report.rewritten[name] + '; ' : '') + 'a braced return type → any' }
        const body_block = m.body
        if (!body_block) { report.refused.push(name + ': no body'); continue }
        // the body between its braces, verbatim — but for one shape the .g compiler reads as its own sugar: an if whose else
        //  starts on a later line with no braces (`if (ok) a\n else b`) becomes "} else {" in the output and breaks.  Those get
        //   braces, exactly (same statements, same order), and the member is named as rewritten
        const b0 = body_block.getStart(sf) + 1, b1 = body_block.getEnd() - 1
        const edits = []
        const braced = (node) => {
            if (ts.isIfStatement(node) && node.elseStatement && !ts.isBlock(node.thenStatement) && !ts.isBlock(node.elseStatement)
                && !ts.isIfStatement(node.elseStatement)
                && sf.getLineAndCharacterOfPosition(node.elseStatement.getStart(sf)).line > sf.getLineAndCharacterOfPosition(node.thenStatement.getStart(sf)).line) {
                const line_start = code.lastIndexOf('\n', node.getStart(sf)) + 1
                const ind = code.slice(line_start, node.getStart(sf))
                const text = `if (${node.expression.getText(sf)}) {\n${ind}    ${node.thenStatement.getText(sf)}\n${ind}} else {\n${ind}    ${node.elseStatement.getText(sf)}\n${ind}}`
                edits.push([node.getStart(sf), node.getEnd(), text])
                return
            }
            ts.forEachChild(node, braced)
        }
        braced(body_block)
        const n_braced = edits.length
        // inside a template string's ${…} the .g compiler applies its &method call sugar to the
        //  TEXT, the same as anywhere else — `a&&b` (tight, as TS's own printer emits) used to come
        //  out `a & this.b()` (story_save, caught by --prove): the per-char scan forgot the first "&"
        //  of the pair by the time it reached the second.  FIXED in the .g compiler (Lang_amp_calls_in_text,
        //  2026-10-22): "&&" is now consumed as one atomic unit, so a `${a && b}` substitution needs no
        //  rewrite — it is real code and the compiler reads it as such.  No `&&`-rewrite pass here any more.
        let n_prop = 0
        const props = (node) => {
            if (ts.isPropertyAccessExpression(node) && node.expression.kind === ts.SyntaxKind.ThisKeyword && data_props.has(node.name.text)) {
                const p = node.parent
                const called = ts.isCallExpression(p) && p.expression === node
                const written = ts.isBinaryExpression(p) && p.left === node && p.operatorToken.kind >= ts.SyntaxKind.FirstAssignment && p.operatorToken.kind <= ts.SyntaxKind.LastAssignment
                const reached = ts.isPropertyAccessExpression(p) || ts.isElementAccessExpression(p)
                if (written || reached) { report.refused.push(`${name}: ${written ? 'writes' : 'reaches into'} this.${node.name.text}, a data property ported as a method — it would act on a fresh copy`); return }
                if (!called) { edits.push([node.getStart(sf), node.getEnd(), node.getText(sf) + '()']); n_prop++ }
                return
            }
            ts.forEachChild(node, props)
        }
        props(body_block)
        if (n_prop) report.rewritten[name] = (report.rewritten[name] ? report.rewritten[name] + '; ' : '') + n_prop + ' read(s) of a data property ported as a method → a call'
        // "&&" is real code to the .g compiler now (fixed); a LONE "&" inside a substitution is still
        //  read as call sugar (same rule as everywhere else in a .g) and can't be ported exactly: refuse.
        //  Strip "&&" pairs first so this never misreads one of those as the thing it's checking for.
        const amp_left = (() => { let bad = 0; const look = (node) => { if (ts.isTemplateSpan(node) && node.expression.getText(sf).replace(/&&/g, '').includes('&')) bad++; ts.forEachChild(node, look) }; look(body_block); return bad })()
        if (amp_left) { report.refused.push(name + ': a template substitution holds an & that isn\'t && — the .g compiler would read it as call sugar'); continue }
        // the .g compiler makes a method async when it holds an `await` ANYWHERE — even inside a nested arrow — which turns a
        //  sync method's return value into a Promise (Story_plan's caller uses it at once).  So a sync method's nested
        //   `async () => await x` (one awaited expression, nothing else) becomes `() => x`: the same promise, the same rejection.
        //    Any other await left inside a sync method is refused
        const is_async = m.modifiers?.some(x => x.kind === ts.SyntaxKind.AsyncKeyword)
        if (!is_async) {
            const unawait = (node) => {
                if (ts.isArrowFunction(node) && node.modifiers?.some(x => x.kind === ts.SyntaxKind.AsyncKeyword)
                    && ts.isAwaitExpression(node.body)) {
                    const params = node.parameters.map(p => p.getText(sf)).join(', ')
                    edits.push([node.getStart(sf), node.getEnd(), `(${params}) => ${node.body.expression.getText(sf)}`])
                    return
                }
                ts.forEachChild(node, unawait)
            }
            unawait(body_block)
            const awaits_left = (() => {
                let n = 0
                const count = (node) => {
                    if (ts.isAwaitExpression(node) && !edits.some(([a, z]) => node.getStart(sf) >= a && node.getEnd() <= z)) n++
                    ts.forEachChild(node, count)
                }
                count(body_block)
                return n
            })()
            if (awaits_left && allow_async.has(name)) report.rewritten[name] = (report.rewritten[name] ? report.rewritten[name] + '; ' : '') + `made async by the .g compiler (${awaits_left} nested awaits) — allowed: callers ignore its return; a sync throw becomes a rejection`
            else if (awaits_left) report.refused.push(`${name}: sync, but holds ${awaits_left} nested await(s) the .g compiler would make it async for`)
            else if (edits.some(e => /^\(.*\) => /.test(e[2]))) report.rewritten[name] = (report.rewritten[name] ? report.rewritten[name] + '; ' : '') + 'nested async () => await x → () => x (stays sync)'
        }
        let inner = code.slice(b0, b1)
        for (const [a, z, text] of edits.sort((x, y) => y[0] - x[0])) inner = inner.slice(0, a - b0) + text + inner.slice(z - b0)
        if (n_braced) report.rewritten[name] = (report.rewritten[name] ? report.rewritten[name] + '; ' : '') + n_braced + ' braceless if/else on two lines braced'
        inner = inner.replace(/^[ \t]*\n/, '').replace(/\n[ \t]*$/, '')
        let pre = []
        if (/[{}]/.test(params)) {
            // braces in a header: rewrite each offending param exactly — a destructured one becomes _argN + the same
            //  destructuring as the body's first line; a default with braces moves into the body as `x = x === undefined ? … : x`
            const ps = []
            m.parameters.forEach((p, i) => {
                const t = p.getText(sf)
                if (!/[{}]/.test(t)) { ps.push(t); return }
                if (ts.isObjectBindingPattern(p.name) || ts.isArrayBindingPattern(p.name)) {
                    const arg = '_arg' + i
                    const init = p.initializer ? ` === undefined ? ${p.initializer.getText(sf)} : ${arg}` : ''
                    ps.push(arg + (p.questionToken || p.initializer ? '?' : ''))
                    pre.push(`let ${p.name.getText(sf)} = ${init ? '(' + arg + init + ')' : arg}`)
                } else {
                    const id = p.name.getText(sf)
                    ps.push(id + (p.initializer ? '?' : ''))
                    if (p.initializer) pre.push(`${id} = ${id} === undefined ? ${p.initializer.getText(sf)} : ${id}`)
                }
            })
            params = ps.join(', ')
            report.rewritten[name] = 'braces in the header moved into the body'
        }
        // a type naming `typeof this.x` is TS the .g compiler's parse check can't read; types don't run, so it becomes any
        if (/typeof this\./.test(inner)) {
            inner = inner.replace(/ReturnType<typeof this\.[A-Za-z_$][\w$]*>/g, 'any')
            if (/typeof this\./.test(inner)) { report.refused.push(name + ': a type naming typeof this.… that isn\'t ReturnType<…>'); continue }
            report.rewritten[name] = (report.rewritten[name] ? report.rewritten[name] + '; ' : '') + 'ReturnType<typeof this.…> → any'
        }
        const body_lines = lines_of(inner)
        const col0 = body_lines.filter(l => /^\S/.test(l))
        if (col0.length) { report.refused.push(`${name}: ${col0.length} body line(s) at column 0 (a template string?) — first: ${col0[0].slice(0, 60)}`); continue }
        const indent = (body_lines.find(l => l.trim()) || '        ').match(/^\s*/)[0] || '        '
        out.push(`${async}${name}(${params})${ret}:`)
        for (const p of pre) out.push(indent + p)
        out.push(...body_lines)
        out.push('')
    } else if (ts.isPropertyAssignment(m)) {
        // a data property: a .g has none.  Ported as a method returning it — callers must accept either shape
        const init = m.initializer.getText(sf)
        const reindented = lines_of(init).map((l, i) => i === 0 ? l : '    ' + l).join('\n')
        out.push(`${name}():`)
        out.push(`        return ${reindented}`)
        out.push('')
        report.rewritten[name] = 'data property → a method returning it (callers: this.' + name + '?.() ?? this.' + name + ')'
    } else {
        report.refused.push(`${name}: a ${ts.SyntaxKind[m.kind]} — the .g compiler has no shape for it`)
    }
}
out.push('// (ends on a comment — a .g must not end on a method-final brace)')

fs.writeFileSync(out_path, out.join('\n') + '\n')
fs.writeFileSync(out_path.replace(/\.g$/, '.port.json'), JSON.stringify({ from: src_path, ...report }, null, 1) + '\n')
console.log(`${members.length} members → ${out_path}`)
console.log(`rewritten ${Object.keys(report.rewritten).length}: ${Object.entries(report.rewritten).map(([k, v]) => k + ' (' + v + ')').join('; ') || '—'}`)
console.log(`refused ${report.refused.length}${report.refused.length ? ':\n  ' + report.refused.join('\n  ') : ''}`)
for (const n of report.notes) console.log('note: ' + n)
process.exit(report.refused.length ? 1 : 0)
