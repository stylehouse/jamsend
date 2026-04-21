<script lang="ts">
    import { _C, objectify, type TheC } from "$lib/data/Stuff.svelte";
    import { Travel } from "$lib/mostly/Selection.svelte"
    // Text.svelte — ghost depositing snap-line and diff functions onto H.* via eatfunc.
    //
    // Mounted in Ghost.svelte alongside Agency, Machinery, Story, Cyto.
    // All functions arrive on every H instance (and subHouses) via
    // H.ghostsHaunt() → Object.assign(h, this.ghosts).
    //
    // ── why a ghost ──────────────────────────────────────────────────────────
    //
    //   These functions have no Svelte reactivity and no Housing dependency.
    //   Making them H.* methods means Story, Cyto, and any future worker can
    //   call this.enL(), this.compute_diff() etc. without importing from a UI
    //   file.  StoryRun (a Svelte component, not a Housing) calls them via the
    //   T = H as any pattern — same surface, no circular imports.
    //
    // ── regions ───────────────────────────────────────────────────────────────
    //
    //   snap-line codec   enj, ind, pad, encode_stringies, enL, deL
    //   diff              depth_of, char_diff_ops, compute_diff,
    //                     squish_context, positional_diff
    //   Dif codec         enDif, deDif
    //
    // ── snap-line format ──────────────────────────────────────────────────────
    //
    //   Each line encodes one C particle:
    //     "${indent}${obj_part}\t${stringies}"
    //
    //   indent:    2 spaces × depth.
    //   obj_part:  JSON of objecties metadata (ref ids, mung list) when present;
    //              empty string otherwise.  Tab is the always-present separator
    //              when obj_part is non-empty; omitted entirely when there are no
    //              objecties (enL omits the tab — deL handles both forms).
    //   stringies: peel format "k:v  k2:v2" when all keys/values are sayable,
    //              otherwise JSON (always starts with "{" so deL can detect it).
    //
    // ── block-quoting (BQ) extension ───────────────────────────────────────────
    //
    //   Selected string keys may be encoded as YAML-style literal block scalars
    //   instead of inline.  This is opt-in via lematch rules supplying
    //   blockquote_these_sc: { source: 1, ... } in their means.
    //
    //   Format (parent at depth D, i.e. 2*D leading spaces):
    //
    //     <2*D spaces>Output,name:Somewhere.svelte,dige:131313113
    //      <2*D+1 space>source: |
    //        <2*D+3 spaces><first line of source>
    //        <2*D+3 spaces><second line of source>
    //        ...
    //     <2*D spaces>Methods        ← 2*D spaces → ends all BQ keys for parent
    //
    //   Rules:
    //     • BQ key line:  exactly 2*D+1 leading spaces, then "key: |"
    //     • BQ body lines: at least 2*D+3 leading spaces (the source lines verbatim,
    //                       each trimmed of exactly 2*D+3 leading spaces on decode)
    //     • A BQ key ends when a line has ≤ 2*D+1 leading spaces.
    //     • The blockquoted string value MUST end with \n (YAML literal block
    //       scalar semantics — trailing newline is part of the value).
    //       enLine returns an error marker in q.bq_errors if it does not.
    //     • Only keys listed in blockquote_these_sc are blockquoted; all others
    //       remain in the inline stringies on the parent line as usual.
    //     • Multiple BQ keys are emitted in order after the parent line,
    //       each at 2*D+1 spaces.
    //
    // ── Dif codec ─────────────────────────────────────────────────────────────
    //
    //   enDif and deDif are a symmetric pair, mirroring enL/deL.
    //   All Dif:* markers flat at dif_depth; content children at
    //   dif_depth + 1 + original_snap_depth.
    //
    //   Marker vocabulary:
    //     Dif:same         — same line; content is the got (=prev) snap line
    //     Dif:unchanged count:N  — squished same-line run (leaf, no content child)
    //     Dif:change       — changed line; content is the got side
    //     Dif:prev         — always immediately follows Dif:change; content is prev
    //     Dif:+            — right_only; content is the new got line
    //     Dif:-            — left_only; content is the gone prev line
    //
    //   Full example at dif_depth=2 (Step:0, Snap:1, Dif:2):
    //
    //     Step:3
    //       Snap:1 diff:1 prev:1
    //         Dif:same
    //           H:LeafFarm Run             ← original depth 0 → child depth 3
    //         Dif:unchanged count:8
    //         Dif:same
    //             A:plate                  ← original depth 1 → child depth 4
    //         Dif:change
    //               w:plate self:1 round:21  ← original depth 2 → child depth 5
    //         Dif:prev
    //               w:plate self:1 round:20
    //         Dif:+
    //               leaf_id:seed_0 dose:1.97
    //
    // ── DiffRow type ──────────────────────────────────────────────────────────
    //
    //   pair       — line present in both columns (same or internally changed)
    //   left_only  — only in reference side ('gone', red)
    //   right_only — only in got side ('neu', green)  — not 'new', JS reserved
    //   squish     — collapsed run of same lines
    //
    //   StoryRun redeclares this locally for TypeScript narrowing.

    import { depeel, peel }     from "$lib/Y.svelte"
    import { diff_match_patch } from 'diff-match-patch'
    import { onMount }          from 'svelte'

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region wormhole Lines
// ── encode_wh_lines ────────────────────────────────────────────────────
// Encode a tree of {sc, children?} items to snap-line text via Travel.
//
// root_sc  — the depth-0 header line, e.g. {Library:1}
// items    — depth-1 entries; each may carry .children for depth 2+
//
// Returns { snap, errors }.
//
// Errors are FATAL — any mung (object/function value on any sc) or dupe
// node causes the offending line to be skipped and the error to record
// the full T.c.path of ancestor snap lines so you can see exactly where
// the problem is.  The caller should refuse to save if errors.length > 0.
    async encode_wh_lines(
        root_sc: Record<string, any>,
        items: Array<{ sc: Record<string, any>, children?: any[] }>
    ): Promise<{ snap: string, errors: string[] }> {
        const H = this as any
        const errors: string[] = []
        const snap_lines: string[] = []
        const seen = new Set<TheC>()

        // Build a TheC tree for Travel to walk.
        // Each item's sc becomes a TheC; children are i()'d into the parent
        // so Travel's n.o({}) call finds them as direct children.
        const build_into = (parent: TheC, sc: Record<string,any>, children?: any[]) => {
            const c = _C({ ...sc })
            parent.i(c)
            for (const child of children ?? []) build_into(c, child.sc, child.children)
        }
        const rootC = _C({ ...root_sc })
        for (const item of items ?? []) build_into(rootC, item.sc, item.children)

        // Walk with Travel — match_sc:{} visits every child at every depth.
        const Tr = new Travel()
        await Tr.dive({
            n: rootC,
            match_sc: {},
            each_fn: async (n: TheC, T: Travel) => {
                const d = T.c.path.length - 1  // 0 for root, 1 for items, etc.

                // Dupe detection: same C object in two places in the tree.
                if (seen.has(n)) {
                    const path_str = T.c.path
                        .map((pt: Travel) => (pt.sc.n as TheC)?.c?.snap_Line ?? '?')
                        .join(' → ')
                    errors.push(`dupe node at depth ${d} — path: ${path_str}`)
                    T.sc.not = 1
                    return
                }
                seen.add(n)

                // Encode via enLine with q.check so mung is flagged.
                const q: any = { d }
                const lines = H.enLine(n, q)

                if (q.objecties?.mung) {
                    // Build path from ancestor snap_Lines stored in prior each_fn calls.
                    const path_str = T.c.path
                        .map((pt: Travel) => (pt.sc.n as TheC)?.c?.snap_Line ?? '?')
                        .join(' → ')
                    errors.push(`mung keys [${q.mung?.join(', ')}] at depth ${d} — path: ${path_str}`)
                    T.sc.not = 1   // skip this node and all its children
                    return
                }

                // Collect BQ errors
                for (const bqe of q.bq_errors ?? []) {
                    errors.push(`blockquote error at depth ${d}: ${bqe}`)
                }

                // Store first snap line on c.c (not c.sc) so it's available for child
                // path debug without polluting the snap output.
                n.c.snap_Line = lines?.[0] ?? ''
                for (const line of lines ?? []) snap_lines.push(line)
            },
        })

        return { snap: snap_lines.join('\n') + '\n', errors }
    },

    // ── decode_wh_lines ────────────────────────────────────────────────────
    // Decode snap-line text into a TheC tree.  Returns { c, errors }.
    //
    // c is the depth-0 root TheC (e.g. sc:{Library:1}) with all children
    // properly i()'d into it — ready for .o() queries at every depth.
    // Returns c:null on fatal error (no root found, or parse error on root).
    //
    // Stack discipline: we maintain a path-like stack [{d,c}].  On each line
    // we pop until the top entry is shallower than d, then parent.i(newC),
    // then push.  This means:
    //
    //   Library:1
    //     Book:LeafJuggle         ← stack [Library, LeafJuggle]
    //       note:1 todo:fix       ← stack [Library, LeafJuggle, note]
    //     Book:LeafFarm           ← pop note+LeafJuggle, stack [Library, LeafFarm]
    //
    // Block-scalar handling: after parsing a normal line onto the stack,
    // consume any immediately following BQ key lines (odd indent = 2*D+1)
    // and their body lines, merging the decoded values into the freshly
    // created TheC's sc before pushing it.
    //
    // Errors:
    //   • More than one depth-0 line → error, second root ignored.
    //   • Depth jump > 1 (e.g. d=0 → d=2) → error, line skipped.
    //   • objecties.mung present → error, line skipped (encoded mung = bad encode).
    //   • Object value in stringies → error, line skipped.
    //   • BQ body missing (key: | with no following body) → error, key skipped.

    decode_wh_lines(snap: string): { C: TheC | null, errors: string[] } {
        const errors: string[] = []
        if (!snap?.trim()) return { C: null, errors: ['empty snap'] }

        // Split into non-empty lines, keeping track of our position with an index
        // so BQ consumption can advance past the main loop cursor.
        const all_lines = snap.split('\n')
        let li = 0   // mutable cursor shared with BQ consumer below

        interface SE { d: number; C: TheC }
        const stack: SE[] = []
        let root: TheC | null = null
        let prev_d = -1

        // count_spaces: leading space count of a raw line.
        const count_spaces = (line: string) => line.match(/^ */)?.[0].length ?? 0

        // consume_bq_keys: after parsing a node at depth D (2*D spaces),
        // look ahead for lines with exactly 2*D+1 leading spaces ("key: |")
        // and their body lines (≥ 2*D+3 spaces).  Merge decoded values into sc.
        // Advances li past everything consumed.
        const consume_bq_keys = (sc: Record<string, any>, parent_d: number) => {
            const bq_sp     = parent_d * 2 + 1   // spaces for BQ key line
            const body_min  = parent_d * 2 + 3   // minimum spaces for body lines

            while (li < all_lines.length) {
                const raw = all_lines[li]
                if (!raw.trim()) { li++; continue }  // skip blank lines inside BQ section
                const sp = count_spaces(raw)
                if (sp !== bq_sp) break   // not a BQ key for this parent — stop

                // Parse "key: |" — only the literal-block-scalar form is supported
                const key_part = raw.slice(sp).trimEnd()
                const bq_match = key_part.match(/^(\w+):\s*\|$/)
                if (!bq_match) break   // not a BQ key line — stop (leave for normal decode)
                const key = bq_match[1]
                li++

                // Collect body lines (all lines with ≥ body_min spaces)
                const body_lines: string[] = []
                while (li < all_lines.length) {
                    const braw = all_lines[li]
                    // Blank lines within the body are kept as empty lines in the value
                    if (!braw.trim()) {
                        // A blank line inside body is kept; we'll decide below whether
                        // we're still in body by checking the next non-blank line.
                        // Simple approach: treat blank as body continuation.
                        body_lines.push('')
                        li++
                        continue
                    }
                    if (count_spaces(braw) < body_min) break   // body ended
                    // Strip exactly body_min leading spaces; preserve the rest verbatim
                    body_lines.push(braw.slice(body_min))
                    li++
                }

                if (!body_lines.length) {
                    errors.push(`BQ key "${key}" at depth ${parent_d} has no body lines`)
                    continue
                }

                // Trim trailing blank lines that were collected past the real content
                while (body_lines.length && body_lines[body_lines.length - 1] === '') {
                    body_lines.pop()
                }

                // Reassemble with \n between lines, and the required trailing \n
                sc[key] = body_lines.join('\n') + '\n'
            }
        }

        while (li < all_lines.length) {
            const raw = all_lines[li]
            li++
            if (!raw.trim()) continue

            const sp = count_spaces(raw)

            // Odd space count means this is a BQ key line orphaned without a parent —
            // this shouldn't happen in well-formed snap but guard it.
            if (sp % 2 !== 0) {
                // Could be a BQ key that was supposed to be consumed above; skip.
                errors.push(`unexpected odd-indent line: "${raw.trim()}"`)
                continue
            }

            let parsed: { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null = null
            try { parsed = this.deL(raw) } catch {
                errors.push(`parse error: "${raw.trim()}"`)
                continue
            }
            if (!parsed) continue

            const { d, objecties, stringies: sc } = parsed

            // Depth jump check — no more than one level deeper than previous.
            if (prev_d >= 0 && d > prev_d + 1) {
                errors.push(`depth jump ${prev_d}→${d}: "${raw.trim()}"`)
                continue
            }
            prev_d = d

            // Mung check — objecties.mung means this line was encoded with munged
            // keys; that's a bug in the encoder, refuse to load it.
            if (objecties?.mung?.length) {
                errors.push(`mung keys [${objecties.mung.join(', ')}] at depth ${d}: "${raw.trim()}"`)
                continue
            }

            const sc_merged = { ...sc }

            // Consume any BQ keys that follow this line before building the TheC,
            // so the TheC gets its full sc including blockquoted values.
            consume_bq_keys(sc_merged, d)

            const C = _C({ ...sc_merged })

            if (d === 0) {
                if (root !== null) {
                    errors.push(`second depth-0 root ignored: "${raw.trim()}"`)
                    continue
                }
                root = C
                stack.length = 0
                stack.push({ d: 0, C })
                continue
            }

            // Pop stack until top is the immediate parent (depth < d).
            while (stack.length > 0 && stack[stack.length - 1].d >= d) stack.pop()

            if (!stack.length) {
                errors.push(`no parent for depth ${d}: "${raw.trim()}"`)
                continue
            }

            stack[stack.length - 1].C.i(C)
            stack.push({ d, C })
        }

        if (!root) errors.push('no depth-0 root found')
        return { C: root, errors }
    },

//#region snap-line codec

    // ── enj / ind / pad ───────────────────────────────────────────────────────
    //
    //   enj: JSON-encode an object for use as the obj_part of a snap line.
    //   ind: produce an indent string for depth d (2 spaces per level).
    //   pad: zero-pad a number to 3 digits, used for NNN.snap filenames.

    enj(o: any): string { return JSON.stringify(o ?? {}) },
    ind(d: number): string { return '  '.repeat(d) },
    pad(n: number): string { return String(n).padStart(3, '0') },

    // ── encode_stringies ──────────────────────────────────────────────────────
    //
    //   Prefer peel format (k:v k2:v2) for readability; fall back to JSON when
    //   any key or value contains unsafe characters (:,\t\n).
    //   Peel rule: key /^\w+$/, value is number|boolean or a string with no
    //   colons, commas, tabs, or newlines.
    //
    //   Note: keys that will be blockquoted are excluded from sc before this
    //   is called, so they never appear inline.

    encode_stringies(obj: Record<string,any>): string {
        const unsafe = /[:,\t\n]/
        for (const [k, v] of Object.entries(obj)) {
            if (unsafe.test(k)) return JSON.stringify(obj)
            if (typeof v === 'number' || typeof v === 'boolean') continue
            if (typeof v !== 'string' || unsafe.test(v)) return JSON.stringify(obj)
        }
        return depeel(obj)
    },

    // ── enL ───────────────────────────────────────────────────────────────────
    //
    //   Encode one parsed snap-line descriptor back to a string.
    //   Omits the tab entirely when there are no objecties (obj_part empty) —
    //   this is the canonical form; deL handles both tab-present and tab-absent.
    //
    //   Returns a single string (the parent line only).
    //   Block-scalar lines for BQ keys are produced by enLine, not enL, since
    //   they require knowing which keys to blockquote and depth for body indent.

    enL(parsed: { d: number, objecties: Record<string,any>, stringies: Record<string,any> }): string {
        const obj_part = Object.keys(parsed.objecties||{}).length ? this.enj(parsed.objecties) : ''
        const str_part = this.encode_stringies(parsed.stringies)
        return obj_part
            ? `${this.ind(parsed.d)}${obj_part}\t${str_part}`
            : `${this.ind(parsed.d)}${str_part}`
    },

    // ── deL ───────────────────────────────────────────────────────────────────
    //
    //   Decode one raw snap line → { d, objecties, stringies }.
    //   Handles both forms:
    //     with objecties:    "  {"mung":["age"]}\tself:1 round:20"
    //     without objecties: "  self:1 round:20"
    //
    //   The tab is the separator between obj_part and str_part only when
    //   obj_part is present.  A line with no tab is stringies-only.
    //   stringies: peel format "k:v k2:v2" or JSON (starts with "{").
    //
    //   Note: deL only decodes the single line — BQ key/body lines that follow
    //   a node line are consumed separately by decode_wh_lines.

    deL(line: string): { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null {
        const spaces  = line.match(/^ */)?.[0].length ?? 0
        const d       = Math.floor(spaces / 2)
        const tab     = line.indexOf('\t')
        const obj_raw = tab >= 0 ? line.slice(spaces, tab) : ''
        const str_raw = tab >= 0 ? line.slice(tab + 1) : line.slice(spaces)
        return {
            d,
            objecties: obj_raw ? JSON.parse(obj_raw) : {},
            stringies: str_raw.startsWith('{') ? JSON.parse(str_raw) : peel(str_raw),
        }
    },

    // ── enLine ──────────────────────────────────────────────────────────────────
    // General-purpose single-particle snap line encoder.
    //
    //   enLine(n, q) → array of snap lines (parent line, then any BQ key/body
    //                   lines), or null when rules say skip.
    //
    // q is both config (in) and result carrier (out):
    //   in:   q.d                   — enL depth
    //         q.rules               — optional matching rules (same schema as story_matching)
    //   out:  q.skip, q.thence, q.stringies, q.objecties, q.mung
    //         q.snap_line           — the parent line (first element of return array)
    //         q.bq_errors           — array of blockquote validation errors (non-fatal
    //                                 in the sense that encoding continues, but callers
    //                                 should surface them — a BQ string not ending in \n
    //                                 is always an error)
    //
    // Rule schema:
    //   { matching_any: [ {sc:{...}} | {sc_only:{...}} ],
    //     means: { skip?, munging?: [{sc:{key:1}, type}],
    //              blockquote_these_sc?: {key:1, ...},
    //              thence_matching? } }
    //
    //   blockquote_these_sc: keys in this map that are also present in n.sc and
    //   have string values ending in \n will be emitted as YAML literal block
    //   scalars after the parent line.  Keys that do NOT end in \n are an error
    //   (recorded in q.bq_errors) and are emitted inline instead so data is not
    //   lost.  Keys with non-string values are silently left inline.
    //
    // Object/function values on n.sc are always put into objecties.ref (excluded
    // from diff), regardless of rules.  Rules may additionally mung scalar keys.
    // T is never touched — callers proxy q.skip → T.sc.not, q.thence → T.sc.thence_matching.

    enLine(n: TheC, q: {
        d: number
        rules?: Array<any>
        // outputs written back:
        snap_line?: string
        stringies?: Record<string, any>
        objecties?: Record<string, any> | undefined
        skip?: boolean
        thence?: Array<any>
        mung?: string[]
        bq_errors?: string[]
    }): string[] | null {
        const mr = n.lematch(q.rules ?? [])
        q.skip   = mr.skip
        q.thence = mr.thence
        if (q.skip) return null

        // Collect blockquote_these_sc from all matched rules (union of all means)
        const bq_keys: Record<string, 1> = {}
        for (const rule of q.rules ?? []) {
            // lematch already checked matching — we need to re-check here or just
            // collect from mr.munging's companion.  Simpler: walk rules directly.
            // (lematch doesn't expose which rules matched, only their combined effects,
            //  so we re-examine means.blockquote_these_sc from any rule that fired.)
            const matched = (rule.matching_any as any[] ?? []).some((entry: any) => {
                if (entry.sc_only) {
                    const want = Object.keys(entry.sc_only)
                    if (Object.keys(n.sc).length !== want.length) return false
                    return n.matches(entry.sc_only)
                }
                return n.matches(entry.sc)
            })
            if (matched && rule.means?.blockquote_these_sc) {
                Object.assign(bq_keys, rule.means.blockquote_these_sc)
            }
        }

        const stringies: Record<string, any> = {}
        const ref: Record<string, string> = {}
        const mung: string[] = []
        const bq_pending: Array<{ key: string, value: string }> = []
        q.bq_errors = []

        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
                ref[k] = objectify(v)
                continue
            }
            const is_munged = mr.munging.find(r => Object.hasOwn(r.sc, k))
            if (is_munged) { mung.push(k); continue }

            // blockquote_these_sc: only strings ending in \n get BQ treatment
            if (bq_keys[k]) {
                if (typeof v === 'string') {
                    if (v.endsWith('\n')) {
                        bq_pending.push({ key: k, value: v })
                        continue   // excluded from inline stringies
                    } else {
                        // Error: must end with \n to be a valid BQ value
                        q.bq_errors.push(`key "${k}" marked for blockquote but value does not end with \\n — encoding inline`)
                        // fall through to stringies (data preserved, error surfaced)
                    }
                }
                // non-string: leave inline silently
            }
            stringies[k] = v
        }

        const objecties: Record<string, any> = {}
        if (Object.keys(ref).length) objecties.ref = ref
        if (mung.length) objecties.mung = mung

        q.stringies = stringies
        q.objecties = Object.keys(objecties).length ? objecties : undefined
        q.mung      = mung

        // Parent line — inline keys only (BQ keys excluded above)
        const parent_line = this.enL({ d: q.d, objecties: q.objecties ?? {}, stringies })
        q.snap_line = parent_line

        const out_lines: string[] = [parent_line]

        // BQ key/body lines: each BQ key becomes:
        //   " ".repeat(2*d+1) + "key: |"
        //   " ".repeat(2*d+3) + <each source line verbatim>
        // The trailing \n of the value is not emitted as a body line — it is
        // implied by the block scalar form and re-added on decode.
        if (bq_pending.length) {
            const key_indent  = ' '.repeat(q.d * 2 + 1)   // 2*d+1 spaces
            const body_indent = ' '.repeat(q.d * 2 + 3)   // 2*d+3 spaces

            for (const { key, value } of bq_pending) {
                out_lines.push(`${key_indent}${key}: |`)
                // Split on \n; the trailing \n produces a final empty string — drop it.
                const body_lines = value.split('\n')
                if (body_lines[body_lines.length - 1] === '') body_lines.pop()
                for (const bl of body_lines) {
                    out_lines.push(`${body_indent}${bl}`)
                }
            }
        }

        return out_lines
    },

    // ── snap_indent ────────────────────────────────────────────────────────────
    // Shift every line in a snap string by +d depth levels.
    // Since enL encodes depth as leading '  ' pairs, prepending '  '.repeat(d)
    // is exactly equivalent to having been encoded at depth+d.
    // Note: BQ key lines (odd indent) and body lines will shift correctly since
    // we're just prepending an even number of spaces.

    snap_indent(snap: string, d: number): string {
        if (!d) return snap
        const prefix = '  '.repeat(d)
        return snap.split('\n').filter(Boolean).map(l => prefix + l).join('\n') + '\n'
    },
    
//#endregion
//#region diff

    // ── depth_of ──────────────────────────────────────────────────────────────
    //
    //   Indent depth of a snap line (2 spaces per level).
    //   "    w:farm" → 2.
    //   Used by squish_context for ancestor walking and by enDif/deDif to map
    //   original_depth ↔ child_depth under a Dif marker.
    //
    //   Note: BQ key lines have odd space counts (2*d+1) — depth_of will return
    //   a fractional-ish result via Math.floor, but BQ lines are never passed
    //   to depth_of in normal diff flow (they are opaque body lines).

    depth_of(line: string): number {
        return Math.floor((line.match(/^ */)?.[0].length ?? 0) / 2)
    },

    // ── char_diff_ops ─────────────────────────────────────────────────────────
    //
    //   Character-level DMP diff between two strings.
    //   diff_cleanupSemantic merges tiny equal fragments into surrounding changes,
    //   reducing noise on floating-point numbers where only last digits differ.
    //   Returns Array<[op, text]>: op 0=equal, -1=deleted, 1=inserted.

    char_diff_ops(a: string, b: string): Array<[number, string]> {
        const dmp = new diff_match_patch()
        const ops = dmp.diff_main(a, b, false)
        dmp.diff_cleanupSemantic(ops)
        return ops
    },

    // < GONE?
    make_diff(got: any[], exp: any[]) {
        // positional diff of two parsed snap line arrays.
        // positional because the snap walk order is stable across runs.
        // tags: 'same' | 'changed' | 'new' (in got not exp) | 'gone' (vice versa)
        const len = Math.max(got.length, exp.length)
        const result: string[] = []
        for (let i = 0; i < len; i++) {
            const g = got[i], e = exp[i]
            if      (!g) result.push('gone')
            else if (!e) result.push('new')
            else if (JSON.stringify(g.stringies) !== JSON.stringify(e.stringies))
                         result.push('changed')
            else         result.push('same')
        }
        return result
    },

    // ── compute_diff ──────────────────────────────────────────────────────────
    //
    //   Line-level DMP diff normalized for alignment.
    //   left = reference (exp_snap or prev got_snap), right = current got_snap.
    //
    //   Lines are normalized to canonical stringies JSON before alignment so
    //   that JSON-encoded and peel-encoded forms of the same particle compare
    //   as equal.  Normalization uses deL's str_raw extraction so it correctly
    //   handles both tab-present and tab-absent line forms.
    //
    //   DMP runs on the normalized text to get alignment; original lines are
    //   substituted back so display and char ops always use the real content.
    //
    //   BQ key and body lines (odd-indent or body-indent) are treated as opaque
    //   text lines by compute_diff — they diff correctly since they're just
    //   strings.  The squish_context ancestor-walker uses depth_of which floors
    //   odd indents, so BQ key lines won't be mistaken for parent anchors.

    compute_diff(text_left: string, text_right: string): any[] {
        if (!text_left && !text_right) return []
        if (!text_left) return text_right.split('\n').filter(Boolean)
            .map(line => ({ kind: 'right_only', line: line.trimEnd() }))
        if (!text_right) return text_left.split('\n').filter(Boolean)
            .map(line => ({ kind: 'left_only', line: line.trimEnd() }))

        // norm_line: canonical stringies JSON for alignment, indent preserved for depth.
        // BQ key lines ("  key: |") and body lines pass through as-is since they
        // don't parse as snap lines — that's fine, they'll align with their counterparts.
        const norm_line = (line: string): string => {
            const indent  = line.match(/^ */)?.[0] ?? ''
            const tab     = line.indexOf('\t')
            const str_raw = tab >= 0 ? line.slice(tab + 1).trimEnd() : line.trimEnd()
            try {
                const stringies = str_raw.startsWith('{') ? JSON.parse(str_raw) : peel(str_raw)
                return indent + JSON.stringify(stringies)
            } catch { return indent + str_raw }
        }

        const left_lines  = text_left.split('\n').filter(Boolean)
        const right_lines = text_right.split('\n').filter(Boolean)
        const norm_left   = left_lines.map(norm_line).join('\n') + '\n'
        const norm_right  = right_lines.map(norm_line).join('\n') + '\n'

        const dmp = new diff_match_patch()
        const enc = (dmp as any).diff_linesToChars_(norm_left, norm_right)
        const raw = dmp.diff_main(enc.chars1, enc.chars2, false)
        ;(dmp as any).diff_charsToLines_(raw, enc.lineArray)

        const rows: any[] = []
        let li = 0, ri = 0
        let pend_l: string[] = [], pend_r: string[] = []

        const flush = () => {
            const n = Math.max(pend_l.length, pend_r.length)
            for (let i = 0; i < n; i++) {
                const l = pend_l[i], r = pend_r[i]
                if (l != null && r != null) {
                    rows.push({ kind: 'pair', left: l, right: r, tag: 'changed',
                                ops: this.char_diff_ops(l, r) })
                } else if (l != null) {
                    rows.push({ kind: 'left_only',  line: l })
                } else if (r != null) {
                    rows.push({ kind: 'right_only', line: r })
                }
            }
            pend_l = []; pend_r = []
        }

        for (const [op, text] of raw) {
            const count = text.split('\n').filter(Boolean).length
            if (op === 0) {
                flush()
                for (let i = 0; i < count; i++) {
                    const l = (left_lines[li++]  ?? '').trimEnd()
                    const r = (right_lines[ri++] ?? '').trimEnd()
                    rows.push({ kind: 'pair', left: l, right: r, tag: 'same' })
                }
            } else if (op === -1) {
                for (let i = 0; i < count; i++) pend_l.push((left_lines[li++]  ?? '').trimEnd())
            } else if (op ===  1) {
                for (let i = 0; i < count; i++) pend_r.push((right_lines[ri++] ?? '').trimEnd())
            }
        }
        flush()
        return rows
    },

    // ── squish_context ────────────────────────────────────────────────────────
    //
    //   Collapse boring same-line runs while preserving the ancestor chain
    //   (tree parents) above every changed/neu/gone row.
    //
    //   For each interesting row, walk backward marking the nearest preceding
    //   line at each lesser indent depth — the tree parent chain.  Runs of
    //   >3 uninteresting same rows collapse to a single squish entry.
    //   A change inside w:plate always shows H:Story → A:plate above it while
    //   squishing unrelated branches.

    squish_context(rows: any[]): any[] {
        const interesting = new Set<number>()

        for (let i = 0; i < rows.length; i++) {
            const r = rows[i]
            if (r.kind === 'squish' || (r.kind === 'pair' && r.tag === 'same')) continue
            interesting.add(i)
        }

        if (interesting.size === 0) {
            return rows.length > 4 ? [{ kind: 'squish', count: rows.length }] : rows
        }

        const row_line = (r: any) =>
            r.kind === 'pair'       ? r.left :
            r.kind === 'left_only'  ? r.line :
            r.kind === 'right_only' ? r.line : ''

        // mark ancestors of every interesting row
        for (const i of [...interesting]) {
            let need_depth = this.depth_of(row_line(rows[i])) - 1
            for (let j = i - 1; j >= 0 && need_depth >= 0; j--) {
                if (rows[j].kind === 'squish') continue
                const d = this.depth_of(row_line(rows[j]))
                if (d <= need_depth) { interesting.add(j); need_depth = d - 1 }
            }
        }

        const result: any[] = []
        let run: number[] = []
        const flush_run = () => {
            if (run.length > 3) result.push({ kind: 'squish', count: run.length })
            else for (const idx of run) result.push(rows[idx])
            run = []
        }
        for (let i = 0; i < rows.length; i++) {
            if (interesting.has(i)) { flush_run(); result.push(rows[i]) }
            else run.push(i)
        }
        flush_run()
        return result
    },

    // ── positional_diff ───────────────────────────────────────────────────────
    //
    //   Compare line i of left against line i of right, no resyncing after
    //   insertions.  Used by 'exp_naive' ("& exp") mode to show exactly which
    //   numbered lines shifted without any realignment.

    positional_diff(text_left: string, text_right: string): any[] {
        const ls = text_left.split('\n').filter(Boolean)
        const rs = text_right.split('\n').filter(Boolean)
        const len = Math.max(ls.length, rs.length)
        const rows: any[] = []
        for (let i = 0; i < len; i++) {
            const l = ls[i], r = rs[i]
            if (!l)       rows.push({ kind: 'right_only', line: r })
            else if (!r)  rows.push({ kind: 'left_only',  line: l })
            else if (l === r) rows.push({ kind: 'pair', left: l, right: r, tag: 'same' })
            else              rows.push({ kind: 'pair', left: l, right: r, tag: 'changed',
                                          ops: this.char_diff_ops(l, r) })
        }
        return rows
    },

//#endregion
//#region Dif codec

    // ── enDif ─────────────────────────────────────────────────────────────────
    //
    //   Encode DiffRow[] as Dif snap lines.  Symmetric with deDif.
    //
    //   dif_depth: the indent depth at which Dif:* markers appear.
    //   collect_range in StoryRun calls with dif_depth=2 (Step=0, Snap=1, Dif=2).
    //
    //   All Dif:* markers emitted flat at dif_depth.  Content children sit at
    //   dif_depth + 1 + original_snap_depth, preserving the snap hierarchy under
    //   each marker so the output is human-readable and deDif can invert it.
    //
    //   Tab handling: the tab in objectied lines ({"mung":...}\t...) is not
    //   leading whitespace.  re_indent() uses replace(/^ +/, '') which strips
    //   only spaces, so tabs in objectied lines survive intact.
    //
    //   BQ lines (odd-indent key lines and their body lines) are treated as
    //   opaque content lines.  re_indent shifts their leading spaces by the same
    //   dif_depth+1+orig_d offset as normal lines — this means the odd-space
    //   property is shifted but the body lines remain ≥ 3 spaces deeper than
    //   their key line, so deDif's restore_snap correctly inverts them.
    //
    //   Encoding:
    //     Dif:same      — got line as only child
    //     Dif:unchanged — leaf, count:N, no content child
    //     Dif:change    — got line as child, then Dif:prev sibling with prev child
    //     Dif:prev      — always immediately follows Dif:change
    //     Dif:+         — got line as child (new in got, absent from prev)
    //     Dif:-         — prev line as child (gone from got, was in prev)

    enDif(rows: any[], dif_depth: number): string[] {
        const ind = (d: number) => '  '.repeat(Math.max(0, d))
        const out: string[] = []

        // re_indent: strip leading spaces and re-prefix at target_depth.
        // replace(/^ +/, '') touches only leading spaces so tabs (objecties
        // separator, never the first character of a snap line) are preserved.
        const re_indent = (line: string, target_depth: number): string =>
            `${ind(target_depth)}${line.trimEnd().replace(/^ +/, '')}`

        // child_depth: where a snap line's content lands under a Dif marker.
        // original depth 0 → dif_depth+1, depth 1 → dif_depth+2, etc.
        const child_depth = (line: string) => dif_depth + 1 + this.depth_of(line)

        for (const row of rows) {

            if (row.kind === 'squish') {
                // leaf — count is the only payload, no content child
                out.push(`${ind(dif_depth)}Dif:unchanged count:${row.count}`)
                continue
            }

            if (row.kind === 'pair' && row.tag === 'same') {
                // ancestor context kept by squish_context; original depth preserved
                out.push(`${ind(dif_depth)}Dif:same`)
                out.push(re_indent(row.right, child_depth(row.right)))
                continue
            }

            if (row.kind === 'pair' && row.tag === 'changed') {
                // got side under Dif:change; prev side under the Dif:prev sibling
                out.push(`${ind(dif_depth)}Dif:change`)
                out.push(re_indent(row.right, child_depth(row.right)))
                out.push(`${ind(dif_depth)}Dif:prev`)
                out.push(re_indent(row.left, child_depth(row.left)))
                continue
            }

            if (row.kind === 'right_only') {
                out.push(`${ind(dif_depth)}Dif:+`)
                out.push(re_indent(row.line, child_depth(row.line)))
                continue
            }

            if (row.kind === 'left_only') {
                out.push(`${ind(dif_depth)}Dif:-`)
                out.push(re_indent(row.line, child_depth(row.line)))
                continue
            }
        }

        return out
    },

    // ── deDif ─────────────────────────────────────────────────────────────────
    //
    //   Decode Dif snap lines back to DiffRow[].  Symmetric inverse of enDif.
    //
    //   dif_depth: the depth at which Dif:* markers appear (must match enDif).
    //   lines: raw text lines already split by '\n', empty strings filtered.
    //
    //   Algorithm:
    //     Walk lines.  Lines at depth === dif_depth are Dif markers.
    //     Lines at depth > dif_depth are content children of the preceding marker.
    //     restore_snap() inverts re_indent: strips the dif_depth+1 prefix to
    //     recover the original snap depth.
    //
    //   Dif:prev is consumed inline by the Dif:change handler (peek-ahead after
    //   children are collected).  An orphaned Dif:prev is a parse error, skipped.
    //
    //   ops are recomputed from restored left/right so returned DiffRows are
    //   immediately renderable in StoryRun without a further char_diff_ops call.
    //
    //   Unknown Dif types are skipped gracefully for forward compatibility.
    // < use, clauded same time as enDif() for completeness
    deDif(lines: string[], dif_depth: number): any[] {
        const rows: any[] = []

        // restore_snap: invert re_indent.
        // Child was placed at dif_depth + 1 + orig_d, so orig_d = actual - (dif_depth+1).
        // Re-prefix with orig_d * 2 spaces; rest of line verbatim.
        const restore_snap = (line: string): string => {
            const actual_d = this.depth_of(line)
            const orig_d   = Math.max(0, actual_d - (dif_depth + 1))
            return '  '.repeat(orig_d) + line.trimEnd().replace(/^ +/, '')
        }

        // collect_children: consume lines deeper than dif_depth.
        // i_ref is a one-element array for mutable pass-by-reference.
        const collect_children = (i_ref: [number]): string[] => {
            const children: string[] = []
            while (i_ref[0] < lines.length && this.depth_of(lines[i_ref[0]]) > dif_depth) {
                children.push(lines[i_ref[0]])
                i_ref[0]++
            }
            return children
        }

        // first_snap: snap content from the first child line of a Dif marker.
        const first_snap = (children: string[]): string =>
            children.length > 0 ? restore_snap(children[0]) : ''

        // peek_prev: if the next marker at dif_depth is Dif:prev, consume it
        // and return its first child's snap.  Otherwise return '' (not found).
        const peek_prev = (i_ref: [number]): string => {
            if (i_ref[0] >= lines.length) return ''
            const next = lines[i_ref[0]]
            if (this.depth_of(next) !== dif_depth) return ''
            const sc = peel(next.trimStart())
            if (sc.Dif !== 'prev') return ''
            i_ref[0]++
            return first_snap(collect_children(i_ref))
        }

        const i_ref: [number] = [0]
        while (i_ref[0] < lines.length) {
            const line = lines[i_ref[0]]
            const d    = this.depth_of(line)

            if (d !== dif_depth) {
                // stray content line outside a Dif marker — skip
                i_ref[0]++
                continue
            }

            const sc       = peel(line.trimStart())
            const dif_type = sc.Dif as string | undefined

            if (!dif_type) {
                // line at dif_depth but not a Dif marker — skip
                i_ref[0]++
                continue
            }

            i_ref[0]++   // consume the marker before reading its children

            if (dif_type === 'unchanged') {
                // leaf — no children
                rows.push({ kind: 'squish', count: Number(sc.count) || 0 })
                continue
            }

            const children = collect_children(i_ref)
            const snap     = first_snap(children)

            if (dif_type === 'same') {
                rows.push({ kind: 'pair', left: snap, right: snap, tag: 'same' })
                continue
            }

            if (dif_type === 'change') {
                // peek for the mandatory Dif:prev sibling immediately after
                const prev_snap = peek_prev(i_ref)
                rows.push({
                    kind: 'pair', left: prev_snap, right: snap, tag: 'changed',
                    ops: this.char_diff_ops(prev_snap, snap),
                })
                continue
            }

            if (dif_type === 'prev') {
                // orphaned Dif:prev — parse error, not preceded by Dif:change
                console.warn('deDif: orphaned Dif:prev — skipping')
                continue
            }

            if (dif_type === '+') {
                rows.push({ kind: 'right_only', line: snap })
                continue
            }

            if (dif_type === '-') {
                rows.push({ kind: 'left_only', line: snap })
                continue
            }

            // unknown Dif type — skip gracefully for forward compatibility
            console.warn(`deDif: unknown Dif type "${dif_type}" — skipping`)
        }

        return rows
    },

//#endregion

    })
    })
</script>