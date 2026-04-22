<script lang="ts">
    // LangCompiling.svelte — compilation guts for the stho-language.
    //
    // Lang.svelte joins features at a high level; the guts live here so that
    // translation can grow (Sunpit bodies, Se, Flug …) without Lang.svelte
    // turning into a mass of helpers.
    //
    // Deposits onto H via M.eatfunc():
    //
    //   Lang_compile(A, w)
    //     Entry.  Walks the document line-by-line; passes each line through
    //     verbatim, swapping only the IOing/Sunpit span (if any) for its
    //     translated JS. Kicks off the rw_op 'write' via the Wormhole,
    //     and stashes w/Compile/Output...
    //
    //   Lang_compile_step(A, w)
    //     Called from Lang(A,w) on every tick while w.c.compile_pending is set.
    //     Re-polls i_elvis_req; when the Wormhole reply lands, notifies
    //     Pantheate via Ghost_update_notify and clears the flag.
    //
    //   Translation:
    //     Lang_compile_collect(state)    → per-Line  {kind:'translated'|'raw', text}
    //     Lang_compile_IOing(node,…)     → one TS expression
    //     Lang_compile_Sunpit(node,…)    → one TS for-of header
    //     Lang_compile_Leg(node,…)       → {sc_src, exactly_src, receiver_hint?, capture_var?}
    //     Lang_compile_PeelItem(node,…)  → one property in the sc (+exactly flag)
    //     Lang_compile_PeelVal(node,…)   → value expression (literal number or identifier)
    //     Lang_compile_leg_obj_src(leg)  → {sc:…, exactly:…}  — the JSON-ish
    //                                       shape backend helpers receive
    //
    // Translation rules (from the regroup() spec, in summary):
    //
    //   Receiver detection — if the first leg is a single bare-$name key
    //   (e.g. "$la" in "o $la/something"), that name is the JS variable the
    //   chain starts from.  Otherwise the receiver is w.
    //
    //   Tier 0 (single-leg, inline — clean native JS, easy to read):
    //     i foo          → receiver.i({foo: 1})
    //     o foo          → receiver.o({foo: 1})
    //     o foo$         → let foo = receiver.o({foo: 1})[0]
    //     o foo:3        → receiver.o({foo: 3}, { exactly: {foo: true} })
    //
    //   Tier 1 (multi-leg → backend function on H, defined in LangSion.svelte):
    //     i a/b/c        → this._i_drill(receiver, [{sc:{a:1}}, {sc:{b:1}}, {sc:{c:1}}])
    //     o a/b/c        → this._o_drill(receiver, [{sc:{a:1}}, {sc:{b:1}}, {sc:{c:1}}])
    //     o a/b$         → let b = this._o_drill1(receiver, [{sc:{a:1}}, {sc:{b:1}}])
    //     S o a/b        → for (const b of this._o_iter(receiver,
    //                        [{sc:{a:1}}, {sc:{b:1}}])) {
    //                          <indented body lines, translated>
    //                        }   — pythonic-indented body capture
    //
    //   Key shapes within an sc:
    //     $name as a key → {name}   (ES6 shorthand; uses the variable `name` in scope)
    //     key:$var       → {key: var}
    //     key:3          → {key: 3}  (+ exactly_for:'key')
    //     key            → {key: 1}  (wildcard)
    //
    //   .i drops `exactly` from its leg objects (insertion doesn't filter).
    //   .o / Sunpit keep it so the helper can pass { exactly } along to C.o().
    //
    // Output shape (render_module): a .svelte ghost file carrying
    //
    //   <script lang="ts">
    //     ...imports...
    //     let { H } = $props()
    //     onMount(async () => {
    //         await H.eatfunc({
    //             // …user's verbatim source with IOing/Sunpit substituted…
    //         })
    //     })
    //   </anotherScriptTag>
    //
    // Pantheate dynamic-imports it and picks up its deposited methods via
    // ghostsHaunt, same as any other ghost file.  theCompiledStuff is just
    // an example function name; the user may write any number of methods
    // as long as they're comma-separated inside the eatfunc's object literal.

    import { TheC } from "$lib/data/Stuff.svelte"
    import { dig } from "$lib/Y.svelte";
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import type { SyntaxNode } from "@lezer/common"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region entry

    // Beliefs-time entry for the compile action button.
    // Fired via elvisto so Story can detect Lang settling after a compile.
    async e_Lang_compile(A: TheC, w: TheC, _e: TheC) {
        await this.Lang_compile(A, w)
    },
    // Fired by the "compile" action button in Lang_plan.  Synchronously
    // builds the module source (so the user gets immediate {result:1} chunks
    // to inspect even if the disk write is slow), then kicks off the Wormhole
    // write request and hands off to Lang_compile_step for the reply phase.
    async Lang_compile(A: TheC, w: TheC) {
        const H = this

        const state = w.c.editorState as EditorState | undefined
        if (!state) { w.i({ see: '⚠ Lang_compile: no editorState yet' }); return }

        // clear previous outputs / errors so a fresh compile is visible
        await w.r({ compile_error: 1 }, {})

        let source: string
        try {
            const lines = this.Lang_compile_collect(state)

            // < maybe pile up interesting objects...
            let translated_i = 0
            for (let i = 0; i < lines.length; i++) {
                const ln = lines[i]
                if (0 && ln.kind === 'translated') {
                    w.i({
                        result: 1, chunk_i: translated_i++,
                        line_number: i + 1,
                        str: ln.text,
                    })
                }
            }

            const body = lines.map(l => l.text).join('\n')
            source = this.Lang_compile_render_module(body)
        } catch (err: any) {
            w.i({ compile_error: 1, msg: String(err?.message ?? err), stack: err?.stack ?? '' })
            return
        }

        // Park the job as a particle so Lang_compile_step (and Story) can
        // observe it properly.  Large source stays in .c to keep sc clean.
        const job = w.oai({ Compile: 1 })
        job.empty()
        job.oai({Output:1,name:'Somewhere.go',source,dige:await dig(source)})
        job.oai({Pending: 1})
        H.elvisto(w, 'think')
    },

    // Called from Lang(A,w) while compile_pending.  The Wormhole will
    // 'think' us back when the write completes (see o_elvis_req.finish),
    // and that re-runs Lang(A,w) which re-enters this.
    async Lang_compile_step(A: TheC, w: TheC) {
        const H = this
        const job = w.o({ Compile: 1 })[0] as TheC | undefined
        if (!job) throw "!job"
        if (!job.oa({Pending:1})) return
        let [ou,...more] = job.o({Output:1})
        if (more.length) throw "many job/Output"

        // stable req lives on w so we don't re-send on every tick
        const req = w.oai(
            { compile_write: 1 },
            {
                rw_op:   'write',
                rw_name: `src/lib/gen/${ou.sc.name}`,
                rw_data: ou.sc.source,
            },
        )

        const done = H.i_elvis_req(w, 'Wormhole/Wormhole', 'rw_op', { req })
        if (!done) return   // still waiting; Wormhole will 'think' us when finished

        // reply is in
        const reply = req.sc.reply
        if (reply?.error) {
            w.i({ compile_error: 1, msg: `write gen: ${reply.error}` })
        } else {
            w.i({ see: `📝 wrote src/lib/gen/${ou.sc.name}` })
            // notify Pantheate so it require()s the fresh module
            H.elvisto('Pantheate/Pantheate', 'Ghost_update_notify',
                { include: ou.sc.name })
        }

        // cleanup
        await w.r({ compile_write: 1 }, {})
        // Compile stays until the next job comes in
        await job.r({Pending:1},{})
    },

//#endregion
//#region collect

    // Walk the document line-by-line (via doc.line(n), independent of the
    // syntax tree's own Line recovery).  For each doc-line we look into the
    // syntax tree for the first IOing or Sunpit node strictly within the
    // line's [from..to] range:
    //
    //   - found → substitute translated TS for the expression's span,
    //             keeping the line's leading whitespace and anything after
    //             the expression verbatim.  kind: 'translated'.
    //   - not found → emit the line verbatim.  kind: 'raw'.
    //
    // This is how we "keep whole lines we don't understand" — the
    // `theCompiledStuff(A,w) {` header, `[3]`, bare JS like
    // `let val = because.sc.it`, the closing `}`, blank lines, comments
    // all pass through unchanged.
    Lang_compile_collect(state: EditorState): Array<{
        kind: 'translated' | 'raw',
        text: string,
    }> {
        const tree = syntaxTree(state)
        const doc  = state.doc
        const out: Array<{ kind: 'translated' | 'raw', text: string }> = []

        let n = 1
        while (n <= doc.lines) {
            n = this._collect_line(n, tree, doc, state, out)
        }
        return out
    },

    // Process doc-line n, push result(s) into out, return next n to process.
    // For Sunpit: also consumes indented body lines and closes the brace.
    _collect_line(n: number, tree, doc, state: EditorState, out): number {
        const line = doc.line(n)

        // first IOing/Sunpit whose span lies within this doc line
        let hit: { name: string, node: SyntaxNode } | null = null
        tree.iterate({
            from: line.from,
            to:   line.to,
            enter: (ref) => {
                if (hit) return false
                if ((ref.name === 'IOing' || ref.name === 'Sunpit' || ref.name === 'ControlFlow')
                        && ref.from >= line.from && ref.to <= line.to) {
                    hit = { name: ref.name, node: ref.node }
                    return false
                }
            },
        })

        if (hit?.name === 'Sunpit') {
            // emit the for-header (open brace only; _collect_line closes it below)
            const header  = this.Lang_compile_Sunpit(hit.node, state, {})
            const before  = line.text.slice(0, hit.node.from - line.from)
            out.push({ kind: 'translated', text: before + header })
            n++

            // indentation of the `S` line — body must be strictly deeper
            const sunpit_indent = (line.text.match(/^(\s*)/) ?? ['',''])[1].length

            // consume and translate body lines while they are more indented
            while (n <= doc.lines) {
                const peek = doc.line(n)
                // blank lines stay inside the loop body
                if (peek.text.trim() === '') {
                    out.push({ kind: 'raw', text: peek.text })
                    n++
                    continue
                }
                const peek_indent = (peek.text.match(/^(\s*)/) ?? ['',''])[1].length
                if (peek_indent <= sunpit_indent) break  // body ended
                // recurse so nested Sunpits and IOings are translated too
                n = this._collect_line(n, tree, doc, state, out)
            }

            // closing brace aligned with the `S` line
            out.push({ kind: 'raw', text: ' '.repeat(sunpit_indent) + '}' })
            return n
        }

        if (hit?.name === 'ControlFlow') {
            const headNode  = hit.node.getChild('ControlFlowHead')
            const titleNode = hit.node.getChild('Title')
            // keyword is "if", "for", "while", "until", "else if", "elsif", or "else"
            const keyword   = state.doc.sliceString(headNode.from, headNode.to).trim()
            let condition   = titleNode
                ? state.doc.sliceString(titleNode.from, titleNode.to).trim()
                : ''
            const before     = line.text.slice(0, hit.node.from - line.from)
            const cf_indent  = (line.text.match(/^(\s*)/) ?? ['', ''])[1].length

            // bail to verbatim — user wrote their own brackets, or condition
            // contains a // comment (which would eat our closing ") {")
            if (condition.startsWith('(') || condition.includes('//')) {
                out.push({ kind: 'raw', text: line.text })
                return n + 1
            }

            n++

            // consume continuation lines — operators that can only open a
            // continuation (&&, || spelled fully; also ternary/chain: ?, :, .)
            const CONTINUATION = /^\s*(&&|\|\||[?:.])/
            while (n <= doc.lines) {
                const peek = doc.line(n)
                if (!CONTINUATION.test(peek.text)) break
                condition += ' ' + peek.text.trim()
                n++
            }

            // emit header — ") {" lands on this line, after the full condition
            let header: string
            if (keyword === 'else') {
                header = `${before}} else {`
            } else if (keyword === 'else if' || keyword === 'elsif') {
                header = `${before}} else if (${condition}) {`
            } else {
                // if, for, while, until
                header = `${before}${keyword} (${condition}) {`
            }
            out.push({ kind: 'translated', text: header })

            // consume indented body lines (same pattern as Sunpit)
            while (n <= doc.lines) {
                const peek = doc.line(n)
                if (peek.text.trim() === '') {
                    out.push({ kind: 'raw', text: peek.text })
                    n++
                    continue
                }
                const peek_indent = (peek.text.match(/^(\s*)/) ?? ['', ''])[1].length
                if (peek_indent <= cf_indent) break
                n = this._collect_line(n, tree, doc, state, out)
            }

            // closing brace — suppressed when the very next same-indent line is
            // else-family, which will open with "} else {" itself
            const ELSE_FAMILY = /^\s*(else\b|elsif\s)/
            const nextLine   = n <= doc.lines ? doc.line(n) : null
            const nextIsElse = nextLine
                && (nextLine.text.match(/^(\s*)/) ?? ['', ''])[1].length === cf_indent
                && ELSE_FAMILY.test(nextLine.text)
            if (!nextIsElse) {
                out.push({ kind: 'raw', text: ' '.repeat(cf_indent) + '}' })
            }

            return n
        }

        if (hit?.name === 'IOing') {
            const translated = this.Lang_compile_IOing(hit.node, state, {})
            const before = line.text.slice(0, hit.node.from - line.from)
            const after  = line.text.slice(hit.node.to   - line.from)
            out.push({ kind: 'translated', text: before + translated + after })
        } else {
            out.push({ kind: 'raw', text: line.text })
        }
        return n + 1
    },

//#endregion
//#region IOing

    // IOing → one TS expression.  The optional capture ("name$" on the last
    // leg) turns the whole expression into `let name = …` with a trailing
    // [0]-style first-pick, whichever form the tier uses.
    Lang_compile_IOing(node: SyntaxNode, state: EditorState, ctx: any): string {
        const ness = this.Lang_compile_IOness(node, state)
        const pathNode = node.getChild('IOpath')
        if (!pathNode) throw new Error('IOing: no IOpath')
        const legNodes = pathNode.getChildren('Leg')
        if (!legNodes.length) throw new Error('IOing: empty IOpath')

        const legs = legNodes.map((l: SyntaxNode) => this.Lang_compile_Leg(l, state, ctx))

        // receiver detection on leg 0 — a single bare "$name" hints the JS var
        let receiver = 'w'
        let startIdx = 0
        if (legs[0].receiver_hint) {
            receiver = legs[0].receiver_hint
            startIdx = 1
        }

        // remaining path after any receiver hint — this is the "real" path
        // the tiers branch on.  (.at(-1) because JS destructuring doesn't
        // allow [...rest, tail] — rest elements must be last.)
        const path = legs.slice(startIdx)
        const tail = path.at(-1)

        let prefix = ''
        if (tail?.capture_var) {
            prefix = `let ${tail.capture_var} = `
        }

        if (!path.length) {
            // pathological: only a receiver hint, no real legs
            return `${prefix}${receiver}`
        }

        // ── tier 0: single-leg, inline ──────────────────────────────
        if (path.length === 1) {
            const only = tail!
            if (ness === 'i') {
                return `${prefix}${receiver}.i(${only.sc_src})`
            }
            // o
            const q = only.exactly_src ? `, { exactly: ${only.exactly_src} }` : ''
            if (only.capture_var) {
                return `${prefix}${receiver}.o(${only.sc_src}${q})[0]`
            }
            return `${prefix}${receiver}.o(${only.sc_src}${q})`
        }

        // ── tier 1: multi-leg → backend function on H ───────────────
        // .i ignores `exactly` so don't bother emitting it in the leg objects;
        // .o / Sunpit keep it so the helper can forward it to C.o().
        const include_exactly = ness === 'o'
        const legs_src = path
            .map(l => this.Lang_compile_leg_obj_src(l, { include_exactly }))
            .join(', ')

        if (ness === 'i') {
            return `${prefix}this._i_drill(${receiver}, [${legs_src}])`
        }
        const helper = tail!.capture_var ? '_o_drill1' : '_o_drill'
        return `${prefix}this.${helper}(${receiver}, [${legs_src}])`
    },

//#endregion
//#region Sunpit

    // Sunpit := "S " IOing
    // Emits only the for-of header (open brace).  Lang_compile_collect's
    // _collect_line captures the pythonic-indented body and appends the
    // closing }.
    //
    //   S o yeses/because
    //     → for (const because of this._o_iter(w, [{sc:{yeses:1}}, {sc:{because:1}}])) {
    Lang_compile_Sunpit(node: SyntaxNode, state: EditorState, ctx: any): string {
        const ioing = node.getChild('IOing')
        if (!ioing) throw new Error('Sunpit: no IOing')

        const ness = this.Lang_compile_IOness(ioing, state)
        const pathNode = ioing.getChild('IOpath')
        if (!pathNode) throw new Error('Sunpit IOing: no IOpath')
        const legNodes = pathNode.getChildren('Leg')
        if (!legNodes.length) throw new Error('Sunpit IOing: empty IOpath')
        const legs = legNodes.map((l: SyntaxNode) => this.Lang_compile_Leg(l, state, ctx))

        let receiver = 'w'
        let startIdx = 0
        if (legs[0].receiver_hint) {
            receiver = legs[0].receiver_hint
            startIdx = 1
        }

        const path = legs.slice(startIdx)
        if (!path.length) return `/* S ${ness}: empty path */`

        // iterator name = the last leg's single bare-Name key, else __n
        let iter_var = '__n'
        const tailLegNode = legNodes[legNodes.length - 1]
        const tailItems = tailLegNode.getChild('PeelGroup')?.getChildren('PeelItem') ?? []
        if (tailItems.length === 1) {
            const kNode = tailItems[0].getChild('PeelKey')?.getChild('Name')
            if (kNode) iter_var = state.doc.sliceString(kNode.from, kNode.to)
        }

        const legs_src = path
            .map(l => this.Lang_compile_leg_obj_src(l))
            .join(', ')
        const prefix = ness === 'i' ? '/* S i */ ' : ''
        return `${prefix}for (const ${iter_var} of this._o_iter(${receiver}, [${legs_src}])) {`
    },

//#endregion
//#region Leg / PeelGroup / PeelItem

    // One Leg = one PeelGroup = comma-separated PeelItems = a single sc {…}
    // plus an optional exactly:{…} for keys that carry an explicit value.
    //
    // A Leg with exactly one PeelItem can also surface a receiver_hint (leg 0)
    // or a capture_var (last leg) — picked up by IOing/Sunpit.
    Lang_compile_Leg(leg: SyntaxNode, state: EditorState, ctx: any): {
        sc_src: string,
        exactly_src: string,
        receiver_hint?: string,
        capture_var?: string,
    } {
        const group = leg.getChild('PeelGroup')
        if (!group) throw new Error('Leg: no PeelGroup')
        const items = group.getChildren('PeelItem')
        if (!items.length) throw new Error('Leg: empty PeelGroup')

        // probe for receiver / capture on a single-item leg
        let receiver_hint: string | undefined
        let capture_var: string | undefined
        if (items.length === 1) {
            const probe = this.Lang_compile_PeelItem(
                items[0], state, { ...ctx, probe: true })
            if (probe.receiver_hint) receiver_hint = probe.receiver_hint
            if (probe.capture_var)   capture_var   = probe.capture_var
        }

        // normal rendering
        const parts: string[] = []
        const exactly_keys: string[] = []
        for (const it of items) {
            const info = this.Lang_compile_PeelItem(it, state, ctx)
            if (info.sc_part) parts.push(info.sc_part)
            if (info.exactly_for) exactly_keys.push(info.exactly_for)
        }

        const sc_src = `{${parts.join(', ')}}`
        const exactly_src = exactly_keys.length
            ? `{${exactly_keys.map(k => `${k}: true`).join(', ')}}`
            : ''

        return { sc_src, exactly_src, receiver_hint, capture_var }
    },

    // One PeelItem → {sc_part, exactly_for?} plus probe flags.
    //
    //   name           →  name: 1              (wildcard, no exactly)
    //   $name          →  name                 (ES6 shorthand; var `name` in scope)
    //                     or receiver_hint=name when probe=true and no value
    //   name$          →  capture_var=name; sc_part still "name: 1" so the
    //                     final .o({name:1})[0] can pick the row out
    //   name:3         →  name: 3              (+ exactly_for:'name')
    //   name:$v        →  name: v              (+ exactly_for:'name')
    //   name:other     →  name: other          (+ exactly_for:'name')
    Lang_compile_PeelItem(item: SyntaxNode, state: EditorState, ctx: any): {
        sc_part: string,
        exactly_for?: string,
        receiver_hint?: string,
        capture_var?: string,
    } {
        const doc = state.doc
        const keyNode = item.getChild('PeelKey')
        const valNode = item.getChild('PeelVal')
        if (!keyNode) throw new Error('PeelItem: no PeelKey')

        const keyNameNode = keyNode.getChild('Name')
        if (!keyNameNode) throw new Error('PeelKey: no Name')
        const name = doc.sliceString(keyNameNode.from, keyNameNode.to)

        // sigils on PeelKey: may appear before and/or after Name
        const sigils = keyNode.getChildren('Sigil')
        const before = sigils.find((s: SyntaxNode) => s.to <= keyNameNode.from)
        const after  = sigils.find((s: SyntaxNode) => s.from >= keyNameNode.to)

        // capture:  name$  with no value
        if (after && !valNode) {
            return { sc_part: `${name}: 1`, capture_var: name }
        }

        // receiver hint / shorthand:  $name  with no value
        if (before && !valNode) {
            if (ctx.probe) return { sc_part: '', receiver_hint: name }
            // ES6 shorthand — uses the variable `name` as both key and value
            return { sc_part: name }
        }

        if (!valNode) {
            // bare name — wildcard
            return { sc_part: `${name}: 1` }
        }

        // has a colon-value → exactly, value comes from PeelVal
        const val_src = this.Lang_compile_PeelVal(valNode, state)
        return { sc_part: `${name}: ${val_src}`, exactly_for: name }
    },

    Lang_compile_PeelVal(val: SyntaxNode, state: EditorState): string {
        const doc = state.doc
        const numNode = val.getChild('Number')
        if (numNode) return doc.sliceString(numNode.from, numNode.to)
        const nameNode = val.getChild('Name')
        if (!nameNode) throw new Error('PeelVal: no Number or Name')
        // Name in PeelVal is always an identifier — whether the user wrote
        // `$val` or just `val`, they mean the variable `val` in scope.
        return doc.sliceString(nameNode.from, nameNode.to)
    },

    // IOness is "i " | "o " — trim to one of the two
    Lang_compile_IOness(node: SyntaxNode, state: EditorState): 'i' | 'o' {
        const ness = node.getChild('IOness')
        if (!ness) throw new Error('no IOness')
        const s = state.doc.sliceString(ness.from, ness.to).trim()
        if (s === 'i') return 'i'
        if (s === 'o') return 'o'
        throw new Error(`IOness unknown: "${s}"`)
    },

    // Serialise a Leg into the JSON-ish shape the backend helpers receive:
    //   {sc: <sc_src>}                              — default
    //   {sc: <sc_src>, exactly: <exactly_src>}      — when exactly is set & requested
    // For .i calls we drop exactly entirely since insertion doesn't filter.
    Lang_compile_leg_obj_src(leg: {
        sc_src: string, exactly_src: string,
    }, opt: { include_exactly?: boolean } = {}): string {
        const include = opt.include_exactly ?? true
        if (include && leg.exactly_src) {
            return `{sc: ${leg.sc_src}, exactly: ${leg.exactly_src}}`
        }
        return `{sc: ${leg.sc_src}}`
    },

//#endregion
//#region rendering

    // Wrap the user's (partially-translated) body in a Svelte ghost module
    // Pantheate can dynamic-import.  The shape is minimal — just the script
    // tag Svelte needs, plus `await H.eatfunc({ … })` around the user's
    // source.  Function names, braces, commas between methods etc. all come
    // from the user — we don't inject theCompiledStuff or any other wrapper.
    Lang_compile_render_module(body: string): string {
        // dodge Svelte's script-tag tokenizer, which will get confused even
        // by closing script tags in comments
        const OPEN  = '<' + 'script lang="ts">'
        const CLOSE = '<' + '/script>'
        return (
`${OPEN}
    // GENERATED by Lang compile — do not edit by hand.
    import { TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    let { H } = $props()

    onMount(async () => {
    await H.eatfunc({

${body}

    })
    })
${CLOSE}
`
        )
    },


    })
    })
</script>