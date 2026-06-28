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
    //     "${indent}${stringies}\t${obj_part}"
    //
    //   indent:    2 spaces × depth.
    //   stringies: peel format "k:v  k2:v2" when all keys/values are sayable,
    //              otherwise JSON (always starts with "{").
    //              The important readable part — sits at the front of the line.
    //   obj_part:  JSON of objecties metadata (loopy, ks, mung list) when present;
    //              empty string otherwise.  Tab is the separator when obj_part is
    //              non-empty; omitted entirely when there are none
    //              (enL omits the tab — deL handles both forms).
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

    // ── spay marker ─────────────────────────────────────────────────────────────
    // The mirage that stands in for a spayed (acknowledged-noise) number.  One
    //  phrase for every spaying (EntropyArrest.md §2.1): Mahmoud Darwish's
    //   "في غيابها كوّنتُ صورتها" — in her absence, I formed her image.  A spay makes
    //    the real value absent (noise) and stands its image in its place.
    //  It is content-impossible: real snap content is ASCII peel (k:v, sayable) and
    //   carries none of the peel separators (, : =), so deL/peel never mistake a
    //    spayed hole for a real value, and the diff index can find every spayed line
    //     by scanning for this phrase across both sides of a row (§4.3).
    const SPAY_MARKER  = 'في غيابها كوّنتُ صورتها'
    // A band that blows past factor× its nailed baseline drops the marker and shows
    //  the real value flagged — a Dif:change that means something (§2.2).
    const SPAY_BLOWOUT = '‼'

    // ── re sugar ────────────────────────────────────────────────────────────────
    // A spayer's capture regex stays legible by hiding the verbose number/token
    //  capture behind a tag: `{NUM}` for a (possibly-fractional) number, `{TOK}` for
    //   a run of non-space (a hash / signature / timestamp).  The tag is what the
    //    author sees in the field AND what rides to disk in toc.snap; it expands to a
    //     real capturing group only when the RegExp is built (spay_desugar).  A legacy
    //      raw regex carries no tag and passes through untouched.
    const SPAY_RE_SUGAR: Record<string, string> = {
        '{NUM}': '(\\d+(?:\\.\\d+)?)',   // a possibly-fractional number (timings, ratios)
        '{INT}': '(\\d+)',               // a plain integer run (dates, times, ids, counters)
        // a whole PeelVal — one field's value (a hash / signature / opaque token).  Bounded to a
        //  run of non-comma, non-whitespace: `,` is the peel field separator (so this never gobbles
        //   the next key) and whitespace is the objecties tab boundary.  A value MAY hold `:`/`/`/`=`
        //    (peel splits only the first `:`), so those stay inside the capture.  Greedy, so it grabs
        //     the whole token even at end-of-line (a non-greedy `\S+?` there would match one char).
        '{TOK}': '([^,\\s]+)',
    }

    onMount(async () => {
    await M.eatfunc({

//#region wormhole Lines
// ── encode_wh_lines ────────────────────────────────────────────────────
// Encode a live TheC tree to snap-line text via Travel + enLine.
//
// Takes a TheC directly — no intermediate {sc, children?} item list.
// Travel walks the live tree; enLine encodes each particle.
//
// opt.matching — lematch rules passed to enLine as q.rules.  Rules may
//   carry means.omit_sc (silent drop), means.blockquote_these_sc (BQ),
//   means.munging (mung → fatal error), and entry.mk for mainkey matching.
// opt.all_knowing — if true, derive known mainkeys from opt.matching
//   entries that carry entry.mk; any particle whose mainkey is not in
//   that set is a fatal error (subtree skipped).
// opt.muted_log — if provided, omit_sc omissions are appended here.
//   Informational: does not block saving.
//
// Repeated C refs (C === C, same object appearing at multiple locations) are
// complained about — refs belong in .c, not the snap tree.  The loopy pair is
// still emitted so the snap reads sensibly:
//   shallowest appearance: objecties.loopy:N  (plus normal sc) — the original
//                          Travel.dive() descends into its children there.
//   all other appearances: objecties.loopy:N, stringies keys all set to 1
//                          (munged shadow — reads like the object, loopy signals ref).
//   forward() visits shallow-first (stack order); pass 1 records min depth
//   per C so pass 2 can stub deeper occurrences before the original is seen.
// Errors are FATAL — mung keys, refs.  (The all_knowing vocabulary gate is parked|
//   the encoder is relaxed about mainkeys so any tree, eg a Ting log, encodes.)
// Caller should refuse to save when errors.length > 0.
    async encode_wh_lines(
        C:   TheC,
        opt?: {
            matching?:        Array<any>
            all_knowing?:     boolean
            muted_log?:       Array<{ depth: number, mainkey: string, omitted: string[] }>
            max_child_depth?: number   // inclusive; children beyond this depth are silently cut
        }
    ): Promise<{ snap: string, errors: string[] }> {
        const H = this as any
        const errors: string[] = []
        const snap_lines: string[] = []

        // The encoder is relaxed about its type situatings — any mainkey encodes,
        //   so a Ting log of taps (mainkeys like tap|reveal|fly, not the Waft
        //   vocabulary) rides the same format.  The vocabulary check below is parked
        //   as an interesting relic|re-arm it by uncommenting both halves if a
        //   strict-protocol Waft ever wants its unknown mainkeys to be fatal again.
        // const known_mainkeys: Set<string> | null = opt?.all_knowing
        //     ? new Set(
        //         (opt.matching ?? [])
        //             .flatMap((r: any) => (r.matching_any ?? []).map((e: any) => e.mk).filter(Boolean))
        //       )
        //     : null

        // ── pass 1: collect all C refs ────────────────────────────────────────
        // Walk the tree once to tally appearances and track the shallowest depth
        // each C reaches.  No encoding yet.
        // ref_count:  C → how many times it appears in the tree.
        // ref_min_d:  C → shallowest depth at which it appears.
        //   The shallowest occurrence is the full-encode "original" — Travel.dive()
        //   will descend into its children there.  Deeper occurrences are stubs.
        //   forward() visits in stack order (shallow-first), so without this
        //   pre-pass the first visit would already win — but when the same C
        //   appears at equal depth in sibling subtrees, ref_min_d breaks the tie
        //   consistently, and makes the intent explicit.
        const ref_count = new Map<TheC, number>()
        const ref_min_d = new Map<TheC, number>()

        const Tr = new Travel()
        await Tr.dive({
            n: C,
            match_sc: {},
            each_fn: async (n: TheC, T: Travel) => {
                const d = T.c.path.length - 1
                if (opt?.max_child_depth !== undefined && d > opt.max_child_depth) {
                    T.sc.not = 1
                    return
                }
                ref_count.set(n, (ref_count.get(n) ?? 0) + 1)
                if (d < (ref_min_d.get(n) ?? Infinity)) ref_min_d.set(n, d)
            },
        })

        // ── pass 2: encode, now knowing which C are repeated ─────────────────
        // ref_seen:    C → assigned loopy integer (set on first encode of that C).
        // ref_encoded: C → true once the full-encode "original" line has been written.
        //   A repeated C encodes fully only at its shallowest depth (ref_min_d);
        //   deeper occurrences are stubs — decoder Travel.dive()s into the original.
        let ref_i = 0
        const ref_seen    = new Map<TheC, number>()
        const ref_encoded = new Set<TheC>()

        await Tr.forward(async (T: Travel) => {
            const n = T.sc.n as TheC
            if (!n) return

            const d = T.c.path.length - 1

            // mainkey of this particle — still read for the muted_log below.
            const mk = Object.keys(n.sc ?? {})[0]
            // all_knowing vocabulary gate — parked with known_mainkeys above.  When
            //   armed it made a mainkey outside the protocol fatal|relaxed now so any
            //   mainkey encodes (the Ting format).
            // if (known_mainkeys && mk && !known_mainkeys.has(mk)) {
            //     const path_str = T.c.path
            //         .map((pt: Travel) => (pt.sc.n as TheC)?.c?.snap_Line ?? '?')
            //         .join(' → ')
            //     errors.push(`unknown particle "${mk}" at depth ${d} — not in protocol — path: ${path_str}`)
            //     T.sc.not = 1
            //     return
            // }

            // Repeated C: assign a ref id on first encounter (any depth).
            const is_repeated = (ref_count.get(n) ?? 1) > 1
            if (is_repeated && !ref_seen.has(n)) {
                ref_seen.set(n, ref_i++)
                // Refs belong in .c, not the snap tree — a C reachable from more than
                //   one place is complained about.  The loopy pair below still forms a
                //   readable shadow so the snap stays inspectable, but the complaint is
                //   fatal, so a real Waft refuses to save a ref graph|a Ting is never
                //   saved, so for it this only surfaces in the splatter panel.
                errors.push(`repeated C ref (loopy ${ref_seen.get(n)}) at depth ${d} — refs belong in .c, not the snap tree`)
            }

            // Stub if already fully encoded, or if a shallower occurrence exists
            // that should be the original (deeper occurrences are always stubs).
            const is_stub = is_repeated && (ref_encoded.has(n) || d > (ref_min_d.get(n) ?? d))

            if (is_stub) {
                // Stub: munged shadow — every key shown as :1 so it reads like the object.
                // hid:1 marks this as the shadow; the original carries loopy:N only.
                const ref_id = ref_seen.get(n)!
                const shadow = Object.fromEntries(Object.keys(n.sc ?? {}).map(k => [k, 1]))
                const stub_line = H.enL({ d, stringies: shadow, objecties: { loopy: ref_id, hid: 1 } })
                snap_lines.push(stub_line)
                n.c.snap_Line = stub_line
                // Don't set T.sc.not — subtree was already skipped on first encode pass;
                // forward() visits nodes flat so subtree children handle themselves.
                return
            }

            const q: any = {
                d,
                rules: opt?.matching ?? [],
                loopy: is_repeated ? ref_seen.get(n) : undefined,
            }
            const lines = H.enLine(n, q)

            if (q.objecties?.mung?.length) {
                const path_str = T.c.path
                    .map((pt: Travel) => (pt.sc.n as TheC)?.c?.snap_Line ?? '?')
                    .join(' → ')
                errors.push(`mung keys [${(q.mung ?? []).join(', ')}] at depth ${d} — path: ${path_str}`)
                T.sc.not = 1
                return
            }

            for (const bqe of q.bq_errors ?? []) {
                errors.push(`blockquote error at depth ${d}: ${bqe}`)
            }

            if (q.omitted?.length && opt?.muted_log) {
                opt.muted_log.push({ depth: d, mainkey: mk ?? '?', omitted: q.omitted })
            }

            if (is_repeated) ref_encoded.add(n)
            n.c.snap_Line = lines?.[0] ?? ''
            for (const line of lines ?? []) snap_lines.push(line)
        })

        return { snap: snap_lines.join('\n') + '\n', errors }
    },

    // ── enWaft ─────────────────────────────────────────────────────────────────
    // Protocol front-end for encode_wh_lines: sets up the Waft matching rules
    // and calls encode_wh_lines(C, opt).
    //
    // opt.all_knowing — vocabulary gate is parked (see encode_wh_lines)|the encoder
    //   is relaxed about mainkeys so any tree encodes.  The flag is kept for the day
    //   the gate is re-armed.
    // opt.matching defaults to WAFT_PROTOCOL — the inline rules that attach
    //   omit_sc:{session keys} to every known mainkey via entry.mk matching.
    // opt.max_child_depth — depth limiting for the format: children deeper than this
    //   are silently cut, so a sprawling Ting encodes to a bounded snap.
    //
    // The SESSION_KEYS stripped silently are: active, created_at, new, not_found.
    // All other scalar keys on known particles encode normally.
    // Object/function values in .sc are still fatal (refs belong in .c).
    //
    // Returns { snap, errors, muted_log }.
    // muted_log entries: { depth, mainkey, omitted: string[] }
    // Errors are fatal — caller should refuse to save.
    async enWaft(
        C:   TheC,
        opt: {
            all_knowing?:     boolean
            matching?:        Array<any>
            muted_log?:       Array<{ depth: number, mainkey: string, omitted: string[] }>
            max_child_depth?: number
        } = {}
    ): Promise<{ snap: string, errors: string[], muted_log: Array<{ depth: number, mainkey: string, omitted: string[] }> }> {
        // Session-only sc fields: expected absences from every snap.
        // Review this list when new session-only patterns are introduced.
        const SESSION_KEYS: Record<string, 1> = { active: 1, created_at: 1, new: 1, not_found: 1 }

        // Matching rules for the Waft particle vocabulary.
        // Each rule matches by mainkey (entry.mk) and silently omits session keys.
        // Hierarchy is unstrict — (Waft|What|Doc|Point)** in any nesting order.
        const WAFT_PROTOCOL = ['Waft', 'What', 'Doc', 'Point', 'WaftTimes', 'Cursor'].map(mk => ({
            matching_any: [{ mk }],
            means: { omit_sc: SESSION_KEYS },
        }))

        opt.all_knowing ??= true   // parked — the vocabulary gate is commented out in encode_wh_lines
        opt.muted_log   ??= []
        opt.matching    ??= WAFT_PROTOCOL

        const { snap, errors } = await (this as any).encode_wh_lines(C, opt)
        return { snap, errors, muted_log: opt.muted_log }
    },

    // ── deWaft ─────────────────────────────────────────────────────────────────
    // Decode snap-line text to a live Waft TheC tree.
    // Wraps decode_wh_lines and applies a path fixup:
    //
    //   path — canonical Waft path; stamped onto C.sc.Waft regardless of
    //     what the snap root line encoded (snap root is informational only).
    //     Means you can copy and rename the files and they'll get the new path.
    //
    // Returns { Waft, errors }.  Waft is null on fatal parse error.
    deWaft(snap: string, path: string): { Waft: TheC | null, errors: string[] } {
        const { C, errors } = (this as any).decode_wh_lines(snap)
        if (!C) return { Waft: null, errors }

        C.sc.Waft = path  

        return { Waft: C, errors }
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

            // TODO: implement loopy decoding — reconstruct shared-C references.
            // For now, a stub line with objecties.loopy (subsequent appearance) is a fatal
            // error: we refuse to decode a snap we can't faithfully reconstruct.
            if (typeof objecties?.loopy === 'number') {
                throw new Error(`decode_wh_lines: loopy protocol not yet implemented (loopy=${objecties.loopy}, ks=${objecties.ks ?? '?'})`)
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
        // A key with : , \t \n mis-splits on decode (peel keys off the first : / =),
        //  so any of them forces JSON.  A VALUE is laxer: peel splits each comma-field
        //   on its FIRST : / = only, so a : or = that occurs INSIDE the value (after the
        //    key's separator) rides through verbatim — a regex like `self=1,round=…` keeps
        //     its : and = fine.  Only , \t \n actually break a value out of its field.
        const unsafe_key = /[:,\t\n]/
        const unsafe_val = /[,\t\n]/
        for (const [k, v] of Object.entries(obj)) {
            if (unsafe_key.test(k)) return JSON.stringify(obj)
            if (typeof v === 'number' || typeof v === 'boolean') continue
            if (typeof v !== 'string' || unsafe_val.test(v)) return JSON.stringify(obj)
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
            ? `${this.ind(parsed.d)}${str_part}\t${obj_part}`
            : `${this.ind(parsed.d)}${str_part}`
    },

    // ── deL ───────────────────────────────────────────────────────────────────
    //
    //   Decode one raw snap line → { d, objecties, stringies }.
    //   Handles both forms:
    //     with objecties:    "  self:1 round:20\t{\"mung\":[\"age\"]}"
    //     without objecties: "  self:1 round:20"
    //
    //   The tab is the separator between str_part and obj_part only when
    //   obj_part is present.  A line with no tab is stringies-only.
    //   stringies: peel format "k:v k2:v2" or JSON (starts with "{").
    //
    //   Note: deL only decodes the single line — BQ key/body lines that follow
    //   a node line are consumed separately by decode_wh_lines.

    deL(line: string): { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null {
        const spaces  = line.match(/^ */)?.[0].length ?? 0
        const d       = Math.floor(spaces / 2)
        const tab     = line.indexOf('\t')
        const str_raw = tab >= 0 ? line.slice(spaces, tab) : line.slice(spaces)
        const obj_raw = tab >= 0 ? line.slice(tab + 1) : ''
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
        loopy?: number              // integer serial — this is the shallowest/original appearance of a repeated C
        // outputs written back:
        snap_line?: string
        stringies?: Record<string, any>
        objecties?: Record<string, any> | undefined
        skip?: boolean
        dontSnap?: boolean          // a matched rule asked to emit this line but prune its subtree
        thence?: Array<any>
        mung?: string[]
        undef?: string[]            // keys present in sc with an undefined value — recorded, not inlined
        omitted?: string[]          // keys silently dropped by omit_sc means
        bq_errors?: string[]
    }): string[] | null {
        const mr = n.lematch(q.rules ?? [])
        q.skip   = mr.skip
        q.thence = mr.thence
        if (q.skip) return null

        // Collect means from all matched rules.
        // entry.mk: match any particle whose first sc key equals that string.
        // entry.sc_only / entry.sc: existing value-exact matching.
        // lematch doesn't expose which rules fired so we re-check here,
        // same pattern as before but now also collects omit_sc.
        const bq_keys:   Record<string, 1> = {}
        const omit_keys: Record<string, 1> = {}
        // spay (EntropyArrest.md §2).  The encoder keeps the snap HONEST — the real
        //  noisy number stays on disk and in the dige (the pivot in §2.3': forgiveness
        //   moved to compare time, not encode time).  Only `drop` bites here, because
        //    it is a structural omission (≡ today's mung — a key that should not appear
        //     at all), deterministic and value-free.  `blank`/`band` are value
        //      forgiveness: they capture a noisy number and forgive it against a marker
        //       or a formula — that needs BOTH the got and the expected number in hand,
        //        which only exists at compare time, so it lives in spay_normalize, not
        //         here.  See spay_normalize / collect_spayers below.
        const spay_drop_keys: Record<string, 1> = {}
        for (const rule of q.rules ?? []) {
            const matched = (rule.matching_any as any[] ?? []).some((entry: any) => {
                if (entry.mk)      return Object.keys(n.sc ?? {})[0] === entry.mk
                if (entry.sc_only) {
                    const want = Object.keys(entry.sc_only)
                    if (Object.keys(n.sc).length !== want.length) return false
                    return n.matches(entry.sc_only)
                }
                if (!entry.sc_has) throw `enLine rule uses neither mk, sc_only, nor sc_has`
                return n.matches(entry.sc_has)
            })
            if (!matched) continue
            if (rule.means?.blockquote_these_sc) Object.assign(bq_keys,   rule.means.blockquote_these_sc)
            if (rule.means?.omit_sc)             Object.assign(omit_keys, rule.means.omit_sc)
            // dontSnap: a structural means (EntropyArrest.md §5/§9 drop-kind) that keeps the
            //  node's own line but tells the snap walk to prune the subtree below it.  The
            //   line still encodes here; story_process_node forwards the flag, snap_H folds.
            if (rule.means?.dontSnap)            q.dontSnap = true
            const spays = rule.means?.spay
                ? (Array.isArray(rule.means.spay) ? rule.means.spay : [rule.means.spay])
                : []
            for (const sp of spays) {
                if (sp.kind === 'drop') Object.assign(spay_drop_keys, sp.these_sc ?? {})
            }
        }

        const stringies: Record<string, any> = {}
        const ref: Record<string, string> = {}
        const mung: string[] = []
        const undef: string[] = []
        const bq_pending: Array<{ key: string, value: string }> = []
        q.bq_errors = []

        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
                ref[k] = objectify(v)
                continue
            }
            const is_munged = mr.munging.find(r => Object.hasOwn(r.these_sc, k)) || spay_drop_keys[k]
            if (is_munged) { mung.push(k); continue }
            // An undefined value is not a clean scalar — inlining it would drop the key
            //  AND tip encode_stringies into the JSON-blob fallback.  Record it like mung
            //   (objecties.undef) so the key's absence is explicit and the rest of the
            //    line stays peelable.  undefined ≡ absent on decode, so nothing to rebuild.
            if (v === undefined) { undef.push(k); continue }
            // A boolean is not a clean scalar, and false is the worst of it: encode_stringies
            //  peels it inline as the bareword "false", which decodes back as a NON-EMPTY →
            //   truthy string, silently INVERTING the flag.  That corrupts live state from the
            //    most natural mistake there is (sc.k = false) — fatal here at the write, not
            //     drifted three ticks downstream.  A snapped boolean rides as 1 or ABSENT, so
            //      DELETE the key (or r()) rather than setting false.  true survives by luck
            //       (truthy in, truthy out), so only false is fatal — the silent corrupter.
            if (v === false) throw `enLine: ${Object.keys(n.sc)[0]} sc key "${k}"=false — a snapped boolean must be 1 or absent; delete the key instead (false decodes back as the truthy string "false" and inverts the flag)`

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
        if (q.loopy !== undefined) objecties.loopy = q.loopy   // shallowest/original appearance of a repeated C
        if (Object.keys(ref).length) objecties.ref = ref
        if (mung.length) objecties.mung = mung
        if (undef.length) objecties.undef = undef

        q.stringies = stringies
        q.objecties = Object.keys(objecties).length ? objecties : undefined
        q.mung      = mung
        q.undef     = undef

        // Parent line — inline keys only (BQ keys excluded above).  Honest: the real
        //  value rides to disk; blank/band forgiveness happens later, in spay_normalize.
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

    // ── spay_line ───────────────────────────────────────────────────────────────
    //   Apply one blank|band spayer to a rendered snap line, in place (§2.1–2.2).
    //   The spayer matches the noisy number via a regex on the line text, so it
    //    reaches a noise token wherever it sits — a mainkey value, a value-key, even
    //     inside an objecties JSON blob.  Returns the line unchanged if the regex
    //      finds nothing (a tolerant locator that over-matches still no-ops cleanly).
    //
    //   blank — replace the matched span with the mirage marker (glyph overridable).
    //   band  — snap the value to its nailed baseline while within tolerance, and
    //            render the real value flagged once it blows past factor× (§2.2).
    //            add_step_mult scales the baseline by the step number, so a counter
    //             that legitimately advances each step (round) stays inside the band.
    //   Both are deterministic within the band: the line carries the baseline (not the
    //    churning value), so the dige is stable until a run blows the band — the only
    //     diff that then survives is a real surprise.
    spay_line(line: string, sp: any, step_n?: number): string {
        if (!sp?.re) return line
        let rx: RegExp
        try { rx = new RegExp(this.spay_desugar(sp.re), sp.flags ?? 'g') }
        catch { return line }   // a malformed authored regex must never crash the snap

        if (sp.kind === 'blank') {
            return line.replace(rx, sp.glyph ?? SPAY_MARKER)
        }
        if (sp.kind === 'band') {
            const factor   = sp.factor ?? 10
            const baseline = sp.add_step_mult ? (sp.first ?? 1) * (step_n ?? 1) : (sp.first ?? 0)
            return line.replace(rx, (m: string) => {
                const v = parseFloat(m)
                if (Number.isNaN(v)) return m
                const hi = factor * baseline
                const lo = sp.floor ? baseline / factor : -Infinity
                const within = v <= hi && v >= lo
                // within band → the deterministic baseline + marker (stable dige, still
                //  findable by the §4.3 index); blown → the real value + blow-out flag.
                return within ? `${this.spay_num(baseline)} ${SPAY_MARKER}`
                              : `${m} ${SPAY_BLOWOUT}`
            })
        }
        return line
    },

    // ── spay_num ────────────────────────────────────────────────────────────────
    //   Render a band baseline back into the line.  Integers stay integers; floats
    //    keep a fixed precision so the baseline text is stable across runs.
    spay_num(v: number): string {
        return Number.isInteger(v) ? String(v) : v.toFixed(3)
    },

    // ── collect_spayers ───────────────────────────────────────────────────────────
    //   Flatten every blank|band spayer out of a matching-rule array (story_matching
    //    ∪ entropy_rules), recursing through thence_matching.  These are the value
    //     spayers used at COMPARE time by spay_normalize — `drop` is excluded (it bites
    //      at encode, a structural omission, not a value to forgive).  No live tree
    //       needed: a spayer is just { kind, re, glyph | first, factor, … }.
    collect_spayers(rules: Array<any>): Array<any> {
        const out: Array<any> = []
        const walk = (rs: Array<any>) => {
            for (const r of rs ?? []) {
                const m = r?.means
                if (!m) continue
                const spays = m.spay ? (Array.isArray(m.spay) ? m.spay : [m.spay]) : []
                // v2 (§8): pull any spayer carrying a `re` — both the new tol:band|any
                //  capture spayers and the legacy blank/band.  `drop` has no `re` (it names
                //   a key, bites at encode), so it is naturally excluded from the compare set.
                for (const sp of spays) if (sp?.re) out.push(sp)
                if (m.thence_matching) walk(m.thence_matching)
            }
        }
        walk(rules)
        return out
    },

    // ── spay_normalize ────────────────────────────────────────────────────────────
    //   The pivot (EntropyArrest.md §2.3').  Snaps are persisted HONEST — the real
    //    noisy number stays on disk.  Forgiveness happens here, at compare time, by
    //     running every value spayer over a snap's text line by line.  Applied to BOTH
    //      the got snap and the expected snap before they are compared, so a noisy span
    //       collapses to the same thing on each side:
    //        blank → both become the marker → the line matches regardless of the number
    //        band  → both snap to the step-scaled baseline while in tolerance → match;
    //                a value that blows the band keeps its real number + ‼ on that side
    //                 only → the lines differ → a real surprise survives.
    //   Because both sides normalize live, a stale fixture recorded at a different
    //    number still compares equal — no re-record needed.  The regex self-selects its
    //     lines (its lookbehind names the key), so applying every spayer to every line
    //      is safe; a non-matching line passes through untouched.
    spay_normalize(snap: string, spayers: Array<any>, step_n?: number): string {
        if (!spayers?.length) return snap
        return snap.split('\n')
            .map(line => spayers.reduce((l, sp) => this.spay_line(l, sp, step_n), line))
            .join('\n')
    },

    // ── Matching v2 — captures & surgical graft (EntropyArrest.md §8) ───────────────
    //   Supersedes spay_normalize's "blank BOTH sides to a marker, compare".  A spayer's
    //    `re` matches edges and carries CAPTURE GROUPS that are the noise; the compare is
    //     two-sided and reconstructive: graft the tolerated exp captures into got, then
    //      require the rebuilt got to EQUAL exp.  Nothing else can hide — a leftover diff
    //       means a real surprise.  No marker, no stored baseline (exp's capture IS the
    //        baseline, read live), no add_step_mult (exp already carries the per-step value).

    // _spay_flags — force global + indices (d) so capture spans are addressable, keeping
    //   any author-supplied flags.
    _spay_flags(sp: any): string {
        return Array.from(new Set(('gd' + (sp.flags ?? '')).split(''))).join('')
    },

    // spay_desugar — expand the legible {NUM}/{TOK} tags in an authored re into the
    //   real capturing groups before a RegExp is built (each tag → exactly one group,
    //    so the graft's group-counting is unaffected).  Idempotent on a raw regex.
    spay_desugar(re: string): string {
        return (re ?? '').replace(/\{NUM\}|\{INT\}|\{TOK\}/g, m => SPAY_RE_SUGAR[m] ?? m)
    },

    // spay_within — is the got capture tolerable against its exp pair?
    //   tol:any  → always (hashes / signatures / timestamps — graft wholesale).
    //   tol:band → numeric: within factor× either way, PLUS an absolute ±slack added AFTER
    //               the factor — `max(a,b) <= factor*min(a,b) + slack` (slack=0 default).  slack
    //                catches a value that jumps in ABSOLUTE terms but not ratio (compile ms: 100↔600
    //                 is 6× yet ±500 is fine); with slack=0 this is exactly the old ratio-only band —
    //                  its 0/0→in and x/0→out cases fall straight out of the one inequality.
    //   Legacy: a spayer with no `tol` is read as band when kind:band, else any.
    spay_within(g: string, e: string, tol: string, factor?: number, slack?: number): boolean {
        if (tol === 'any') return true
        if (tol === 'band') {
            const gv = parseFloat(g), ev = parseFloat(e)
            if (Number.isNaN(gv) || Number.isNaN(ev)) return false
            const a = Math.abs(gv), b = Math.abs(ev), f = factor ?? 10, s = slack ?? 0
            return Math.max(a, b) <= f * Math.min(a, b) + s
        }
        return false
    },

    // spay_graft_line — rebuild one got line toward its aligned exp line by grafting every
    //   tolerated capture (exp's value over got's span).  A spayer's Nth match on got pairs
    //    with its Nth match on exp; mismatched match counts ⇒ that spayer grafts nothing
    //     (the line will then fail to reconcile, which is the correct verdict).  A regex with
    //      no capture groups treats the whole match as capture 0 (legacy whole-match rules).
    spay_graft_line(gotLine: string, expLine: string, spayers: Array<any>, _step_n?: number): string {
        let out = gotLine
        for (const sp of spayers) {
            if (!sp?.re) continue
            let rx: RegExp
            try { rx = new RegExp(this.spay_desugar(sp.re), this._spay_flags(sp)) }
            catch { continue }   // a malformed authored regex must never crash the compare
            const gms = [...out.matchAll(rx)]
            const ems = [...expLine.matchAll(rx)]
            if (!gms.length || gms.length !== ems.length) continue
            const tol = sp.tol ?? (sp.kind === 'band' ? 'band' : 'any')
            const edits: Array<{ start: number, end: number, text: string }> = []
            for (let mi = 0; mi < gms.length; mi++) {
                const gm = gms[mi], em = ems[mi]
                const ng = gm.length - 1                                  // capture group count
                const groups = ng > 0 ? Array.from({ length: ng }, (_, k) => k + 1) : [0]
                for (const grp of groups) {
                    const gcap = gm[grp], ecap = em[grp]
                    if (gcap == null || ecap == null || gcap === ecap) continue
                    if (!this.spay_within(gcap, ecap, tol, sp.factor, sp.slack)) continue
                    const span = (gm as any).indices?.[grp]
                    if (!span) continue
                    edits.push({ start: span[0], end: span[1], text: ecap })
                }
            }
            // apply right-to-left so earlier offsets stay valid
            edits.sort((a, b) => b.start - a.start)
            for (const ed of edits) out = out.slice(0, ed.start) + ed.text + out.slice(ed.end)
        }
        return out
    },

    // spay_graft — the snap-level forgiveness verdict (§8.2).  Positional line zip: a value
    //   drift keeps line count + order, so a differing count is structural drift (not value
    //    noise) → not forgiven (the §2.4 ordering caveat landing correctly).  Each differing
    //     line must reconstruct EXACTLY into exp via grafts, else the step is a real surprise.
    //      Returns the graft log too, for the future §4.3 index (which spans got→exp rewrote).
    spay_graft(got: string, exp: string, spayers: Array<any>, step_n?: number):
            { forgiven: boolean, grafts: Array<{ line: number, from: string, to: string }> } {
        const grafts: Array<{ line: number, from: string, to: string }> = []
        if (!spayers?.length) return { forgiven: got === exp, grafts }
        const gl = got.split('\n'), el = exp.split('\n')
        if (gl.length !== el.length) return { forgiven: false, grafts }
        let forgiven = true
        for (let i = 0; i < gl.length; i++) {
            if (gl[i] === el[i]) continue
            const rebuilt = this.spay_graft_line(gl[i], el[i], spayers, step_n)
            if (rebuilt === el[i]) grafts.push({ line: i, from: gl[i], to: el[i] })
            else forgiven = false
        }
        return { forgiven, grafts }
    },

    // spay_classify_line — for the diff glow (Storui): does any spayer's `re` touch this
    //   got/exp line pair, and would grafting it FULLY reconcile the line?  Reuses
    //    spay_graft_line so the glow can never disagree with the verdict (spay_graft):
    //     a line glows 'graft' iff that same line would be forgiven at compare.
    //      'none'  — no Entcase reaches this line.
    //      'graft' — matched AND the grafted got reconstructs EXACTLY into exp → acknowledged
    //                 noise, forgiven at compare.
    //      'blown' — matched but a residual diff survives the graft → a real surprise on a
    //                 watched line.  Two ways in: a capture out of variance (band blown), OR
    //                  an UNCAPTURED change riding the same line as a forgiven capture (e.g. a
    //                   compiled-text edit next to a noise `at` timestamp).  The old classify
    //                    only checked the captures and missed the second case — it glowed
    //                     'graft' on a line the verdict refused, the exact "looks fuzz-ok but
    //                      isn't" trap.  Now the glow names the true blocker.
    spay_classify_line(gotLine: string, expLine: string, spayers: Array<any>): 'none' | 'graft' | 'blown' {
        let touched = false
        for (const sp of spayers) {
            if (!sp?.re) continue
            let rx: RegExp
            try { rx = new RegExp(this.spay_desugar(sp.re), this._spay_flags(sp)) } catch { continue }
            const gms = [...gotLine.matchAll(rx)]
            const ems = [...expLine.matchAll(rx)]
            if (!gms.length || gms.length !== ems.length) continue
            for (let mi = 0; mi < gms.length && !touched; mi++) {
                const gm = gms[mi], em = ems[mi]
                const ng = gm.length - 1
                const groups = ng > 0 ? Array.from({ length: ng }, (_, k) => k + 1) : [0]
                for (const grp of groups) if (gm[grp] != null && em[grp] != null) { touched = true; break }
            }
        }
        if (!touched) return 'none'
        // graft only if the WHOLE line reconstructs — the same test the verdict applies.
        return this.spay_graft_line(gotLine, expLine, spayers) === expLine ? 'graft' : 'blown'
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

        // norm_line: indent + canonical stringies JSON + tab + canonical objecties JSON.
        // Both halves included — a line whose stringies are unchanged but objecties changed
        // (e.g. a ref key renamed) must not align as equal.
        const norm_line = (line: string): string => {
            const indent  = line.match(/^ */)?.[0] ?? ''
            const tab     = line.indexOf('\t')
            const str_raw = tab >= 0 ? line.slice(indent.length, tab).trimEnd() : line.slice(indent.length).trimEnd()
            const obj_raw = tab >= 0 ? line.slice(tab + 1) : ''
            try {
                const obj_norm  = obj_raw ? JSON.stringify(JSON.parse(obj_raw)) : ''
                const stringies = str_raw.startsWith('{') ? JSON.parse(str_raw) : peel(str_raw)
                return indent + JSON.stringify(stringies) + '\t' + obj_norm
            } catch { return indent + str_raw + '\t' + obj_raw }
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
    //   Tab handling: the tab in objectied lines (str_part\t{...}) is not
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

    enDif(rows: any[], dif_depth: number, spayers?: Array<any>): string[] {
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
                // got side under Dif:change; prev side under the Dif:prev sibling.
                //  When spayers are in hand, tag the marker with how an Entcase sees this
                //   line — `,spay:graft` (acknowledged noise that would forgive) or
                //    `,spay:blown` (a watched line whose value blew its band) — so a
                //     pasted diff carries the same signal the live glow shows.  deDif reads
                //      only sc.Dif, so the extra key round-trips harmlessly.
                const sc = spayers?.length
                    ? this.spay_classify_line(row.right, row.left, spayers) : 'none'
                out.push(`${ind(dif_depth)}Dif:change${sc !== 'none' ? `,spay:${sc}` : ''}`)
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