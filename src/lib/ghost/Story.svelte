<script lang="ts">
    // Ghost: Story — mounts into the parent House via M.eatfunc({...}).
    // All methods below become House instance methods once eatfunc completes.
    //
    // ── This / The duality ───────────────────────────────────────────────────
    //
    //   This  — what is spontaneously happening right now, this session.
    //           Particles live as direct children of w, the Story work particle.
    //           Uppercase key: {Step:N}
    //           Carries: snap, got_snap, exp_snap, dige, ok, hollow, accepted.
    //           Has {watched:'ave'} in sc so enroll_watched() picks it up and
    //           any version bump on a Step is visible to StoryRun as a reactive
    //           change, even though the Step is not inside the ave container.
    //
    //   The   — the canonical record; what was on disk plus what was accepted.
    //           Lives in w.c.The, a separate C-tree never walked by snap or saved.
    //           Lowercase key: {step:N, dige:"hash"}
    //           Children: {note:1, frontier:1}  — singleton roaming note
    //                     {note:1, todo:"text"} — user annotation
    //
    //   This is analogous to the local / remote duality in git, but named to
    //   read naturally in prose: "This step" = live session, "The step" = record.
    //   The idiom is reusable anywhere there is a stored-thing ↔ live-thing joint.
    //
    // ── Swatches ─────────────────────────────────────────────────────────────
    //
    //   w/%watched:swatches  — one {note_coloring:"type", color:"#hex"} per key.
    //   Built lazily by ensure_swatch() before any note of that type reaches the UI.
    //   Fatal for the UI to encounter a note type with no swatch.
    //
    // ── exactly() — the wildcard dodge ──────────────────────────────────────
    //
    //   Numeric 1 is the wildcard value in this C system:
    //     o({Step:1})            — matches ALL particles that have a "Step" key
    //     o(exactly({Step:1}))   — matches ONLY Step === 1 (literal number one)
    //
    //   exactly() (from Y.ts) stringifies all values so the C engine sees a
    //   non-wildcard string and does a literal equality test.  Future language
    //   tooling may fold this into o()'s second argument.

    import { objectify, TheC }            from "$lib/data/Stuff.svelte"
    import type { TheD, Travel }          from "$lib/mostly/Selection.svelte"
    import { Selection }                  from "$lib/mostly/Selection.svelte"
    import { dig, exactly }               from "$lib/Y"
    import { onMount }                    from "svelte"
    import { now_in_seconds_with_ms }     from "$lib/p2p/Peerily.svelte"
    import { ANSWER_CALLS_TICK_MS, House, WormholeNav } from "$lib/O/Housing.svelte"

    let { M } = $props()
    let V = { Story: 0 }   // set Story: 1 here to enable drive/analysis debug logs

    // ── colour palette ───────────────────────────────────────────────────────
    // Assigned in first-seen order via ensure_swatch().
    // Frontier always gets FRONTIER_COLOR.  Prepend an entry here to reserve a
    // colour for a well-known type before the auto-assign loop reaches it.
    const NOTE_PALETTE   = ['#7bc8a4','#7ab0d4','#c9a96e','#b08fc8','#d49a7a','#7abfb8','#a8b87a','#c87aaa','#a07878']
    const FRONTIER_COLOR = '#c55'

    onMount(async () => {
    await M.eatfunc({

//#region snap-line codec
//
//  The snap line format is shared by toc.snap (The tree) and NNN.snap (step
//  content).  Each line encodes one C particle:
//
//    "${indent}${obj_part}\t${JSON.stringify(stringies)}"
//
//  indent: 2 spaces × depth.
//  obj_part: JSON of objecties metadata (ref ids, mung list) when present,
//            empty string otherwise.  Tab is the always-present separator.

    pad: (n: number) => String(n).padStart(3, '0'),

    enj(o: any): string { return JSON.stringify(o ?? {}) },
    ind(d: number): string { return '  '.repeat(d) },

    // encode one D particle as a snap line
    enL(D: TheD, d: number): string {
        const obj      = D.sc?.objecties
        const obj_part = obj ? this.enj(obj) : ''
        return `${this.ind(d)}${obj_part}\t${this.enj(D.sc?.stringies)}`
    },

    // decode one snap line → { d, objecties, stringies }
    // throws "no tab" on malformed lines so callers can catch and skip
    deL(line: string): { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null {
        const spaces = line.match(/^ */)?.[0].length ?? 0
        const d      = Math.floor(spaces / 2)
        const tab    = line.indexOf('\t')
        if (tab < 0) throw "no tab"
        const obj_raw = line.slice(spaces, tab)
        return {
            d,
            objecties: obj_raw ? JSON.parse(obj_raw) : {},
            stringies: JSON.parse(line.slice(tab + 1)),
        }
    },


//#region The helpers — canonical disk-backed toc tree

    step_c(container: TheC, n: number, key: string): TheC {
        // Universal find-or-create for any step-keyed particle.
        // Works for both The/{step:n} and This/{Step:n} (and any future container).
        // Always bumps container version on creation so watchers see the new particle.
        //
        //   step_c(w.c.The,  n, 'step')  — The's canonical record
        //   step_c(w.c.This, n, 'Step')  — This's live session record
        //
        // exactly() stringifies n → "n"; Stuff coerces it back to a number in o_kv,
        // so this correctly finds {step:2} regardless of whether n is number or string.
        const sc: Record<string,any> = {}
        sc[key] = n
        const existing = container.o(exactly(sc))[0]
        if (existing) return existing
        const c = container.i(sc)
        container.bump_version()
        return c
    },

    The_step(w: TheC, n: number): TheC {
        return this.step_c(w.c.The, n, 'step')
    },

    The_step_dige(w: TheC, n: number): string | undefined {
        return (w.c.The)?.o(exactly({ step: n }))[0]?.sc.dige 
    },

    The_frontier(w: TheC): number {
        // read the frontier step number from the {note:1,frontier:1} particle.
        // o({note:1,frontier:1}) — both values are wildcard 1, matching any particle
        // that has both "note" and "frontier" keys.  That is exactly what we want.
        // returns 0 when absent (clean / no unreviewed mismatch).
        for (const s of (w.c.The).o({ step: 1 })) {
            if ((s.o({ note: 1, frontier: 1 })).length > 0) {
                return s.sc.step
            }
        }
        return 0
    },

    The_set_frontier(w: TheC, n: number) {
        // move the singleton {note:1,frontier:1} note to step n, or clear (n=0).
        // "thing.drop(thing)" — the particle drops itself; the container checks
        // liveness before returning particles, so the old reference is immediately
        // invalidated and will not appear in future queries.
        const The = w.c.The
        for (const s of The.o({ step: 1 })) {
            for (const fr of s.o({ note: 1, frontier: 1 })) {
                fr.drop(fr)
            }
        }
        if (n > 0) {
            this.The_step(w, n).i({ note: 1, frontier: 1 })
            this.ensure_swatch(w, 'frontier')
        }
    },


//#region This helpers — live session step particles and colour swatches

    i_step(w: TheC, n: number): TheC {
        // find-or-create the live This/{Step:n} particle inside w.c.This.
        // w.c.This is the session step container, wired in Story_plan/Story().
        // Delegates to step_c which bumps version on creation.
        return this.step_c(w.c.This, n, 'Step')
    },

    step_i_note(w: TheC, n: number, note_sc: Record<string,any>, mode: 'add'|'move'|'remove') {
        // Unified note mutation on The/%step:N.  Always calls story_analysis().
        //
        //   'add'    — add note_sc as a new child of step n; ensure its swatch.
        //   'move'   — remove note_sc from every step first, then add to step n.
        //              Use for singleton notes (frontier) that must be unique globally.
        //   'remove' — drop the first matching note from step n.
        //
        // note:1 is always prepended so it appears first in any data UI display,
        // and if the caller already included it the spread is benign.
        // e.g. step_i_note(w, 3, {frontier:1}, 'move')
        //      → note_sc becomes {note:1, frontier:1}
        //
        // .matches() is used for removal — it honours the C wildcard rules,
        // which is correct here: we want "find the note that looks like this sc".
        note_sc = { note: 1, ...note_sc }

        const H   = this as House
        const The = w.c.The

        if (mode === 'move' || mode === 'remove') {
            for (const s of The.o({ step: 1 })) {
                for (const existing of s.o({ note: 1 })) {
                    if (existing.matches(note_sc)) {
                        existing.drop(existing)   // thing.drop(thing)
                        break
                    }
                }
            }
        }

        if (mode === 'add' || mode === 'move') {
            H.The_step(w, n).i(note_sc)
            for (const key of Object.keys(note_sc).filter(k => k !== 'note')) {
                H.ensure_swatch(w, key)
            }
        }

        H.story_analysis(w)
    },

    ensure_swatch(w: TheC, type: string) {
        // Ensure {note_coloring:type, color:"#hex"} exists in swatchC.
        // swatchC is cached on w.c from Story_plan.
        // Must be called before any note of a new type reaches story_analysis().
        const sw = w.c.swatchC
        const all_sw = sw.o({ note_coloring: 1 })
        if (all_sw.find(s => s.sc.note_coloring === type)) return

        const non_frontier = (sw.o({ note_coloring: 1 }))
            .filter(s => s.sc.note_coloring !== 'frontier')
        const color = type === 'frontier'
            ? FRONTIER_COLOR
            : NOTE_PALETTE[non_frontier.length % NOTE_PALETTE.length]
        sw.i({ note_coloring: type, color })
    },


//#region toc.snap codec — encode/decode The to/from disk
//
//  toc.snap is the on-disk form of The.  It uses the same snap line codec as
//  NNN.snap files, so a single reader handles everything.
//
//  Layout:
//    depth 0  — story root   \t{"story":"BookName"}
//    depth 1  — step         "  \t{"step":N,"dige":"hash"}"
//    depth 2  — note         "    \t{"note":1,...typeKV}"
//
//  snap text is never included in step lines — it lives in NNN.snap only.
//  Steps without a dige are written only when they carry notes, so user
//  annotations on not-yet-run steps survive a save.

    encode_toc_snap(w: TheC): string {
        const book  = w.sc.Book
        const lines: string[] = []

        lines.push(`\t${this.enj({ story: book })}`)

        const steps = (w.c.The)?.o({ step: 1 })
            .filter(s => !!s.sc.dige || (s.o({ note: 1 })).length > 0)
            .sort((a, b) => (a.sc.step as number) - (b.sc.step as number))

        for (const s of steps) {
            const sc: Record<string,any> = { step: s.sc.step }
            if (s.sc.dige) sc.dige = s.sc.dige
            lines.push(`${this.ind(1)}\t${this.enj(sc)}`)
            for (const noteC of s.o({ note: 1 })) {
                lines.push(`${this.ind(2)}\t${this.enj(noteC.sc)}`)
            }
        }
        return lines.join('\n') + '\n'
    },

    decode_toc_snap(snap: string, w: TheC) {
        // deserialise toc.snap into The/%step:N + notes, and pre-create hollow
        // This/{Step:N} particles for every known step so the UI strip shows all
        // expected pips immediately, before any step runs this session.
        //
        // idempotent: safe to call again with the same content.
        if (!snap) return
        let curStep: TheC | null = null

        for (const line of snap.split('\n').filter(Boolean)) {
            let parsed: ReturnType<typeof this.deL> | null = null
            try { parsed = this.deL(line) } catch { continue }
            if (!parsed) continue
            const sc: Record<string,any> = { ...parsed.stringies }

            if (parsed.d === 0) {
                // depth 0: story root — could validate Book match here in future

            } else if (parsed.d === 1 && sc.step != null) {
                // depth 1: step entry — find-or-create in The (uses exactly())
                curStep = this.The_step(w, sc.step as number)
                if (sc.dige) curStep.sc.dige = sc.dige

            } else if (parsed.d === 2 && sc.note && curStep) {
                // depth 2: note — JSON comparison avoids wildcard-1 over-matching
                const sc_j   = JSON.stringify(sc)
                const already = (curStep.o({ note: 1 }))
                    .find(n => JSON.stringify(n.sc) === sc_j)
                if (!already) {
                    curStep.i(sc)
                    for (const key of Object.keys(sc).filter(k => k !== 'note')) {
                        this.ensure_swatch(w, key)
                    }
                }
            }
        }
        // The is now populated — the UI strip is built from The/%step entries in
        // story_analysis (the_steps array), not from pre-created hollow stepsC entries.
        // This/{Step:n} is created only when a step actually runs this session.
    },


//#region note event handlers
//
//  Dispatched by the UI via storyH.elvisto('Story/Story', 'story_add_note', {…}).
//
//  note_sc format: { note:1, <typeKey>:<value>, … }
//    e.g. { note:1, frontier:1 }     — moves the frontier to this step
//         { note:1, todo:"fix me" }  — free-text annotation
//
//  The UI builds note_sc via peel(userstring) then prepends note:1.
//    peel("frontier")       → { frontier:1 }
//    peel("todo:fix me")    → { todo:"fix me" }

    async story_add_note(A: TheC, w: TheC, e?: TheC) {
        // note_sc from the UI: plain type keys, e.g. {frontier:1} or {todo:"fix me"}.
        // step_i_note prepends note:1 itself, so the UI does not need to include it.
        // frontier is a singleton: 'move' ensures only one exists across all steps.
        const n       = e?.sc.step_n  as number | undefined
        const note_sc = e?.sc.note_sc as Record<string,any> | undefined
        if (n == null || !note_sc) return
        const mode = ('frontier' in note_sc) ? 'move' : 'add'
        this.step_i_note(w, n, note_sc, mode)
    },

    async story_delete_note(A: TheC, w: TheC, e?: TheC) {
        const n        = e?.sc.step_n  as number | undefined
        const note_idx = e?.sc.note_idx as number | undefined
        if (n == null || note_idx == null) return
        const notes = this.The_step(w, n).o({ note: 1 })
        const noteC = notes[note_idx]
        if (noteC) noteC.drop(noteC)   // thing.drop(thing)
        this.story_analysis(w)
    },


//#region analysis — story_analysis, story_sel, story_accept

    parse_snap(s: string) {
        // snap string → array of deL-parsed line objects, nulls filtered
        if (!s) return []
        return s.split('\n').filter(Boolean)
            .map(l => this.deL(l))
            .filter(x => x !== null)
    },

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

    // story_analysis: write scalar state into ave/{story_analysis:1} and bump ave.
    // Called after every mutation that should surface in the UI.
    // Steps and swatches are not serialised here — they are live children of
    // This/swatchC inside ave, re-read fresh by the UI on every bump.
    story_analysis(w: TheC) {
        const run      = w.o({ run: 1 })[0]
        const The      = w.c.The
        const ave      = w.c.ave
        const thisC    = w.c.This
        if (!ave || !thisC) return   // Story_plan hasn't run yet
        const frontier = (run?.sc.frontier as number) ?? 0

        let open_at = run?.sc.open_at ?? null
        const failed_at = run?.sc.failed_at
        if (failed_at != null && open_at == null) open_at = run.sc.open_at = failed_at

        // w.c.This = w/%This,Story:book — visible in Stuffing directly.
        // No separate mirror needed; This is the real particle, not a copy.

        // notes from The/%step:n — keyed by step number.
        // TheC refs are safe here; notes only change on explicit user action.
        const notes: Record<number, TheC[]> = {}
        for (const theStep of ((w.c.The)?.o({ step: 1 }))) {
            const n     = theStep.sc.step
            const notes = theStep.o({ note: 1 })
            if (notes.length) notes[n] = notes
        }

        // the_steps: plain {n, dige} snapshot from The — the canonical expected set.
        // The UI builds the full strip skeleton from this, overlaying live stepsC data
        // for steps that have actually run this session.  sorted ascending.
        const the_steps = ((w.c.The)?.o({ step: 1 }))
            .map(s => ({ n: s.sc.step as number, dige: s.sc.dige  }))
            .sort((a, b) => a.n - b.n)

        const bad_count = thisC ? (thisC.o({ Step: 1 }) as any[]).filter(s => !s.sc.ok && !s.sc.accepted).length : 0

        const an          = ave.oai({ story_analysis: 1 })
        an.sc.run_sc      = run ? { ...run.sc } : null
        an.sc.frontier    = frontier
        an.sc.open_at        = open_at
        an.sc.bad_count   = bad_count
        an.sc.steps       = the_steps
        an.sc.notes       = notes
        ;V.Story && console.log(`📊 story_analysis: the_steps=${the_steps.length} live=${(w.c.This)?.o({Step:1}).length ?? 0} frontier=${frontier}`)
        ave.bump_version()
    },

    async story_sel(A: TheC, w: TheC, e?: TheC) {
        const run = w.o({ run: 1 })[0]
        if (run) run.sc.open_at = e?.sc.open_at ?? null
        this.story_analysis(w)
    },

    async story_accept_all(A: TheC, w: TheC) {
        // Accept every !ok step in This at once.  Used after a lenient run that
        // accumulated multiple mismatches.  Promotes all diges into The, marks
        // accepted, sheds snap text, then saves and resumes.
        const H   = this
        const run = w.o({ run: 1 })[0]
        if (!run) return
        const allBad = (w.c.This?.o({ Step: 1 }) ?? []).filter(s => !s.sc.ok)
        ;V.Story && console.log(`✅ story_accept_all: ${allBad.length} steps`)
        for (const step of allBad) {
            const n = step.sc.Step
            if (step.sc.dige) H.The_step(w, n).sc.dige = step.sc.dige
            step.sc.accepted = true
            delete step.sc.snap
            delete step.sc.got_snap
        }
        run.sc.frontier = 0
        H.The_set_frontier(w, 0)
        delete run.sc.failed_at
        delete run.sc.fetch_snap
        run.sc.paused = false
        run.sc.open_at   = null
        H.story_analysis(w)
        H.story_save()
        const sub = H.Story_subHouse(A, w)
        if (sub) H.story_drive(sub.Run, w, run)
    },


//#region story_accept

    async story_accept(A: TheC, w: TheC, e?: TheC) {
        // Accept a mismatch at step n:
        //   1. Clone This/{Step:n}.dige → The/{step:n}.dige.  The now reflects reality.
        //   2. Mark stepC.sc.accepted = true so the UI can dull the pip distinctively.
        //   3. Shed snap/got_snap from This/{Step:n} — they would appear as object refs
        //      in future story_snap walks and clutter the mung output.
        //   4. Advance the frontier note in The (for save/reload bookkeeping).
        //   5. Clear failure state; resume the drive.
        const H   = this
        const run = w.o({ run: 1 })[0]
        if (!run) return
        const n = e?.sc.accept_n as number | undefined
        if (n == null) return

        const The_all = (w.c.The).o({ step: 1 })
        const max_step = Math.max(0, ...The_all.map(s => s.sc.step as number))

        if (n >= max_step) {
            run.sc.frontier = 0
            H.The_set_frontier(w, 0)
        } else {
            run.sc.frontier = n
            H.The_set_frontier(w, n)
        }

        // This → The: promote the accepted dige into the canonical record
        const step = H.i_step(w, n)
        if (step.sc.dige) H.The_step(w, n).sc.dige = step.sc.dige
        step.sc.accepted = true
        delete step.sc.snap
        delete step.sc.got_snap
        ;V.Story && console.log(`✅ story_accept n=${n} dige=${step.sc.dige?.slice(0,8)} frontier=${run.sc.frontier}`)
        ;V.Story && console.log(`✅ story_accept n=${n} dige=${step.sc.dige?.slice?.(0,8)} frontier=${run.sc.frontier}`)

        delete run.sc.failed_at
        delete run.sc.fetch_snap
        run.sc.paused = false
        run.sc.open_at    = null

        H.story_analysis(w)
        H.story_save()

        const sub = H.Story_subHouse(A, w)
        if (sub) H.story_drive(sub.Run, w, run)
    },


//#region snap encoding — walk Run and encode to snap lines
//
//  story_snap walks the Run sub-House via Selection and encodes each particle
//  as a snap line.  story_matching rules govern what gets skipped, munged, or
//  traced (re-identified across runs by a stable identity).
//
//  Any object or function value not covered by munging rules falls through to
//  the objectify() path and ends up in objecties.ref — it is present in the
//  snap line but excluded from the diff comparison (which only uses stringies).
//  This is the "deL munges any ref still on %Story we didn't know about" rule:
//  unknown refs are automatically neutralised rather than causing errors or
//  polluting the diff.

    story_matching: [
        {
            // House-level particles: mung timer ids (they change every run)
            matching_any: [{ sc: { H: 1 } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_only: { mo: 1, interval: 1, id: 1 } }],
                      means: { munging: [{ sc: { id: 1 }, type: 'timer_id' }] } },
                ]
            }
        },
        {
            // Actor / worker level: skip self-ref bookkeeping; mung timestamps
            matching_any: [{ sc: { A: 1 } }, { sc: { w: 1 } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_only: { self: 1, est: 1 } }],
                      means: { skip: true } },
                    { matching_any: [{ sc_only: { self: 1, round: 1, age: 1 } }],
                      means: { munging: [{ sc: { age: 1 }, type: 'time' }] } },
                    { matching_any: [{ sc_only: { wasLast: 1, at: 1 } }],
                      means: { munging: [{ sc: { at: 1 }, type: 'time' }] } },
                    { matching_any: [{ sc_only: { chaFrom: 1, was: 1, v: 1, at: 1 } }],
                      means: { munging: [{ sc: { at: 1 }, type: 'time' }] } },
                ]
            }
        },
        {
            // Story work particle itself — any object ref on w that wasn't caught
            // by the rules above (The, toc_loaded, wh, run_path, etc.) is left to
            // the objectify() fallback in story_process_node, which puts it into
            // objecties.ref.  That ref is excluded from diff comparisons (only
            // stringies are diffed), so it is effectively munged without explicit
            // listing.  Add explicit munging entries here if a ref becomes noisy.
            matching_any: [{ sc: { Story: 1 } }],
            means: { thence_matching: [] }
        },
    ] as Array<any>,

    story_rule_matches(n: TheC, entry: any): boolean {
        if (entry.sc_only) {
            const want = Object.keys(entry.sc_only)
            if (Object.keys(n.sc).length !== want.length) return false
            return n.matches(entry.sc_only)
        }
        return n.matches(entry.sc)
    },

    story_process_node(n: TheC, T: Travel, D: TheD) {
        // classify one particle during the snap walk.
        // builds stringies (serialisable diff-comparable values),
        // ref (object values → stable ids via objectify — excluded from diff),
        // mung (keys deliberately excluded, e.g. timestamps).
        // sets T.sc.not=1 to skip the particle entirely.
        const active: Array<any> = [
            ...this.story_matching,
            ...(T.sc.up?.sc.thence_matching ?? []),
        ]

        const stringies: Record<string,any>    = {}
        const ref:       Record<string,string> = {}
        const mung:      string[]              = []
        const munging:   Array<any> = []
        const thence:    Array<any> = []
        const seen = new Set<string>()
        let   skip = false

        for (const rule of active) {
            if (!(rule.matching_any as Array<any>).some((e: any) => this.story_rule_matches(n, e))) continue
            for (const m of rule.means?.munging ?? []) munging.push(m)
            if (rule.means?.skip) { skip = true }
            for (const tw of rule.means?.thence_matching ?? []) {
                const key = JSON.stringify(tw)
                if (!seen.has(key)) { seen.add(key); thence.push(tw) }
            }
        }

        if (skip) { T.sc.not = 1; return }

        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
                // unknown object/fn ref — goes to objecties.ref, excluded from diff
                ref[k] = objectify(v)
                continue
            }
            const m = munging.find(r => Object.hasOwn(r.sc, k))
            if (m) { mung.push(k); continue }
            stringies[k] = v
        }

        const objecties: Record<string,any> = {}
        if (Object.keys(ref).length)  objecties.ref  = ref
        if (mung.length)              objecties.mung = mung

        D.sc.stringies  = stringies
        D.sc.objecties  = Object.keys(objecties).length ? objecties : undefined
        D.sc.copy       = { ...n.sc }
        D.sc.snap_copy ??= this.enj(stringies)
        if (mung.length) { D.c.munged ??= []; D.c.munged.push(mung) }
        if (thence.length) T.sc.thence_matching = thence
    },

    async story_snap(Run: House): Promise<string> {
        // walk Run via Selection, encoding each particle as a snap line.
        // Selection is cached on Run.c.snap_Se so it retains trace history across
        // steps — that history is what produces the changed/new/gone diff tags.
        const lines: Array<{ D: TheD, depth: number }> = []

        Run.c.snap_Se ??= new Selection()
        const Se: Selection = Run.c.snap_Se

        await Se.process({
            n:          Run,
            process_sc: { snap_root: 1 },
            match_sc:   {},
            trace_sc:   { snap_node: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                this.story_process_node(n, T, D)
                if (T.sc.not) return
                if (T.c.path.length === 1) {
                    T.sc.more = (n.o({})).filter(c => !c.sc.snap_root)
                }
                lines.push({ D, depth: T.c.path.length - 1 })
            },

            trace_fn: async (uD: TheD, n: TheC, _T: Travel) => {
                // stable identity for re-identification across runs
                const identity = Object.fromEntries(
                    Object.keys(n.sc).map(k => [`the_${k}`, n.sc[k]])
                )
                return uD.i({ snap_node: 1, ...identity })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined) => {
                const curr     = this.enj(D.sc.stringies)
                D.sc.changed   = bD?.sc.snap_copy != null && curr !== bD.sc.snap_copy
                D.sc.is_new    = !bD
                D.sc.snap_copy = curr
            },
        })

        return lines.map(({ D, depth }) => this.enL(D, depth)).join('\n') + '\n'
    },


//#region Story_subHouse and Story_plan

    Story_subHouse(A: TheC, w: TheC) {
        // Get-or-create the Run sub-House for this Book and wire its actors.
        // Called every tick from Story() — cheap when the House and actors already exist.
        // Returns { Run, book } or null when Book is missing or Run_A_<Book> is absent.
        const book = w.sc.Book 
        if (!book) { w.i({ see: '!Book' }); return null }

        const Run  = this.subHouse(book)
        Run.sc.Run = 1
        Run.c.no_ambient = true   // story_drive owns the clock; suppress ambient tick

        if (!Run.oa({ A: 1 })) {
            const init_fn = (Run as any)[`Run_A_${book}`] as Function | undefined
            if (!init_fn) { w.i({ error: `!Run_A_${book}` }); return null }
            init_fn.call(Run)
        }
        return { Run, book }
    },

    Story_plan(A: TheC, w: TheC, book: string) {
        // Called once when there is no %run yet — no run means no The/This either.
        // Creates all C structure fresh; wires w.c.* for the session.
        //
        //   w/%The,story:book   — canonical toc; from disk.
        //     /%step:N,dige
        //       /%note:1,...
        //   w/%This,Story:book  — live session steps (also placed in ave for reactivity).
        //     /%Step:N          — ok/dige/got_snap/accepted/saved
        //   H/%watched:ave
        //     /%swatches:1
        //     /%This,Story:book — same C particle as w's This (multi-placed)
        //     /%story_analysis:1
        //
        const H = this

        w.c.The  = w.i({ The:  1, story: book })
        w.c.This = w.i({ This: 1, Story: book })

        const ave   = H.oai_enroll(H, { watched: 'ave' })
        ave.i(w.c.This)                          // This appears in both w and ave
        w.c.swatchC = ave.oai({ swatches: 1 })
        w.c.ave     = ave

        H.oai_enroll(H, { watched: 'actions' })

        return w.i({ run: book, done: 0, steps_done: 0, total: 30, steps_total: 30, paused: false, mode: 'new' })
    },


//#region Story — main worker loop

    async Story(A: TheC, w: TheC) {
        const H    = this
        const sub  = H.Story_subHouse(A, w)
        if (!sub) return
        const { Run, book } = sub

        // Story_plan runs once — creates everything. If run exists, everything else does too.
        let run = w.o({ run: book })[0]
        if (!run) run = H.Story_plan(A, w, book)

        const fs_safe  = (s: string) => s.replace(/[:/\\?*"|<>]/g, '-')
        const run_path = `Story/${fs_safe(book)}`
        const wh       = await H.requesty_serial(w, 'wh')

        if (!run.c.toc_loaded) {
            // ── load toc.snap ──────────────────────────────────────────────
            // Wormhole.read_toc handles toc.json → toc.snap migration transparently
            // (reads toc.json if toc.snap absent, converts, writes toc.snap, returns).
            const toc_req = await wh.oai({ wh_path: run_path, wh_op: 'read_toc' })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ toc...' })

            const toc_snap = toc_req.sc.reply?.toc_snap ?? ''
            H.decode_toc_snap(toc_snap, w)   // fills The + pre-creates hollow This/{Step:N}

            const step_count = (w.c.The)?.o({ step: 1 }).length ?? 0
            run.sc.mode      = step_count > 0 ? 'check' : 'new'
            run.sc.frontier  = H.The_frontier(w)   // restored from {note:1,frontier:1}
            w.c.run_path     = run_path
            w.c.wh           = wh
            run.c.toc_loaded = true
            H.story_analysis(w)
        }

        if (run.sc.fetch_snap) {
            // ── fetch the expected snap for the failed step ────────────────
            // stored on This/{Step:N}.sc.exp_snap and shown in the diff panel.
            const n        = run.sc.fetch_snap
            const snap_req = await wh.oai({ wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ snap ${H.pad(n)}...` })

            H.i_step(w, n).sc.exp_snap = snap_req.sc.reply?.snap ?? '(not found)'
            delete run.sc.fetch_snap
            H.story_analysis(w)
        }

        if (!run.c.driving && !run.sc.paused) H.story_drive(Run, w, run)
        await H.story_ui(Run, w, run)
        w.i({ see: `${book} ${run.sc.done} [${run.sc.mode}]${run.sc.paused ? ' ⏸' : ''}` })
    },


//#region story_drive — three-phase async run loop
//
//  Three-phase async loop.  All phases are closures over run and the drive locals.
//
//   Phase 1 — do_step  (inside H beliefs mutex via post_do)
//     checks termination conditions, fires Run.elvisto(Run,'think') after 1ms,
//     then hands off to poll_step.
//
//   Phase 2 — poll_step  (plain setTimeout chain, no mutex)
//     waits for Run to go quiescent (finished_run timestamp fresh and stable),
//     then queues snap_step.
//
//   Phase 3 — snap_step  (inside H beliefs mutex via post_do)
//     encodes the snap, compares diges, stores on This/{Step:N}, schedules next.

    story_drive(Run: House, w: TheC, run: TheC) {
        if (run.c.driving) return
        run.c.driving = true

        const H    = this as House
        const TICK = ANSWER_CALLS_TICK_MS

        const update_status = async (label: string, cls = 'default') => {
            const wa = () => H.o({ watched: 'actions' })[0]
            await wa()?.r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa()?.bump_version()
        }

        // Phase 1: do_step
        const do_step = async () => {
            if (!run.c.driving || run.sc.paused) {
                console.log(`⏸ do_step skipped: driving=${run.c.driving} paused=${run.sc.paused}`)
                schedule(); return
            }
            const n = ((run.sc.done ?? run.sc.steps_done ?? 0) as number) + 1
            ;V.Story && console.log(`▷ do_step n=${n} mode=${run.sc.mode}`)
            ;V.Story && console.log(`The at n=${n}:`, (w.c.The)?.o({step:1}).map((s:any)=>s.sc.step+'→'+(s.sc.dige?s.sc.dige.slice(0,6):'no-dige')).join(', '))
            ;V.Story && console.log(`The_step_dige(${n}) =`, H.The_step_dige(w, n))

            if (run.sc.mode === 'new' && n > ((run.sc.total ?? run.sc.steps_total ?? 30) as number)) {
                run.c.driving = false; run.sc.paused = true
                H.story_analysis(w)
                await update_status('recorded ✓', 'start')
                console.log(`✓ Story: complete (${run.sc.total} steps)`)
                return
            }
            if (run.sc.mode === 'check' && !H.The_step_dige(w, n)) {
                run.c.driving = false; run.sc.paused = true
                // clear frontier when we reach the end — no outstanding mismatch
                run.sc.frontier = 0
                H.The_set_frontier(w, 0)
                // if we ran lenient, open the last !ok step so the user can review it
                const last_bad = (w.c.This?.o({ Step: 1 }) ?? [])
                    .filter(s => !s.sc.ok)
                    .sort((a, b) => b.sc.Step - a.sc.Step)[0]
                if (last_bad) run.sc.open_at = last_bad.sc.Step
                H.story_analysis(w)
                await update_status('done ✓', 'start')
                console.log(`✓ Story: check complete at n=${n}`)
                return
            }

            run.c.step_n     = n
            run.c.began_step = now_in_seconds_with_ms()
            setTimeout(() => { if (run.c.driving) Run.elvisto(Run, 'think') }, 1)
            setTimeout(poll_step, TICK)
        }

        // Phase 2: poll_step — wait for Run to go quiescent
        const poll_step = () => {
            if (!run.c.driving) return
            const f = Run.c.finished_run as number | null
            const quiescent = f != null
                && f > (run.c.began_step as number)
                && (now_in_seconds_with_ms() - f) < TICK * 1.5
            if (!quiescent) { setTimeout(poll_step, TICK); return }
            ;V.Story && console.log(`⏱ poll_step quiescent n=${run.c.step_n}`)
            H.post_do(snap_step, { see: 'story_snap' })
        }

        // Phase 3: snap_step — encode, compare, store, schedule next
        const snap_step = async () => {
            if (!run.c.driving) return
            const n = run.c.step_n
            run.sc.done  = n
            run.sc.steps_done = n   // keep old key in sync for any persisted reads

            const snap     = await this.story_snap(Run)
            const got_dige = await dig(snap)

            const step     = H.i_step(w, n)
            step.sc.unrun = false

            if (run.sc.mode === 'new') {
                step.sc.snap     = snap
                step.sc.dige     = got_dige
                step.sc.ok       = true
                step.sc.accepted = true   // new-mode steps are self-accepting; save loop uses this
                H.The_step(w, n).sc.dige = got_dige
                H.story_analysis(w)
                await update_status(
                    `recording ${H.pad(n)}/${H.pad(run.sc.total)}`, 'save')
                schedule()

            } else {
                const exp_dige = H.The_step_dige(w, n)
                const ok       = exp_dige === got_dige
                ;V.Story && console.log(`🔍 n=${n} ok=${ok} exp=${exp_dige?.slice(0,8)} got=${got_dige.slice(0,8)}`)
                step.sc.got_snap = snap
                step.sc.dige     = got_dige
                step.sc.ok       = ok
                H.story_analysis(w)

                if (!ok && !run.sc.lenient) {
                    run.c.driving     = false
                    run.sc.paused     = true
                    run.sc.failed_at  = n
                    run.sc.fetch_snap = n
                    run.sc.frontier   = n
                    H.The_set_frontier(w, n)
                    await update_status(`✗ step ${H.pad(n)}`, 'stop')
                    console.log(`⛔ Story: step ${H.pad(n)} mismatch — exp=${exp_dige?.slice(0,8)} got=${got_dige.slice(0,8)}`)
                    H.main(); return
                }
                if (!ok) console.log(`⚠ Story: step ${H.pad(n)} mismatch accepted (lenient)`)
                await update_status(`${ok ? '✓' : '⚠'} ${H.pad(n)}`, ok ? 'default' : 'save')
                ;V.Story && console.log(`✔ snap_step ok n=${n}, scheduling`)
                schedule()
            }
        }

        const schedule = () => {
            if (!run.c.driving) return
            ;V.Story && console.log(`⏭ schedule driving=${run.c.driving} paused=${run.sc.paused}`)
            setTimeout(() => {
                if (!run.c.driving) return
                H.post_do(do_step, { see: 'story_step' })
            }, 200)
        }

        schedule()
        console.log(`▶ Story: drive started for ${run.sc.run}`)
    },


//#region story_save — merge This→The and write toc.snap
//
//  Merge This → The for all ok and accepted steps, sync the frontier note,
//  encode to toc.snap, and ship via Wormhole.
//
//  Merge rule:
//   ok steps always update their step dige in The.
//   mismatch steps within the frontier also update (user accepted them).
//   steps beyond the frontier keep the dige from The (from load), preserving
//    the original ground truth for the unreviewed portion.

    story_save(this: House) {
        const storyH = this
        const A      = storyH.o({ A: 'Story' })[0]
        const w      = A?.o({ w: 'Story' })[0]
        if (!w) return

        const wh         = w.c.wh as any
        const run_path   = w.c.run_path 
        const run        = w.o({ run: 1 })[0]
        const frontier   = (run?.sc.frontier as number) ?? 0
        const The        = w.c.The
        const thisC      = w.c.This
        const all_steps = thisC ? thisC.o({ Step: 1 }) : []
        if (!all_steps.length && !The?.o({ step: 1 }).length) return
        ;V.Story && console.log(`💾 story_save: ${all_steps.length} steps, writable=${all_steps.filter(s=>s.sc.ok||s.sc.accepted).length}, saved=${all_steps.filter(s=>s.sc.saved).length}`)

        // The diges were already set by snap_step (new mode) and story_accept (check mode).
        // No merge loop needed — just sync the frontier note and encode.

        // sync frontier note so toc.snap reflects the current state exactly
        const all_the_steps = The.o({ step: 1 })
        const max_step      = Math.max(0, ...all_the_steps.map(s => s.sc.step as number))
        if (frontier > 0 && frontier < max_step) {
            storyH.The_set_frontier(w, frontier)
        } else {
            storyH.The_set_frontier(w, 0)   // clean: no outstanding mismatch
        }

        const snap       = storyH.encode_toc_snap(w)
        const step_count = all_the_steps.filter(s => !!s.sc.dige).length

        if (!wh || !run_path) {
            storyH.stashed ??= {}
            storyH.stashed[`${run?.sc.run}.snap`] = snap
            return
        }

        storyH.post_do(async () => {
            const toc_req = await wh.i({ wh_path: run_path, wh_op: 'write_toc', wh_data: snap })
            storyH.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })

            // write NNN.snap only where the content is new or changed:
            //   new-mode: step.sc.snap is set (this is the first recording)
            //   accepted mismatch: step.sc.got_snap is set and accepted=true (replacing old file)
            // Check-mode ok steps have got_snap but the file already exists on disk unchanged.
            for (const step of all_steps) {
                if (step.sc.saved) continue
                const is_new_recording = !!step.sc.snap          // new mode
                const is_accepted_change = step.sc.accepted && !!step.sc.got_snap  // check mode mismatch
                if (!is_new_recording && !is_accepted_change) continue
                const n            = step.sc.Step
                const snap_content = step.sc.snap ?? step.sc.got_snap
                if (!snap_content) continue
                ;V.Story && console.log(`💾 writing snap n=${n} new=${is_new_recording} accepted=${is_accepted_change}`)
                const snap_req = await wh.i({
                    wh_path: run_path, wh_op: 'write_snap',
                    wh_step: n, wh_data: snap_content,
                })
                storyH.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })
                step.sc.saved = true
            }

            const tag = frontier > 0 ? ` frontier:${frontier}` : ' clean'
            console.log(`💾 wormhole: ${run_path} (${step_count} steps${tag})`)
        }, { see: 'story_save' })
    },


//#region story_reset

    story_reset(this: House) {
        // Stop any in-flight drive, clear all toc and session state, drop actors.
        // The next Story invocation starts fresh: re-reads toc.snap, re-builds The,
        // re-creates hollow This/{Step:N}, etc.
        for (const h of this.all_House) {
            for (const w of (h as House).o({ w: 1 })) {
                for (const run of w.o({ run: 1 })) run.c.driving = false
                // drop all live Step particles from This (w.c.This = w/%This,Story:book)
                const thisC = w.c.This
                if (thisC) for (const s of thisC.o({ Step: 1 })) s.drop(s)
                delete (w as any).c.This
                delete (w as any).c.The   // will be re-created from disk on next load
                delete (w as any).c.The
                delete (w as any).c.toc_loaded
                delete (w as any).c.wh
                delete (w as any).c.run_path
            }
            delete (h as any).c?.snap_Se
        }

        this.todo = []
        for (const A of this.o({ A: 1 })) this.drop(A)
        this.prng = [1, 2, 3, 4]
        console.log(`🔄 ${this.name} reset`)
    },


//#region mechanisms — Run wiring, story_ui

    oai_enroll(target: TheC, sc: Record<string,any>): TheC {
        // Find-or-create a {watched:X} container on target, enrolling it exactly once.
        // o(sc)[0] retrieves any existing particle; on first creation enroll_watched()
        // traverses H/A*/w* to pick up any {watched:X} particles wherever they now live.
        const existing = target.o(sc)[0]
        if (existing) return existing
        const c = target.i(sc)
        this.enroll_watched()
        return c
    },

    Run_A_LeafFarm(this: House) {
        for (const [Aname, wname] of [
            ['farm',     'farm'],
            ['plate',    'plate'],
            ['enzymeco', 'enzymeco'],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🌿 ${this.name} LeafFarm wired`)
    },

    async story_ui(this: House, Run: House, w: TheC, run: TheC) {
        const wa = this.o({ watched: 'actions' })[0]
        if (!wa) return
        const paused = run.sc.paused
        const mode   = run.sc.mode ?? 'new'

        wa.oai({ action: 1, role: 'pause' }, {
            label: paused ? 'Resume' : 'Pause',
            icon:  paused ? '▶' : '⏸',
            cls:   paused ? 'start' : 'stop',
            fn: () => {
                run.sc.paused = !run.sc.paused
                if (!run.sc.paused && !run.c.driving) this.story_drive(Run, w, run)
            },
        })
        wa.oai({ action: 1, role: 'save'   }, { label: 'Save',  icon: '💾', cls: 'save',   fn: () => this.story_save()  })
        wa.oai({ action: 1, role: 'reset'  }, { label: 'Reset', icon: '🔄', cls: 'remove', fn: () => this.story_reset() })

        const lenient = !!run.sc.lenient
        wa.oai({ action: 1, role: 'lenient' }, {
            label: lenient ? 'Lenient ⚠' : 'Lenient', icon: '⚠', cls: lenient ? 'save' : 'default',
            fn: () => {
                run.sc.lenient = !run.sc.lenient
                if (run.sc.lenient && run.sc.failed_at && !run.c.driving) {
                    delete run.sc.failed_at; delete run.sc.fetch_snap
                    run.sc.paused = false
                    this.story_drive(Run, w, run)
                }
            },
        })
        await wa.r({ action: 1, role: 'status' }, {
            label:    `${mode} ${run.sc.failed_at ? '✗' + this.pad(run.sc.failed_at) : this.pad(run.sc.done ?? run.sc.steps_done ?? 0)}`,
            cls:      run.sc.failed_at ? 'stop' : mode === 'new' ? 'save' : 'default',
            disabled: true,
        })
    },



    })
    })
</script>