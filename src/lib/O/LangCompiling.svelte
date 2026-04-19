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
    //     Entry.  Collects expressions from the current editorState, translates
    //     them, assembles a <script> module, kicks off the rw_op 'write' through
    //     the Wormhole.  Stashes the pending request on w so Lang_compile_step
    //     can pick it up next tick.  Also publishes per-chunk {result:1,...}
    //     particles on w/** for inspection/testing.
    //
    //   Lang_compile_step(A, w)
    //     Called from Lang(A,w) on every tick while w.c.compile_pending is set.
    //     Re-polls i_elvis_req; when the Wormhole reply lands, notifies
    //     Pantheate via Ghost_update_notify and clears the flag.
    //
    //   Translation:
    //     Lang_compile_collect(state)   → top-level {IOing|Sunpit|raw} chunks
    //     Lang_compile_IOing(node,…)    → one TS statement
    //     Lang_compile_Sunpit(node,…)   → one TS for-of header
    //     Lang_compile_Leg(node,…)      → {sc_src, exactly_src, receiver_hint?, capture_var?}
    //     Lang_compile_PeelItem(node,…) → one property in the sc (+exactly flag)
    //     Lang_compile_PeelVal(node,…)  → value expression (literal number or identifier)
    //
    // Translation rules (from the regroup() spec, in summary):
    //
    //   Receiver detection — if the first leg is a single bare-$name key
    //   (e.g. "$la" in "o $la/something"), that name is the JS variable the
    //   chain starts from.  Otherwise the receiver is w.
    //
    //   i path            → receiver.i({leg0}).i({leg1})…
    //   o single leg      → receiver.o({leg})[, {exactly:{…}}]
    //   o multi-leg       → receiver.oa({leg0})?.[0]?.oa({leg1})?.[0]?.o({legN}[, q])
    //                        — wrapped in ( … ?? [] ) so an intermediate miss is []
    //   o with name$      → last leg is a single bare-name$ capture; the whole
    //                        statement becomes  let name = …  .o({name:1})[0]
    //   $name as a key    → {name}  (shorthand, uses the variable in scope)
    //   key:$var          → {key: var}   (identifier)
    //   key:3             → {key: 3}     (number literal)
    //   any key with :val → lands in exactly:{key:true} so o() does a strict match
    //
    //   S <IOing>         → for (const <iter> of (<iterable>)) { /* body… */ }
    //                        — pythonic-indented body is phase 3, see regroup()
    //
    // Output: wrapped as a ghost module at src/lib/gen/Somewhere.svelte containing
    //   await M.eatfunc({ async theCompiledStuff(A, w) { … } })
    // Pantheate picks it up via w/{include:'Somewhere.svelte'} after we post
    // Ghost_update_notify.

    import { TheC } from "$lib/data/Stuff.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import type { SyntaxNode } from "@lezer/common"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region entry

    // Fired by the "compile" action button in Lang_plan.  Synchronously
    // builds the module source (so the user gets immediate {result:1} chunks
    // to inspect even if the disk write is slow), then kicks off the Wormhole
    // write request and hands off to Lang_compile_step for the reply phase.
    async Lang_compile(A: TheC, w: TheC) {
        const H = this

        const state = w.c.editorState as EditorState | undefined
        if (!state) { w.i({ see: '⚠ Lang_compile: no editorState yet' }); return }

        // clear previous outputs / errors so a fresh compile is visible
        await w.r({ result: 1 }, {})
        await w.r({ compile_error: 1 }, {})

        let file_source: string
        try {
            const chunks = this.Lang_compile_collect(state)
            const fn_body_lines: string[] = []
            for (let i = 0; i < chunks.length; i++) {
                const ch = chunks[i]
                const ctx = { indent: '        ' }
                let str = ''
                if (ch.kind === 'IOing')       str = this.Lang_compile_IOing(ch.node!, state, ctx)
                else if (ch.kind === 'Sunpit') str = this.Lang_compile_Sunpit(ch.node!, state, ctx)
                else                            str = ch.text!       // 'raw' fallback — a comment
                fn_body_lines.push(str)

                // meaningfully split so w/** is testable per spec
                w.i({
                    result: 1, chunk_i: i,
                    kind: ch.kind,
                    from: ch.from, to: ch.to,
                    str,
                })
            }

            const fnName = 'theCompiledStuff'
            const fn_src = this.Lang_compile_render_fn(fnName, fn_body_lines)
            w.i({ result: 1, chunk_i: 'fn', name: fnName, str: fn_src })

            file_source = this.Lang_compile_render_module([fn_src])
            w.i({ result: 1, chunk_i: 'file', str: file_source })
        } catch (err: any) {
            w.i({ compile_error: 1, msg: String(err?.message ?? err), stack: err?.stack ?? '' })
            return
        }

        // stash the source to be written and flip the pending flag;
        // Lang(A,w) picks this up on the next tick via Lang_compile_step.
        w.c.compile_source = file_source
        w.c.compile_name   = 'Somewhere.svelte'
        w.c.compile_pending = true
        H.elvisto(w, 'think')
    },

    // Called from Lang(A,w) while compile_pending.  The Wormhole will
    // 'think' us back when the write completes (see o_elvis_req.finish),
    // and that re-runs Lang(A,w) which re-enters this.
    async Lang_compile_step(A: TheC, w: TheC) {
        const H = this
        if (!w.c.compile_pending) return

        // stable req lives on w so we don't re-send on every tick
        const req = w.oai(
            { compile_write: 1 },
            {
                rw_op:   'write',
                rw_name: `src/lib/gen/${w.c.compile_name}`,
                rw_data: w.c.compile_source,
            },
        )

        const done = H.i_elvis_req(w, 'Wormhole/Wormhole', 'rw_op', { req })
        if (!done) return   // still waiting; Wormhole will 'think' us when finished

        // reply is in
        const reply = req.sc.reply
        if (reply?.error) {
            w.i({ compile_error: 1, msg: `write gen: ${reply.error}` })
        } else {
            w.i({ see: `📝 wrote src/lib/gen/${w.c.compile_name}` })
            // notify Pantheate so it require()s the fresh module
            H.elvisto('Pantheate/Pantheate', 'Ghost_update_notify',
                { include: w.c.compile_name })
        }

        // cleanup so the next compile starts fresh
        await w.r({ compile_write: 1 }, {})
        w.c.compile_pending = false
        w.c.compile_source  = null
        w.c.compile_name    = null
    },

//#endregion
//#region collect

    // Walk the Lezer tree and pull out Line-level IOing / Sunpit nodes.
    // Lines that don't carry a translatable expression are kept as 'raw'
    // so their content survives as a // comment — the compile is additive,
    // not destructive.  Everything in Lang_default_text() that isn't stho
    // (the "theCompiledStuff(A,w) {" wrapper, "[3]", blank lines) lands here.
    Lang_compile_collect(state: EditorState): Array<{
        kind: 'IOing' | 'Sunpit' | 'raw',
        node?: SyntaxNode,
        text?: string,
        from: number,
        to: number,
    }> {
        const tree = syntaxTree(state)
        const doc = state.doc
        const out: any[] = []

        let ln = tree.topNode.firstChild
        while (ln) {
            if (ln.name === 'Line') {
                let handled = false
                let e = ln.firstChild
                while (e) {
                    if (e.name === 'IOing' || e.name === 'Sunpit') {
                        out.push({ kind: e.name, node: e, from: e.from, to: e.to })
                        handled = true
                        break
                    }
                    e = e.nextSibling
                }
                if (!handled) {
                    const raw = doc.sliceString(ln.from, ln.to)
                    const trimmed = raw.replace(/\s+$/, '')
                    // keep blank lines as blanks; everything else as a // comment
                    const text = trimmed.trim()
                        ? `// ${trimmed.replace(/^\s+/, '')}`
                        : ''
                    out.push({ kind: 'raw', text, from: ln.from, to: ln.to })
                }
            }
            ln = ln.nextSibling
        }
        return out
    },

//#endregion
//#region IOing

    // IOing → one TS statement.
    // The optional capture ("name$" on the last leg) turns the whole
    // statement into `let name = …`  with a trailing [0] on the final .o().
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

        // capture detection on the last leg — "name$" binds the result
        const lastLeg = legs[legs.length - 1]
        let prefix = ''
        let pick_first_on_tail = false
        if (lastLeg.capture_var) {
            prefix = `let ${lastLeg.capture_var} = `
            pick_first_on_tail = true
        }

        if (startIdx >= legs.length) {
            // pathological: only a receiver hint, no real legs; emit the bare var
            return `${prefix}${receiver}`
        }

        if (ness === 'i') {
            // .i chain — always returns TheC, no need for optional chaining
            let expr = receiver
            for (let i = startIdx; i < legs.length; i++) {
                expr += `.i(${legs[i].sc_src})`
            }
            return `${prefix}${expr}`
        }

        // o — drill with .oa(leg)?.[0] through the middle, end with .o(tail)
        //
        // After the first ?.[0] the chain may be undefined, so every further
        // step is gated with ?. — e.g.
        //   o a/b/c → w.oa({a:1})?.[0]?.oa({b:1})?.[0]?.o({c:1})
        // Non-capture multi-leg wraps the whole thing in ( … ?? [] ) so a
        // missing intermediate collapses to [] rather than undefined (the
        // caller expects an array).
        const middle = legs.slice(startIdx, legs.length - 1)
        const tail   = legs[legs.length - 1]
        const q = tail.exactly_src ? `, { exactly: ${tail.exactly_src} }` : ''

        let expr = receiver
        for (let i = 0; i < middle.length; i++) {
            const gate = (i === 0) ? '.' : '?.'
            expr += `${gate}oa(${middle[i].sc_src})?.[0]`
        }
        const tailGate = middle.length ? '?.' : '.'
        expr += `${tailGate}o(${tail.sc_src}${q})`

        if (pick_first_on_tail) {
            // let name = …  with [0] (or ?.[0] if the chain was optional)
            const last = middle.length ? '?.[0]' : '[0]'
            return `${prefix}${expr}${last}`
        }
        if (middle.length) {
            return `${prefix}(${expr} ?? [])`
        }
        return `${prefix}${expr}`
    },

//#endregion
//#region Sunpit

    // Sunpit := "S " IOing
    // For phase 2 we emit a for-of header; the body is a placeholder comment.
    // Phase 3 introduces pythonic indentation and body capture.
    //
    //   S o yeses/because
    //     → for (const because of (w.o({yeses:1}).flatMap((__x: any) => __x.o({because:1})))) { /* body… */ }
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

        if (startIdx >= legs.length) {
            return `/* S ${ness}: empty path */`
        }

        // iterator name = the last leg's single bare-Name key, else __n
        let iter_var = '__n'
        const tailLegNode = legNodes[legNodes.length - 1]
        const tailItems = tailLegNode.getChild('PeelGroup')?.getChildren('PeelItem') ?? []
        if (tailItems.length === 1) {
            const kNode = tailItems[0].getChild('PeelKey')?.getChild('Name')
            if (kNode) iter_var = state.doc.sliceString(kNode.from, kNode.to)
        }

        // build iterable: use flatMap at every step so multiple matches at each
        // level all get traversed — distinct from the .oa()?.[0] pattern used
        // by plain o, which throws away siblings.  Sunpit is iteration.
        let iter = `${receiver}.o(${legs[startIdx].sc_src})`
        for (let i = startIdx + 1; i < legs.length; i++) {
            iter = `${iter}.flatMap((__x: any) => __x.o(${legs[i].sc_src}))`
        }

        const prefix = ness === 'i' ? '/* S i */ ' : ''
        return `${prefix}for (const ${iter_var} of (${iter})) { /* body… */ }`
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

//#endregion
//#region rendering

    // Assemble the translated lines into the named function body.
    // 8-space indent inside the function body matches M.eatfunc({...}) style
    // used by the rest of the codebase (Machinery.svelte, Lang.svelte …).
    Lang_compile_render_fn(name: string, body_lines: string[]): string {
        const indented = body_lines.map(l => l ? `        ${l}` : '').join('\n')
        return `    async ${name}(A: TheC, w: TheC) {\n${indented}\n    }`
    },

    // Wrap the function(s) in a ghost module Pantheate can require().
    // The shape mirrors any other ghost (Machinery, Lang, …): a <script>
    // with an onMount that calls M.eatfunc({...fns}).
    Lang_compile_render_module(fn_parts: string[]): string {
        // dodge Svelte's script-tag tokenizer, which will get confused even by closing script tags in comments
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

${fn_parts.join(',\n\n')},

    })
    })
${CLOSE}
`
        )
    },


    })
    })
</script>