<script lang="ts">
    // LangTwist.svelte — ghost.  A plaything for code|data graphs.
    //
    //   Where Cyto *renders* a graph it's handed, LangTwist *finds* one: it reads a
    //   handful of Docs, matches calls against defs across and within them, and pulls a
    //   candidate execution graph out of the result — a Waft full of `def` nodes and the
    //   `to` edges between them.  It is deliberately a first cut: name-matching, not a
    //   real resolver.  The interesting signal is the CROSS-Doc edge (a call in one Doc
    //   landing on a def in another) and the UNRESOLVED call (a call matching no def we
    //   scanned — a gap, or a name that lives outside the scanned set).
    //
    // ── The Waft is the store ────────────────────────────────────────────────
    //
    //   w.c.twist is a single Waft particle (`Waft:'LangTwist/graph'`) under the ghost's
    //   `watched:'twist'` bucket.  Everything the scan learns rides in it as plain C:
    //
    //     def:<name>          a definition site.  sc.doc, sc.line, sc.kind; bumped sc.hits
    //                          each rescan so a node that keeps mattering reads "hot".
    //       └ to:<name>       an outgoing call edge (child of the calling def).  sc.n = count,
    //                          sc.cross = 1 when caller and callee live in different Docs.
    //     unresolved:<name>   a call that matched no scanned def.  sc.n, sc.doc.
    //
    //   Because it's just C, it persists through the same Dexie→IndexedDB path as the rest
    //   of the tree, and it's fully derivable from the source Docs — so it's the perfect
    //   thing to let the browser evict under storage pressure: lose it, rescan, done.
    //   (See the storage note at the foot of this file.)
    //
    // ── Commission / trigger ─────────────────────────────────────────────────
    //
    //   Idle like Cyto until pointed at something.  Two ways in:
    //     e_LangTwist_commission {Sources}  — Sources = TheC[] Doc roots to scan.
    //     the `scan` action / e_LangTwist_scan — scans the live editor's Docs (reached
    //       via H.ave's %examining → c.w, the seam Liesui/SurprisePopover use), or, with
    //       nothing open, the ghost's own House tree as a demo source.
    //   A scanned source is watch_c'd, so a later mutation re-arms a rescan — the graph
    //   keeps breathing with the code.
    //
    // ── Not built yet (the fun part) ─────────────────────────────────────────
    //   · trace mode: weave H.trace into the compiled gen so edges light by real runtime
    //     traffic, not just static name-match — "gratuitous amounts of trace to find where
    //     everything actually goes".  Hook: langtwist_scan would fold a trace tally onto
    //     each `to` edge's sc.n.
    //   · proportion + vibrate: hand w.c.twist to Cyto as a Scannable (e_Cyto_commission)
    //     and drive node size from sc.hits, edge weight from sc.n, and a per-tick wave so
    //     busy regions visibly shimmer.  vibe_duration is the seed knob.
    //   · the data graph: the same machine pointed at runtime C particles instead of Doc
    //     source — the structure we actually push around all day.  Same Waft, `kind:data`.

    import { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import LangTwistui from "./LangTwistui.svelte"

    let { M } = $props()

    // Common call-shaped keywords to drop from the `NAME(` heuristic so the graph isn't
    //  buried in if/for/while/return noise.
    const KEYWORDS = new Set([
        'if', 'for', 'while', 'switch', 'catch', 'return', 'await', 'typeof',
        'function', 'super', 'constructor', 'new', 'do', 'else',
    ])

    onMount(async () => {
    await M.eatfunc({

//#region w:LangTwist — boot, plan, think

    // One-shot bootstrap: create the A:/w: world so the think-loop starts sweeping
    //  LangTwist(A,w).  Call once after the ghost mounts —
    //   H.i_elvisto(H, 'LangTwist_boot', {}) — or add `H.i({A:'LangTwist'}).i({w:'LangTwist'})`
    //    to a boot recipe.  Kept here so the whole ghost lives in one file.
    LangTwist_boot() {
        const H = this as House
        if (H.o({ A: 'LangTwist' }).length) return
        H.i({ A: 'LangTwist' }).i({ w: 'LangTwist' })
    },

    async LangTwist(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.LangTwist_plan(w)
        if (w.c.want_scan) { w.c.want_scan = false; await this.langtwist_scan(w) }
        const g = w.c.twist as TheC | undefined
        if (!g) return w.i({ see: '🧬 awaiting a source' })
        const defs  = g.o({ def: 1 }).length
        const edges = this.langtwist_edge_count(w)
        w.i({ see: defs ? `🧬 ${defs} defs · ${edges} edges` : '🧬 nothing matched yet' })
    },

    LangTwist_plan(w: TheC) {
        const H   = this as House
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'LangTwist' }, { component: LangTwistui })
        const wa  = H.oai_enroll(H, { watched: 'twist' })
        w.c.twist     = wa.oai({ Waft: 'LangTwist/graph' })
        w.sc.vibe_duration ??= 0.6      // seed for the future Cyto shimmer
        w.c.plan_done = true
        this.langtwist_install_actions(w)
    },

    langtwist_install_actions(w: TheC) {
        const H  = this as House
        const wa = H.oai_enroll(H, { watched: 'actions' })
        wa.oai({ action: 1, role: 'langtwist_scan' }, {
            label: 'scan', icon: '🧬', cls: 'default',
            fn: () => H.i_elvisto(w, 'LangTwist_scan', {}),
        })
        wa.oai({ action: 1, role: 'langtwist_wipe' }, {
            label: 'wipe', icon: '⌀', cls: 'remove',
            fn: () => H.i_elvisto(w, 'LangTwist_wipe', {}),
        })
    },

//#endregion
//#region elvis handlers

    // Hand LangTwist an explicit set of Doc roots to scan.
    async e_LangTwist_commission(A: TheC, w: TheC, e: TheC) {
        if (!w.c.plan_done) this.LangTwist_plan(w)
        const sources = (e?.sc.Sources as TheC[] | undefined) ?? []
        w.c.Sources   = sources
        w.c.want_scan = true
    },

    async e_LangTwist_scan(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.LangTwist_plan(w)
        w.c.Sources   = undefined   // fall back to the live-editor / demo source
        w.c.want_scan = true
    },

    async e_LangTwist_wipe(A: TheC, w: TheC) {
        const g = w.c.twist as TheC | undefined
        if (!g) return
        for (const n of g.o() as TheC[]) g.drop(n)
        g.bump_version()
    },

//#endregion
//#region the scan

    // Resolve the Docs to scan: an explicit commission, else the live editor's Lies Docs,
    //  else (nothing open) the ghost's own House tree, so a fresh tab still shows something.
    langtwist_sources(w: TheC): TheC[] {
        const H = this as House
        const given = w.c.Sources as TheC[] | undefined
        if (given && given.length) return given
        const liesW = H.ave?.ob({ examining: 1 })[0]?.c?.w as TheC | undefined
        if (liesW) {
            const docs = [
                ...(liesW.o({ loaded_doc: 1 }) as TheC[]),
                ...(liesW.o({ Waft: 1 }) as TheC[]),
            ]
            if (docs.length) return docs
        }
        return H.o() as TheC[]      // demo fallback: graph the live particle tree
    },

    // Best-effort source text for a Doc node — the text may ride on the node, on its .c,
    //  or be spread across child `text:` tokens.  When none is found we degrade to the
    //   C-structure path (names only) in langtwist_extract.
    langtwist_doc_text(doc: TheC): string {
        const direct = (doc.sc.text ?? doc.c?.text) as string | undefined
        if (typeof direct === 'string' && direct.length) return direct
        const toks = (doc.o({ text: 1 }) as TheC[]).map(t => t.sc.text as string).filter(Boolean)
        return toks.join(' ')
    },

    // Pull (defs, calls) out of one Doc.  First cut, intentionally loose:
    //   def   — `function NAME`, `def NAME`, or a bare `NAME(...) {` / `NAME =>` head.
    //   call  — a DSL `&NAME`, or a plain `NAME(` application.
    //  Noisy on purpose; tightening this against Lang's compiled structure (real call|def
    //   facts, not regex) is the next phase.  doc_label names the Doc for cross-Doc edges.
    langtwist_extract(doc: TheC): { label: string, defs: { name: string, line: number, kind: string }[], calls: { name: string, line: number }[] } {
        const H     = this as House
        const label = (doc.sc.path ?? doc.sc.Waft ?? doc.sc.loaded_doc ?? H.mainkey?.(doc) ?? '?') as string
        const text  = this.langtwist_doc_text(doc)
        const defs: { name: string, line: number, kind: string }[]  = []
        const calls: { name: string, line: number }[]               = []

        if (text) {
            text.split('\n').forEach((ln: string, i: number) => {
                let m: RegExpExecArray | null
                const reDef = /(?:\bfunction\s+|\bdef\s+|\basync\s+)([A-Za-z_]\w*)|^\s*([A-Za-z_]\w*)\s*\([^()]*\)\s*[:{]/g
                while ((m = reDef.exec(ln))) defs.push({ name: m[1] ?? m[2], line: i + 1, kind: 'code' })
                const reCall = /&\s*([A-Za-z_]\w*)|\b([A-Za-z_]\w*)\s*\(/g
                while ((m = reCall.exec(ln))) {
                    const name = m[1] ?? m[2]
                    if (KEYWORDS.has(name)) continue
                    calls.push({ name, line: i + 1 })
                }
            })
        } else {
            // no text — take child node names as defs so cross-Doc name-coincidence still draws.
            for (const kid of doc.o() as TheC[]) {
                const name = String(H.mainkey?.(kid) ?? '')
                if (/^[A-Za-z_]\w*$/.test(name)) defs.push({ name, line: 0, kind: 'struct' })
            }
        }
        return { label, defs, calls }
    },

    langtwist_edge_count(w: TheC): number {
        const g = w.c.twist as TheC | undefined
        if (!g) return 0
        return (g.o({ def: 1 }) as TheC[]).reduce((n, d) => n + d.o({ to: 1 }).length, 0)
    },

    // The pass: extract every Doc, build a global name→def-Doc index, then write defs and
    //  resolved/unresolved call edges into the Waft.  Re-runnable: existing nodes keep their
    //   slot, sc.hits accrues so persistently-busy nodes read hot, and a stale node simply
    //    stops gaining hits.
    async langtwist_scan(w: TheC) {
        const H = this as House
        const g = w.c.twist as TheC
        if (!g) return

        const sources = this.langtwist_sources(w)
        const scanned = sources.map((s: TheC) => this.langtwist_extract(s))

        // name → the Doc label(s) that define it.  First definer wins as the edge target.
        const defDoc = new Map<string, string>()
        for (const s of scanned)
            for (const d of s.defs)
                if (!defDoc.has(d.name)) defDoc.set(d.name, s.label)

        for (const s of scanned) {
            // def nodes
            for (const d of s.defs) {
                const node = g.oai({ def: d.name }, { doc: s.label, line: d.line, kind: d.kind })
                node.sc.hits = ((node.sc.hits as number) ?? 0) + 1
            }
            // call edges — attribute each call to the caller Doc's def of the same... well,
            //  at first cut we don't know WHICH def in this Doc made the call, so we hang the
            //   edge off a synthetic per-Doc origin node `def:<label>` (the Doc as a caller).
            const origin = g.oai({ def: s.label }, { doc: s.label, kind: 'doc' })
            origin.sc.hits = ((origin.sc.hits as number) ?? 0) + 1
            const tally = new Map<string, number>()
            for (const c of s.calls) tally.set(c.name, (tally.get(c.name) ?? 0) + 1)
            for (const [name, n] of tally) {
                const target = defDoc.get(name)
                if (target) {
                    const edge = origin.oai({ to: name }, { n })
                    edge.sc.n = n
                    if (target !== s.label) edge.sc.cross = 1; else delete edge.sc.cross
                } else {
                    const u = g.oai({ unresolved: name }, { doc: s.label })
                    u.sc.n = ((u.sc.n as number) ?? 0) + n
                }
            }
        }

        // keep the graph breathing: watch each real source ONCE so a later mutation
        //  re-arms a rescan.  Guarded by a Set on w.c so rescans don't stack handlers.
        const watched: Set<TheC> = (w.c.watched_sources ??= new Set())
        for (const s of sources) {
            if (watched.has(s)) continue
            watched.add(s)
            H.watch_c(s, () => { w.c.want_scan = true })
        }

        g.bump_version()
        ;(H.o({ watched: 'twist' })[0] as TheC)?.bump_version()
    },

//#endregion

    })
    })
</script>
